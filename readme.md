# Edgar.Godot

> [!CAUTION] 
> **WIP**: This project is currently under active development. Features and implementations are subject to change.

## Overview
`Edgar.Godot` is a GDScript toolkit that integrates the [Edgar-DotNet](https://github.com/OndrejNepozitek/Edgar-DotNet) procedural level generation algorithm into Godot. It converts **Godot Scenes**/**Tiled maps** and custom room graph resources into Godot-ready data for runtime Rogue-like dungeon assembly, with a replaceable kernel supporting both C# and GDExtension implementations.

Edgar.Godot consumes map files (`*.tscn` / `*.scn` / `*.tmx` / `*.tmj`) and custom JSON graph resources (`*.edgar-graph`) that define room connectivity and metadata.

> [!IMPORTANT]  
> [YATI](https://github.com/Kiamo2/YATI) is no longer needed as a separate addon — its runtime is now bundled via `preload`. The original YATI addon can coexist without conflict, and may be safely kept or removed.
> 
> Native Godot scene (`.tscn`) is supported now for 2d scenes.  
> Check [godot 2d scene references](./addons/edgar.godot/reference.md#godot-2d-scenes)  

> [!IMPORTANT]  
> Uses the C#/.NET types via [Edgar.Aot](https://github.com/RickyYCheng/Edgar.Aot); requires a .NET-enabled Godot build.  
>  
> For the native GDExtension version, see [Edgar.GDExtension](https://github.com/RickyYCheng/Edgar.GDExtension).  

## Core Features
- 🗺️ Converts **Godot scene** or **[Tiled](https://www.mapeditor.org/) map files** into Godot-compatible templates, complete with metadata for procedural map generation. 
- ⚙️ Custom `JSON` room graph format (`*.edgar-graph`) for defining room connectivity.
- 📝 **Visual Graph Editor**: Built-in editor for designing room graphs with layer-based room categorization and per-graph layer management.
- 🔄 Kernel Replaceability: Standardized interfaces that are compatible with both `C#` scripts and `GDExtension` versions.
- Generates Godot-friendly `Dictionary` layouts utilizing the Kernel's API.
- Includes a sample renderer for displaying generated maps on `TileMapLayer`.
- 🌑 **Fog of War (FOW)**: Dynamic visibility system that reveals explored areas while hiding unexplored regions.
- 🗺️ **Minimap**: Real-time minimap display for navigation and overview of generated dungeons.

![alt text](docs/images/edgar_designer.png)
> Edgar Designer

![FOW & Minimap Demo](docs/images/minimap.png)
> Fog of War and Minimap demo

## Meta Reference
There are some already in-used fields in the Tiled map's `properties`.  
They are used to define the room's metadata for Edgar.  

This project bundles YATI runtime, so you can use YATI's custom properties (e.g. `godot_node_type`, `godot_group`) directly in Tiled. See [YATI's reference](https://github.com/Kiamo2/YATI/blob/main/Reference.md) for the full list.

For Edgar.Godot-specific fields, see [reference](addons/edgar.godot/reference.md).

## Quick Start
Please check the exmaples in the `examples/` folder.

## Roadmap

### Primitives
- [x] Runtime external loading for tmx/tmj files
  - [x] Remove bundled `YATI` addon version

### Godot 2D
- [x] Godot 2D Scene Support — Alternative to Tiled files for room definitions
  - [x] Add proxy support to customize loading procedures
  - [x] Add `*.tscn/*.scn` support for main screen graph-edit
  - [x] Add edgar extractor for godot scenes
  - [x] Make proxy suitable for processing scenes

### Godot 3D (experimental)
- [ ] 3D Renderer Support — Integration with GridMap and other 3D tile systems

### Edgar-Dotnet Functionalities
- [ ] Cover `Edgar-Dotnet`'s minimun room distance
- [ ] Simplify `Edgar-Dotnet` corridor design

