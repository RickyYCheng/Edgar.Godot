using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;

using Edgar.Geometry;
using Edgar.GraphBasedGenerator.Common;
using Edgar.GraphBasedGenerator.Grid2D;

using Godot;
using Godot.Collections;

[GlobalClass]
public partial class EdgarGodotGenerator : RefCounted
{
    GraphBasedGeneratorGrid2D<string> _captured_generator;
    Godot.Collections.Dictionary<string, Dictionary> _nodes;
    Array<Dictionary> _edges;
    Array<Godot.Collections.Dictionary<string, Dictionary>> _layers;
    int _minimum_room_distance;
    int? _room_template_repeat_mode_default;
    int? _room_template_repeat_mode_override;

    public EdgarGodotGenerator()
    {
        _captured_generator = null;
        _nodes = null;
        _edges = null;
        _layers = null;
    }

    private EdgarGodotGenerator(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers, int minimum_room_distance = 0, int? room_template_repeat_mode_default = null, int? room_template_repeat_mode_override = null)
    {
        _captured_generator = null;
        _nodes = nodes;
        _edges = edges;
        _layers = layers;
        _minimum_room_distance = minimum_room_distance;
        _room_template_repeat_mode_default = room_template_repeat_mode_default;
        _room_template_repeat_mode_override = room_template_repeat_mode_override;
    }

    private void ensure_generator()
    {
        if (_captured_generator != null)
            return;

        var level_description = GetLevelDescription(_nodes, _edges, _layers, _minimum_room_distance, _room_template_repeat_mode_default, _room_template_repeat_mode_override);
        if (level_description != null)
        {
            _captured_generator = new GraphBasedGeneratorGrid2D<string>(level_description);
        }
    }

    [Pure]
    private static LevelDescriptionGrid2D<string> GetLevelDescription(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers, int minimum_room_distance = 0, int? room_template_repeat_mode_default = null, int? room_template_repeat_mode_override = null)
    {
        if (nodes == null || edges == null || layers == null)
            return null;

        var level_description = new LevelDescriptionGrid2D<string>()
        {
            MinimumRoomDistance = minimum_room_distance,
            RoomTemplateRepeatModeDefault = FromInt(room_template_repeat_mode_default),
            RoomTemplateRepeatModeOverride = FromInt(room_template_repeat_mode_override)
        };

        var layer_template_builders = new List<List<System.Func<RoomTemplateRepeatMode?, RoomTemplateGrid2D>>>(layers.Count);
        foreach (var layer in layers)
        {
            var builders = new List<System.Func<RoomTemplateRepeatMode?, RoomTemplateGrid2D>>(layer.Count);
            foreach (var kv in layer)
            {
                var name = kv.Key;
                var lnk = kv.Value;
                var boundary = new PolygonGrid2D(lnk["boundary"].AsVector2Array().Reverse().Select(pt => new Vector2Int((int)pt.X, (int)pt.Y)));
                var doors = lnk["doors"].AsGodotArray<Vector2[]>().Select(door => door.Select(pt => new Vector2Int((int)pt.X, (int)pt.Y)).ToArray()).ToArray();

                var doors_list = new List<DoorGrid2D>(doors.Length);
                foreach (var door in doors)
                {
                    var pt = door[0];
                    for (var i = 1; i < door.Length; i++)
                    {
                        doors_list.Add(new DoorGrid2D(pt, door[i]));
                        pt = door[i];
                    }
                }

                var transformations = lnk.ContainsKey("transformations") ? lnk["transformations"].AsInt32Array().Select(e => (TransformationGrid2D)e).ToList() : [TransformationGrid2D.Identity];

                var manual_door = new ManualDoorModeGrid2D(doors_list);
                builders.Add(repeatMode => new RoomTemplateGrid2D(boundary, manual_door, name, allowedTransformations: transformations, repeatMode: repeatMode));
            }
            layer_template_builders.Add(builders);
        }

        foreach (var node_name in nodes.Keys)
        {
            var node = nodes[node_name];
            var layer = node["edgar_layer"].AsInt32();
            var is_corridor = node["is_corridor_room"].AsBool();

            var repeat_mode_raw = node.ContainsKey("repeat_mode") ? (int?)node["repeat_mode"].AsInt32() : null;
            var repeat_mode = repeat_mode_raw.HasValue && repeat_mode_raw.Value >= 0
                ? (RoomTemplateRepeatMode?)repeat_mode_raw.Value
                : null;

            var room_templates = layer_template_builders[layer].Select(b => b(repeat_mode)).ToList();
            var room_description = new RoomDescriptionGrid2D(is_corridor, room_templates);
            level_description.AddRoom(node_name, room_description);
        }

        foreach (var connection in edges)
        {
            var from_node = connection["from_node"].AsString();
            var to_node = connection["to_node"].AsString();
            level_description.AddConnection(from_node, to_node);
        }

        return level_description;
    }

    public static bool resource_valid(Resource level)
        => level is not null && level.HasMeta("is_edgar_graph");

