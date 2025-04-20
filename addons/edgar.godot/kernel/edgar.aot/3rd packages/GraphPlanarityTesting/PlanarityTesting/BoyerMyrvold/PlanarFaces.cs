namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold
{
	using System.Collections.Generic;

	/// <summary>
	/// Class holding faces of a planar embedding of a graph.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public class PlanarFaces<T>
	{
		/// <summary>
		/// List of faces. 
		/// Vertices are in the same order as they appear on the face.
		/// </summary>
		public List<List<T>> Faces { get; }

		public PlanarFaces(List<List<T>> faces)
		{
			Faces = faces;
		}
	}
}