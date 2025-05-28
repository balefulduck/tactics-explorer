-- Window entity - a 1x1 tile object with specific border styling
local Window = {}
Window.__index = Window

function Window:new(grid, gridX, gridY)
    local self = setmetatable({}, Window)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Window attributes
    self.width = grid.tileSize   -- 1 tile wide
    self.height = grid.tileSize  -- 1 tile high
    self.color = {0.85, 0.85, 0.95, 1} -- Light blue-ish
    self.borderColor = {0.93, 0.93, 0.93, 1} -- #eeeeee
    
    return self
end

function Window:update(dt)
    -- No movement or animation for now
end

function Window:draw()
    local tileSize = self.grid.tileSize
    
    -- Draw window background
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Calculate border dimensions (75% of each side)
    local borderLength = tileSize * 0.75
    local borderOffset = (tileSize - borderLength) / 2
    
    -- Draw white borders (top, right, left) - 2px, #eeeeee, 75% of side length
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    
    -- Top border
    love.graphics.line(
        self.x + borderOffset, self.y,
        self.x + borderOffset + borderLength, self.y
    )
    
    -- Left border
    love.graphics.line(
        self.x, self.y + borderOffset,
        self.x, self.y + borderOffset + borderLength
    )
    
    -- Right border
    love.graphics.line(
        self.x + tileSize, self.y + borderOffset,
        self.x + tileSize, self.y + borderOffset + borderLength
    )
    
    -- Draw 3 horizontal lines at the bottom - 1px, #eeeeee, 90% of side length
    local bottomLineLength = tileSize * 0.9
    local bottomLineOffset = (tileSize - bottomLineLength) / 2
    local bottomY = self.y + tileSize - 8  -- Position near bottom
    
    love.graphics.setLineWidth(1)
    
    -- Draw 3 lines tightly above each other
    for i = 0, 2 do
        love.graphics.line(
            self.x + bottomLineOffset, bottomY - (i * 2),
            self.x + bottomLineOffset + bottomLineLength, bottomY - (i * 2)
        )
    end
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Check if a grid position is part of the window
function Window:containsPosition(gridX, gridY)
    return gridX == self.gridX and gridY == self.gridY
end

return Window