    public static EdgarGodotGenerator cons(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers, int minimum_room_distance = 0, int? room_template_repeat_mode_default = null, int? room_template_repeat_mode_override = null)
        => new(nodes, edges, layers, minimum_room_distance, room_template_repeat_mode_default, room_template_repeat_mode_override);

    public static EdgarGodotGenerator from_resource(Resource level)
    {
        if (resource_valid(level) is false)
        {
            GD.PushError($"The level resource is not a valid edgar level resource!");
            return null;
        }

        try
        {
            var nodes = level.GetMeta("nodes").AsGodotDictionary<string, Dictionary>();
            var edges = level.GetMeta("edges").AsGodotArray<Dictionary>();
            var minimum_room_distance = (int)level.GetMeta("minimum_room_distance", 0);
            var room_template_repeat_mode_default = level.HasMeta("room_template_repeat_mode_default") ? (int?)level.GetMeta("room_template_repeat_mode_default") : null;
            var room_template_repeat_mode_override = level.HasMeta("room_template_repeat_mode_override") ? (int?)level.GetMeta("room_template_repeat_mode_override") : null;
            var cache = new Godot.Collections.Dictionary<string, Dictionary>();
            var proxy = EdgarGodot.get_proxy();
            var layers = new Array<Godot.Collections.Dictionary<string, Dictionary>>(level.GetMeta("layers").AsGodotArray<string[]>().Select(layer =>
            {
                var result = new Godot.Collections.Dictionary<string, Dictionary> { };

                foreach (var name in layer)
                {
                    if (cache.TryGetValue(name, out var cached))
                    {
                        result.Add(name, cached);
                        continue;
                    }

                    var lnk = get_lnk(name, proxy);
                    if (lnk is null || lnk.Count == 0)
                        continue;

                    cache[name] = lnk;
                    result.Add(name, lnk);
                }

                return result;
            }));

            return cons(nodes, edges, layers, minimum_room_distance, room_template_repeat_mode_default, room_template_repeat_mode_override);
        }
        catch (System.Exception ex)
        {
            GD.PushError($"Failed to create generator from resource: {ex.Message}");
            return null;
        }
    }

    public Dictionary generate_layout()
    {
        ensure_generator();

        if (_captured_generator == null)
        {
            GD.PushError("Generator is not initialized. Please provide valid nodes, edges, and layers.");
            return [];
        }

        var layout = _captured_generator.GenerateLayout();
        if (layout == null) return [];
        // NOTE: keep same with gd-extension version
        return new Dictionary {
            { "rooms", new Array(layout.Rooms.Select(room => (Variant)new Dictionary
                {
                    { "room", room.Room },
                    { "position", new Vector2(room.Position.X, room.Position.Y) },
                    { "outline", new Array(room.Outline.GetPoints().Select(pt => (Variant)new Vector2(pt.X, pt.Y))) },
                    { "is_corridor", room.IsCorridor },
                    { "transformation", (int)room.Transformation },
                    { "doors", new Array(room.Doors.Select(door => (Variant)new Dictionary{ { "from_room", door.FromRoom }, { "to_room", door.ToRoom }, { "door_line", new Dictionary { { "from", new Vector2(door.DoorLine.From.X, door.DoorLine.From.Y) }, { "to", new Vector2(door.DoorLine.To.X, door.DoorLine.To.Y) } } } })) },
                    { "template", room.RoomTemplate.Name },
                    //{ "description", new Dictionary{ { "is_corridor", room.RoomDescription.IsCorridor }, { "templates", new Array(room.RoomDescription.RoomTemplates.Select(template => (Variant)template.Name)) } } },
                }))
            }
        };
    }

    public Dictionary generate_layout_with_seed_injection(int seed)
    {
        inject_seed(seed);
        return generate_layout();
    }

    public void inject_seed(int seed)
    {
        ensure_generator();

        if (_captured_generator == null)
        {
            GD.PushError("Generator is not initialized. Please provide valid nodes, edges, and layers.");
            return;
        }

        _captured_generator.InjectRandomGenerator(new System.Random(seed));
    }

    private static RoomTemplateRepeatMode? FromInt(int? value)
        => value switch
        {
            0 => RoomTemplateRepeatMode.AllowRepeat,
            1 => RoomTemplateRepeatMode.NoImmediate,
            2 => RoomTemplateRepeatMode.NoRepeat,
            _ => null
        };

    private static Dictionary get_lnk(string template, GDScript proxy = null)
    {
        proxy ??= EdgarGodot.get_proxy();

        if (proxy is not null)
        {
            return proxy.Call(nameof(get_lnk), template).As<Dictionary>();
        }

        var template_scene = GD.Load<PackedScene>(template);
        if (template_scene == null)
        {
            GD.PushError($"Failed to load template: {template}");
            return null;
        }
        var scene_state = template_scene.GetState();
        for (var i = 0; i < scene_state.GetNodePropertyCount(0); i++)
        {
            var prop_name = scene_state.GetNodePropertyName(0, i);
            if (prop_name == "metadata/lnk")
                return scene_state.GetNodePropertyValue(0, i).AsGodotDictionary();
        }
        return null;
    }
}
