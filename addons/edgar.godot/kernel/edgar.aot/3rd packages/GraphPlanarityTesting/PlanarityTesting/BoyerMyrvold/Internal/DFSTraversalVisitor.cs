namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold.Internal
{
	using System;
	using Graphs.Algorithms;
	using Graphs.DataStructures;

	internal class DFSTraversalVisitor<T> : BaseDFSTraversalVisitor<Vertex<T>>
	{
		private int count;

		public override void StartVertex(Vertex<T> vertex, IGraph<Vertex<T>> graph)
		{
			vertex.Parent = vertex;
			vertex.LeastAncestor = count;
		}

		public override void DiscoverVertex(Vertex<T> vertex, IGraph<Vertex<T>> graph)
		{
			vertex.LowPoint = count;
			vertex.DFSNumber = count;
			count++;
		}

		public override void TreeEdge(IEdge<Vertex<T>> edge, IGraph<Vertex<T>> graph)
		{
			var source = edge.Source;
			var target = edge.Target;

			target.Parent = source;
			target.DFSEdge = edge;
			target.LeastAncestor = source.DFSNumber;
		}

		public override void BackEdge(IEdge<Vertex<T>> edge, IGraph<Vertex<T>> graph)
		{
			var source = edge.Source;
			var target = edge.Target;

			if (target != source.Parent)
			{
				var sourceLowPoint = source.LowPoint;
				var targetDFSNumber = target.DFSNumber;
				var sourceLeastAncestorDFSNumber = source.LeastAncestor;

				source.LowPoint = Math.Min(sourceLowPoint, targetDFSNumber);
				source.LeastAncestor = Math.Min(sourceLeastAncestorDFSNumber, targetDFSNumber);
			}
		}

		public override void FinishVertex(Vertex<T> vertex, IGraph<Vertex<T>> graph)
		{
			var lowPoint = vertex.LowPoint;
			var parent = vertex.Parent;
			var parentLowpoint = parent.LowPoint;

			if (vertex != vertex.Parent)
			{
				parent.LowPoint = Math.Min(lowPoint, parentLowpoint);
			}
		}
	}
}