namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold.Internal
{
	using System.Collections.Generic;
	using System.Linq;
	using Graphs.DataStructures;

	internal class FaceHandle<T>
	{
		private LinkedList<IEdge<T>> edgeList = new LinkedList<IEdge<T>>();

		public T FirstVertex { get; private set; }

		public T SecondVertex { get; private set; }

		public T TrueFirstVertex { get; private set; }

		public T TrueSecondVertex { get; private set; }

		public T Anchor { get; }

		public FaceHandle(T anchor, T nullVertex)
		{
			this.Anchor = anchor;
			FirstVertex = nullVertex;
			TrueFirstVertex = nullVertex;
			SecondVertex = nullVertex;
			TrueSecondVertex = nullVertex;
		}

		public FaceHandle(T anchor, IEdge<T> initialEdge)
		{
			var source = initialEdge.Source;
			var target = initialEdge.Target;
			var otherVertex = source.Equals(anchor) ? target : source;

			this.Anchor = anchor;
			FirstVertex = otherVertex;
			SecondVertex = otherVertex;
			TrueFirstVertex = otherVertex;
			TrueSecondVertex = otherVertex;

			edgeList = new LinkedList<IEdge<T>>();
			edgeList.AddLast(initialEdge);
		}

		public void GlueFirstToSecond(FaceHandle<T> bottom)
		{
			if (edgeList == null || edgeList.Count == 0)
			{
				edgeList = new LinkedList<IEdge<T>>(bottom.edgeList);
			}
			else
			{
				edgeList.PrependRange(bottom.edgeList); // TODO: slow
			}

			TrueFirstVertex = bottom.TrueFirstVertex;
			FirstVertex = bottom.FirstVertex;
		}

		public void GlueSecondToFirst(FaceHandle<T> bottom)
		{
			if (edgeList == null || edgeList.Count == 0)
			{
				edgeList = new LinkedList<IEdge<T>>(bottom.edgeList);
			}
			else
			{
				edgeList.AppendRange(bottom.edgeList); // TODO: slow
			}

			TrueSecondVertex = bottom.TrueSecondVertex;
			SecondVertex = bottom.SecondVertex;
		}

		public void Flip()
		{
			edgeList = new LinkedList<IEdge<T>>(edgeList.Reverse());

			{
				var temp = TrueFirstVertex;
				TrueFirstVertex = TrueSecondVertex;
				TrueSecondVertex = temp;
			}

			{
				var temp = FirstVertex;
				FirstVertex = SecondVertex;
				SecondVertex = temp;
			}
		}

		public IReadOnlyCollection<IEdge<T>> GetEdges()
		{
			return edgeList?.ToList().AsReadOnly();
		}

		public void SetFirstVertex(T vertex)
		{
			FirstVertex = vertex;
		}

		public void SetSecondVertex(T vertex)
		{
			SecondVertex = vertex;
		}

		public void PushFirst(IEdge<T> edge)
		{
			edgeList.AddFirst(edge);

			var otherVertex = edge.Source.Equals(Anchor) ? edge.Target : edge.Source;

			FirstVertex = otherVertex;
			TrueFirstVertex = otherVertex;
		}

		public void PushSecond(IEdge<T> edge)
		{
			edgeList.AddLast(edge);

			var otherVertex = edge.Source.Equals(Anchor) ? edge.Target : edge.Source;

			SecondVertex = otherVertex;
			TrueSecondVertex = otherVertex;
		}
	}
}