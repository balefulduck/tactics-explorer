-- Map class for representing a game map
local Tile = require("src.maps.tile")

local Map = {}
Map.__index = Map

function Map:new(grid, width, height)
    local self = setmetatable({}, Map)
    
    self.grid = grid
    self.width = width or 20
    self.height = height or 15
    self.tiles = {}
    
    -- Set this map as the current map in the grid
    grid:setCurrentMap(self)
    
    -- Initialize empty map
    for y = 1, self.height do
        self.tiles[y] = {}
        for x = 1, self.width do
            self.tiles[y][x] = nil
        end
    end
    
    return self
end

function Map:generateDefaultMap()
    -- Create a simple default map with floor tiles and some walls
    for y = 1, self.height do
        for x = 1, self.width do
            -- Create walls around the edges
            if x == 1 or y == 1 or x == self.width or y == self.height then
                self.tiles[y][x] = Tile:new("wall", x, y, self.grid)
            else
                -- Add some random walls
                if love.math.random() < 0.1 then
                    self.tiles[y][x] = Tile:new("wall", x, y, self.grid)
                else
                    self.tiles[y][x] = Tile:new("floor", x, y, self.grid)
                end
            end
        end
    end
    
    -- Ensure the starting position (1,1) is always a floor tile
    self.tiles[2][2] = Tile:new("floor", 2, 2, self.grid)
end

function Map:getTile(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    
    return self.tiles[y][x]
end

function Map:setTile(x, y, tileType)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false
    end
    
    self.tiles[y][x] = Tile:new(tileType, x, y, self.grid)
    return true
end

function Map:draw()
    -- Draw all tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            if tile then
                tile:draw()
            end
        end
    end
end

return Map
