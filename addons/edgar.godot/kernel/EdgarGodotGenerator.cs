using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;

using Edgar.Geometry;
using Edgar.GraphBasedGenerator.Grid2D;
using Edgar.Legacy.Utils.Interfaces;

using Godot;
using Godot.Collections;

[GlobalClass]
public partial class EdgarGodotGenerator(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers) : RefCounted
{
    readonly GraphBasedGeneratorGrid2D<string> _captured_generator = new(GetLevelDescription(nodes, edges, layers));

    [Pure]
    private static LevelDescriptionGrid2D<string> GetLevelDescription(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers)
    {
        var level_description = new LevelDescriptionGrid2D<string>();

        var layer_templates = new List<List<RoomTemplateGrid2D>>(layers.Count);
        foreach (var layer in layers)
        {
            var templates = new List<RoomTemplateGrid2D>(layers.Count);
            foreach (var kv in layer)
            {
                var name = kv.Key;
                var lnk = kv.Value;
                var boundary = new PolygonGrid2D(lnk["boundary"].AsVector2Array().Reverse().Select(pt => new Vector2Int((int)pt.X, (int)pt.Y)));
                var doors = lnk["doors"].AsGodotArray<Vector2[]>().Select(door => door.Select(pt => new Vector2Int((int)pt.X, (int)pt.Y)).ToArray());

                var doors_list = new List<DoorGrid2D>();
                foreach (var door in doors)
                {
                    var pt = door[0];
                    for (var i = 1; i < door.Length; i++)
                    {
                        doors_list.Add(new DoorGrid2D(pt, door[i]));
                        pt = door[i];
                    }
                }
                var manual_door = new ManualDoorModeGrid2D(doors_list);
                var room_template = new RoomTemplateGrid2D(boundary, manual_door, name);
                templates.Add(room_template);
            }
            layer_templates.Add(templates);
        }

        foreach (var node in nodes.Keys)
        {
            var layer = nodes[node]["edgar_layer"].AsInt32();
            var is_corridor = nodes[node]["is_corridor_room"].AsBool();
            var room_description = new RoomDescriptionGrid2D(is_corridor, layer_templates[layer]);
            level_description.AddRoom(node, room_description);
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

    public static EdgarGodotGenerator cons(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers)
        => new(nodes, edges, layers);

    public static EdgarGodotGenerator from_resource(Resource level)
    {
        if (resource_valid(level) is false)
        {
            GD.PushError($"The level resource is not a valid edgar level resource!");
            return null;
        }

        var nodes = level.GetMeta("nodes").AsGodotDictionary<string, Dictionary>();
        var edges = level.GetMeta("edges").AsGodotArray<Dictionary>();
        var layers = new Array<Godot.Collections.Dictionary<string, Dictionary>>(level.GetMeta("layers").AsGodotArray<string[]>().Select(layer =>
        {
            var result = new Godot.Collections.Dictionary<string, Dictionary> { };

            foreach (var name in layer)
            {
                var tmj = GD.Load<PackedScene>(name);
                var lnk = tmj.GetState().GetNodePropertyValue(0, 0).AsGodotDictionary();
                result.Add(name, lnk);
            }

            return result;
        }));

        return cons(nodes, edges, layers);
    }

    public Dictionary generate_layout()
    {
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
                    //{ "transformation", room.Transformation.ToString() },
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
        _captured_generator.InjectRandomGenerator(new System.Random(seed));
    }
}
