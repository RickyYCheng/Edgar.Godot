namespace GraphPlanarityTesting.PlanarityTesting.BoyerMyrvold.Internal
{
	using System;
	using System.Collections.Generic;

	internal class BucketSort
	{
		public static T[] Sort<T>(IEnumerable<T> elements, Func<T, int> valueSelector, int bucketsCount)
		{
			var buckets = new List<T>[bucketsCount];

			for (int i = 0; i < bucketsCount; i++)
			{
				buckets[i] = new List<T>();
			}

			foreach (var element in elements)
			{
				buckets[valueSelector(element)].Add(element);
			}

			var result = new List<T>();

			foreach (var bucket in buckets)
			{
				foreach (var element in bucket)
				{
					result.Add(element);
				}
			}

			return result.ToArray();
		}
	}
}