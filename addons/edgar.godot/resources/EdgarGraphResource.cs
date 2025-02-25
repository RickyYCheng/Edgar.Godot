using System.Linq;

using Godot;
using Godot.Collections;

[Tool, GlobalClass, Icon("res://addons/edgar.godot/icons/edgar_graph_icon.svg")]
public partial class EdgarGraphResource : Resource
{
    [Export] public Dictionary nodes = [];
    [Export] public Array<Dictionary<string, string>> edges = [];
    [Export] public Array<Array<EdgarTiledResource>> layers_tmjs = [];

    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_1 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_2 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_3 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_4 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_5 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_6 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_7 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_8 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_9 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_10 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_11 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_12 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_13 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_14 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_15 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_16 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_17 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_18 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_19 { get; }
    [ExportToolButton("", Icon = "Callable")] public System.Action select_layer_20 { get; }

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
    public EdgarGraphResource()
    {
        select_layer_1 = () => _select_layer(0);
        select_layer_2 = () => _select_layer(1);
        select_layer_3 = () => _select_layer(2);
        select_layer_4 = () => _select_layer(3);
        select_layer_5 = () => _select_layer(4);
        select_layer_6 = () => _select_layer(5);
        select_layer_7 = () => _select_layer(6);
        select_layer_8 = () => _select_layer(7);
        select_layer_9 = () => _select_layer(8);
        select_layer_10 = () => _select_layer(9);
        select_layer_11 = () => _select_layer(10);
        select_layer_12 = () => _select_layer(11);
        select_layer_13 = () => _select_layer(12);
        select_layer_14 = () => _select_layer(13);
        select_layer_15 = () => _select_layer(14);
        select_layer_16 = () => _select_layer(15);
        select_layer_17 = () => _select_layer(16);
        select_layer_18 = () => _select_layer(17);
        select_layer_19 = () => _select_layer(18);
        select_layer_20 = () => _select_layer(19);

        PropertyListChanged += () => save();
    }

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

    private Dictionary get_data() =>
        new()
        {
            { "nodes", nodes },
            { "edges", edges },
            { "layers_tmjs", new Array<Array<string>>(layers_tmjs.Select(array => new Array<string>(array.Select(tmj_res => tmj_res.ResourcePath))))},
        };

    private void set_data(Dictionary data)
    {
        if (data is null) return;

        nodes = data["nodes"].AsGodotDictionary();
        edges = data["edges"].AsGodotArray<Dictionary<string, string>>();

        layers_tmjs = [.. data["layers_tmjs"].AsGodotArray<Array<string>>().Select(array => new Array<EdgarTiledResource>(array.Select(path => ResourceLoader.Load<EdgarTiledResource>(path))))];
    }
    private bool save()
    {
        var file = FileAccess.Open(ResourcePath, FileAccess.ModeFlags.Write);
        if (file is null) return false;

        return file.StoreString(Json.Stringify(get_data()));
    }
}
