using Godot;

[GlobalClass, Tool]
public partial class EdgarRendererTMLs : EdgarRendererBase<Node2D>
{
    [Export] TileMapLayer[] tilemaplayers = [];

    public override void _draw_room(EdgarTiledResource tiledResource, int transformation, Vector2 position)
    {

    }
}
