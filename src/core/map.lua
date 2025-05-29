-- Map class for representing a game map
-- Uses the new entity-based system

local Tile = require("src.core.tile")

local Map = {}
Map.__index = Map

function Map:new(grid, width, height)
    local self = setmetatable({}, Map)
    
    self.grid = grid
    self.width = width or 20
    self.height = height or 15
    self.tiles = {}
    self.entities = {}
    
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

function Map:getTile(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    
    return self.tiles[y][x]
end

function Map:setTile(x, y, tileType, extraProperties)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false
    end
    
    self.tiles[y][x] = Tile.createTile(tileType, self.grid, x, y, extraProperties)
    return true
end

function Map:addEntity(entity)
    table.insert(self.entities, entity)
    
    -- If the entity is not walkable, update the walkable property of the tiles it occupies
    if not entity.walkable then
        for y = entity.gridY, entity.gridY + entity.height - 1 do
            for x = entity.gridX, entity.gridX + entity.width - 1 do
                local tile = self:getTile(x, y)
                if tile then
                    tile.walkable = false
                end
            end
        end
    end
    
    return entity
end

function Map:removeEntity(entityToRemove)
    for i, entity in ipairs(self.entities) do
        if entity == entityToRemove then
            table.remove(self.entities, i)
            
            -- Reset walkable property of tiles if needed
            if not entity.walkable then
                for y = entity.gridY, entity.gridY + entity.height - 1 do
                    for x = entity.gridX, entity.gridX + entity.width - 1 do
                        local tile = self:getTile(x, y)
                        if tile and tile.tileType ~= "wall" then
                            tile.walkable = true
                        end
                    end
                end
            end
            
            return true
        end
    end
    
    return false
end

function Map:getEntitiesAt(gridX, gridY)
    local entitiesAtPosition = {}
    
    -- Check regular entities
    for _, entity in ipairs(self.entities) do
        if entity.containsPosition and entity:containsPosition(gridX, gridY) then
            table.insert(entitiesAtPosition, entity)
        end
    end
    
    -- Check for window tiles at this position
    if gridX >= 1 and gridX <= self.width and gridY >= 1 and gridY <= self.height then
        local tile = self.tiles[gridY][gridX]
        if tile and tile.isWindow and tile.interactable then
            table.insert(entitiesAtPosition, tile)
        end
    end
    
    return entitiesAtPosition
end

function Map:createRoomMap(windowPositions)
    windowPositions = windowPositions or {}
    
    -- Create a room map with walls around the edges
    for y = 1, self.height do
        for x = 1, self.width do
            -- Create walls around the edges
            if x == 1 or y == 1 or x == self.width or y == self.height then
                -- Check if this position should be a window
                local isWindow = false
                for _, pos in ipairs(windowPositions) do
                    if pos.x == x and pos.y == y then
                        isWindow = true
                        break
                    end
                end
                
                -- Create wall or window
                if isWindow then
                    self:setTile(x, y, "wall", {isWindow = true})
                else
                    self:setTile(x, y, "wall")
                end
            else
                self:setTile(x, y, "floor")
            end
        end
    end
    
    return self
end

function Map:update(dt)
    -- Update all entities
    for _, entity in ipairs(self.entities) do
        if entity.update then
            entity:update(dt)
        end
    end
    
    -- Update all tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            if tile and tile.update then
                tile:update(dt)
            end
        end
    end
end

function Map:draw()
    -- Draw all tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            if tile and tile.draw then
                tile:draw()
            end
        end
    end
    
    -- Draw all entities
    for _, entity in ipairs(self.entities) do
        if entity.draw then
            entity:draw()
        end
    end
end

return Map
