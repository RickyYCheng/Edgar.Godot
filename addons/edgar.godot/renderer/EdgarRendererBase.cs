using Edgar.GraphBasedGenerator.Grid2D;

using Godot;
using Godot.Collections;

public abstract partial class EdgarRendererBase<TNode> : Node where TNode : Node
{
    [Export] public EdgarGraphResource GraphResource { get; private set; }
    public void _draw(LayoutGrid2D<string> layout)
    {
        var rooms = layout.Rooms;

        foreach (var room in rooms)
        {
            var position = new Vector2(room.Position.X, room.Position.Y);
            var transformation = (int)room.Transformation;
            var tiledResource = ResourceLoader.Load<EdgarTiledResource>(room.RoomTemplate.Name);
            _draw_room(tiledResource, transformation, position);
        }
    }
    public void _draw(Dictionary layoutDict)
    {
        var rooms = layoutDict["rooms"].AsGodotArray<Dictionary>();
        foreach (var room in rooms)
        {
            var _pos = room["position"].AsGodotDictionary<string, float>();
            var position = new Vector2(_pos["x"], _pos["y"]);
            var transformation = room["transformation"].AsInt32();
            var tiledResource = ResourceLoader.Load<EdgarTiledResource>(room["template"].AsString());
            _draw_room(tiledResource, transformation, position);
        }
    }

    public abstract void _draw_room(EdgarTiledResource tiledResource, int transformation, Vector2 position);
}
