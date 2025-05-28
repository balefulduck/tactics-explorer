-- Camera system for handling viewport and scrolling
local Camera = {}
Camera.__index = Camera

function Camera:new(width, height)
    local self = setmetatable({}, Camera)
    
    self.x = 0
    self.y = 0
    self.scale = 1
    self.rotation = 0
    self.width = width or love.graphics.getWidth()
    self.height = height or love.graphics.getHeight()
    
    -- Camera settings
    self.smoothing = 0.1  -- Lower = smoother camera (0-1)
    self.target = nil
    
    return self
end

function Camera:setTarget(target)
    self.target = target
end

function Camera:update(dt)
    if self.target then
        -- Calculate center position of target
        local targetX = self.target.x + self.target.grid.tileSize / 2
        local targetY = self.target.y + self.target.grid.tileSize / 2
        
        -- Calculate desired camera position (center on target)
        local desiredX = targetX - self.width / 2
        local desiredY = targetY - self.height / 2
        
        -- Smooth camera movement
        self.x = self.x + (desiredX - self.x) * self.smoothing * (60 * dt)
        self.y = self.y + (desiredY - self.y) * self.smoothing * (60 * dt)
    end
end

function Camera:set()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.rotate(self.rotation)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:screenToWorld(screenX, screenY)
    -- Convert screen coordinates to world coordinates
    local worldX = screenX / self.scale + self.x
    local worldY = screenY / self.scale + self.y
    
    return worldX, worldY
end

function Camera:worldToScreen(worldX, worldY)
    -- Convert world coordinates to screen coordinates
    local screenX = (worldX - self.x) * self.scale
    local screenY = (worldY - self.y) * self.scale
    
    return screenX, screenY
end

return Camera
