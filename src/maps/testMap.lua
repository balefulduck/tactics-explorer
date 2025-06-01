-- Test Map for Core Mechanics
-- This map is designed to test the Time Unit and Line of Sight systems

local Map = require("src.core.map")
local Barrel = require("src.entities.barrel")
local Player = require("src.entities.player")

local TestMap = {}

function TestMap.create(game)
    -- Create a new map with dimensions 20x20
    local map = Map:new(game.grid, 20, 20)
    
    -- Fill the map with stone floor tiles
    for x = 1, map.width do
        for y = 1, map.height do
            map:setTile(x, y, "stoneFloor")
        end
    end
    
    -- Create a grass area in the center
    for x = 8, 13 do
        for y = 8, 13 do
            map:setTile(x, y, "grassFloor")
        end
    end
    
    -- Add walls around the perimeter
    for x = 1, map.width do
        map:setTile(x, 1, "wall")
        map:setTile(x, map.height, "wall")
    end
    
    for y = 1, map.height do
        map:setTile(1, y, "wall")
        map:setTile(map.width, y, "wall")
    end
    
    -- Add some internal walls to test line of sight
    -- Vertical wall segment
    for y = 5, 10 do
        map:setTile(7, y, "wall")
    end
    
    -- Horizontal wall segment
    for x = 12, 17 do
        map:setTile(x, 14, "wall")
    end
    
    -- Add a window in each wall segment
    map:setTile(7, 8, "wall", {isWindow = true})
    map:setTile(15, 14, "wall", {isWindow = true})
    
    -- Add water area (non-walkable)
    for x = 14, 18 do
        for y = 3, 7 do
            map:setTile(x, y, "water")
        end
    end
    
    -- Add barrels for cover and obstacles
    local barrels = {
        {x = 5, y = 5},
        {x = 10, y = 10},
        {x = 15, y = 5},
        {x = 5, y = 15},
        {x = 12, y = 12}
    }
    
    for _, pos in ipairs(barrels) do
        local barrel = Barrel:new(map, pos.x, pos.y)
        map:addEntity(barrel)
    end
    
    -- Add a player entity at position 3,3
    local player = Player:new(map, 3, 3)
    map:addEntity(player)
    game.player = player
    
    -- Add an enemy at position 17,17 (would be implemented with proper enemy entity)
    -- For now, we'll just add a placeholder barrel with a different color
    local enemy = Barrel:new(map, 17, 17, {labelText = "Enemy"})
    enemy.color = {0.8, 0.2, 0.2, 1} -- Red color
    enemy.borderColor = {0.6, 0.1, 0.1, 1}
    enemy.showLabel = true
    map:addEntity(enemy)
    
    -- Set up test for Time Unit system
    -- Create a sequence of barrels that require different TU costs to navigate around
    local tuTestBarrels = {
        {x = 3, y = 7},
        {x = 3, y = 8},
        {x = 3, y = 9},
        {x = 4, y = 9},
        {x = 5, y = 9},
        {x = 6, y = 9}
    }
    
    for _, pos in ipairs(tuTestBarrels) do
        local barrel = Barrel:new(map, pos.x, pos.y)
        barrel.color = {0.3, 0.6, 0.3, 1} -- Green color to distinguish the TU test area
        map:addEntity(barrel)
    end
    
    -- Set up test for Line of Sight system
    -- Create a barrier with different heights
    local sightTestPositions = {
        {x = 10, y = 15, height = 0.5}, -- Low obstacle (partial obstruction)
        {x = 11, y = 15, height = 1.0}, -- Medium obstacle (partial obstruction)
        {x = 12, y = 15, height = 2.0}  -- Tall obstacle (full obstruction)
    }
    
    for _, pos in ipairs(sightTestPositions) do
        local barrel = Barrel:new(map, pos.x, pos.y)
        barrel.properties.height = pos.height
        barrel.color = {0.2, 0.2, 0.8, 1} -- Blue color to distinguish sight test objects
        barrel.labelText = "H:" .. pos.height
        barrel.showLabel = true
        map:addEntity(barrel)
    end
    
    return map
end

return TestMap
