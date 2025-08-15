namespace GraphPlanarityTesting.PlanarityTesting.PlanarFaceTraversal
{
	using Graphs.DataStructures;

	/// <summary>
	/// Planar face traversal visitor.
	/// Inspired by Boost library.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public interface IPlanarFaceTraversalVisitor<T>
	{
		/// <summary>
		/// Called once before any faces are visited
		/// </summary>
		void BeginTraversal();

		/// <summary>
		/// Called once, for each face, before any vertex or edge on that face has been visited.
		/// </summary>
		void BeginFace();

		/// <summary>
		/// Called once, for each face, after all vertices and all edges on that face have been visited.
		/// </summary>
		/// <param name="edge"></param>
		void NextEdge(IEdge<T> edge);

		/// <summary>
		/// Called once on each vertex in the current face (the start and end of which are designated by calls to begin_face() and end_face(), respectively) in order according to the order established by the planar embedding
		/// </summary>
		/// <param name="vertex"></param>
		void NextVertex(T vertex);

		/// <summary>
		/// Called once on each edge in the current face (the start and end of which are designated by calls to begin_face() and end_face(), respectively) in order according to the order established by the planar embedding.
		/// </summary>
		void EndFace();

		/// <summary>
		/// Called once after all faces have been visited.
		/// </summary>
		void EndTraversal();
	}
}