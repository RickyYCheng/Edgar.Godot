namespace GraphPlanarityTesting.Graphs.DataStructures
{
	using System;
	using System.Collections.Generic;

	/// <summary>
	/// Class representing an edge of a graph.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public class Edge<T> : IEdge<T>, IEquatable<Edge<T>>
	{
		/// <summary>
		/// First vertex of the edge.
		/// </summary>
		public T Source { get; }

		/// <summary>
		/// Second vertex of the edge.
		/// </summary>
		public T Target { get; }

		public Edge(T from, T to)
		{
			Source = from;
			Target = to;
		}

		public bool Equals(Edge<T> other)
		{
			if (other is null) return false;
			if (ReferenceEquals(this, other)) return true;
			return EqualityComparer<T>.Default.Equals(Source, other.Source) && EqualityComparer<T>.Default.Equals(Target, other.Target);
		}

		public override bool Equals(object obj)
		{
			if (obj is null) return false;
			if (ReferenceEquals(this, obj)) return true;
			if (obj.GetType() != GetType()) return false;
			return Equals((Edge<T>)obj);
		}

		public override int GetHashCode()
		{
			unchecked
			{
				return (EqualityComparer<T>.Default.GetHashCode(Source) * 397) ^ EqualityComparer<T>.Default.GetHashCode(Target);
			}
		}

		public override string ToString()
		{
			return $"({Source},{Target})";
		}
	}
}