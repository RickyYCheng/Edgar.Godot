namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold.Internal
{
	using System.Collections.Generic;

	internal static class LinkedListExtensions
	{
		public static void AppendRange<T>(this LinkedList<T> source,
			IEnumerable<T> items)
		{
			foreach (T item in items)
			{
				source.AddLast(item);
			}
		}

		public static void PrependRange<T>(this LinkedList<T> source,
			IEnumerable<T> items)
		{
			LinkedListNode<T> first = source.First;
			foreach (T item in items)
			{
				source.AddBefore(first, item);
			}
		}
	}
}