-- Barrel entity
-- A barrel that can be used as cover or an obstacle
-- Can also be destroyed or pushed

local Entity = require("src.core.entity")

local Barrel = setmetatable({}, {__index = Entity})
Barrel.__index = Barrel

function Barrel:new(map, gridX, gridY, options)
    local self = setmetatable({}, Barrel)
    
    options = options or {}
    
    -- Handle both map and grid objects
    if map.grid then
        -- If a map is passed, get the grid from it
        self.grid = map.grid
        self.map = map
    else
        -- If a grid is passed directly
        self.grid = map
    end
    
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    self.gridWidth = 1  -- Width in grid cells
    self.gridHeight = 1 -- Height in grid cells
    self.name = options.labelText or "Barrel"
    self.type = "obstacle"
    self.properties = { 
        dimensions = "1x1", 
        cover = true, 
        pushable = true,
        destructible = true,
        height = 1.5  -- Taller than a table but shorter than a wall
    }
    self.flavorText = "A sturdy wooden barrel. Looks like it could be pushed or broken."
    
    -- Size based on grid
    self.width = self.grid.tileSize
    self.height = self.grid.tileSize
    
    -- Visual properties
    self.color = {0.6, 0.4, 0.2, 1} -- Brown
    self.borderColor = {0.4, 0.25, 0.1, 1} -- Darker brown
    self.borderWidth = 2
    self.showLabel = false
    self.labelText = "barrel"
    
    -- Gameplay properties
    self.walkable = false
    self.interactable = true
    self.health = 50  -- Can be destroyed
    
    -- Calculate pixel position from grid position
    self.x = (self.gridX - 1) * self.grid.tileSize
    self.y = (self.gridY - 1) * self.grid.tileSize
    
    return self
end

-- Interaction method
function Barrel:interact()
    local result = {
        success = true,
        message = "You push the barrel..."
    }
    
    -- In a real implementation, we would handle pushing logic here
    -- For now, just return the interaction result
    
    return result
end

-- Custom drawing function
function Barrel:draw()
    -- Base entity drawing
    love.graphics.setColor(self.color)
    
    -- Draw barrel with padding
    local padding = 2
    local x = self.x + padding
    local y = self.y + padding
    local width = self.width - (padding * 2)
    local height = self.height - (padding * 2)
    
    -- Draw the barrel body (slightly oval)
    love.graphics.ellipse("fill", x + width/2, y + height/2, width/2 - 1, height/2 - 3)
    
    -- Draw barrel rim (top ellipse)
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", x + width/2, y + height/2, width/2 - 1, height/2 - 3)
    
    -- Draw barrel top ellipse
    love.graphics.ellipse("line", x + width/2, y + height/4, width/2 - 3, height/8)
    
    -- Draw barrel bottom ellipse
    love.graphics.ellipse("line", x + width/2, y + height*3/4, width/2 - 3, height/8)
    
    -- Draw vertical barrel lines
    love.graphics.line(x + width/4, y + height/4, x + width/4, y + height*3/4)
    love.graphics.line(x + width*3/4, y + height/4, x + width*3/4, y + height*3/4)
    
    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", x + width/2 + 2, y + height - 4, width/2, height/8)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    
    -- Draw label if enabled
    if self.showLabel then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(self.labelText, self.x + 5, self.y + 5)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Method to handle damage
function Barrel:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        -- In a real implementation, we would handle destruction here
        -- For example, removing from the grid and possibly spawning debris
        return true -- Destroyed
    end
    return false -- Not destroyed
end

-- Method to handle pushing
function Barrel:push(direction)
    local targetX = self.gridX
    local targetY = self.gridY
    
    -- Determine target position based on direction
    if direction == "up" then
        targetY = targetY - 1
    elseif direction == "down" then
        targetY = targetY + 1
    elseif direction == "left" then
        targetX = targetX - 1
    elseif direction == "right" then
        targetX = targetX + 1
    end
    
    -- Check if target position is valid (would be implemented in the game logic)
    -- For now, just return the target position
    return {x = targetX, y = targetY}
end

-- Time Unit system integration (for compatibility with the existing TU system)
function Barrel:getTUCost(action)
    if action == "push" then
        return 30 -- Cost to push the barrel
    elseif action == "destroy" then
        return 50 -- Cost to destroy the barrel
    end
    return 0
end

return Barrel
