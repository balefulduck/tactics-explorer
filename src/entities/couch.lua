-- Couch entity - a 3x1 tile furniture object
local Couch = {}
Couch.__index = Couch

function Couch:new(grid, gridX, gridY)
    local self = setmetatable({}, Couch)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Couch attributes
    local padding = 2
    self.padding = padding
    self.tileSize = grid.tileSize - (padding * 2)
    self.width = 3 * self.tileSize  -- 3 tiles wide
    self.height = self.tileSize     -- 1 tile high
    self.color = {0.93, 0.93, 0.93, 1} -- #eeeeee (monochrome)
    
    -- Load the Megrim font if needed
    self.font = love.graphics.newFont("assets/fonts/Megrim.ttf", 14)
    
    return self
end

function Couch:update(dt)
    -- No movement or animation for now
end

function Couch:draw()
    local tileSize = self.tileSize
    local padding = self.padding
    local adjustedX = self.x + padding
    local adjustedY = self.y + padding
    
    -- Draw drop shadow
    love.graphics.setColor(0, 0, 0, 0.3)  -- Semi-transparent black
    love.graphics.rectangle("fill", adjustedX + 2, adjustedY + 2, self.width, self.height)
    
    -- Draw the couch base (all three tiles)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", adjustedX, adjustedY, self.width, self.height)
    
    -- Draw all borders in black
    love.graphics.setColor(0, 0, 0, 1) -- Black
    love.graphics.setLineWidth(1.5)
    
    -- Left tile borders
    love.graphics.line(
        adjustedX, adjustedY,                       -- Top-left
        adjustedX + tileSize, adjustedY             -- Top-right
    )
    love.graphics.line(
        adjustedX, adjustedY,                       -- Top-left
        adjustedX, adjustedY + tileSize             -- Bottom-left
    )
    love.graphics.line(
        adjustedX, adjustedY + tileSize,            -- Bottom-left
        adjustedX + tileSize, adjustedY + tileSize  -- Bottom-right
    )
    
    -- Right tile borders (mirrored)
    love.graphics.line(
        adjustedX + 2 * tileSize, adjustedY,                -- Top-left
        adjustedX + 3 * tileSize, adjustedY                 -- Top-right
    )
    love.graphics.line(
        adjustedX + 3 * tileSize, adjustedY,                -- Top-right
        adjustedX + 3 * tileSize, adjustedY + tileSize      -- Bottom-right
    )
    love.graphics.line(
        adjustedX + 2 * tileSize, adjustedY + tileSize,     -- Bottom-left
        adjustedX + 3 * tileSize, adjustedY + tileSize      -- Bottom-right
    )
    
    -- Draw the three horizontal lines on the middle tile
    local midX = adjustedX + tileSize
    local midWidth = tileSize
    
    -- Calculate positions for the three lines
    local line1Y = adjustedY + tileSize * 0.25
    local line2Y = adjustedY + tileSize * 0.4
    local line3Y = adjustedY + tileSize * 0.55
    
    -- Draw the three lines (middle one slightly longer)
    love.graphics.setLineWidth(1)
    
    -- Line 1 (top)
    love.graphics.line(
        midX + midWidth * 0.2, line1Y,
        midX + midWidth * 0.8, line1Y
    )
    
    -- Line 2 (middle, slightly longer)
    love.graphics.line(
        midX + midWidth * 0.15, line2Y,
        midX + midWidth * 0.85, line2Y
    )
    
    -- Line 3 (bottom)
    love.graphics.line(
        midX + midWidth * 0.2, line3Y,
        midX + midWidth * 0.8, line3Y
    )
    
    -- Draw "couch" text on the middle tile at the bottom
    love.graphics.setFont(self.font)
    local text = "couch"
    local textWidth = self.font:getWidth(text)
    local textX = midX + (midWidth - textWidth) / 2
    local textY = adjustedY + tileSize * 0.75
    
    love.graphics.print(text, textX, textY)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(love.graphics.getFont())
end

-- Check if a grid position is part of the couch
function Couch:containsPosition(gridX, gridY)
    return gridY == self.gridY and 
           gridX >= self.gridX and 
           gridX < self.gridX + 3
end

return Couch
