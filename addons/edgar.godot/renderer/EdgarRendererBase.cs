using Godot;

using System;

public partial class EdgarRendererBase : Node
{
    [Signal] public delegate void RenderedEventHandler();

    public virtual void _draw() { }
}
