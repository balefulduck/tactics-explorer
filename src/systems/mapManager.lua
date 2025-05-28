-- Map Manager for loading and managing game maps
local Map = require("src.maps.map")

local MapManager = {}
MapManager.__index = MapManager

function MapManager:new(grid)
    local self = setmetatable({}, MapManager)
    
    self.grid = grid
    self.maps = {}
    
    return self
end

function MapManager:loadMap(mapName)
    -- Check if the map is already loaded
    if self.maps[mapName] then
        return self.maps[mapName]
    end
    
    -- For now, create a default map if no specific map is found
    local map = Map:new(self.grid, 20, 15)  -- 20x15 grid map
    
    -- Initialize the map with some basic tiles
    map:generateDefaultMap()
    
    -- Store the map for future reference
    self.maps[mapName] = map
    
    return map
end

function MapManager:createRoomMap(width, height)
    -- Create a room map with walls around the edges
    local map = Map:new(self.grid, width, height)
    
    -- Initialize all tiles as floor
    for y = 1, height do
        for x = 1, width do
            -- Create walls around the edges
            if x == 1 or y == 1 or x == width or y == height then
                map:setTile(x, y, "wall")
            else
                map:setTile(x, y, "floor")
            end
        end
    end
    
    return map
end

function MapManager:unloadMap(mapName)
    if self.maps[mapName] then
        self.maps[mapName] = nil
    end
end

return MapManager
