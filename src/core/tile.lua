-- Tile class for representing a single grid tile
-- Uses the new entity-based system for consistency

local Entity = require("src.core.entity")

local Tile = setmetatable({}, {__index = Entity})
Tile.__index = Tile

-- Define all tile configurations in one place for better scalability
local tileConfigs = {
    floor = {
        name = "Floor",
        color = {0.93, 0.93, 0.93, 1}, -- White
        borderColor = {0.85, 0.85, 0.85, 1},
        walkable = true,
        showLabel = false,
        drawDetails = function(self, x, y, tileSize)
            -- No special rendering for floor
        end
    },
    wall = {
        name = "Wall",
        color = {0.93, 0.93, 0.93, 1}, -- White (same as floor)
        borderColor = {0, 0, 0, 1}, -- Black border
        borderWidth = 2,
        walkable = false, -- Walls are never walkable
        showLabel = false,
        -- Static shared border points to avoid flickering
        -- These will be created once and shared across all wall tiles
        sharedBorderPoints = nil,
        drawDetails = function(self, x, y, tileSize)
            -- Draw a slightly irregular, hand-drawn looking border with 1px padding
            love.graphics.setColor(0, 0, 0, 1) -- Black
            love.graphics.setLineWidth(2)
            
            -- Create padding of 1px from the edge
            local padding = 1
            local innerX = x + padding
            local innerY = y + padding
            local innerSize = tileSize - (padding * 2)
            
            -- Initialize border points if needed
            if not self.borderPoints then
                -- Create shared border points if they don't exist yet
                if not Tile.wallBorderPoints then
                    local segments = 4 -- Number of segments for each side
                    local segmentWidth = innerSize / segments
                    local jitter = 0.5 -- Small amount of irregularity
                    local points = {
                        top = {},
                        right = {},
                        bottom = {},
                        left = {}
                    }
                    
                    -- Generate points for all four sides
                    for i = 0, segments do
                        -- Generate random offsets
                        points.top[i] = math.random() * jitter
                        points.right[i] = math.random() * jitter
                        points.bottom[i] = math.random() * jitter
                        points.left[i] = math.random() * jitter
                    end
                    
                    -- Store in the Tile class for sharing
                    Tile.wallBorderPoints = points
                end
                
                -- Use the shared points
                self.borderPoints = Tile.wallBorderPoints
            end
            
            local points = self.borderPoints
            local segments = 4
            local segmentWidth = innerSize / segments
            
            -- Check if this wall tile is adjacent to the player
            local isAdjacent = false
            if self.grid and self.grid.game and self.grid.game.player then
                local player = self.grid.game.player
                local playerX, playerY = player.gridX, player.gridY
                
                -- Check if player is adjacent (including diagonals)
                isAdjacent = math.abs(self.gridX - playerX) <= 1 and math.abs(self.gridY - playerY) <= 1
            end
            
            -- Draw base wall fill
            if not self.isWindow then
                love.graphics.setColor(0.93, 0.93, 0.93, 1) -- Wall color
                love.graphics.rectangle("fill", innerX, innerY, innerSize, innerSize)
            else
                -- For windows, use a light blue background
                love.graphics.setColor(0.9, 0.95, 1, 0.7) -- Light blue for window background
                love.graphics.rectangle("fill", innerX, innerY, innerSize, innerSize)
                
                -- If adjacent to player, add a highlight
                if isAdjacent then
                    love.graphics.setColor(0.9, 0.9, 0.5, 0.3) -- Subtle yellow highlight
                    love.graphics.rectangle("fill", innerX, innerY, innerSize, innerSize)
                end
            end
            
            -- Draw the border using pre-calculated irregularities
            love.graphics.setColor(0, 0, 0, 1) -- Black
            for i = 0, segments - 1 do
                -- Top border
                love.graphics.line(
                    innerX + (i * segmentWidth), innerY + points.top[i],
                    innerX + ((i + 1) * segmentWidth), innerY + points.top[i + 1]
                )
                
                -- Right border
                love.graphics.line(
                    innerX + innerSize + points.right[i], innerY + (i * segmentWidth),
                    innerX + innerSize + points.right[i + 1], innerY + ((i + 1) * segmentWidth)
                )
                
                -- Bottom border
                love.graphics.line(
                    innerX + innerSize - (i * segmentWidth), innerY + innerSize + points.bottom[i],
                    innerX + innerSize - ((i + 1) * segmentWidth), innerY + innerSize + points.bottom[i + 1]
                )
                
                -- Left border
                love.graphics.line(
                    innerX + points.left[i], innerY + innerSize - (i * segmentWidth),
                    innerX + points.left[i + 1], innerY + innerSize - ((i + 1) * segmentWidth)
                )
            end
            
            -- If this is a window, draw 4 squares in the center
            if self.isWindow then
                -- Draw the window frame
                love.graphics.setColor(0.6, 0.4, 0.2, 1) -- Brown frame color
                love.graphics.setLineWidth(2) -- Make frame more visible
                
                -- Horizontal divider
                love.graphics.line(
                    innerX, innerY + innerSize/2,
                    innerX + innerSize, innerY + innerSize/2
                )
                
                -- Vertical divider
                love.graphics.line(
                    innerX + innerSize/2, innerY,
                    innerX + innerSize/2, innerY + innerSize
                )
                
                -- Draw glass panes with blue tint
                love.graphics.setColor(0.7, 0.8, 1, 0.6) -- More visible blue for glass
                
                -- Top-left pane
                love.graphics.rectangle("fill", 
                    innerX + 2, innerY + 2, 
                    innerSize/2 - 3, innerSize/2 - 3
                )
                
                -- Top-right pane
                love.graphics.rectangle("fill", 
                    innerX + innerSize/2 + 1, innerY + 2, 
                    innerSize/2 - 3, innerSize/2 - 3
                )
                
                -- Bottom-left pane
                love.graphics.rectangle("fill", 
                    innerX + 2, innerY + innerSize/2 + 1, 
                    innerSize/2 - 3, innerSize/2 - 3
                )
                
                -- Bottom-right pane
                love.graphics.rectangle("fill", 
                    innerX + innerSize/2 + 1, innerY + innerSize/2 + 1, 
                    innerSize/2 - 3, innerSize/2 - 3
                )
            end
        end
    },
    water = {
        name = "Water",
        color = {0.93, 0.93, 0.93, 1}, -- White (same as floor)
        borderColor = {0.4, 0.6, 0.8, 1}, -- Blue border
        walkable = false,
        showLabel = false,
        drawDetails = function(self, x, y, tileSize)
            -- Water-specific rendering could be added here
        end
    },
    grass = {
        name = "Grass",
        color = {0.93, 0.93, 0.93, 1}, -- White (same as floor)
        borderColor = {0.5, 0.7, 0.5, 1}, -- Green border
        walkable = true,
        showLabel = false,
        drawDetails = function(self, x, y, tileSize)
            -- Grass-specific rendering could be added here
        end
    }
    -- Add more tile types easily here
}

