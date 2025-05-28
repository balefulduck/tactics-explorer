-- Coffee Table entity - a 1x1 tile furniture object with rounded borders
local CoffeeTable = {}
CoffeeTable.__index = CoffeeTable

function CoffeeTable:new(grid, gridX, gridY)
    local self = setmetatable({}, CoffeeTable)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Coffee table attributes
    self.width = grid.tileSize
    self.height = grid.tileSize
    self.color = {0.6, 0.4, 0.2, 1} -- Brown
    
    return self
end

function CoffeeTable:update(dt)
    -- No movement or animation for now
end

function CoffeeTable:draw()
    local tileSize = self.grid.tileSize
    local radius = tileSize / 6  -- Rounded corner radius
    
    -- Draw the coffee table with rounded corners
    love.graphics.setColor(self.color)
    
    -- Draw rounded rectangle (LÖVE doesn't have a built-in rounded rect function)
    -- So we'll draw it using multiple shapes
    
    -- Main rectangle (slightly smaller to account for corners)
    love.graphics.rectangle("fill", 
        self.x + radius, 
        self.y + radius, 
        self.width - radius * 2, 
        self.height - radius * 2
    )
    
    -- Left and right rectangles
    love.graphics.rectangle("fill", 
        self.x, 
        self.y + radius, 
        radius, 
        self.height - radius * 2
    )
    
    love.graphics.rectangle("fill", 
        self.x + self.width - radius, 
        self.y + radius, 
        radius, 
        self.height - radius * 2
    )
    
    -- Top and bottom rectangles
    love.graphics.rectangle("fill", 
        self.x + radius, 
        self.y, 
        self.width - radius * 2, 
        radius
    )
    
    love.graphics.rectangle("fill", 
        self.x + radius, 
        self.y + self.height - radius, 
        self.width - radius * 2, 
        radius
    )
    
    -- Four corner circles
    love.graphics.circle("fill", self.x + radius, self.y + radius, radius)
    love.graphics.circle("fill", self.x + self.width - radius, self.y + radius, radius)
    love.graphics.circle("fill", self.x + radius, self.y + self.height - radius, radius)
    love.graphics.circle("fill", self.x + self.width - radius, self.y + self.height - radius, radius)
    
    -- Draw table surface detail (a simple circle in the middle)
    love.graphics.setColor(0.7, 0.5, 0.3, 1)  -- Slightly lighter brown
    love.graphics.circle("fill", 
        self.x + tileSize / 2, 
        self.y + tileSize / 2, 
        tileSize / 4
    )
    
    -- Draw border
    love.graphics.setColor(0.4, 0.25, 0.15, 1)  -- Darker brown
    love.graphics.setLineWidth(1.5)
    
    -- We need to manually draw the rounded rectangle outline
    -- Top-left corner
    love.graphics.arc("line", "open", self.x + radius, self.y + radius, radius, math.pi, math.pi * 1.5)
    
    -- Top-right corner
    love.graphics.arc("line", "open", self.x + self.width - radius, self.y + radius, radius, math.pi * 1.5, math.pi * 2)
    
    -- Bottom-right corner
    love.graphics.arc("line", "open", self.x + self.width - radius, self.y + self.height - radius, radius, 0, math.pi * 0.5)
    
    -- Bottom-left corner
    love.graphics.arc("line", "open", self.x + radius, self.y + self.height - radius, radius, math.pi * 0.5, math.pi)
    
    -- Connect the arcs with lines
    -- Top line
    love.graphics.line(self.x + radius, self.y, self.x + self.width - radius, self.y)
    
    -- Right line
    love.graphics.line(self.x + self.width, self.y + radius, self.x + self.width, self.y + self.height - radius)
    
    -- Bottom line
    love.graphics.line(self.x + radius, self.y + self.height, self.x + self.width - radius, self.y + self.height)
    
    -- Left line
    love.graphics.line(self.x, self.y + radius, self.x, self.y + self.height - radius)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Check if a grid position is part of the coffee table
function CoffeeTable:containsPosition(gridX, gridY)
    return gridX == self.gridX and gridY == self.gridY
end

return CoffeeTable
