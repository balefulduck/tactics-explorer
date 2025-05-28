-- Player entity
local Player = {}
Player.__index = Player

function Player:new(grid, gridX, gridY)
    local self = setmetatable({}, Player)
    
    self.grid = grid
    self.gridX = gridX or 1
    self.gridY = gridY or 1
    
    -- Calculate world position based on grid position
    self.x, self.y = grid:gridToWorld(self.gridX, self.gridY)
    
    -- Player attributes
    self.moveSpeed = 4  -- Grid cells per second
    self.color = {0.2, 0.2, 0.2, 1}  -- Dark gray (monochrome)
    self.size = (grid.tileSize - 4) * 0.8  -- Slightly smaller than a tile, accounting for padding
    
    -- Movement state
    self.isMoving = false
    self.targetX = self.x
    self.targetY = self.y
    
    return self
end

function Player:update(dt)
    -- Handle smooth movement between grid cells
    if self.isMoving then
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance < 1 then
            -- We've reached the target position
            self.x = self.targetX
            self.y = self.targetY
            self.isMoving = false
        else
            -- Move towards the target position
            local moveAmount = self.moveSpeed * self.grid.tileSize * dt
            local angle = math.atan2(dy, dx)
            
            self.x = self.x + math.cos(angle) * moveAmount
            self.y = self.y + math.sin(angle) * moveAmount
        end
    end
end

function Player:move(dx, dy)
    if self.isMoving then return false end
    
    local newGridX = self.gridX + dx
    local newGridY = self.gridY + dy
    
    -- Check if the new position is valid and walkable
    -- In a real game, you'd pass the current map to check walkability
    if self.grid:isValidPosition(newGridX, newGridY) then
        -- Update grid position
        self.gridX = newGridX
        self.gridY = newGridY
        
        -- Calculate new world position target
        self.targetX, self.targetY = self.grid:gridToWorld(self.gridX, self.gridY)
        self.isMoving = true
        
        return true
    end
    
    return false
end

function Player:draw()
    -- Calculate center position with padding adjustment
    local padding = 2
    local tileSize = self.grid.tileSize - (padding * 2)
    local centerX = self.x + padding + tileSize / 2
    local centerY = self.y + padding + tileSize / 2
    local radius = self.size / 2
    
    -- Draw drop shadow
    love.graphics.setColor(0, 0, 0, 0.3)  -- Semi-transparent black
    love.graphics.circle("fill", centerX + 2, centerY + 2, radius)
    
    -- Draw the player
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", centerX, centerY, radius)
    
    -- Draw outline
    love.graphics.setColor(0, 0, 0, 1)  -- Black
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", centerX, centerY, radius)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Player
