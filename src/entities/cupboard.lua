-- Cupboard entity - a 1x4 tile furniture object
local Cupboard = {}
Cupboard.__index = Cupboard

function Cupboard:new(grid, gridX, gridY)
    local self = setmetatable({}, Cupboard)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Cupboard attributes
    self.width = 4 * grid.tileSize  -- 4 tiles wide
    self.height = grid.tileSize     -- 1 tile high
    self.color = {0.93, 0.93, 0.93, 1} -- Same whitish color as floor tiles (#eeeeee)
    
    -- Load the Megrim font
    self.font = love.graphics.newFont("assets/fonts/Megrim.ttf", 16)
    
    return self
end

function Cupboard:update(dt)
    -- No movement or animation for now
end

function Cupboard:draw()
    local tileSize = self.grid.tileSize
    
    -- Draw the cupboard base
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw border
    love.graphics.setColor(0.4, 0.3, 0.2, 1) -- Darker brown
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Draw cupboard details
    
    -- Vertical dividers between sections
    for i = 1, 3 do
        local dividerX = self.x + i * tileSize
        love.graphics.line(
            dividerX, self.y + 5,
            dividerX, self.y + self.height - 5
        )
    end
    
    -- Draw handles on each section
    for i = 0, 3 do
        local handleX = self.x + i * tileSize + tileSize / 2
        local handleY = self.y + self.height * 0.7
        local handleWidth = 8
        local handleHeight = 3
        
        love.graphics.rectangle(
            "fill",
            handleX - handleWidth / 2,
            handleY - handleHeight / 2,
            handleWidth,
            handleHeight
        )
    end
    
    -- Draw "cupboard" text across the middle tiles
    love.graphics.setFont(self.font)
    local text = "cupboard"
    local textWidth = self.font:getWidth(text)
    
    -- Center the text across the middle two tiles
    local textX = self.x + tileSize + (tileSize * 2 - textWidth) / 2
    local textY = self.y + (self.height - self.font:getHeight()) / 2
    
    love.graphics.setColor(0, 0, 0, 1) -- Black text
    love.graphics.print(text, textX, textY)
    
    -- Reset color, line width, and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(love.graphics.getFont())
end

-- Check if a grid position is part of the cupboard
function Cupboard:containsPosition(gridX, gridY)
    return gridY == self.gridY and 
           gridX >= self.gridX and 
           gridX < self.gridX + 4
end

return Cupboard
