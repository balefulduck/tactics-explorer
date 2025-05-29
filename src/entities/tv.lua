-- TV entity - a 1x1 tile furniture object
local TV = {}
TV.__index = TV

function TV:new(grid, gridX, gridY)
    local self = setmetatable({}, TV)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- TV attributes
    self.width = grid.tileSize
    self.height = grid.tileSize
    self.color = {0.93, 0.93, 0.93, 1} -- Same whitish color as floor tiles (#eeeeee)
    
    return self
end

function TV:update(dt)
    -- No movement or animation for now
end

function TV:draw()
    local tileSize = self.grid.tileSize
    
    -- Draw the TV base
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw double borders
    love.graphics.setColor(0, 0, 0, 1) -- Black
    
    -- Outer border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Inner border
    local padding = 4
    love.graphics.rectangle("line", 
        self.x + padding, 
        self.y + padding, 
        self.width - padding * 2, 
        self.height - padding * 2
    )
    
    -- Draw TV screen
    love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Light gray for screen
    love.graphics.rectangle("fill", 
        self.x + padding * 2, 
        self.y + padding * 2, 
        self.width - padding * 4, 
        self.height - padding * 4
    )
    
    -- Draw TV icon (simple antenna)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(1.5)
    
    local centerX = self.x + tileSize / 2
    local topY = self.y + padding * 3
    local antennaHeight = tileSize / 4
    
    -- Draw antenna base
    love.graphics.line(
        centerX - 10, topY,
        centerX + 10, topY
    )
    
    -- Draw antenna sticks
    love.graphics.line(
        centerX - 5, topY,
        centerX - 10, topY - antennaHeight
    )
    
    love.graphics.line(
        centerX + 5, topY,
        centerX + 10, topY - antennaHeight
    )
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Check if a grid position is part of the TV
function TV:containsPosition(gridX, gridY)
    return gridX == self.gridX and gridY == self.gridY
end

return TV
