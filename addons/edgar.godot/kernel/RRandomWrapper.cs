using Godot;

[GlobalClass]
public partial class RRandomWrapper : Node
{
    ulong seed;
    [Export] public ulong Seed 
    { 
        get => seed;
        set
        {
            if (IsNodeReady())
            {
                GD.PushError($"[{nameof(RRandomWrapper)}] Cannot set random seed after node {this} is ready!");
                return;
            }
            seed = value;
        } 
    }
    public RRandom Random { get; private set; }
    public override void _Ready()
    {
        Random = new(this, Seed);
    }
}
