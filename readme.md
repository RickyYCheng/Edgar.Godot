# Edgar.Godot

> [!CAUTION] 
> WIP: This project is currently under active development. Features and implementations may change.

## Overview
Edgar.Godot is a powerful GDScript toolkit designed to seamlessly integrate the [Edgar-Dotnet](https://github.com/OndrejNepozitek/Edgar-DotNet) algorithm for procedural generation of Rogue-like maps with the Godot game engine.  

Edgar.Godot uses `*.tmj`/`*.tmx` tile map files and custom JSON-based data resource `*.edgar-graph` files.

> **Dependencies**:  
> - Requires the [YATI](https://github.com/Kiamo2/YATI) plugin. (Included in this repository's source code)
> - **Current Implementation Note**:  
>   This repository uses [Edgar.Aot](https://github.com/RickyYCheng/Edgar.Aot) (C#/.NET implementation) and requires a Godot version supporting .NET  
>   For the native `GDExtension` implementation, visit: [Edgar.GDExtension](https://github.com/RickyYCheng/Edgar.GDExtension)
> [!Caution]
> The core work focuses primarily on the development of the GDScript and C# versions, rather than GDExtension.
> The updates for the GDExtension kernel may lag behind the main development efforts.

## Core Features
- 🗺️ Converts [Tiled](https://www.mapeditor.org/) map files to Godot-parsable JSON resources with meta information for procedural map generation via [YATI](https://github.com/Kiamo2/YATI).
- ⚙️ Custom `JSON` room graph format (`*.edgar-graph`) for defining room connectivity
- 🔄 Kernel Replaceability: Standardized interfaces compatible with both `C#` scripts and `GDExtension` versions
- Generates Godot-friendly `Dictionary` layouts using the Kernel's API.
- Sample renderer to display generated maps on `TileMapLayer`.

## Development Roadmap
- [x] Kernel Standardization: Unified interfaces for `C#` scripts and `GDExtension`
- [ ] Renderer Enhancements
	- [x] Choose pivot room
	- [ ] Beacons in pivot rooms to do accurate spawning / positioning
- [ ] Implement full feature set parity with Edgar-Dotnet
	- [ ] Template transformation
	- [ ] Dependency of random seeding
- [ ] Release on Godot Asset Library / Store

## Quick Start
Please check the default scene.
