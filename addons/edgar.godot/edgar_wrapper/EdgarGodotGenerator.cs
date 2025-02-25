using Edgar.Geometry;

using Godot;
using Godot.Collections;

using System.Linq;

[GlobalClass]
public partial class EdgarGodotGenerator: GodotObject
{
    public EdgarGraphResource GraphResource { get; }
    public static EdgarGodotGenerator Create(EdgarGraphResource graphRes) => new(graphRes);
    public EdgarGodotGenerator(EdgarGraphResource graphRes)
    {
        GraphResource = graphRes;
        // TODO: store data.
    }
    private static Dictionary GetRoomTemplateGrid2DDictionary(EdgarTiledResource tiledRes)
    {
        var posx = tiledRes.boundary["x"].AsInt32();
        var posy = tiledRes.boundary["y"].AsInt32();
        Array<Vector2> polygon = [.. tiledRes.boundary["polygon"].AsVector2Array().Select(pt => new Vector2(pt.X + posx, pt.Y + posy))];

        return new()
        {
            { "name", tiledRes.ResourcePath.GetFile().GetBaseName() },
            { "polygon", polygon },
            // TODO: add transformations
        };
    }
}
