-- Entity Sight Extension
-- Adds sight capabilities to entities

local EntitySightExtension = {}

-- Add sight capabilities to an entity
function EntitySightExtension.extend(entity, config)
    config = config or {}
    
    -- Mark entity as having sight
    entity.hasSight = true
    
    -- Set sight properties
    entity.sightRange = config.sightRange or 100
    entity.maxSightRange = config.maxSightRange or 130
    entity.perception = config.perception or 1.0  -- Perception multiplier (1.0 = normal)
    entity.height = config.height or 2  -- Default entity height
    entity.direction = config.direction or 0  -- Direction entity is facing in degrees (0 = right)
    
    -- Initialize visible entities list
    entity.visibleEntities = {}
    
    -- Field of view properties
    entity.fieldOfView = config.fieldOfView or 120  -- Degrees
    entity.peripheralVision = config.peripheralVision or true  -- Whether entity has peripheral vision
    
    -- Add sight-related methods
    
    -- Set the direction the entity is facing
    if not entity.setDirection then
        entity.setDirection = function(self, direction)
            self.direction = direction
            return self.direction
        end
    end
    
    -- Set direction based on movement
    if not entity.updateDirectionFromMovement then
        entity.updateDirectionFromMovement = function(self, dx, dy)
            if dx == 0 and dy == 0 then return self.direction end
            
            self.direction = math.deg(math.atan2(dy, dx))
            return self.direction
        end
    end
    
    -- Check if this entity can see another entity
    if not entity.canSee then
        entity.canSee = function(self, target)
            -- This requires a reference to the sight manager
            if self.world and self.world.sightManager then
                return self.world.sightManager:canSee(self, target)
            end
            return false
        end
    end
    
    -- Get all entities this entity can see
    if not entity.getVisibleEntities then
        entity.getVisibleEntities = function(self)
            return self.visibleEntities or {}
        end
    end
    
    -- Check if a specific position is visible
    if not entity.canSeePosition then
        entity.canSeePosition = function(self, x, y)
            -- Create a temporary target at the position
            local target = {
                gridX = x,
                gridY = y,
                name = "position_" .. x .. "_" .. y,
                id = "temp_" .. x .. "_" .. y
            }
            
            -- Check visibility
            if self.world and self.world.sightManager then
                return self.world.sightManager:canSee(self, target)
            end
            return false
        end
    end
    
    -- Update sight (recalculate visible entities)
    if not entity.updateSight then
        entity.updateSight = function(self)
            if self.world and self.world.sightManager then
                -- Reset visible entities
                self.visibleEntities = {}
                
                -- Check visibility of all other entities
                for _, target in ipairs(self.world.entities or {}) do
                    if self ~= target then
                        local canSee = self:canSee(target)
                        
                        if canSee then
                            table.insert(self.visibleEntities, target)
                        end
                    end
                end
            end
            return self.visibleEntities
        end
    end
    
    return entity
end

-- Create a fog of war system for a map based on entity sight
function EntitySightExtension.createFogOfWar(map, observer)
    local fogOfWar = {}
    
    -- Initialize fog of war grid
    for y = 1, map.height do
        fogOfWar[y] = {}
        for x = 1, map.width do
            -- 0 = unexplored, 1 = previously seen, 2 = currently visible
            fogOfWar[y][x] = 0
        end
    end
    
    -- Update fog of war based on what the observer can see
    local function updateFogOfWar()
        if not observer or not observer.canSeePosition then return end
        
        -- Mark currently visible tiles
        for y = 1, map.height do
            for x = 1, map.width do
                if observer:canSeePosition(x, y) then
                    fogOfWar[y][x] = 2  -- Currently visible
                elseif fogOfWar[y][x] == 2 then
                    fogOfWar[y][x] = 1  -- Previously seen
                end
            end
        end
    end
    
    -- Check if a position is visible in the fog of war
    local function isVisible(x, y)
        if x < 1 or y < 1 or x > map.width or y > map.height then
            return false
        end
        return fogOfWar[y][x] == 2
    end
    
    -- Check if a position has been explored
    local function isExplored(x, y)
        if x < 1 or y < 1 or x > map.width or y > map.height then
            return false
        end
        return fogOfWar[y][x] > 0
    end
    
    -- Draw the fog of war
    local function draw()
        love.graphics.setColor(0, 0, 0, 0.7)  -- Dark fog
        
        for y = 1, map.height do
            for x = 1, map.width do
                if fogOfWar[y][x] == 0 then
                    -- Unexplored - completely dark
                    love.graphics.rectangle(
                        "fill",
                        (x - 1) * map.grid.tileSize,
                        (y - 1) * map.grid.tileSize,
                        map.grid.tileSize,
                        map.grid.tileSize
                    )
                elseif fogOfWar[y][x] == 1 then
                    -- Previously seen - partially dark
                    love.graphics.setColor(0, 0, 0, 0.4)
                    love.graphics.rectangle(
                        "fill",
                        (x - 1) * map.grid.tileSize,
                        (y - 1) * map.grid.tileSize,
                        map.grid.tileSize,
                        map.grid.tileSize
                    )
                end
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Return the fog of war interface
    return {
        update = updateFogOfWar,
        isVisible = isVisible,
        isExplored = isExplored,
        draw = draw,
        data = fogOfWar
    }
end

return EntitySightExtension