function Tile:new(config)
    -- Set default tile-specific properties
    config.type = config.type or "tile"
    config.name = config.name or "Tile"
    config.width = 1
    config.height = 1
    
    -- Override walkable property for walls - walls should never be walkable
    if config.tileType == "wall" then
        config.walkable = false
    else
        config.walkable = config.walkable ~= nil and config.walkable or true
    end
    
    -- Create the tile using the Entity constructor
    local self = Entity.new(self, config)
    
    -- Tile-specific properties
    self.tileType = config.tileType or "floor"
    self.drawDetails = config.drawDetails
    
    -- Copy any extra properties from config
    if config.isWindow ~= nil then
        self.isWindow = config.isWindow
        
        -- Add properties for window tiles to support infoscreen
        if self.isWindow then
            self.interactable = true
            self.name = "Window"
            self.labelText = "window"
            self.properties = {
                dimensions = "1x1",
                transparent = true,
                breakable = true
            }
            
            -- Add flavor text for the infoscreen
            self.flavorText = "Well, it's window."
            
            -- Add interaction method for window tiles
            function self:interact()
                local result = {
                    success = true,
                    message = "Looking through the window..."
                }
                return result
            end
        end
    end
    
    return self
end

-- Factory method to create different types of tiles
function Tile.createTile(tileType, grid, gridX, gridY, extraProperties)
    -- Get the configuration for this tile type, or default to floor if not found
    local config = tileConfigs[tileType] or tileConfigs["floor"]
    
    local tileConfig = {
        grid = grid,
        gridX = gridX,
        gridY = gridY,
        tileType = tileType,
        name = config.name,
        color = config.color,
        borderColor = config.borderColor,
        borderWidth = config.borderWidth,
        walkable = config.walkable,
        showLabel = config.showLabel,
        drawDetails = config.drawDetails
    }
    
    -- Add any extra properties (like isWindow)
    if extraProperties then
        for k, v in pairs(extraProperties) do
            tileConfig[k] = v
        end
    end
    
    return Tile:new(tileConfig)
end

-- Override the draw method to add tile-specific rendering
function Tile:draw()
    -- Call the parent draw method for basic rendering
    Entity.draw(self)
    
    -- Call tile-specific drawing function if it exists
    if self.drawDetails then
        self.drawDetails(self, self.x, self.y, self.grid.tileSize)
    end
    
    -- Reset colors and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Tile
