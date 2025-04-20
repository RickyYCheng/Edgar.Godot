namespace GraphPlanarityTesting.Graphs.Algorithms
{
	using DataStructures;

	public abstract class BaseDFSTraversalVisitor<T> : IDFSTraversalVisitor<T>
	{
		public virtual void InitializeVertex(T vertex, IGraph<T> graph)
		{

		}

		public virtual void StartVertex(T vertex, IGraph<T> graph)
		{

		}

		public virtual void DiscoverVertex(T vertex, IGraph<T> graph)
		{

		}

		public virtual void ExamineEdge(IEdge<T> edge, IGraph<T> graph)
		{

		}

		public virtual void TreeEdge(IEdge<T> edge, IGraph<T> graph)
		{

		}

		public virtual void BackEdge(IEdge<T> edge, IGraph<T> graph)
		{

		}

		public virtual void FinishEdge(IEdge<T> edge, IGraph<T> graph)
		{

		}

		public virtual void FinishVertex(T vertex, IGraph<T> graph)
		{

		}
	}
}