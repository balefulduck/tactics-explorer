-- Grid system for managing the game's grid-based world
local Grid = {}
Grid.__index = Grid

function Grid:new(tileSize)
    local self = setmetatable({}, Grid)
    
    self.tileSize = tileSize or 64
    self.currentMap = nil  -- Will be set by the map when it's created
    
    return self
end

-- Convert grid coordinates to world coordinates
function Grid:gridToWorld(gridX, gridY)
    return gridX * self.tileSize, gridY * self.tileSize
end

-- Convert world coordinates to grid coordinates (accounting for padding)
function Grid:worldToGrid(worldX, worldY)
    return math.floor(worldX / self.tileSize) + 1, math.floor(worldY / self.tileSize) + 1
end

-- Set the current map reference
function Grid:setCurrentMap(map)
    self.currentMap = map
end

-- Check if a grid position is valid (within map bounds)
function Grid:isValidPosition(gridX, gridY, map)
    if not map then return true end
    
    return gridX >= 1 and gridX <= map.width and
           gridY >= 1 and gridY <= map.height
end

-- Check if a grid position is walkable
function Grid:isWalkable(gridX, gridY, map)
    if not self:isValidPosition(gridX, gridY, map) then
        return false
    end
    
    local tile = map:getTile(gridX, gridY)
    return tile and tile.walkable
end

-- Draw grid lines (for debugging)
function Grid:draw()
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    
    -- Get visible area based on camera (approximate)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local startX, startY = 0, 0
    local endX = math.ceil(screenWidth / self.tileSize) + 1
    local endY = math.ceil(screenHeight / self.tileSize) + 1
    
    -- Draw vertical lines
    for x = startX, endX do
        local worldX = x * self.tileSize
        love.graphics.line(worldX, startY * self.tileSize, worldX, endY * self.tileSize)
    end
    
    -- Draw horizontal lines
    for y = startY, endY do
        local worldY = y * self.tileSize
        love.graphics.line(startX * self.tileSize, worldY, endX * self.tileSize, worldY)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Grid
