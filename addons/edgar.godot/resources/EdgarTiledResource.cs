using System.Linq;

using Godot;
using Godot.Collections;

[Tool, GlobalClass, Icon("res://addons/edgar.godot/icons/edgar_tiled_icon.svg")]
public partial class EdgarTiledResource : Resource
{
    [Export] public Dictionary tmj = [];
    [Export] public Dictionary boundary = [];
    [Export] public Array<Dictionary> doors = [];
    public void set_data(Dictionary data)
    {
        if (data is null) return;

        tmj = data;
        var objects = _enumerate_objects();
        foreach (var @object in objects)
        {
            if (boundary.Count == 0 && @object["type"].AsString() == "Lnk.Boundary")
                boundary = @object;
            if (@object["type"].AsString() == "Lnk.Door")
                doors.Add(@object);
        }
    }

    private bool check_clock_wise(Array<Vector2> points)
    {
        var vec = points[^1];
        long num = 0L;
        foreach (Vector2 point in points)
        {
            num += (long)(point.X - vec.X) * (long)(point.Y + vec.Y);
            vec = point;
        }

        return num > 0;
    }
    private bool _handle_polygon_points_clockwise(Array<Vector2> polygon)
    {
        var is_clockwise = check_clock_wise(polygon);

        if (is_clockwise) return true;

        polygon.Reverse();

        is_clockwise = check_clock_wise(polygon);

        if (is_clockwise) return true;

        return false;
    }

    private Variant _vec2_from_xy_obj(Dictionary obj) => Variant.From(new Vector2(obj["x"].AsSingle(), obj["y"].AsSingle()));

    private void _enumerate_layer_objects(Dictionary layer, Array<Dictionary> list)
    {
        var layer_type = layer["type"].AsString();
        if (layer_type == "objectgroup")
        {
            foreach(var @object in layer["objects"].AsGodotArray<Dictionary>())
            {
                if (@object.ContainsKey("polygon")) 
                {
                    @object["polygon"] = new Array(@object["polygon"].AsGodotArray<Dictionary>().Select(_vec2_from_xy_obj));

                    if (_handle_polygon_points_clockwise(@object["polygon"].AsGodotArray<Vector2>()) is false)
                        GD.PrintErr("Cannot convert polygon to a clockwise one. ");
                }
                else if (@object.ContainsKey("polyline"))
                    @object["polyline"] = new Array(@object["polyline"].AsGodotArray<Dictionary>().Select(_vec2_from_xy_obj));

                list.Add(@object);
            }
        }
        else if (layer_type == "group")
        {
            foreach (var inner_layer in layer["layers"].AsGodotArray<Dictionary>())
                _enumerate_layer_objects(inner_layer, list);
        }
    }

    private Array<Dictionary> _enumerate_objects()
    {
        Array<Dictionary> list = [];
        foreach(var layer in tmj["layers"].AsGodotArray<Dictionary>())
        {
            _enumerate_layer_objects(layer, list);
        }
        return list;
    }
}
