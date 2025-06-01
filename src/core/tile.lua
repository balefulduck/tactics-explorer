-- Tile class for representing a single grid tile
-- Uses the new entity-based system for consistency

local Entity = require("src.core.entity")
local Examinable = require("src.interfaces.examinable")

local Tile = setmetatable({}, {__index = Entity})
Tile.__index = Tile

-- Define all tile configurations in one place for better scalability
local tileConfigs = {
    -- Floor tiles group - all floor tiles have height 0 and dimensions 1x1
    stoneFloor = {
        name = "Stone Floor",
        color = {0.85, 0.85, 0.85, 1}, -- Light gray
        borderColor = {0, 0, 0, 0}, -- Transparent border (no border)
        borderWidth = 0,
        walkable = true,
        showLabel = false,
        height = 0,
        stepSound = 1.1,
        events = {
            { name = "shoeUntie", chance = 0.05 }
        },
        infoscreenImage = "assets/images/stonefloor.jpg",
        flavorText = "How long will these stones remain?",
        drawDetails = function(self, x, y, tileSize)
            -- Add a subtle gap between tiles (2 pixels)
            local gap = 2
            
            -- Stone floor rendering - subtle texture
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            local padding = 2
            local innerX = x + gap/2 + padding
            local innerY = y + gap/2 + padding
            local innerSize = tileSize - gap - (padding * 2)
            
            -- Draw base floor
            love.graphics.setColor(0.82, 0.82, 0.82, 1)
            love.graphics.rectangle("fill", x + gap/2, y + gap/2, tileSize - gap, tileSize - gap)
            
            -- Draw a subtle stone pattern
            for i = 0, 2 do
                for j = 0, 2 do
                    -- Randomize stone color slightly
                    local shade = 0.75 + (((i+j) % 3) * 0.05)
                    love.graphics.setColor(shade, shade, shade, 1)
                    
                    -- Draw stone blocks with small gaps
                    love.graphics.rectangle("fill", 
                        innerX + (i * innerSize/3) + 1, 
                        innerY + (j * innerSize/3) + 1, 
                        innerSize/3 - 2, 
                        innerSize/3 - 2)
                end
            end
        end
    },
    grassFloor = {
        name = "Grass",
        color = {0.7, 0.9, 0.7, 1}, -- Light green
        borderColor = {0.5, 0.7, 0.5, 1}, -- Darker green border
        walkable = true,
        showLabel = false,
        height = 0,
        stepSound = 0.5,
        events = {
            { name = "shoeUntie", chance = 0.008 }
        },
        infoscreenImage = "grassfloor.jpg",
        flavorText = "You feel the soft and living grass beneath your feet",
        drawDetails = function(self, x, y, tileSize)
            -- Grass rendering - small tufts
            local padding = 2
            local innerX = x + padding
            local innerY = y + padding
            local innerSize = tileSize - (padding * 2)
            
            -- Base grass color
            love.graphics.setColor(0.6, 0.8, 0.6, 1)
            love.graphics.rectangle("fill", innerX, innerY, innerSize, innerSize)
            
            -- Draw grass tufts
            love.graphics.setColor(0.5, 0.7, 0.5, 1)
            love.graphics.setLineWidth(1)
            
            -- Create a pseudo-random pattern based on position
            math.randomseed(self.gridX * 100 + self.gridY)
            for i = 1, 15 do
                local x1 = innerX + math.random(innerSize)
                local y1 = innerY + math.random(innerSize)
                local height = 2 + math.random(4)
                
                love.graphics.line(x1, y1, x1, y1 - height)
            end
            -- Reset random seed
            math.randomseed(os.time())
        end
    },
    wall = {
        name = "Wall",
        color = {0.93, 0.93, 0.93, 1}, -- White (same as floor)
        borderColor = {0, 0, 0, 0}, -- Transparent border (no border)
        borderWidth = 0,
        walkable = false, -- Walls are never walkable
        showLabel = false,
        height = 2, -- Wall has height 2 for sight system
        
        -- We'll load the image in the drawDetails function to handle errors better
        drawDetails = function(self, x, y, tileSize)
            -- Load the image if not already loaded
            if not self.wallImage then
                -- Use pcall to catch any errors during image loading
                local success, result = pcall(function()
                    return love.graphics.newImage("assets/images/wall.png")
                end)
                
                if success then
                    self.wallImage = result
                    print("Wall image loaded successfully. Dimensions: " .. self.wallImage:getWidth() .. "x" .. self.wallImage:getHeight())
                else
                    print("Failed to load wall image: " .. tostring(result))
                    self.wallImage = false -- Mark as failed to avoid repeated attempts
                end
            end
            
            -- Add a subtle gap between tiles (2 pixels)
            local gap = 2
            
            -- Draw the wall sprite if image loaded successfully
            if self.wallImage and self.wallImage ~= false then
                love.graphics.setColor(1, 1, 1, 1) -- Reset color to white for proper image rendering
                
                -- Get actual image dimensions
                local imgWidth = self.wallImage:getWidth()
                local imgHeight = self.wallImage:getHeight()
                
                -- Calculate scale to fit the tile size minus the gap
                local scaleX = (tileSize - gap) / imgWidth
                local scaleY = (tileSize - gap) / imgHeight
                
                -- Draw the image with a small gap
                love.graphics.draw(self.wallImage, x + gap/2, y + gap/2, 0, scaleX, scaleY)
            else
                -- Fallback rendering if image failed to load
                love.graphics.setColor(0.6, 0.6, 0.6, 1) -- Dark gray
                love.graphics.rectangle("fill", x + gap/2, y + gap/2, tileSize - gap, tileSize - gap)
                
                -- Add a simple wall pattern
                love.graphics.setColor(0.4, 0.4, 0.4, 1) -- Darker gray for pattern
                love.graphics.rectangle("fill", x + gap/2 + 2, y + gap/2 + 2, tileSize - gap - 4, tileSize - gap - 4)
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
    -- Keeping the old grass type temporarily for backward compatibility
    grass = {
        name = "Old Grass",
        color = {0.93, 0.93, 0.93, 1}, -- White (same as floor)
        borderColor = {0.5, 0.7, 0.5, 1}, -- Green border
        walkable = true,
        showLabel = false,
        height = 0,
        drawDetails = function(self, x, y, tileSize)
            -- Redirect to the new grassFloor type
            tileConfigs.grassFloor.drawDetails(self, x, y, tileSize)
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
    self.tileType = config.tileType or "stoneFloor" -- Default to stoneFloor instead of generic floor
    self.drawDetails = config.drawDetails
    
    -- Add height property (0 for floor tiles)
    self.height = config.height or 0
    
    -- Add step sound property
    self.stepSound = config.stepSound
    
    -- Add events
    self.events = config.events or {}
    
    -- Add infoscreen image
    self.infoscreenImage = config.infoscreenImage
    
    -- Add flavor text if not already set
    if not self.flavorText and config.flavorText then
        self.flavorText = config.flavorText
    end
    
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
    -- Get the configuration for this tile type, or default to stoneFloor if not found
    local config = tileConfigs[tileType] or tileConfigs["stoneFloor"]
    
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
        drawDetails = config.drawDetails,
        height = config.height,
        stepSound = config.stepSound,
        events = config.events,
        infoscreenImage = config.infoscreenImage,
        flavorText = config.flavorText
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

-- Override the getExaminationInfo method to provide tile-specific information
function Tile:getExaminationInfo()
    -- Start with the base entity information
    local info = Entity.getExaminationInfo(self)
    
    -- Add tile-specific information
    info.tileType = self.tileType
    info.height = self.height
    
    -- Add walkability information
    info.walkable = self.walkable
    
    -- Add special properties for specific tile types
    if self.isWindow then
        info.description = "A glass window that allows you to see outside."
        info.flavorText = self.flavorText or "Light streams through the glass panes."
    elseif self.tileType == "wall" then
        info.description = "A solid wall that blocks movement."
        info.flavorText = self.flavorText or "The wall appears sturdy and well-built."
    elseif self.tileType == "water" then
        info.description = "A body of water that cannot be traversed."
        info.flavorText = self.flavorText or "The water ripples gently."
    end
    
    return info
end

return Tile
