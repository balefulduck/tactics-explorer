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
    
    local self = Entity.new(self, config)
    
    -- Player-specific properties
    self.moveSpeed = 0.05 -- Reduced from 0.2 to make movement more responsive
    self.moveTimer = 0
    self.isMoving = false
    self.targetX = self.gridX
    self.targetY = self.gridY
    self.canMove = true -- Flag to control movement input
    
    return self
end

function Player:update(dt)
    -- Handle movement animation
    if self.isMoving then
        self.moveTimer = self.moveTimer + dt
        
        if self.moveTimer >= self.moveSpeed then
            -- Movement complete
            self.gridX = self.targetX
            self.gridY = self.targetY  -- Fixed typo: was self.targetY = self.targetY
            self.x, self.y = self.grid:gridToWorld(self.gridX, self.gridY)
            self.isMoving = false
            self.moveTimer = 0
            self.canMove = true  -- Allow movement again
        end
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
    
    -- Set target position
    self.targetX = targetX
    self.targetY = targetY
    self.isMoving = true
    self.moveTimer = 0
    self.canMove = false  -- Prevent movement until animation completes
    
    -- Update position immediately
    self.gridX = targetX
    self.gridY = targetY
    self.x, self.y = self.grid:gridToWorld(self.gridX, self.gridY)
    
    return true
end

function Player:draw()
    -- Call parent draw method
    Entity.draw(self)
    
    -- Add player-specific visual elements
    local tileSize = self.grid.tileSize
    
    -- Calculate center position
    local centerX = self.x + tileSize / 2
    local centerY = self.y + tileSize / 2
    
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
