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
    
    -- Zoom settings
    self.minZoom = 0.25
    self.maxZoom = 2.0
    self.zoomStep = 0.05  -- Smaller step for smoother zooming
    self.targetScale = 1.0  -- Target scale for smooth transitions
    self.zoomSmoothing = 0.15  -- Smoothing factor for zoom transitions
    
    -- Panning settings
    self.isPanning = false
    self.lastMouseX = 0
    self.lastMouseY = 0
    
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
    -- Smooth zoom transition
    if self.scale ~= self.targetScale then
        self.scale = self.scale + (self.targetScale - self.scale) * self.zoomSmoothing * (60 * dt)
        
        -- Snap to target scale if very close to avoid floating point issues
        if math.abs(self.scale - self.targetScale) < 0.001 then
            self.scale = self.targetScale
        end
    end
    
    if self.target and not self.isPanning then
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

-- Zoom the camera at a specific screen position
function Camera:zoomAt(x, y, amount)
    -- Convert screen coordinates to board-relative coordinates
    local boardX = x - self.boardX
    local boardY = y - self.boardY
    
    -- Only zoom if mouse is over the board area
    if boardX >= 0 and boardX <= self.boardWidth and
       boardY >= 0 and boardY <= self.boardHeight then
        
        -- Calculate world position before zoom
        local worldX, worldY = self:screenToWorld(x, y)
        
        -- Calculate new target scale
        local oldTargetScale = self.targetScale
        if amount > 0 then
            -- Zoom in
            self.targetScale = math.min(self.maxZoom, self.targetScale + self.zoomStep)
        elseif amount < 0 then
            -- Zoom out
            self.targetScale = math.max(self.minZoom, self.targetScale - self.zoomStep)
        end
        
        -- Only adjust position if scale actually changed
        if oldTargetScale ~= self.targetScale then
            -- Calculate what the world position would be after the zoom
            local newWorldX = (boardX / self.targetScale) + self.x
            local newWorldY = (boardY / self.targetScale) + self.y
            
            -- Adjust camera position to keep the point under cursor in same position
            self.x = self.x + (worldX - newWorldX)
            self.y = self.y + (worldY - newWorldY)
        end
        
        return true
    end
    
    return false
end

-- Start panning the camera
function Camera:startPan(x, y)
    self.isPanning = true
    self.lastMouseX = x
    self.lastMouseY = y
    return true
end

-- Update camera panning
function Camera:updatePan(x, y)
    if self.isPanning then
        -- Calculate the movement in screen space
        local dx = x - self.lastMouseX
        local dy = y - self.lastMouseY
        
        -- Move the camera (dividing by scale to account for zoom level)
        self.x = self.x - dx / self.scale
        self.y = self.y - dy / self.scale
        
        -- Update last mouse position
        self.lastMouseX = x
        self.lastMouseY = y
        return true
    end
    return false
end

-- Stop panning the camera
function Camera:stopPan()
    self.isPanning = false
    return true
end

return Camera
