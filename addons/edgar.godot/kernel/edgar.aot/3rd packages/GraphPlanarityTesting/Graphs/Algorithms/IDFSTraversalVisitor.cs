namespace GraphPlanarityTesting.Graphs.Algorithms
{
	using DataStructures;

	/// <summary>
	/// DFS Traversal visitor interface.
	/// Inspired by Boost library.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public interface IDFSTraversalVisitor<T>
	{
		/// <summary>
		/// Is invoked on every vertex of the graph before the start of the graph search.
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="graph"></param>
		void InitializeVertex(T vertex, IGraph<T> graph);

		/// <summary>
		/// Iis invoked on the source vertex once before the start of the search.
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="graph"></param>
		void StartVertex(T vertex, IGraph<T> graph);

		/// <summary>
		/// Is invoked when a vertex is encountered for the first time.
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="graph"></param>
		void DiscoverVertex(T vertex, IGraph<T> graph);

		/// <summary>
		/// Is invoked on every out-edge of each vertex after it is discovered.
		/// </summary>
		/// <param name="edge"></param>
		/// <param name="graph"></param>
		void ExamineEdge(IEdge<T> edge, IGraph<T> graph);

		/// <summary>
		/// Is invoked on each edge as it becomes a member of the edges that form the search tree. If you wish to record predecessors, do so at this event point.
		/// </summary>
		/// <param name="edge"></param>
		/// <param name="graph"></param>
		void TreeEdge(IEdge<T> edge, IGraph<T> graph);

		/// <summary>
		/// Is invoked on the back edges in the graph.
		/// </summary>
		/// <param name="edge"></param>
		/// <param name="graph"></param>
		void BackEdge(IEdge<T> edge, IGraph<T> graph);

		/// <summary>
		/// Is invoked on the non-tree edges in the graph as well as on each tree edge after its target vertex is finished.
		/// </summary>
		/// <param name="edge"></param>
		/// <param name="graph"></param>
		void FinishEdge(IEdge<T> edge, IGraph<T> graph);

		/// <summary>
		/// Is invoked on a vertex after all of its out edges have been added to the search tree and all of the adjacent vertices have been discovered (but before their out-edges have been examined).
		/// </summary>
		/// <param name="vertex"></param>
		/// <param name="graph"></param>
		void FinishVertex(T vertex, IGraph<T> graph);
	}
}