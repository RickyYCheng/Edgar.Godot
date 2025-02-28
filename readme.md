# Edgar.Godot

Edgar.Godot is the Godot version of the highly acclaimed [Edgar-DotNet](https://github.com/OndrejNepozitek/Edgar-DotNet), designed to bring its powerful procedural level generation capabilities to the Godot engine.  
[Edgar-DotNet](https://github.com/OndrejNepozitek/Edgar-DotNet) is a renowned 2D procedural level generator, ideal for creating maps in 2D Rogue-Like games, and this amazing library was developed by OndrejNepozitek, building upon the works of Chongyang Ma.

> **Note**: Edgar.Godot currently focuses primarily on generating level layouts (Layout), rather than providing a complete, out-of-the-box solution.  
> Users can utilize the generated layouts and customize/expand the map content according to their own needs.  
> For example, users need to write their own code to fill in Tile Maps, Tile Mayers, Grid Maps, etc.

---

## Installation Guide

1. **Ensure Using the Godot Dotnet Version**  
   Edgar.Godot relies on the Godot Dotnet version to run. Please confirm that your Godot environment is properly configured.

2. **Install Edgar-DotNet**  
   Add the latest Edgar-DotNet package via NuGet or directly in your project files.

3. **Import the Plugin**  
   Import the Edgar.Godot plugin in Godot's AssetLib.

4. **Use the API**  
   Call the APIs provided by Edgar.Godot via GDS or C# scripts to start generating level layouts.

---

## Examples

Please refer to the example projects in this repository to understand the detailed implementation steps.
