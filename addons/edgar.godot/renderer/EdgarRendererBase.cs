using Godot;

public partial class EdgarRendererBase<TNode> : Node where TNode : Node
{
    [Signal] public delegate void RenderedEventHandler();

    public virtual void _draw() { }
}
