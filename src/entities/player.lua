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
    
    -- Facing direction (0 = East, 1 = South, 2 = West, 3 = North)
    self.facingDirection = 0
    -- Direction vectors for each facing direction
    self.directionVectors = {
        {x = 1, y = 0},  -- East (0)
        {x = 0, y = 1},  -- South (1)
        {x = -1, y = 0}, -- West (2)
        {x = 0, y = -1}  -- North (3)
    }
    
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
    
    -- Update facing direction based on movement
    self:updateFacingDirection(dx, dy)
    
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
    
    -- Calculate rotation based on facing direction
    local rotation = self.facingDirection * math.pi / 2 -- Convert to radians (0, π/2, π, 3π/2)
    
    -- Draw the image centered on the tile with rotation
    love.graphics.draw(
        self.characterImage,
        centerX,
        centerY,
        rotation, -- Apply rotation based on facing direction
        self.characterScale,
        self.characterScale,
        self.characterImage:getWidth() / 2, -- origin X (center of image)
        self.characterImage:getHeight() / 2  -- origin Y (center of image)
    )
    
    -- Draw direction indicator
    local dirVector = self.directionVectors[self.facingDirection + 1]
    local indicatorLength = tileSize * 0.4
    local startX = centerX
    local startY = centerY
    local endX = startX + dirVector.x * indicatorLength
    local endY = startY + dirVector.y * indicatorLength
    
    -- Draw direction arrow
    love.graphics.setColor(0.2, 0.8, 0.2, 0.8) -- Green arrow
    love.graphics.setLineWidth(3)
    love.graphics.line(startX, startY, endX, endY)
    
    -- Draw arrowhead
    local arrowSize = tileSize * 0.15
    local angle = math.atan2(dirVector.y, dirVector.x)
    local arrowAngle1 = angle + math.pi * 0.8
    local arrowAngle2 = angle - math.pi * 0.8
    love.graphics.line(endX, endY, endX + math.cos(arrowAngle1) * arrowSize, endY + math.sin(arrowAngle1) * arrowSize)
    love.graphics.line(endX, endY, endX + math.cos(arrowAngle2) * arrowSize, endY + math.sin(arrowAngle2) * arrowSize)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Update the player's facing direction based on movement or direct input
function Player:updateFacingDirection(dx, dy)
    if dx == 0 and dy == 0 then
        return -- No change in direction if not moving
    end
    
    -- Determine new facing direction based on movement vector
    if dx > 0 and dy == 0 then
        self.facingDirection = 0     -- East
    elseif dx == 0 and dy > 0 then
        self.facingDirection = 1     -- South
    elseif dx < 0 and dy == 0 then
        self.facingDirection = 2     -- West
    elseif dx == 0 and dy < 0 then
        self.facingDirection = 3     -- North
    elseif dx > 0 and dy > 0 then
        self.facingDirection = 0     -- Default to East for diagonal movement
    elseif dx < 0 and dy > 0 then
        self.facingDirection = 2     -- Default to West for diagonal movement
    elseif dx < 0 and dy < 0 then
        self.facingDirection = 2     -- Default to West for diagonal movement
    elseif dx > 0 and dy < 0 then
        self.facingDirection = 0     -- Default to East for diagonal movement
    end
    
    -- Notify sight system of direction change if available
    if self.map and self.map.sightManager then
        self.map.sightManager:updateAllSight()
    end
end

-- Change direction without moving (costs 25 TU)
function Player:changeDirection(newDirection)
    -- Clamp direction to valid range (0-3)
    newDirection = math.max(0, math.min(3, newDirection))
    
    -- Only update if direction actually changes
    if self.facingDirection ~= newDirection then
        self.facingDirection = newDirection
        
        -- Notify sight system of direction change if available
        if self.map and self.map.sightManager then
            self.map.sightManager:updateAllSight()
        end
        
        return true
    end
    
    return false
end

-- Get the current facing direction vector
function Player:getFacingDirectionVector()
    return self.directionVectors[self.facingDirection + 1]
end

return Player
