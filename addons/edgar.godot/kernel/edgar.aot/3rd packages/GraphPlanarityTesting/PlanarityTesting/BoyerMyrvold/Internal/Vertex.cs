namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold.Internal
{
	using System;
	using System.Collections.Generic;
	using Graphs.DataStructures;

	/// <summary>
	/// Vertex with all its information as described in the original paper.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	internal class Vertex<T> : IEquatable<Vertex<T>>
	{
		public T Value { get; }

		public int DFSNumber { get; set; }

		public Vertex<T> Parent { get; set; }

		public IEdge<Vertex<T>> DFSEdge { get; set; }

		public FaceHandle<Vertex<T>> FaceHandle { get; set; }

		public FaceHandle<Vertex<T>> DFSChildHandle { get; set; }

		public Vertex<T> CanonicalDFSChild { get; set; }

		public LinkedList<FaceHandle<Vertex<T>>> PertinentRoots { get; set; }

		public LinkedList<Vertex<T>> SeparatedDFSChildList { get; set; }

		public LinkedListNode<Vertex<T>> SeparatedNodeInParentList { get; set; }

		public List<IEdge<Vertex<T>>> BackEdges { get; set; }

		public int BackedgeFlag { get; set; }

		public int Visited { get; set; }

		public bool Flipped { get; set; }

		public int LeastAncestor { get; set; }

		public int LowPoint { get; set; }

		public Vertex(T value)
		{
			Value = value;
		}

		public override bool Equals(object obj)
		{
			var vertex = obj as Vertex<T>;
			return vertex != null &&
				   EqualityComparer<T>.Default.Equals(Value, vertex.Value);
		}

		public override int GetHashCode()
		{
			return EqualityComparer<T>.Default.GetHashCode(Value);
		}

		public static bool operator ==(Vertex<T> vertex1, Vertex<T> vertex2)
		{
			return EqualityComparer<Vertex<T>>.Default.Equals(vertex1, vertex2);
		}

		public static bool operator !=(Vertex<T> vertex1, Vertex<T> vertex2)
		{
			return !(vertex1 == vertex2);
		}

		public bool Equals(Vertex<T> other)
		{
			if (ReferenceEquals(null, other)) return false;
			if (ReferenceEquals(this, other)) return true;
			return EqualityComparer<T>.Default.Equals(Value, other.Value);
		}

		public override string ToString()
		{
			return $"{Value}";
		}
	}
}