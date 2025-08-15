using System.Diagnostics.Contracts;
using System.Linq;

using Godot;
using Godot.Collections;

[GlobalClass]
public partial class EdgarGodot : GodotObject
{
    [Pure]
    public static bool is_edgar_level_resource(Resource level)
        => level is not null && level.HasMeta("is_edgar_graph");
    [Pure]
    public static EdgarGodotGenerator get_generator_from_resource(Resource level)
    {
        if (is_edgar_level_resource(level) is false)
        {
            GD.PrintErr($"The resource {level} is not a valid edgar level resource!");
            return null;
        }

        var nodes = level.GetMeta("nodes").AsGodotDictionary<string, Dictionary>();
        var edges = level.GetMeta("edges").AsGodotArray<Dictionary>();
        var layers = new Array<Godot.Collections.Dictionary<string, Dictionary>>(level.GetMeta("layers").AsGodotArray<string[]>().Select(level =>
        {
            var result = new Godot.Collections.Dictionary<string, Dictionary> { };

            foreach(var name in level)
            {
                var tmj = GD.Load<PackedScene>(name);
                var lnk = tmj.GetState().GetNodePropertyValue(0, 0).AsGodotDictionary();
                result.Add(name, lnk);
            }

            return result;
        }));

        return get_generator(nodes, edges, layers);
    }
    [Pure]
    public static EdgarGodotGenerator get_generator(Godot.Collections.Dictionary<string, Dictionary> nodes, Array<Dictionary> edges, Array<Godot.Collections.Dictionary<string, Dictionary>> layers)
        => new(nodes, edges, layers);
}
