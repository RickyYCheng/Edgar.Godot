using System;
using System.Collections.Generic;
using System.Linq;
using Edgar.Legacy.GeneralAlgorithms.DataStructures.Common;

namespace Edgar.Geometry
{
    public static class TransformationGrid2DHelper
    {
        public static TransformationGrid2D[] GetAllTransformationsOld()
        {
            return Enum.GetValues<TransformationGrid2D>();
        }

        public static List<TransformationGrid2D> GetAll()
        {
            return [.. Enum.GetValues<TransformationGrid2D>()];
        }

        public static List<TransformationGrid2D> GetRotations(bool includeIdentity = true)
        {
            return [
                TransformationGrid2D.Identity,
                TransformationGrid2D.Rotate90,
                TransformationGrid2D.Rotate180,
                TransformationGrid2D.Rotate270
            ];
        }
    }
}