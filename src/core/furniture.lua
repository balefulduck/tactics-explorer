-- Furniture factory
-- Creates different types of furniture entities with consistent styling

local Entity = require("src.core.entity")

local Furniture = {}

-- Factory method to create different types of furniture
function Furniture.create(furnitureType, grid, gridX, gridY, options)
    options = options or {}
    
    local config = {
        grid = grid,
        gridX = gridX,
        gridY = gridY,
        type = "furniture",
        walkable = false,
        interactable = true,
        showLabel = true,
    }
    
    -- Configure based on furniture type
    if furnitureType == "couch" then
        config.name = "Couch"
        config.labelText = "couch"
        config.width = 3
        config.height = 1
        config.properties = {
            sittable = true,
            cover = true,
            comfort = 3,
            dimensions = "3x1",
            height = 2,
            penetration = {
                ["9MM"] = 0.75,
                ["5.56"] = 1,
                ["7.62"] = 1.5
            }
        }
        
    elseif furnitureType == "tv" then
        config.name = "TV"
        config.labelText = "TV"
        config.width = 1
        config.height = 1
        config.properties = {
            watchable = true,
            electronic = true
        }
        
    elseif furnitureType == "coffee_table" then
        config.name = "Coffee Table"
        config.labelText = "coffee table"
        config.width = 1
        config.height = 1
        config.properties = {
            surface = true
        }
        
    elseif furnitureType == "cupboard" then
        config.name = "Cupboard"
        config.labelText = "cupboard"
        config.width = 4
        config.height = 1
        config.properties = {
            storage = true,
            searchable = true,
            capacity = 10
        }
        
    elseif furnitureType == "window" then
        config.name = "Window"
        config.labelText = "window"
        config.width = 1
        config.height = 1
        config.properties = {
            transparent = true,
            breakable = true
        }
        
    elseif furnitureType == "plant" then
        config.name = "Plant"
        config.labelText = "plant"
        config.width = 1
        config.height = 1
        config.properties = {
            decorative = true,
            watered = options.watered or false
        }
        
    elseif furnitureType == "bed" then
        config.name = "Bed"
        config.labelText = "bed"
        config.width = 2
        config.height = 1
        config.properties = {
            sittable = true,
            sleepable = true,
            comfort = 4
        }
        
    elseif furnitureType == "desk" then
        config.name = "Desk"
        config.labelText = "desk"
        config.width = 2
        config.height = 1
        config.properties = {
            surface = true,
            workable = true
        }
        
    elseif furnitureType == "chair" then
        config.name = "Chair"
        config.labelText = "chair"
        config.width = 1
        config.height = 1
        config.properties = {
            sittable = true,
            comfort = 2
        }
        
    else
        -- Default generic furniture
        config.name = options.name or "Furniture"
        config.labelText = options.labelText or "furniture"
        config.width = options.width or 1
        config.height = options.height or 1
        config.properties = options.properties or {}
    end
    
    -- Override with any provided options
    for k, v in pairs(options) do
        config[k] = v
    end
    
    -- Create the entity
    local furniture = Entity:new(config)
    
    -- Add rotation property (default to 0)
    furniture.rotation = options.rotation or 0
    
    -- Add furniture-specific methods
    
    -- Custom interaction method based on furniture type
    function furniture:interact()
        local result = {
            success = true,
            message = "Interacted with " .. self.name
        }
        
        if self.properties.sittable then
            result.message = "Sat on the " .. self.name
        elseif self.properties.storage then
            result.message = "Opened the " .. self.name
        elseif self.properties.watchable then
            result.message = "Turned on the " .. self.name
        end
        
        return result
    end
    
    -- Custom draw method to add furniture-specific visual elements
    local originalDraw = furniture.draw
    function furniture:draw()
        -- Call the original draw method
        originalDraw(self)
        
        -- Add furniture-specific visual elements
        local tileSize = self.grid.tileSize
        
        if furnitureType == "couch" then
            -- Add couch details (simple line pattern)
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
            love.graphics.setLineWidth(1)
            
            -- Draw back of couch
            local backY = self.y + tileSize * 0.2
            love.graphics.line(
                self.x, backY,
                self.x + self.width * tileSize, backY
            )
            
            -- Draw cushion divisions
            for i = 1, self.width - 1 do
                local dividerX = self.x + i * tileSize
                love.graphics.line(
                    dividerX, self.y + tileSize * 0.2,
                    dividerX, self.y + tileSize
                )
            end
            
        elseif furnitureType == "tv" then
            -- Add TV screen
            love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
            love.graphics.rectangle(
                "fill",
                self.x + tileSize * 0.15,
                self.y + tileSize * 0.15,
                tileSize * 0.7,
                tileSize * 0.5
            )
            
        elseif furnitureType == "cupboard" then
            -- Add cupboard details
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
            
            -- Vertical dividers between sections
            for i = 1, self.width - 1 do
                local dividerX = self.x + i * tileSize
                love.graphics.line(
                    dividerX, self.y + tileSize * 0.1,
                    dividerX, self.y + tileSize * 0.9
                )
            end
            
            -- Draw handles on each section
            for i = 0, self.width - 1 do
                local handleX = self.x + i * tileSize + tileSize * 0.5
                local handleY = self.y + tileSize * 0.7
                
                love.graphics.rectangle(
                    "fill",
                    handleX - 4,
                    handleY - 1.5,
                    8,
                    3
                )
            end
            
        elseif furnitureType == "window" then
            -- Add window details
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
            
            -- Window cross
            love.graphics.line(
                self.x, self.y + tileSize * 0.5,
                self.x + tileSize, self.y + tileSize * 0.5
            )
            
            love.graphics.line(
                self.x + tileSize * 0.5, self.y,
                self.x + tileSize * 0.5, self.y + tileSize
            )
            
        elseif furnitureType == "plant" then
            -- Add plant details
            love.graphics.setColor(0.3, 0.5, 0.3, 0.4)
            
            -- Draw pot
            love.graphics.rectangle(
                "fill",
                self.x + tileSize * 0.3,
                self.y + tileSize * 0.6,
                tileSize * 0.4,
                tileSize * 0.3
            )
            
            -- Draw plant stems and leaves
            love.graphics.setLineWidth(1.5)
            local centerX = self.x + tileSize * 0.5
            local baseY = self.y + tileSize * 0.6
            
            -- Stem
            love.graphics.line(
                centerX, baseY,
                centerX, self.y + tileSize * 0.2
            )
            
            -- Leaves
            love.graphics.line(
                centerX, self.y + tileSize * 0.4,
                centerX + tileSize * 0.2, self.y + tileSize * 0.3
            )
            
            love.graphics.line(
                centerX, self.y + tileSize * 0.5,
                centerX - tileSize * 0.2, self.y + tileSize * 0.4
            )
        end
        
        -- Reset colors and line width
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
    end
    
    return furniture
end

return Furniture
