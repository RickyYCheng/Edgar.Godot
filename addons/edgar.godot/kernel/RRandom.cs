using System;

using Godot;

public class RRandom : Random
{
    readonly Lazy<Node> lazyNetworkRollback;
    readonly Lazy<Node> lazyNetworkTime;

    Node NetworkRollback => lazyNetworkRollback.Value;
    Node NetworkTime => lazyNetworkTime.Value;

    readonly RandomNumberGenerator _rng;
    long _last_reset_tick = -1;
    long _last_reset_rollback_tick = -1;

    public RRandom(Node node, ulong p_seed)
    {
        lazyNetworkRollback = new(() => node.GetNode("/root/NetworkRollback"));
        lazyNetworkTime = new(() => node.GetNode("/root/NetworkTime"));

        _rng = new()
        {
            Seed = p_seed
        };
    }

    void EnsureState()
    {
        if (Engine.IsEditorHint()) return;

        if (NetworkTime is null || NetworkRollback is null) return;

        var time_tick = NetworkTime.Get("tick").AsInt64();
        var rollback_tick = NetworkRollback.Get("tick").AsInt64();

        if (time_tick == _last_reset_tick
            && rollback_tick == _last_reset_rollback_tick)
            return;
        
        if (NetworkRollback.Call("is_rollback").AsBool())
        {
            _rng.State = (ulong)GD.Hash(new Godot.Collections.Array { _rng.Seed, rollback_tick });
        }
        else
        {
            _rng.State = (ulong)GD.Hash(new Godot.Collections.Array { _rng.Seed, time_tick });
        }

        _last_reset_rollback_tick = rollback_tick;
        _last_reset_tick = time_tick;
    }

    public override int Next()
    {
        EnsureState();
        return (int)_rng.Randi();
    }
    public override int Next(int maxValue)
    {
        EnsureState();
        return _rng.RandiRange(0, maxValue);
    }
    public override int Next(int minValue, int maxValue)
    {
        EnsureState();
        return _rng.RandiRange(minValue, maxValue);
    }
    public override void NextBytes(byte[] buffer)
    {
        throw new Exception();
    }
    public override void NextBytes(Span<byte> buffer)
    {
        throw new Exception();
    }
    public override double NextDouble()
    {
        throw new Exception();
    }
    public override long NextInt64()
    {
        throw new Exception();
    }
    public override long NextInt64(long maxValue)
    {
        throw new Exception();
    }
    public override long NextInt64(long minValue, long maxValue)
    {
        throw new Exception();
    }
    public override float NextSingle()
    {
        EnsureState();
        return _rng.Randi();
    }
    protected override double Sample()
    {
        throw new Exception();
    }
}
