# Tactics Explorer

A top-down 2D grid-based tactics and exploration game built with LÖVE2D.

## Overview

Tactics Explorer is a grid-based game that combines tactical combat with exploration elements. The game features a player character that can move around a tile-based world, interact with the environment, and engage in tactical encounters.

## Project Structure

```
tactics-explorer/
├── main.lua                 # Main entry point
├── src/                     # Source code
│   ├── game.lua             # Main game controller
│   ├── entities/            # Game entities
│   │   └── player.lua       # Player implementation
│   ├── systems/             # Game systems
│   │   ├── camera.lua       # Camera and viewport management
│   │   ├── grid.lua         # Grid system for tile-based world
│   │   ├── mapManager.lua   # Manages loading and switching maps
│   │   └── ui.lua           # User interface elements
│   └── maps/                # Map-related code
│       ├── map.lua          # Map implementation
│       └── tile.lua         # Tile implementation
└── assets/                  # Game assets
    ├── images/              # Image assets
    └── sounds/              # Sound assets
```

## Controls

### Game Controls
- **WASD** or **Arrow Keys**: Move the player
- **E** or **Space**: Interact with objects
- **Shift**: Show information about adjacent objects
- **F1**: Toggle debug grid
- **F2**: Toggle map editor
- **ESC**: Quit the game

### Map Editor Controls
- **F2**: Toggle between game and editor mode
- **G**: Toggle grid visibility
- **U**: Toggle UI panel visibility
- **1**: Select tile placement tool
- **2**: Select entity placement tool
- **3**: Select eraser tool
- **Ctrl+S**: Save map
- **Ctrl+L**: Load map

## Requirements

- LÖVE2D 11.3 or higher (https://love2d.org/)

## Running the Game

1. Install LÖVE2D from https://love2d.org/
2. Run the game by either:
   - Dragging the project folder onto the LÖVE2D executable
   - Running `love /path/to/tactics-explorer` from the command line

## Development

This project is set up with a basic framework for a grid-based tactics game. Key features include:

- Grid-based movement system
- Camera system with smooth following
- Tile-based map system
- Simple UI framework

## Next Steps

- Implement combat mechanics
- Add more entity types (enemies, NPCs)
- Create different map types and environments
- Add items and inventory system
- Implement game progression and objectives
