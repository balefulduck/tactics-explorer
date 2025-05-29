-- Grid system for the game world
-- Handles coordinate conversions and grid-based operations

local Grid = {}
Grid.__index = Grid

function Grid:new(tileSize)
    local self = setmetatable({}, Grid)
    
    self.tileSize = tileSize or 64
    self.currentMap = nil
    self.debug = false
    
    return self
end

-- Convert grid coordinates to world coordinates
function Grid:gridToWorld(gridX, gridY)
    return (gridX - 1) * self.tileSize, (gridY - 1) * self.tileSize
end

-- Convert world coordinates to grid coordinates
function Grid:worldToGrid(worldX, worldY)
    return math.floor(worldX / self.tileSize) + 1, math.floor(worldY / self.tileSize) + 1
end

-- Set the current map
function Grid:setCurrentMap(map)
    self.currentMap = map
end

-- Check if a grid position is walkable
function Grid:isWalkable(gridX, gridY)
    -- Check map boundaries
    if not self.currentMap then
        return false
    end
    
    -- Check if there's a tile and if it's walkable
    local tile = self.currentMap:getTile(gridX, gridY)
    if not tile or not tile.walkable then
        return false
    end
    
    -- Check if there's an entity blocking the tile
    if self.currentMap.entities then
        for _, entity in ipairs(self.currentMap.entities) do
            if entity.containsPosition and entity:containsPosition(gridX, gridY) and not entity.walkable then
                return false
            end
        end
    end
    
    return true
end

-- Draw debug grid
function Grid:draw()
    if not self.debug or not self.currentMap then
        return
    end
    
    local mapWidth = self.currentMap.width * self.tileSize
    local mapHeight = self.currentMap.height * self.tileSize
    
    -- Draw grid lines
    love.graphics.setColor(0.5, 0.5, 0.5, 0.3) -- Semi-transparent gray
    love.graphics.setLineWidth(1)
    
    -- Vertical lines
    for x = 0, self.currentMap.width do
        local worldX = x * self.tileSize
        love.graphics.line(worldX, 0, worldX, mapHeight)
    end
    
    -- Horizontal lines
    for y = 0, self.currentMap.height do
        local worldY = y * self.tileSize
        love.graphics.line(0, worldY, mapWidth, worldY)
    end
    
    -- Draw grid coordinates for debugging
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    local font = love.graphics.getFont()
    local fontSize = font:getHeight()
    
    for y = 1, self.currentMap.height do
        for x = 1, self.currentMap.width do
            local worldX, worldY = self:gridToWorld(x, y)
            local coordText = x .. "," .. y
            love.graphics.print(coordText, worldX + 2, worldY + 2)
            
            -- Indicate walkable status
            if self:isWalkable(x, y) then
                love.graphics.setColor(0, 0.7, 0, 0.3) -- Green for walkable
            else
                love.graphics.setColor(0.7, 0, 0, 0.3) -- Red for non-walkable
            end
            
            love.graphics.rectangle("fill", worldX + fontSize + 5, worldY + 2, 8, 8)
            love.graphics.setColor(0.2, 0.2, 0.2, 0.7) -- Reset to text color
        end
    end
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Grid
