using System.Linq;

using Godot;
using Godot.Collections;

[Tool, GlobalClass, Icon("res://addons/edgar.godot/icons/edgar_graph_icon.svg")]
public partial class EdgarGraphResource : Resource
{
    [Export] public Dictionary nodes = [];
    [Export] public Array<Dictionary<string, string>> edges = [];
    [Export] public Array<Array<EdgarTiledResource>> layers_tmjs = [];

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
    public EdgarGraphResource()
    {
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
