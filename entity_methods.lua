-- Get entity dimensions from the furniture module
function MapEditor:getEntityDimensions(entityType)
    -- Create a temporary entity to get its dimensions
    local tempEntity = Furniture.create(entityType, self.grid, 1, 1)
    if tempEntity then
        local width = tempEntity.width or 1
        local height = tempEntity.height or 1
        return width, height
    end
    return 1, 1  -- Default to 1x1 if entity type not found
end

-- Rotate the current entity dimensions
function MapEditor:rotateEntity()
    -- Rotate by 90 degrees clockwise
    self.entityRotation = (self.entityRotation + 90) % 360
    print("Entity rotated to " .. self.entityRotation .. " degrees")
end

-- Get rotated entity dimensions
function MapEditor:getRotatedEntityDimensions(entityType)
    local width, height = self:getEntityDimensions(entityType)
    
    -- If rotation is 90 or 270 degrees, swap width and height
    if self.entityRotation == 90 or self.entityRotation == 270 then
        return height, width
    end
    
    return width, height
end

-- Apply rotation to an entity
function MapEditor:applyRotationToEntity(entity)
    if entity and self.entityRotation > 0 then
        entity.rotation = self.entityRotation
        
        -- If rotation is 90 or 270 degrees, swap width and height
        if self.entityRotation == 90 or self.entityRotation == 270 then
            local temp = entity.width
            entity.width = entity.height
            entity.height = temp
        end
    end
    
    return entity
end
