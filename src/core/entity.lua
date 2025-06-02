-- Base Entity class
-- This serves as the foundation for all game objects

local Examinable = require("src.interfaces.examinable")

local Entity = {}
Entity.__index = Entity

function Entity:new(config)
    local self = setmetatable({}, self)
    
    -- Core properties
    self.id = config.id or "entity_" .. tostring(math.random(1000000))
    self.type = config.type or "entity"
    self.name = config.name or "Entity"
    self.description = config.description or ""
    
    -- Position and dimensions
    self.grid = config.grid
    self.gridX = config.gridX or 1
    self.gridY = config.gridY or 1
    self.width = config.width or 1  -- Width in grid cells
    self.height = config.height or 1 -- Height in grid cells
    
    -- Calculate world position
    if self.grid then
        self.x, self.y = self.grid:gridToWorld(self.gridX, self.gridY)
    else
        self.x, self.y = 0, 0
    end
    
    -- Visual properties
    self.color = config.color or {0.93, 0.93, 0.93, 1} -- Default white
    self.borderColor = config.borderColor or {0.7, 0.7, 0.7, 1}
    self.borderWidth = config.borderWidth or 1
    self.showLabel = config.showLabel or false
    self.labelText = config.labelText or self.name
    self.labelFont = config.labelFont or love.graphics.getFont()
    
    -- Interaction properties
    self.walkable = config.walkable or false
    self.interactable = config.interactable or false
    self.properties = config.properties or {}
    
    -- Optional image
    self.image = config.image
    
    return self
end

function Entity:update(dt)
    -- Base update logic
    -- Override in subclasses as needed
end

function Entity:draw()
    if not self.grid then return end
    
    local tileSize = self.grid.tileSize
    local totalWidth = self.width * tileSize
    local totalHeight = self.height * tileSize
    
    -- Draw entity background only if it's not fully transparent
    if self.color[4] > 0 then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, totalWidth, totalHeight)
    end
    
    -- Draw border only if it's not fully transparent and has width
    if self.borderColor[4] > 0 and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", self.x, self.y, totalWidth, totalHeight)
    end
    
    -- Draw label if enabled
    if self.showLabel then
        love.graphics.setFont(self.labelFont)
        local text = self.labelText
        local textWidth = self.labelFont:getWidth(text)
        local textHeight = self.labelFont:getHeight()
        
        -- Center the text
        local textX = self.x + (totalWidth - textWidth) / 2
        local textY = self.y + (totalHeight - textHeight) / 2
        
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8) -- Dark gray, semi-transparent
        love.graphics.print(text, textX, textY)
    end
    
    -- Reset colors and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function Entity:containsPosition(gridX, gridY)
    -- Use gridWidth/gridHeight if available, otherwise fall back to width/height
    local entityWidth = self.gridWidth or self.width or 1
    local entityHeight = self.gridHeight or self.height or 1
    
    return gridX >= self.gridX and 
           gridX < self.gridX + entityWidth and
           gridY >= self.gridY and
           gridY < self.gridY + entityHeight
end

function Entity:interact()
    -- Base interaction logic
    -- Override in subclasses as needed
    return {
        success = true,
        message = "Interacted with " .. self.name
    }
end

function Entity:hasProperty(propertyName)
    return self.properties[propertyName] ~= nil
end

function Entity:getProperty(propertyName)
    return self.properties[propertyName]
end

function Entity:setProperty(propertyName, value)
    self.properties[propertyName] = value
    return true
end

-- Implementation of the Examinable interface
-- Returns standardized examination information about this entity
function Entity:getExaminationInfo()
    local info = {
        name = self.name or "Unknown Entity",
        description = self.description or "",
        properties = {},
        image = self.image,
        flavorText = self.flavorText or "You see nothing special about this."
    }
    
    -- Add relevant properties for display
    for key, value in pairs(self.properties) do
        -- Skip complex tables and functions
        if type(value) ~= "table" and type(value) ~= "function" then
            info.properties[key] = value
        end
    end
    
    -- Add type information
    info.type = self.type
    
    -- Add size information if relevant
    if self.width > 1 or self.height > 1 then
        info.dimensions = self.width .. "x" .. self.height
    end
    
    return info
end

return Entity
