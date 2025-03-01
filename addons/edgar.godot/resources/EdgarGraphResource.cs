using System.Drawing;
using System.Linq;

using Edgar.Geometry;
using Edgar.GraphBasedGenerator.Grid2D;

using Godot;
using Godot.Collections;

[Tool, GlobalClass, Icon("res://addons/edgar.godot/icons/edgar_icon.svg")]
public partial class EdgarGraphResource : Resource
{
    [Export] public Dictionary nodes = [];
    [Export] public Array<Dictionary<string, string>> edges = [];
    [Export] public Array<Array<EdgarTiledResource>> layers_tmjs = [];

    private GraphBasedGeneratorGrid2D<string> generator;

    #region ToolButtons
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_1 => Callable.From(() => _select_layer(0));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_2 => Callable.From(() => _select_layer(1));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_3 => Callable.From(() => _select_layer(2));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_4 => Callable.From(() => _select_layer(3));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_5 => Callable.From(() => _select_layer(4));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_6 => Callable.From(() => _select_layer(5));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_7 => Callable.From(() => _select_layer(6));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_8 => Callable.From(() => _select_layer(7));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_9 => Callable.From(() => _select_layer(8));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_10 => Callable.From(() => _select_layer(9));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_11 => Callable.From(() => _select_layer(10));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_12 => Callable.From(() => _select_layer(11));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_13 => Callable.From(() => _select_layer(12));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_14 => Callable.From(() => _select_layer(13));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_15 => Callable.From(() => _select_layer(14));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_16 => Callable.From(() => _select_layer(15));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_17 => Callable.From(() => _select_layer(16));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_18 => Callable.From(() => _select_layer(17));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_19 => Callable.From(() => _select_layer(18));
    [ExportToolButton("", Icon = "Callable")] public Callable select_layer_20 => Callable.From(() => _select_layer(19));
    void _select_layer(int id)
    {
        if (layers_tmjs.Count <= id)
            layers_tmjs.Resize(id + 1);

        layers_tmjs[id] = [];

        var paths = EditorInterface.Singleton.GetSelectedPaths();

        foreach (var path in paths)
        {
            if (path.EndsWith(".tmj") is false) continue;

            layers_tmjs[id].Add(ResourceLoader.Load<EdgarTiledResource>(path));
        }

        NotifyPropertyListChanged();
    }
    #endregion
    public EdgarGraphResource()
    {
        PropertyListChanged += () => save();
    }

    #region Godot Editor
    private void _validate_layer_button(Dictionary property, int id)
    {
        if (property["name"].AsString() == $"select_layer_{id+1}")
        {
            var layer_name = ProjectSettings.GetSetting($"layer_names/edgar/layer_{id+1}").AsString();

            if (layer_name == "")
                property["usage"] = Variant.From(PropertyUsageFlags.Storage);

            property["hint_string"] = $"select tmjs for layer \"{layer_name}\",Callable";
        }
    }

    public override void _ValidateProperty(Dictionary property)
    {
        for (var i = 0; i < 20; i++)
            _validate_layer_button(property, i);
    }
    #endregion
    
    public Dictionary get_data() =>
        new()
        {
            { "nodes", nodes },
            { "edges", edges },
            { "layers_tmjs", new Array<Array<string>>(layers_tmjs.Select(array => new Array<string>(array.Select(tmj_res => tmj_res.ResourcePath))))},
        };
    public void set_data(Dictionary data)
    {
        if (data is null) return;

        nodes = data["nodes"].AsGodotDictionary();
        edges = data["edges"].AsGodotArray<Dictionary<string, string>>();

        layers_tmjs = [.. data["layers_tmjs"].AsGodotArray<Array<string>>().Select(array => new Array<EdgarTiledResource>(array.Select(path => ResourceLoader.Load<EdgarTiledResource>(path))))];
    }
    public bool save()
    {
        if (this is null) return true; // avoid disposed

        var file = FileAccess.Open(ResourcePath, FileAccess.ModeFlags.Write);
        if (file is null) return false;

        return file.StoreString(Json.Stringify(get_data()));
    }

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
    private LevelDescriptionGrid2D<string> GetLevelDescriptionGrid2D()
    {
        var layers_tmjs = this.layers_tmjs;
        var layers_templates = layers_tmjs.Select(tmjs => tmjs.Select(GetRoomTemplateGrid2D).ToList()).ToArray();

        // TODO: add MinimumRoomDistance and RepeatMode
        var levelDesctipion = new LevelDescriptionGrid2D<string>();

        // add rooms
        foreach (var kv in this.nodes)
        {
            var name = kv.Key.AsString();
            var node = kv.Value.AsGodotDictionary();
            var isCorridor = node["is_corridor_room"].AsInt32() == 1;
            var edgarLayer = node["edgar_layer"].AsInt32();

            var roomDescription = new RoomDescriptionGrid2D(isCorridor, layers_templates[edgarLayer]);
            levelDesctipion.AddRoom(name, roomDescription);
        }

        // add edges
        foreach (var conn in this.edges)
        {
            var fromNode = conn["from_node"];
            var toNode = conn["to_node"];
            levelDesctipion.AddConnection(fromNode, toNode);
        }

        return levelDesctipion;
    }

    public LayoutGrid2D<string> GenerateLayout() => (generator ??= new(GetLevelDescriptionGrid2D())).GenerateLayout();
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
