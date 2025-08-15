namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold
{
	using System;
	using System.Collections.Generic;
	using Graphs.DataStructures;

	/// <summary>
	/// Class that holds a planar embedding of a graph.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public class PlanarEmbedding<T>
	{
		private readonly Dictionary<T, List<IEdge<T>>> embedding;

		public PlanarEmbedding(Dictionary<T, List<IEdge<T>>> embedding)
		{
			this.embedding = embedding;
		}

		/// <summary>
		/// Gets edges around a given vertex in the same order as
		/// they would appear in a drawing of a corresponding graph.
		/// </summary>
		/// <param name="vertex"></param>
		/// <returns></returns>
		public List<IEdge<T>> GetEdgesAroundVertex(T vertex)
		{
			if (embedding.TryGetValue(vertex, out var edges))
			{
				return edges;
			}

			throw new ArgumentException("Given vertex was not found");
		}
	}
}