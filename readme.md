# Edgar.Godot

> [!CAUTION] 
> **WIP**: This project is currently under active development. Features and implementations are subject to change.

## Overview
`Edgar.Godot` is a GDScript toolkit that integrates the [Edgar-DotNet](https://github.com/OndrejNepozitek/Edgar-DotNet) procedural level generation algorithm into Godot. It converts Tiled maps and custom room graph resources into Godot-ready data for runtime Rogue-like dungeon assembly, with a replaceable kernel supporting both C# and GDExtension implementations.

Edgar.Godot consumes Tiled map files (`*.tmx` / `*.tmj`) and custom JSON graph resources (`*.edgar-graph`) that define room connectivity and metadata.

> **Dependencies**  
> - [YATI](https://github.com/Kiamo2/YATI) plugin (bundled with this repository)  

> [!NOTE]
> Uses the C#/.NET types via [Edgar.Aot](https://github.com/RickyYCheng/Edgar.Aot); requires a .NET-enabled Godot build.  
> For the native GDExtension version, see [Edgar.GDExtension](https://github.com/RickyYCheng/Edgar.GDExtension).  

> [!IMPORTANT]  
> The primary focus of development is on the GDScript and C# versions, with GDExtension updates potentially lagging behind the main development efforts.  

## Core Features
- 🗺️ Converts [Tiled](https://www.mapeditor.org/) map files into Godot-compatible JSON resources, complete with metadata for procedural map generation using [YATI](https://github.com/Kiamo2/YATI).
- ⚙️ Custom `JSON` room graph format (`*.edgar-graph`) for defining room connectivity.
- 🔄 Kernel Replaceability: Standardized interfaces that are compatible with both `C#` scripts and `GDExtension` versions.
- Generates Godot-friendly `Dictionary` layouts utilizing the Kernel's API.
- Includes a sample renderer for displaying generated maps on `TileMapLayer`.

## Development Roadmap
- [x] Kernel Standardization: Unified interfaces for both C# and GDExtension implementations
- [x] Renderer Improvements
	- [x] Pivot room selection
	- [x] Partially render (e.g. specific layers, rooms) of the generated layout
	- [x] Anchor system in pivot rooms for precise positioning
- [x] Feature parity with Edgar-DotNet
	- [x] Deterministic generation via seed management
- [x] Publish on the Godot Asset Library / Store
- [x] Add examples use concrete tilesets
- [x] Add outline message for layout.rooms to make rendering more flexible
> === WILL NOT IMPLEMENT CURRENTLY ===
- [ ] Ability to render 3d maps with 2d layouts

> [!IMPORTANT]
> Will not currently implement transformation of room shapes.  
> Since for tilemaps, transforming the room shape would require re-arranging the tiles, which is not feasible with the current Tiled map format and Edgar's generation algorithm.

## Meta Reference
There are some already in-used fields in the Tiled map's `properties`.  
They are used to define the room's metadata for Edgar.  

Firstly, since this project use [YATI](https://github.com/Kiamo2/YATI), please refer to [YATI's reference](https://github.com/Kiamo2/YATI/blob/main/Reference.md).  

After that, the specific fields for Edgar.Godot can be found in [reference](reference.md).

## Quick Start
Please check the default scene.
