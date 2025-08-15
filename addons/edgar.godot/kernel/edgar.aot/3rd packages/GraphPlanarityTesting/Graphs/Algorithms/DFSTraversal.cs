namespace GraphPlanarityTesting.Graphs.Algorithms
{
	using System;
	using System.Collections.Generic;
	using System.Linq;
	using DataStructures;

	public static class DFSTraversal
	{
		#region Non-recursive version

		/// <summary>
		/// Traverses a given graph in a DFS order, starting from a given vertex.
		/// </summary>
		/// <typeparam name="T"></typeparam>
		/// <param name="graph"></param>
		/// <param name="startVertex"></param>
		/// <param name="visitor"></param>
		public static void Traverse<T>(IGraph<T> graph, T startVertex, IDFSTraversalVisitor<T> visitor)
		{
			var vertices = graph.Vertices.ToList();
			var states = new Dictionary<T, State>();

			foreach (var vertex in vertices)
			{
				states.Add(vertex, State.NotDiscovered);
				visitor.InitializeVertex(vertex, graph);
			}

			visitor.StartVertex(startVertex, graph);
			Traverse(graph, startVertex, visitor, states);

			foreach (var vertex in vertices)
			{
				if (states[vertex] == State.NotDiscovered)
				{
					visitor.StartVertex(vertex, graph);
					Traverse(graph, vertex, visitor, states);
				}
			}
		}

		/// <summary>
		/// Traverses a given graph in a DFS order.
		/// </summary>
		/// <typeparam name="T"></typeparam>
		/// <param name="graph"></param>
		/// <param name="visitor"></param>
		public static void Traverse<T>(IGraph<T> graph, IDFSTraversalVisitor<T> visitor)
		{
			Traverse(graph, graph.Vertices.First(), visitor);
		}

		private static void Traverse<T>(IGraph<T> graph, T startVertex, IDFSTraversalVisitor<T> visitor, Dictionary<T, State> states)
		{
			var stack = new Stack<VertexInfo<T>>();
			stack.Push(new VertexInfo<T>(startVertex, graph.GetNeighbours(startVertex).GetEnumerator()));
			states[startVertex] = State.Discovered;
			visitor.DiscoverVertex(startVertex, graph);

			while (stack.Count != 0)
			{
				var vertexInfo = stack.Peek();
				var vertex = vertexInfo.Vertex;
				var neighboursIterator = vertexInfo.NeighboursIterator;

				if (vertexInfo.CurrentOutcomingEdge != null)
				{
					visitor.FinishEdge(vertexInfo.CurrentOutcomingEdge, graph);
				}

				if (neighboursIterator.MoveNext())
				{
					var neighbour = neighboursIterator.Current;
					var neighbourState = states[neighbour];
					var edge = new Edge<T>(vertex, neighbour);
					vertexInfo.CurrentOutcomingEdge = edge;

					if (neighbourState == State.NotDiscovered)
					{
						visitor.TreeEdge(edge, graph);
						visitor.DiscoverVertex(neighbour, graph);
						states[neighbour] = State.Discovered;

						stack.Push(new VertexInfo<T>(neighbour, graph.GetNeighbours(neighbour).GetEnumerator()));
					}
					else if (neighbourState == State.Discovered)
					{
						visitor.BackEdge(edge, graph);
						visitor.FinishEdge(edge, graph);
					}
				}
				else
				{
					stack.Pop();
					visitor.FinishVertex(vertex, graph);
					states[vertex] = State.Closed;
				}
			}
		}

		#endregion


		#region Recursive version

		[Obsolete("Use non-recursive version")]
		internal static void TraverseRecursive<T>(IGraph<T> graph, T startVertex, IDFSTraversalVisitor<T> visitor)
		{
			var vertices = graph.Vertices.ToList();
			var states = new Dictionary<T, State>();

			foreach (var vertex in vertices)
			{
				states.Add(vertex, State.NotDiscovered);
				visitor.InitializeVertex(vertex, graph);
			}

			visitor.StartVertex(startVertex, graph);
			TraverseRecursive(graph, startVertex, visitor, states);

			foreach (var vertex in vertices)
			{
				if (states[vertex] == State.NotDiscovered)
				{
					visitor.StartVertex(vertex, graph);
					TraverseRecursive(graph, vertex, visitor, states);
				}
			}
		}

		[Obsolete("Use non-recursive version")]
		internal static void TraverseRecursive<T>(IGraph<T> graph, IDFSTraversalVisitor<T> visitor)
		{
			TraverseRecursive(graph, graph.Vertices.First(), visitor);
		}

		[Obsolete("Use non-recursive version")]
		private static void TraverseRecursive<T>(IGraph<T> graph, T vertex, IDFSTraversalVisitor<T> visitor, Dictionary<T, State> states)
		{
			states[vertex] = State.Discovered;
			visitor.DiscoverVertex(vertex, graph);

			foreach (var neighbour in graph.GetNeighbours(vertex))
			{
				var edge = new Edge<T>(vertex, neighbour);
				visitor.ExamineEdge(edge, graph);
				var neighbourState = states[neighbour];

				if (neighbourState == State.NotDiscovered)
				{
					visitor.TreeEdge(edge, graph);
					TraverseRecursive(graph, neighbour, visitor, states);
				}
				else if (neighbourState == State.Discovered)
				{
					visitor.BackEdge(edge, graph);
				}

				visitor.FinishEdge(edge, graph);
			}

			states[vertex] = State.Closed;
			visitor.FinishVertex(vertex, graph);
		}

		#endregion

		private enum State
		{
			NotDiscovered, Discovered, Closed
		}

		private class VertexInfo<T>
		{
			public T Vertex { get; }

			public IEnumerator<T> NeighboursIterator { get; }

			public IEdge<T> CurrentOutcomingEdge { get; set; }

			public VertexInfo(T vertex, IEnumerator<T> neighboursIterator)
			{
				Vertex = vertex;
				NeighboursIterator = neighboursIterator;
			}
		}
	}
}