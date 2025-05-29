-- Plant entity - a 1x1 tile decorative object
local Plant = {}
Plant.__index = Plant

function Plant:new(grid, gridX, gridY)
    local self = setmetatable({}, Plant)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Plant attributes
    self.width = grid.tileSize
    self.height = grid.tileSize
    self.color = {0.93, 0.93, 0.93, 1} -- Same whitish color as floor tiles (#eeeeee)
    
    -- Load the Megrim font
    self.font = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 14)
    
    return self
end

function Plant:update(dt)
    -- No movement or animation for now
end

function Plant:draw()
    local tileSize = self.grid.tileSize
    
    -- Draw the background (slightly lighter green)
    love.graphics.setColor(0.3, 0.8, 0.4, 0.2)  -- Light green with transparency
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw a thin circle in the center
    local centerX = self.x + tileSize / 2
    local centerY = self.y + tileSize / 2
    local circleRadius = tileSize / 6
    
    love.graphics.setColor(self.color)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", centerX, centerY, circleRadius)
    
    -- Draw 'plant' text around the circle
    love.graphics.setFont(self.font)
    
    -- Calculate text positions around the circle
    local text = "plant"
    local textWidth = self.font:getWidth(text)
    local textHeight = self.font:getHeight()
    
    -- Position the text below the circle
    local textX = centerX - textWidth / 2
    local textY = centerY + circleRadius + 5
    
    love.graphics.setColor(0, 0, 0, 1)  -- Black text
    love.graphics.print(text, textX, textY)
    
    -- Reset color, line width, and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(love.graphics.getFont())
end

-- Check if a grid position is part of the plant
function Plant:containsPosition(gridX, gridY)
    return gridX == self.gridX and gridY == self.gridY
end

return Plant
