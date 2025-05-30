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
    self.activeTiles = {}
    
    -- Set this map as the current map in the grid
    grid:setCurrentMap(self)
    
    -- Initialize empty map
    for y = 1, self.height do
        self.tiles[y] = {}
        self.activeTiles[y] = {}
        for x = 1, self.width do
            self.tiles[y][x] = nil
            self.activeTiles[y][x] = true  -- All tiles start as active by default
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

-- Get a single entity at the specified grid position
function Map:getEntityAt(gridX, gridY)
    local entities = self:getEntitiesAt(gridX, gridY)
    if #entities > 0 then
        return entities[1]
    end
    return nil
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
    -- Draw tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            if tile then
                if self:isTileActive(x, y) then
                    -- Draw active tiles normally
                    tile:draw()
                else
                    -- Draw inactive tiles with a pattern to indicate they're inactive
                    local worldX, worldY = self.grid:gridToWorld(x, y)
                    local tileSize = self.grid.tileSize
                    
                    -- Draw a darker version of the tile
                    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
                    love.graphics.rectangle("fill", worldX, worldY, tileSize, tileSize)
                    
                    -- Draw a cross pattern to indicate inactive
                    love.graphics.setColor(0.5, 0.1, 0.1, 0.7)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(worldX, worldY, worldX + tileSize, worldY + tileSize)
                    love.graphics.line(worldX + tileSize, worldY, worldX, worldY + tileSize)
                    love.graphics.setLineWidth(1)
                end
            end
        end
    end
    
    -- Draw entities (only on active tiles)
    for _, entity in ipairs(self.entities) do
        -- Only draw entities on active tiles
        if self:isTileActive(entity.gridX, entity.gridY) then
            entity:draw()
        end
    end
end

-- Check if a tile is active
function Map:isTileActive(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false
    end
    return self.activeTiles[y][x]
end

-- Toggle a tile's active state
function Map:toggleTileActive(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end
    self.activeTiles[y][x] = not self.activeTiles[y][x]
    
    -- If deactivating a tile, remove any entities on it
    if not self.activeTiles[y][x] then
        local entitiesToRemove = {}
        for _, entity in ipairs(self.entities) do
            -- Check if entity occupies this tile
            if entity.gridX <= x and entity.gridX + entity.width - 1 >= x and
               entity.gridY <= y and entity.gridY + entity.height - 1 >= y then
                table.insert(entitiesToRemove, entity)
            end
        end
        
        -- Remove entities
        for _, entity in ipairs(entitiesToRemove) do
            self:removeEntity(entity)
        end
    end
end

-- Check if an entity can be placed at its current position
function Map:canPlaceEntity(entity)
    -- Make sure the entity is within map bounds
    if entity.gridX < 1 or entity.gridY < 1 or 
       entity.gridX + entity.width - 1 > self.width or 
       entity.gridY + entity.height - 1 > self.height then
        return false
    end
    
    -- Check if all tiles the entity would occupy are active
    for y = entity.gridY, entity.gridY + entity.height - 1 do
        for x = entity.gridX, entity.gridX + entity.width - 1 do
            if not self:isTileActive(x, y) then
                return false
            end
        end
    end
    
    -- Check for collisions with other entities
    for _, existingEntity in ipairs(self.entities) do
        -- Skip if it's the same entity
        if existingEntity ~= entity then
            -- Check for overlap
            if entity.gridX < existingEntity.gridX + existingEntity.width and
               entity.gridX + entity.width > existingEntity.gridX and
               entity.gridY < existingEntity.gridY + existingEntity.height and
               entity.gridY + entity.height > existingEntity.gridY then
                return false
            end
        end
    end
    
    -- Check for collision with walls
    for y = entity.gridY, entity.gridY + entity.height - 1 do
        for x = entity.gridX, entity.gridX + entity.width - 1 do
            local tile = self:getTile(x, y)
            if tile and tile.tileType == "wall" and not tile.isWindow then
                return false
            end
        end
    end
    
    return true
end

return Map

