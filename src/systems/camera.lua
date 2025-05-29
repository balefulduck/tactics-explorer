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
    
    -- Board viewport settings (will be updated by game)
    self.boardX = 0
    self.boardY = 0
    self.boardWidth = width
    self.boardHeight = height
    
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
        
        -- Define the deadzone (area where camera doesn't move)
        -- Use smaller deadzone for the newspaper layout board
        local deadzonePadding = math.min(100, self.boardWidth / 6) -- Adjust based on board size
        local deadzoneLeft = self.x + deadzonePadding
        local deadzoneRight = self.x + self.boardWidth - deadzonePadding
        local deadzoneTop = self.y + deadzonePadding
        local deadzoneBottom = self.y + self.boardHeight - deadzonePadding
        
        -- Calculate desired camera position based on deadzone
        local desiredX = self.x
        local desiredY = self.y
        
        -- Only move camera horizontally if target is approaching screen edge
        if targetX < deadzoneLeft then
            desiredX = self.x - (deadzoneLeft - targetX)
        elseif targetX > deadzoneRight then
            desiredX = self.x + (targetX - deadzoneRight)
        end
        
        -- Only move camera vertically if target is approaching screen edge
        if targetY < deadzoneTop then
            desiredY = self.y - (deadzoneTop - targetY)
        elseif targetY > deadzoneBottom then
            desiredY = self.y + (targetY - deadzoneBottom)
        end
        
        -- Smooth camera movement
        self.x = self.x + (desiredX - self.x) * self.smoothing * (60 * dt)
        self.y = self.y + (desiredY - self.y) * self.smoothing * (60 * dt)
    end
end

function Camera:set()
    love.graphics.push()
    
    -- First translate to the board position in the newspaper layout
    love.graphics.translate(self.boardX, self.boardY)
    
    -- Then apply the camera transformations within the board
    love.graphics.translate(-self.x, -self.y)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.rotate(self.rotation)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:screenToWorld(screenX, screenY)
    -- Adjust for board position in the layout
    local boardRelativeX = screenX - self.boardX
    local boardRelativeY = screenY - self.boardY
    
    -- Convert screen coordinates to world coordinates
    local worldX = boardRelativeX / self.scale + self.x
    local worldY = boardRelativeY / self.scale + self.y
    
    return worldX, worldY
end

function Camera:worldToScreen(worldX, worldY)
    -- Convert world coordinates to screen coordinates
    local boardRelativeX = (worldX - self.x) * self.scale
    local boardRelativeY = (worldY - self.y) * self.scale
    
    -- Adjust for board position in the layout
    local screenX = boardRelativeX + self.boardX
    local screenY = boardRelativeY + self.boardY
    
    return screenX, screenY
end

-- Update the camera's board viewport based on the game's layout
function Camera:setBoardViewport(x, y, width, height)
    self.boardX = x
    self.boardY = y
    self.boardWidth = width
    self.boardHeight = height
end

return Camera
