// MIT License
// 
// Copyright (c) 2025 RickyYC
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

using System.Buffers;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;

using Edgar.Geometry;
using Edgar.GraphBasedGenerator.Grid2D;

using Godot;
using Godot.Collections;

[GlobalClass]
public partial class EdgarGodot : GodotObject
{
    [Pure]
    public static Callable get_generator(Resource level)
    {
        var level_description = GetLevelDescription(level);
        var generator = new GraphBasedGeneratorGrid2D<string>(level_description);
        return Callable.From(() =>
        {
            var layout = generator.GenerateLayout();
            if (layout == null) return [];
            return new Dictionary
            {
                { "rooms", new Array(layout.Rooms.Select(room => (Variant)new Dictionary
                    {
                        { "room", room.Room },
                        { "position", new Vector2(room.Position.X, room.Position.Y) },
                        { "outline", new Array(room.Outline.GetPoints().Select(pt => (Variant)new Vector2(pt.X, pt.Y))) },
                        { "is_corridor", room.IsCorridor },
                        //{ "transformation", room.Transformation.ToString() },
                        { "doors", new Array(room.Doors.Select(door => (Variant)new Dictionary{ { "from_room", door.FromRoom }, { "to_room", door.ToRoom }, { "door_line", new Dictionary { { "from", new Vector2(door.DoorLine.From.X, door.DoorLine.From.Y) }, { "to", new Vector2(door.DoorLine.To.X, door.DoorLine.To.Y) } } } })) },
                        { "template", room.RoomTemplate.Name },
                        { "description", new Dictionary{ { "is_corridor", room.RoomDescription.IsCorridor }, { "templates", new Array(room.RoomDescription.RoomTemplates.Select(template => (Variant)template.Name)) } } },
                        
                    })) 
                }
            };
        });
    }

    [Pure]
    public static LevelDescriptionGrid2D<string> GetLevelDescription(Resource level)
    {
        if (is_edgar_level_resource(level) is false) return null;

        var level_description = new LevelDescriptionGrid2D<string>();

        var nodes = level.GetMeta("nodes").AsGodotDictionary<string, Dictionary>();
        var edges = level.GetMeta("edges").AsGodotArray<Dictionary>();
        var layers = level.GetMeta("layers").AsGodotArray<string[]>().Select(layer => layer.Select(GD.Load<PackedScene>).ToArray()).ToArray();

        var layer_templates = new List<List<RoomTemplateGrid2D>>(layers.Length);
        foreach (var layer in layers)
        {
            var templates = new List<RoomTemplateGrid2D>(layers.Length);
            foreach (var tmj in layer)
            {
                var lnk = tmj.GetState().GetNodePropertyValue(0, 0).AsGodotDictionary();
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
                var room_template = new RoomTemplateGrid2D(boundary, manual_door, name: tmj.ResourcePath);
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

    [Pure]
    public static bool is_edgar_level_resource(Resource level)
        => level is not null && level.HasMeta("is_edgar_graph");
}
