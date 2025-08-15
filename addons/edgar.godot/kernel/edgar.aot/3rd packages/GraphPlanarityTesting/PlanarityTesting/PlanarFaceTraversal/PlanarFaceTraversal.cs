namespace GraphPlanarityTesting.PlanarityTesting.PlanarFaceTraversal
{
	using System.Collections.Generic;
	using BoyerMyrvold;
	using Graphs.DataStructures;

	/// <summary>
	/// Planar face traversal.
	/// Inspired by Boost library.
	/// </summary>
	public static class PlanarFaceTraversal
	{
		/// <summary>
		/// Traverses planar face of a given embedding.
		/// </summary>
		/// <typeparam name="T"></typeparam>
		/// <param name="graph"></param>
		/// <param name="embedding"></param>
		/// <param name="visitor"></param>
		public static void Traverse<T>(IGraph<T> graph, PlanarEmbedding<T> embedding, IPlanarFaceTraversalVisitor<T> visitor)
		{
			var nextEdge = new Dictionary<IEdge<T>, Dictionary<T, IEdge<T>>>();
			var visited = new Dictionary<IEdge<T>, HashSet<T>>();

			foreach (var edge in graph.Edges)
			{
				nextEdge[edge] = new Dictionary<T, IEdge<T>>();
				visited[edge] = new HashSet<T>();
			}

			visitor.BeginTraversal();

			foreach (var vertex in graph.Vertices)
			{
				var vertexEmbedding = embedding.GetEdgesAroundVertex(vertex);

				for (var i = 0; i < vertexEmbedding.Count; i++)
				{
					var edge = vertexEmbedding[i];
					var followingEdge = i != vertexEmbedding.Count - 1 ? vertexEmbedding[i + 1] : vertexEmbedding[0];

					if (nextEdge.ContainsKey(edge))
					{
						nextEdge[edge][vertex] = followingEdge;
					}
					else
					{
						nextEdge[SwitchEdge(edge)][vertex] = followingEdge;
					}
				}
			}

			var selfLoops = new List<IEdge<T>>();
			var edgesCache = new List<IEdge<T>>();
			var verticesInEdge = new List<T>();

			foreach (var edge in graph.Edges)
			{
				edgesCache.Add(edge);

				if (edge.Source.Equals(edge.Target))
				{
					selfLoops.Add(edge);
				}
			}

			foreach (var edge in edgesCache)
			{
				var e = edge;
				verticesInEdge.Clear();
				verticesInEdge.Add(e.Source);
				verticesInEdge.Add(e.Target);

				foreach (var vertex in verticesInEdge)
				{
					var v = vertex;
					var edgeVisited = GetCorrectEdgeValue(visited, e);
					var beginFace = false;

					if (!edgeVisited.Contains(v))
					{
						visitor.BeginFace();
						beginFace = true;
					}

					while (!edgeVisited.Contains(v))
					{
						visitor.NextVertex(v);
						visitor.NextEdge(e);
						edgeVisited.Add(v);

						v = e.Source.Equals(v) ? e.Target : e.Source;
						e = GetCorrectEdgeValue(nextEdge, e)[v];
						edgeVisited = GetCorrectEdgeValue(visited, e);
					}

					if (beginFace)
					{
						visitor.EndFace();
					}
				}
			}

			// Iterate over all self-loops, visiting them once separately
			// (they've already been visited once, this visitation is for
			// the "inside" of the self-loop)

			foreach (var edge in selfLoops)
			{
				visitor.BeginFace();
				visitor.NextEdge(edge);
				visitor.NextVertex(edge.Source);
				visitor.EndFace();
			}

			visitor.EndTraversal();
		}

		private static IEdge<T> SwitchEdge<T>(IEdge<T> edge)
		{
			return new Edge<T>(edge.Target, edge.Source);
		}

		private static TValue GetCorrectEdgeValue<T, TValue>(Dictionary<IEdge<T>, TValue> dictionary, IEdge<T> edge)
		{
			if (dictionary.ContainsKey(edge))
			{
				return dictionary[edge];
			}

			return dictionary[SwitchEdge(edge)];
		}
	}
}