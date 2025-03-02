using Godot;

public abstract partial class EdgarRendererBase<TNode> : Node where TNode : Node
{
    [Signal] public delegate void RenderedEventHandler();

    public abstract void _draw();
}
