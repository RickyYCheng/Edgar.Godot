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
- [ ] Renderer Improvements
	- [x] Pivot room selection
	- [ ] Beacon system in pivot rooms for precise spawning and positioning
- [ ] Sample renderer using a concrete tileset
- [ ] Feature parity with Edgar-DotNet
	- [ ] Template transformations
	- [ ] Deterministic generation via seed management
- [ ] Publish on the Godot Asset Library / Store

## Quick Start
Please check the default scene.
