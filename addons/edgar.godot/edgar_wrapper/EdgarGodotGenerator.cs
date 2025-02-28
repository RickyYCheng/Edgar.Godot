using Edgar.Geometry;
using Edgar.GraphBasedGenerator.Grid2D;

using Godot;
using Godot.Collections;

using System.Linq;

[GlobalClass]
public partial class EdgarGodotGenerator : GodotObject
{
    private readonly GraphBasedGeneratorGrid2D<string> generator;
    public EdgarGodotGenerator(EdgarGraphResource graphRes)
    {
        generator = new GraphBasedGeneratorGrid2D<string>(GetLevelDescriptionGrid2D(graphRes));
    }
    public static EdgarGodotGenerator Create(EdgarGraphResource graphRes) => new(graphRes);
    private static RoomTemplateGrid2D GetRoomTemplateGrid2D(EdgarTiledResource tiledRes)
    {
        var name = tiledRes.ResourcePath.GetFile().GetBaseName();

        var boundX = tiledRes.boundary["x"].AsInt32();
        var boundY = tiledRes.boundary["y"].AsInt32();
        var outline = new PolygonGrid2D(tiledRes.boundary["polygon"].AsVector2Array().Select(pt => new Vector2Int((int)pt.X + boundX, (int)pt.Y + boundY)));

        var doors = new ManualDoorModeGrid2D([.. tiledRes.doors.SelectMany(door =>
        {
            var doorPoints = door["polyline"].AsVector2Array().Select(pt => new Vector2Int((int)pt.X + door["x"].AsInt32(), (int)pt.Y + door["y"].AsInt32()));
            var fst = doorPoints.Skip(1);
            var snd = doorPoints.SkipLast(1);
            var doorModes = Enumerable.Zip(fst, snd, (fst, snd) => new DoorGrid2D(fst, snd));
            return doorModes;
        })]);

        var transformations = tiledRes.boundary.ContainsKey("properties") ? Json.ParseString(tiledRes.boundary["properties"].AsGodotArray<Dictionary>().FirstOrDefault(prop => prop["name"].AsString() == "transformation")["value"].AsString()).AsInt32Array().Select(e => (TransformationGrid2D)e) : [TransformationGrid2D.Identity];

        return new RoomTemplateGrid2D(outline, doors, name, allowedTransformations: [.. transformations]);
    }
    private static LevelDescriptionGrid2D<string> GetLevelDescriptionGrid2D(EdgarGraphResource graphRes)
    {
        var layers_tmjs = graphRes.layers_tmjs;
        var layers_templates = layers_tmjs.Select(tmjs => tmjs.Select(GetRoomTemplateGrid2D).ToList()).ToArray();

        // TODO: add MinimumRoomDistance and RepeatMode
        var levelDesctipion = new LevelDescriptionGrid2D<string>();

        // add rooms
        foreach (var kv in graphRes.nodes)
        {
            var name = kv.Key.AsString();
            var node = kv.Value.AsGodotDictionary();
            var isCorridor = node["is_corridor_room"].AsInt32() == 1;
            var edgarLayer = node["edgar_layer"].AsInt32();

            var roomDescription = new RoomDescriptionGrid2D(isCorridor, layers_templates[edgarLayer]);
            levelDesctipion.AddRoom(name, roomDescription);
        }

        // add edges
        foreach (var conn in graphRes.edges)
        {
            var fromNode = conn["from_node"];
            var toNode = conn["to_node"];
            levelDesctipion.AddConnection(fromNode, toNode);
        }

        return levelDesctipion;
    }

    public LayoutGrid2D<string> GenerateLayout() => generator.GenerateLayout();
    public Dictionary GenerateLayoutDictionary() => LayoutToDictionary(GenerateLayout());
    
    private static Dictionary LayoutToDictionary(LayoutGrid2D<string> layout) =>
        new()
        {
            {
                "rooms", new Array<Dictionary>(layout.Rooms.Select(room => new Dictionary
                {
                    { "room", room.Room },
                    { "is_corridor", room.IsCorridor },
                    { "position", new Dictionary{ { "x", room.Position.X }, { "y", room.Position.Y } } },
                    { "template", room.RoomTemplate.Name },
                    { "transformation", (int)room.Transformation },
                }))
            }
        };
}
