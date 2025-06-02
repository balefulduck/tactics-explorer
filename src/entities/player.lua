-- Player entity
-- Represents the player character in the game

local Entity = require("src.core.entity")

local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player:new(grid, gridX, gridY)
    local config = {
        grid = grid,
        gridX = gridX or 1,
        gridY = gridY or 1,
        type = "player",
        name = "Player",
        width = 1,
        height = 1,
        color = {0.93, 0.93, 0.93, 1}, -- White background
        borderColor = {0.2, 0.2, 0.8, 1}, -- Blue border
        borderWidth = 2,
        showLabel = false,
        walkable = false,
        interactable = false
    }
    
    -- If a map was passed instead of a grid, extract the grid from it
    if grid.grid then
        config.grid = grid.grid
    end
    
    local self = Entity.new(self, config)
    
    -- Player-specific properties
    self.moveSpeed = 0.2 -- Time in seconds for movement animation
    self.moveTimer = 0
    self.isMoving = false
    self.targetX = self.gridX
    self.targetY = self.gridY
    self.canMove = true -- Flag to control movement input
    
    -- Visual position (for smooth movement)
    self.visualX, self.visualY = self.x, self.y
    self.movementProgress = 0 -- Progress of movement animation (0-1)
    
    return self
end

function Player:update(dt)
    -- Handle movement animation
    if self.isMoving then
        self.moveTimer = self.moveTimer + dt
        self.movementProgress = math.min(1, self.moveTimer / self.moveSpeed)
        
        -- Calculate visual position using interpolation
        local startX, startY = self.grid:gridToWorld(self.gridX, self.gridY)
        local endX, endY = self.grid:gridToWorld(self.targetGridX, self.targetGridY)
        
        -- Use easing function for smoother movement
        local progress = self:easeInOutQuad(self.movementProgress)
        self.visualX = startX + (endX - startX) * progress
        self.visualY = startY + (endY - startY) * progress
        
        if self.moveTimer >= self.moveSpeed then
            -- Movement complete
            self.gridX = self.targetGridX
            self.gridY = self.targetGridY
            self.x, self.y = self.grid:gridToWorld(self.gridX, self.gridY)
            self.visualX, self.visualY = self.x, self.y
            self.isMoving = false
            self.moveTimer = 0
            self.movementProgress = 0
            self.canMove = true  -- Allow movement again
            
            -- Notify map that movement is complete (for sight updates)
            if self.map and self.map.onEntityMovementComplete then
                self.map:onEntityMovementComplete(self)
            end
        end
    end
    
-- Easing function for smoother movement
function Player:easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end
end

function Player:move(dx, dy)
    -- Check if movement is allowed
    if not self.canMove then
        return false
    end
    
    -- Calculate target position
    local targetX = self.gridX + dx
    local targetY = self.gridY + dy
    
    -- Check if the move is valid
    if not self.grid:isWalkable(targetX, targetY) then
        return false
    end
    
    -- Store logical grid position for game logic
    local logicalX, logicalY = self.gridX, self.gridY
    
    -- Set target position for animation
    self.targetGridX = targetX
    self.targetGridY = targetY
    self.isMoving = true
    self.moveTimer = 0
    self.movementProgress = 0
    self.canMove = false  -- Prevent movement until animation completes
    
    -- Notify map that movement has started (for sight transition)
    if self.map and self.map.onEntityMovementStart then
        self.map:onEntityMovementStart(self, targetX, targetY)
    end
    
    -- Return true to indicate movement was initiated
    return true
end

function Player:draw()
    -- Override parent draw method for smooth movement
    -- We'll draw our own rectangle instead of using Entity.draw
    
    -- Use visual position for drawing during movement
    local drawX, drawY = self.visualX, self.visualY
    if not self.isMoving then
        drawX, drawY = self.x, self.y
    end
    
    -- Draw entity background
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", drawX, drawY, self.width, self.height)
    
    -- Draw entity border
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", drawX, drawY, self.width, self.height)
    end
    
    -- Add player-specific visual elements
    local tileSize = self.grid.tileSize
    
    -- Calculate center position based on visual position
    local centerX = drawX + tileSize / 2
    local centerY = drawY + tileSize / 2
    
    -- Load the character PNG image if not already loaded
    if not self.characterImage then
        self.characterImage = love.graphics.newImage("assets/images/character.png")
        
        -- Calculate scale to fit within the tile
        local maxSize = tileSize * 0.8 -- Leave some margin
        self.characterScale = math.min(
            maxSize / self.characterImage:getWidth(),
            maxSize / self.characterImage:getHeight()
        )
    end
    
    -- Draw the character image
    love.graphics.setColor(1, 1, 1, 1) -- White (no tint)
    
    -- Draw the image centered on the tile
    love.graphics.draw(
        self.characterImage,
        centerX,
        centerY,
        0, -- rotation (none)
        self.characterScale,
        self.characterScale,
        self.characterImage:getWidth() / 2, -- origin X (center of image)
        self.characterImage:getHeight() / 2  -- origin Y (center of image)
    )
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Player
