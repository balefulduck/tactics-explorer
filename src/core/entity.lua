-- Base Entity class
-- This serves as the foundation for all game objects

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
    
    -- Draw entity background
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, totalWidth, totalHeight)
    
    -- Draw border
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(self.borderWidth)
    love.graphics.rectangle("line", self.x, self.y, totalWidth, totalHeight)
    
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
    return gridX >= self.gridX and 
           gridX < self.gridX + self.width and
           gridY >= self.gridY and
           gridY < self.gridY + self.height
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

return Entity
