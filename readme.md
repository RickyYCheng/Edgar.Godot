# Edgar.Godot

## Overview
Edgar.Godot is a comprehensive GDScript toolkit for converting `*.tmj`/`*.tmx` tilemap files and custom `*.edgar-graph` files into ready-to-use JSON data resources. The generated `*.edgar-graph` files can be seamlessly integrated with the Edgar engine to procedurally generate Rogue-like maps.

> **Dependencies**:  
> - Requires `YATI` addon, `Edgar` source scripts are included.
> - **Current Implementation Note**:  
>   This repository currently utilizes `Edgar.Aot` (C#/.NET version), requiring Godot with .NET support.  
>   For a native GDExtension implementation, visit: [Edgar.GDExtension](https://github.com/RickyYCheng/Edgar.GDExtension)

## Development Roadmap
- [ ] Standardize interfaces between `C#` script and GDExtension versions  
- [ ] Finalize repository structure and implementation approach
