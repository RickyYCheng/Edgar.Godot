namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold
{
	using System;
	using System.Collections.Generic;
	using System.Linq;
	using Graphs.Algorithms;
	using Graphs.DataStructures;
	using Internal;
	using PlanarFaceTraversal;

	/// <summary>
	/// Implementation of the Boyer-Myrvol algorithm.
	/// Inspired by the implementation in the Boost library.
	/// </summary>
	/// <typeparam name="T">Vertex type.</typeparam>
	public class BoyerMyrvold<T>
	{
		private IGraph<Vertex<T>> transformedGraph;

		private Dictionary<T, Vertex<T>> originalVertexMapping;

		private Vertex<T>[] verticesByDFSNumberNew;

		private Vertex<T>[] verticesByLowPointNew;

		private List<IEdge<Vertex<T>>> selfLoopsNew;

		private Stack<MergeInfo> mergeStackNew;

		#region Public API

		/// <summary>
		/// Tries to get faces of a planar embedding of a given graph.
		/// </summary>
		/// <param name="graph">Graph</param>
		/// <param name="faces">Faces of a planar embedding if planar, null otherwise</param>
		/// <returns>True if planar, false otherwise</returns>
		public bool TryGetPlanarFaces(IGraph<T> graph, out PlanarFaces<T> faces)
		{
			if (!IsPlanar(graph, out var embedding))
			{
				faces = null;
				return false;
			}

			var planarFaceVisitor = new GetPlanarFacesVisitor<T>();
			PlanarFaceTraversal.Traverse(graph, embedding, planarFaceVisitor);

			faces = new PlanarFaces<T>(planarFaceVisitor.Faces);
			return true;
		}

		/// <summary>
		/// Checks if a given graph is planar.
		/// </summary>
		/// <param name="graph">Graph</param>
		/// <returns>True if planar, false otherwise</returns>
		public bool IsPlanar(IGraph<T> graph)
		{
			return IsPlanar(graph, out var _);
		}

		/// <summary>
		/// Checks if a given graph is planar and provides a planar embedding if so.
		/// </summary>
		/// <param name="graph">Graph</param>
		/// <param name="embedding">Planar embedding if a given graph is planar, null otherwise</param>
		/// <returns>True if planar, false otherwise</returns>
		public bool IsPlanar(IGraph<T> graph, out PlanarEmbedding<T> embedding)
		{
			// Transforms input graph
			TransformGraph(graph);

			// Init helper collections
			selfLoopsNew = new List<IEdge<Vertex<T>>>();
			mergeStackNew = new Stack<MergeInfo>();

			// Use DFS traversal to add basic information to each of the vertices
			var visitor = new DFSTraversalVisitor<T>();
			DFSTraversal.Traverse(transformedGraph, visitor);

			// Sort vertices by dfs number ASC
			verticesByDFSNumberNew = BucketSort.Sort(transformedGraph.Vertices, x => x.DFSNumber, transformedGraph.VerticesCount);

			// Sort vertices by low point ASC
			verticesByLowPointNew = BucketSort.Sort(transformedGraph.Vertices, x => x.LowPoint, transformedGraph.VerticesCount);

			// Init vertex fields
			foreach (var vertex in transformedGraph.Vertices)
			{
				vertex.BackEdges = new List<IEdge<Vertex<T>>>();
				vertex.Visited = int.MaxValue;
				vertex.BackedgeFlag = transformedGraph.VerticesCount + 1;
				vertex.Flipped = false;

				var dfsParent = vertex.Parent;

				if (vertex != dfsParent)
				{
					var parentEdge = vertex.DFSEdge;
					vertex.FaceHandle = new FaceHandle<Vertex<T>>(vertex, parentEdge);
					vertex.DFSChildHandle = new FaceHandle<Vertex<T>>(dfsParent, parentEdge);
				}
				else
				{
					vertex.FaceHandle = new FaceHandle<Vertex<T>>(vertex, (Vertex<T>)null); // TODO: change
					vertex.DFSChildHandle = new FaceHandle<Vertex<T>>(dfsParent, (Vertex<T>)null);
				}

				vertex.CanonicalDFSChild = vertex;
				vertex.PertinentRoots = new LinkedList<FaceHandle<Vertex<T>>>();
				vertex.SeparatedDFSChildList = new LinkedList<Vertex<T>>();
			}

			// Init separated dfs child lists
			//
			// Original Boost comment:
			// We need to create a list of not-yet-merged depth-first children for
			// each vertex that will be updated as bicomps get merged. We sort each
			// list by ascending lowpoint, which allows the externally_active
			// function to run in constant time, and we keep a pointer to each
			// vertex's representation in its parent's list, which allows merging
			//in constant time.
			foreach (var vertex in verticesByLowPointNew)
			{
				var dfsParent = vertex.Parent;

				if (vertex != dfsParent)
				{
					var node = dfsParent.SeparatedDFSChildList.AddLast(vertex);
					vertex.SeparatedNodeInParentList = node;
				}
			}

			// Call the main algorithm
			var isPlanar = IsPlanar();

			if (!isPlanar)
			{
				embedding = null;
				return false;
			}

			embedding = GetPlanarEmbedding();
			return true;
		}

		#endregion

		#region Helper methods

		/// <summary>
		/// Transforms a given graph to a representation that is useful for the algorithm.
		/// It enhances all vertices with additional information.
		/// </summary>
		/// <param name="graph"></param>
		private void TransformGraph(IGraph<T> graph)
		{
			transformedGraph = new UndirectedAdjacencyListGraph<Vertex<T>>();

			originalVertexMapping = new Dictionary<T, Vertex<T>>();

			foreach (var vertex in graph.Vertices)
			{
				var newVertex = new Vertex<T>(vertex);
				originalVertexMapping.Add(vertex, newVertex);
				transformedGraph.AddVertex(newVertex);
			}

			foreach (var edge in graph.Edges)
			{
				var source = originalVertexMapping[edge.Source];
				var target = originalVertexMapping[edge.Target];
				transformedGraph.AddEdge(source, target);
			}
		}

		/// <summary>
		/// Constructs a planar embedding from individual face handles.
		/// </summary>
		/// <returns></returns>
		private PlanarEmbedding<T> GetPlanarEmbedding()
		{
			var embedding = new Dictionary<T, List<IEdge<T>>>();
			foreach (var vertex in transformedGraph.Vertices)
			{
				var faceHandle = vertex.FaceHandle;
				embedding[vertex.Value] = faceHandle.GetEdges()?.Select(x => new Edge<T>(x.Source.Value, x.Target.Value)).Cast<IEdge<T>>().ToList();
			}

			return new PlanarEmbedding<T>(embedding);
		}

		#endregion

		#region Boyer Myrvold algorithm

		/// <summary>
		/// The main entry point of the algorithm.
		/// </summary>
		/// <returns></returns>
		private bool IsPlanar()
		{
			// Original Boost comment:
			// This is the main algorithm: starting with a DFS tree of embedded
			// edges (which, since it's a tree, is planar), iterate through all
			// vertices by reverse DFS number, attempting to embed all backedges
			// connecting the current vertex to vertices with higher DFS numbers.
			//
			// The walkup is a procedure that examines all such backedges and sets
			// up the required data structures so that they can be searched by the
			// walkdown in linear time. The walkdown does the actual work of
			// embedding edges and flipping bicomps, and can identify when it has
			// come across a kuratowski subgraph.

			foreach (var vertex in verticesByDFSNumberNew.Reverse())
			{
				Walkup(vertex);

				if (!Walkdown(vertex))
				{
					return false;
				}
			}

			Cleanup();

			return true;
		}

		private void Walkup(Vertex<T> vertex)
		{
			// Original Boost comment:
			// The point of the walkup is to follow all backedges from v to
			// vertices with higher DFS numbers, and update pertinent_roots
			// for the bicomp roots on the path from backedge endpoints up
			// to v. This will set the stage for the walkdown to efficiently
			// traverse the graph of bicomps down from v.

			foreach (var neighbour in transformedGraph.GetNeighbours(vertex))
			{
				Walkup(vertex, new Edge<Vertex<T>>(vertex, neighbour));
			}
		}

		private void Walkup(Vertex<T> vertex, IEdge<Vertex<T>> edge)
		{
			var source = edge.Source;
			var target = edge.Target;

			if (source.Equals(target))
			{
				selfLoopsNew.Add(edge);
				return;
			}

			var w = vertex.Equals(source) ? target : vertex;

			if (w.DFSNumber < vertex.DFSNumber || edge.Equals(w.DFSEdge))
				return;

			w.BackEdges.Add(edge);
			var timestamp = vertex.DFSNumber;
			w.BackedgeFlag = timestamp;

			var leadVertex = w;

			while (true)
			{
				var foundRoot = true;

				// Move to the root of the current bicomp or the first visited
				// vertex on the bicomp by going up each side in parallel
				foreach (var faceVertex in IterateBothSides(leadVertex))
				{
					if (faceVertex.Visited == timestamp)
					{
						foundRoot = false;
						break;
					}

					leadVertex = faceVertex;
					leadVertex.Visited = timestamp;
				}

				// If we've found the root of a bicomp through a path we haven't
				// seen before, update pertinent_roots with a handle to the
				// current bicomp. Otherwise, we've just seen a path we've been
				// up before, so break out of the main while loop.
				if (foundRoot)
				{
					var dfsChild = leadVertex.CanonicalDFSChild;
					var parent = dfsChild.Parent;

					dfsChild.DFSChildHandle.FirstVertex.Visited = timestamp;
					dfsChild.DFSChildHandle.SecondVertex.Visited = timestamp;

					if (dfsChild.LowPoint < vertex.DFSNumber ||
					    dfsChild.LeastAncestor < vertex.DFSNumber
					)
					{
						parent.PertinentRoots.AddLast(dfsChild.DFSChildHandle);
					}
					else
					{
						parent.PertinentRoots.AddFirst(dfsChild.DFSChildHandle);
					}

					if (parent != vertex && parent.Visited != timestamp)
					{
						leadVertex = parent;
					}
					else
						break;
				}
				else
				{
					break;
				}
			}
		}

		private bool Walkdown(Vertex<T> vertex)
		{
			// Original Boost comment:
			// This procedure is where all of the action is - pertinent_roots
			// has already been set up by the walkup, so we just need to move
			// down bicomps from v until we find vertices that have been
			// labeled as backedge endpoints. Once we find such a vertex, we
			// embed the corresponding edge and glue together the bicomps on
			// the path connecting the two vertices in the edge. This may
			// involve flipping bicomps along the way.

			mergeStackNew.Clear();

			while (vertex.PertinentRoots.Count != 0)
			{
				var rootFaceHandle = vertex.PertinentRoots.First.Value;
				vertex.PertinentRoots.RemoveFirst();
				var currentFaceHandle = rootFaceHandle;

				while (true)
				{
					Vertex<T> firstSideVertex = null;
					Vertex<T> secondSideVertex = null;
					var firstTail = currentFaceHandle.Anchor;
					var secondTail = currentFaceHandle.Anchor;
					var firstSideVertices = IterateFirstSide(currentFaceHandle);

					foreach (var faceVertex in firstSideVertices)
					{
						if (Pertinent(faceVertex, vertex) || ExternallyActive(faceVertex, vertex))
						{
							firstSideVertex = faceVertex;
							secondSideVertex = faceVertex;
							break;
						}

						firstTail = faceVertex;
					}

					if (firstSideVertex == null || firstSideVertex == currentFaceHandle.Anchor)
					{
						break;
					}

					foreach (var faceVertex in IterateSecondSide(currentFaceHandle))
					{
						if (Pertinent(faceVertex, vertex) || ExternallyActive(faceVertex, vertex))
						{
							secondSideVertex = faceVertex;
							break;
						}

						secondTail = faceVertex;
					}

					Vertex<T> chosen = null;
					var choseFirstUpperPath = false;

					if (InternallyActive(firstSideVertex, vertex))
					{
						chosen = firstSideVertex;
						choseFirstUpperPath = true;
					}
					else if (InternallyActive(secondSideVertex, vertex))
					{
						chosen = secondSideVertex;
						choseFirstUpperPath = false;
					}
					else if (Pertinent(firstSideVertex, vertex))
					{
						chosen = firstSideVertex;
						choseFirstUpperPath = true;
					}
					else if (Pertinent(secondSideVertex, vertex))
					{
						chosen = secondSideVertex;
						choseFirstUpperPath = false;
					}
					else
					{
						// If there's a pertinent vertex on the lower face
						// between the first_face_itr and the second_face_itr,
						// this graph isn't planar.
						foreach (var faceVertex in IterateFace(firstSideVertex, firstTail))
						{
							if (faceVertex == secondSideVertex)
							{
								break;
							}

							if (Pertinent(faceVertex, vertex))
							{
								return false;
							}
						}


						// Otherwise, the fact that we didn't find a pertinent
						// vertex on this face is fine - we should set the
						// short-circuit edges and break out of this loop to
						// start looking at a different pertinent root.
						if (firstSideVertex == secondSideVertex)
						{
							if (firstTail != vertex)
							{
								var first = firstTail.FaceHandle.FirstVertex;
								var second = firstTail.FaceHandle.SecondVertex;

								var tmpFirstTail = firstTail;
								firstTail = first == firstSideVertex ? second : first;
								firstSideVertex = tmpFirstTail;
							}
							else if (secondTail != vertex)
							{
								var first = secondTail.FaceHandle.FirstVertex;
								var second = secondTail.FaceHandle.SecondVertex;

								var tmpSecondTrail = secondTail;
								secondTail = first == secondSideVertex ? second : first;
								secondSideVertex = tmpSecondTrail;
							}
							else
							{
								break;
							}
						}

						firstSideVertex.CanonicalDFSChild = rootFaceHandle.FirstVertex.CanonicalDFSChild;
						secondSideVertex.CanonicalDFSChild = rootFaceHandle.SecondVertex.CanonicalDFSChild;

						rootFaceHandle.SetFirstVertex(firstSideVertex);
						rootFaceHandle.SetSecondVertex(secondSideVertex);

						if (firstSideVertex.FaceHandle.FirstVertex == firstTail)
						{
							firstSideVertex.FaceHandle.SetFirstVertex(vertex);
						}
						else
						{
							firstSideVertex.FaceHandle.SetSecondVertex(vertex);
						}

						if (secondSideVertex.FaceHandle.FirstVertex == secondTail)
						{
							secondSideVertex.FaceHandle.SetFirstVertex(vertex);
						}
						else
						{
							secondSideVertex.FaceHandle.SetSecondVertex(vertex);
						}

						break;
					}

					// When we unwind the stack, we need to know which direction
					// we came down from on the top face handle
					var choseFirstLowerPath = (choseFirstUpperPath && chosen.FaceHandle.FirstVertex == firstTail)
											  || (!choseFirstUpperPath && chosen.FaceHandle.FirstVertex == secondTail);

					//If there's a backedge at the chosen vertex, embed it now
					Vertex<T> w;
					if (chosen.BackedgeFlag == vertex.DFSNumber)
					{
						w = chosen;

						chosen.BackedgeFlag = transformedGraph.VerticesCount + 1;

						foreach (var edge in chosen.BackEdges)
						{
							if (choseFirstLowerPath)
							{
								chosen.FaceHandle.PushFirst(edge);
							}
							else
							{
								chosen.FaceHandle.PushSecond(edge);
							}
						}
					}
					else
					{
						mergeStackNew.Push(new MergeInfo(chosen, choseFirstUpperPath, choseFirstLowerPath));
						currentFaceHandle = chosen.PertinentRoots.First.Value;
						continue;
					}

					//Unwind the merge stack to the root, merging all bicomps
					var nextBottomFollowsFirst = choseFirstUpperPath;

					while (mergeStackNew.Count != 0)
					{
						var bottomPathFollowsFirst = nextBottomFollowsFirst;
						var mergeInfo = mergeStackNew.Pop();

						var mergePoint = mergeInfo.Vertex;
						nextBottomFollowsFirst = mergeInfo.ChoseFirstUpperPath;
						var topPathFollowsFirst = mergeInfo.ChoseFirstLowerPath;

						var topHandle = mergePoint.FaceHandle;
						var bottomHandle = mergePoint.PertinentRoots.First.Value;
						var bottomDFSChild = mergePoint.PertinentRoots.First.Value.FirstVertex.CanonicalDFSChild;

						RemoveVertexFromSeparatedDFSChildList(mergePoint.PertinentRoots.First.Value.FirstVertex.CanonicalDFSChild);

						mergePoint.PertinentRoots.RemoveFirst();

						if (topPathFollowsFirst && bottomPathFollowsFirst)
						{
							bottomHandle.Flip();
							topHandle.GlueFirstToSecond(bottomHandle);
						}
						else if (!topPathFollowsFirst && bottomPathFollowsFirst)
						{
							bottomDFSChild.Flipped = true;
							topHandle.GlueSecondToFirst(bottomHandle);
						}
						else if (topPathFollowsFirst && !bottomPathFollowsFirst)
						{
							bottomDFSChild.Flipped = true;
							topHandle.GlueFirstToSecond(bottomHandle);
						}
						else //!top_path_follows_first && !bottom_path_follows_first
						{
							bottomHandle.Flip();
							topHandle.GlueSecondToFirst(bottomHandle);
						}
					}

					//Finally, embed all edges (v,w) at their upper end points
					w.CanonicalDFSChild = rootFaceHandle.FirstVertex.CanonicalDFSChild;

					foreach (var edge in chosen.BackEdges)
					{
						if (nextBottomFollowsFirst)
						{
							rootFaceHandle.PushFirst(edge);
						}
						else
						{
							rootFaceHandle.PushSecond(edge);
						}
					}

					chosen.BackEdges.Clear();
					currentFaceHandle = rootFaceHandle;
				}
			}

			return true;
		}

		private void Cleanup()
		{
			// If the graph isn't biconnected, we'll still have entries
			// in the separated_dfs_child_list for some vertices. Since
			// these represent articulation points, we can obtain a
			// planar embedding no matter what order we embed them in.
			foreach (var vertex in transformedGraph.Vertices)
			{
				if (vertex.SeparatedDFSChildList.Count != 0)
				{
					foreach (var childVertex in vertex.SeparatedDFSChildList)
					{
						childVertex.DFSChildHandle.Flip();
						vertex.FaceHandle.GlueFirstToSecond(childVertex.DFSChildHandle);
					}
				}
			}

			// Up until this point, we've flipped bicomps lazily by setting
			// flipped[v] to true if the bicomp rooted at v was flipped (the
			// lazy aspect of this flip is that all descendents of that vertex
			// need to have their orientations reversed as well). Now, we
			// traverse the DFS tree by DFS number and perform the actual
			// flipping as needed
			foreach (var vertex in verticesByDFSNumberNew)
			{
				var vertexFlipped = vertex.Flipped;
				var parentFlipped = vertex.Parent.Flipped;

				if (vertexFlipped && !parentFlipped)
				{
					vertex.FaceHandle.Flip();
				}
				else if (parentFlipped && !vertexFlipped)
				{
					vertex.FaceHandle.Flip();
					vertex.Flipped = true;
				}
				else
				{
					vertex.Flipped = false;
				}
			}

			// If there are any self-loops in the graph, they were flagged
			// during the walkup, and we should add them to the embedding now.
			// Adding a self loop anywhere in the embedding could never
			// invalidate the embedding, but they would complicate the traversal
			// if they were added during the walkup/walkdown.
			foreach (var edge in selfLoopsNew)
			{
				edge.Source.FaceHandle.PushSecond(edge);
			}
		}

		private bool Pertinent(Vertex<T> vertex, Vertex<T> otherVertex)
		{
			// w is pertinent with respect to v if there is a backedge (v,w) or if
			// w is the root of a bicomp that contains a pertinent vertex.
			return vertex.BackedgeFlag == otherVertex.DFSNumber || vertex.PertinentRoots.Count != 0;
		}

		private bool ExternallyActive(Vertex<T> vertex, Vertex<T> otherVertex)
		{
			// Let a be any proper depth-first search ancestor of v. w is externally
			// active with respect to v if there exists a backedge (a,w) or a
			// backedge (a,w_0) for some w_0 in a descendent bicomp of w.
			var otherVertexDFSNumber = otherVertex.DFSNumber;

			return vertex.LeastAncestor < otherVertexDFSNumber
			       || (vertex.SeparatedDFSChildList.Count != 0 &&
			           vertex.SeparatedDFSChildList.First.Value.LowPoint < otherVertexDFSNumber);
		}

		private bool InternallyActive(Vertex<T> vertex, Vertex<T> otherVertex)
		{
			return Pertinent(vertex, otherVertex) && !ExternallyActive(vertex, otherVertex);
		}

		private void RemoveVertexFromSeparatedDFSChildList(Vertex<T> vertex)
		{
			var toDelete = vertex.SeparatedNodeInParentList;
			var list = vertex.Parent.SeparatedDFSChildList;

			list.Remove(toDelete);
		}

		private class MergeInfo
		{
			public Vertex<T> Vertex { get; }

			public bool ChoseFirstUpperPath { get; }

			public bool ChoseFirstLowerPath { get; }

			public MergeInfo(Vertex<T> vertex, bool choseFirstUpperPath, bool choseFirstLowerPath)
			{
				Vertex = vertex;
				ChoseFirstUpperPath = choseFirstUpperPath;
				ChoseFirstLowerPath = choseFirstLowerPath;
			}
		}

		#region Face iteratos

		/// <summary>
		/// Starts with the "first" vertex of a face handle of a given vertex.
		/// Stops after a root is find.
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="returnCurrent">
		/// There are always 2 possible edges to follow from each vertex. So we have to
		/// keep track from which vertex did we come to the current vertex.
		/// 
		/// The returnCurrent argument determines which of the two vertices is returned.
		/// true - returns the current vertex
		/// false - returns the previous vertex
		/// </param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateFirstSide(Vertex<T> vertex, bool returnCurrent = true)
		{
			return IterateFace(vertex.FaceHandle, x => x.FirstVertex, returnCurrent);
		}

		/// <summary>
		/// Starts with the "first" vertex of a given face handle.
		/// Stops after a root is find.
		/// </summary>
		/// <param name="face"></param>
		/// <param name="returnCurrent">
		/// There are always 2 possible edges to follow from each vertex. So we have to
		/// keep track from which vertex did we come to the current vertex.
		/// 
		/// The returnCurrent argument determines which of the two vertices is returned.
		/// true - returns the current vertex
		/// false - returns the previous vertex
		/// </param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateFirstSide(FaceHandle<Vertex<T>> face, bool returnCurrent = true)
		{
			return IterateFace(face, x => x.FirstVertex, returnCurrent);
		}

		/// <summary>
		/// Starts with the "second" vertex of a face handle of a given vertex.
		/// Stops after a root is find.
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="returnCurrent">
		/// There are always 2 possible edges to follow from each vertex. So we have to
		/// keep track from which vertex did we come to the current vertex.
		/// 
		/// The returnCurrent argument determines which of the two vertices is returned.
		/// true - returns the current vertex
		/// false - returns the previous vertex
		/// </param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateSecondSide(Vertex<T> vertex, bool returnCurrent = true)
		{
			return IterateFace(vertex.FaceHandle, x => x.SecondVertex, returnCurrent);
		}

		/// <summary>
		/// Starts with the "second" vertex of a given face handle.
		/// Stops after a root is find.
		/// </summary>
		/// <param name="face"></param>
		/// <param name="returnCurrent">
		/// There are always 2 possible edges to follow from each vertex. So we have to
		/// keep track from which vertex did we come to the current vertex.
		/// 
		/// The returnCurrent argument determines which of the two vertices is returned.
		/// true - returns the current vertex
		/// false - returns the previous vertex
		/// </param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateSecondSide(FaceHandle<Vertex<T>> face, bool returnCurrent = true)
		{
			return IterateFace(face, x => x.SecondVertex, returnCurrent);
		}

		/// <summary>
		/// Iterates over a given face.
		/// </summary>
		/// <param name="face"></param>
		/// <param name="currentVertexSelector"></param>
		/// <param name="returnCurrent">
		/// There are always 2 possible edges to follow from each vertex. So we have to
		/// keep track from which vertex did we come to the current vertex.
		/// 
		/// The returnCurrent argument determines which of the two vertices is returned.
		/// true - returns the current vertex
		/// false - returns the previous vertex
		/// </param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateFace(FaceHandle<Vertex<T>> face, Func<FaceHandle<Vertex<T>>, Vertex<T>> currentVertexSelector, bool returnCurrent = true)
		{
			var previous = face.Anchor;
			var current = currentVertexSelector(face);

			return IterateFace(current, previous, returnCurrent);
		}

		/// <summary>
		/// Iterates over a given face.
		/// </summary>
		/// <param name="current"></param>
		/// <param name="previous"></param>
		/// <param name="returnCurrent"></param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateFace(Vertex<T> current, Vertex<T> previous, bool returnCurrent = true)
		{
			while (true)
			{
				if (returnCurrent)
				{
					yield return current;
				}
				else
				{
					yield return previous;
				}

				var face = current.FaceHandle;

				var first = face.FirstVertex;
				var second = face.SecondVertex;

				if (first == previous)
				{
					previous = current;
					current = second;
				}
				else if (second == previous)
				{
					previous = current;
					current = first;
				}
				else
				{
					yield break;
				}
			}
		}

		/// <summary>
		/// Iterates over both sides of the face handle of a given vertex.
		/// </summary>
		/// <param name="vertex"></param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateBothSides(Vertex<T> vertex)
		{
			return IterateBothSides(vertex.FaceHandle);
		}

		/// <summary>
		/// Iterates over both sides of the face in parallel until the root is found.
		/// </summary>
		/// <remarks>
		/// Always returns the "previous" vertex!
		/// 
		/// The first returned vertex is the anchor of a given face. Both iterators are then
		/// advanced so that anchor point is not returned twice. After that, both iterators
		/// alternate in returning the current follow vertex. If any of the iterators encounter
		/// the root vertex, the whole process ends.
		/// </remarks>
		/// <param name="face"></param>
		/// <returns></returns>
		private IEnumerable<Vertex<T>> IterateBothSides(FaceHandle<Vertex<T>> face)
		{
			var firstEnumerable = IterateFirstSide(face, false);
			var secondEnumerable = IterateSecondSide(face, false);
			var firstActive = false;

			using (var firstEnumerator = firstEnumerable.GetEnumerator())
			{
				using (var secondEnumerator = secondEnumerable.GetEnumerator())
				{
					if (!firstEnumerator.MoveNext() || !secondEnumerator.MoveNext())
					{
						yield break;
					}

					yield return firstEnumerator.Current;

					if (!firstEnumerator.MoveNext() || !secondEnumerator.MoveNext())
					{
						yield break;
					}

					while (true)
					{
						if (firstActive)
						{
							yield return firstEnumerator.Current;

							if (!firstEnumerator.MoveNext())
							{
								yield break;
							}
						}
						else
						{
							yield return secondEnumerator.Current;

							if (!secondEnumerator.MoveNext())
							{
								yield break;
							}
						}

						firstActive = !firstActive;
					}
				}
			}
		}

		#endregion

		#endregion
	}
}