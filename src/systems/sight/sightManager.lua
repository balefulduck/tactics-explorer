-- Sight Manager
-- Handles line of sight calculations for entities

local SightManager = {}
SightManager.__index = SightManager

function SightManager:new(map)
    local self = setmetatable({}, SightManager)
    
    -- Store reference to the map
    self.map = map
    
    -- Sight constants (easily tweakable)
    self.constants = {
        BASE_SIGHT_RANGE = 100,        -- Perfect visibility range
        MAX_SIGHT_RANGE = 130,         -- Maximum possible sight range
        DEGRADATION_START = 100,       -- Where sight starts to degrade
        HEIGHT_THRESHOLD = 2,          -- Height at which objects fully block sight
        PARTIAL_OBSTRUCTION_FACTOR = 0.5,  -- Chance reduction for partial obstructions
        
        -- Peripheral vision settings
        PERIPHERAL_ANGLE = 120,        -- Angle of peripheral vision (in degrees)
        PERIPHERAL_PENALTY = 0.7,      -- Detection chance multiplier in peripheral vision
        
        -- Other factors
        DARKNESS_PENALTY = 0.5,        -- Detection chance multiplier in darkness
        MOVEMENT_BONUS = 0.2,          -- Detection chance bonus for moving targets
    }
    
    -- Cache for line of sight calculations
    self.losCache = {}
    self.cacheLifetime = 5             -- How many turns before cache is invalidated
    
    -- Debug flags
    self.debug = false
    self.visualizeLoS = false
    
    return self
end

-- Calculate if entity A can see entity B
function SightManager:canSee(entityA, entityB)
    if not entityA or not entityB then return false end
    
    -- Quick distance check first (optimization)
    local dist = self:getDistance(entityA, entityB)
    if dist > self.constants.MAX_SIGHT_RANGE then
        return false
    end
    
    -- Check if we have a cached result
    local cacheKey = self:getCacheKey(entityA, entityB)
    if self.losCache[cacheKey] and self.losCache[cacheKey].turn >= (entityA.world and entityA.world.currentTurn or 0) - self.cacheLifetime then
        return self.losCache[cacheKey].result
    end
    
    -- Calculate line of sight
    local losResult = self:calculateLineOfSight(entityA, entityB)
    
    -- Cache the result
    self.losCache[cacheKey] = {
        result = losResult,
        turn = entityA.world and entityA.world.currentTurn or 0
    }
    
    return losResult
end

-- Calculate line of sight between two entities
function SightManager:calculateLineOfSight(observer, target)
    -- Get positions
    local x1, y1 = observer.gridX, observer.gridY
    local x2, y2 = target.gridX, target.gridY
    
    -- Calculate base chance of seeing
    local seeingChance = self:calculateSeeingChance(observer, target)
    
    -- If chance is 0, return false immediately
    if seeingChance <= 0 then
        return false
    end
    
    -- Check for obstructions along the line
    local obstructionFactor = self:calculateObstructionFactor(x1, y1, x2, y2, observer.height or self.constants.HEIGHT_THRESHOLD)
    
    -- Apply obstruction factor to seeing chance
    seeingChance = seeingChance * obstructionFactor
    
    -- Debug output
    if self.debug then
        print(observer.name .. " sees " .. target.name .. " with chance: " .. seeingChance)
    end
    
    -- Roll for detection
    local roll = math.random()
    local detected = roll <= seeingChance
    
    return detected
end

-- Calculate the base chance of seeing a target based on distance and other factors
function SightManager:calculateSeeingChance(observer, target)
    -- Get distance
    local dist = self:getDistance(observer, target)
    
    -- Base chance starts at 100%
    local chance = 1.0
    
    -- Apply distance degradation
    if dist > self.constants.DEGRADATION_START then
        local degradation = (dist - self.constants.DEGRADATION_START) / 
                           (self.constants.MAX_SIGHT_RANGE - self.constants.DEGRADATION_START)
        chance = chance * (1 - degradation)
    end
    
    -- Apply peripheral vision penalty if applicable
    if observer.direction then
        local angle = self:calculateAngle(observer, target)
        local angleDiff = math.abs(self:angleDifference(angle, observer.direction))
        
        if angleDiff > self.constants.PERIPHERAL_ANGLE / 2 then
            chance = chance * self.constants.PERIPHERAL_PENALTY
        end
    end
    
    -- Apply lighting conditions
    local lightLevel = self:getLightLevel(target.gridX, target.gridY)
    if lightLevel < 0.7 then  -- Arbitrary threshold for "darkness"
        chance = chance * (lightLevel + self.constants.DARKNESS_PENALTY)
    end
    
    -- Apply movement bonus if target is moving
    if target.isMoving then
        chance = math.min(1.0, chance + self.constants.MOVEMENT_BONUS)
    end
    
    -- Apply observer's perception bonus/penalty
    if observer.perception then
        chance = chance * observer.perception
    end
    
    -- Apply target's stealth bonus/penalty
    if target.stealth then
        chance = chance * (1 - target.stealth)
    end
    
    -- Ensure chance is within bounds
    return math.max(0, math.min(1, chance))
end

-- Calculate obstruction factor along a line
function SightManager:calculateObstructionFactor(x1, y1, x2, y2, observerHeight)
    observerHeight = observerHeight or self.constants.HEIGHT_THRESHOLD
    
    -- Get all tiles along the line
    local tiles = self:getLinePoints(x1, y1, x2, y2)
    
    -- Start with no obstruction
    local factor = 1.0
    
    -- Track the highest obstruction so far
    local highestObstruction = 0
    
    -- Check each tile along the line (except the start and end points)
    for i = 2, #tiles - 1 do
        local tile = tiles[i]
        
        -- Get tile and objects at this position
        local tileHeight = self:getTileHeight(tile.x, tile.y)
        local objectsHeight = self:getObjectsHeight(tile.x, tile.y)
        
        -- Use the higher of tile or objects
        local totalHeight = math.max(tileHeight, objectsHeight)
        
        -- If height is greater than observer, full obstruction
        if totalHeight >= observerHeight and totalHeight > highestObstruction then
            highestObstruction = totalHeight
            
            -- Full obstruction
            if totalHeight >= self.constants.HEIGHT_THRESHOLD then
                factor = 0
                break
            else
                -- Partial obstruction
                factor = factor * (1 - self:getObstructionFactor(tile.x, tile.y))
            end
        end
    end
    
    return factor
end

-- Get the obstruction factor for a specific tile
function SightManager:getObstructionFactor(x, y)
    -- Default partial obstruction
    local factor = self.constants.PARTIAL_OBSTRUCTION_FACTOR
    
    -- Check if the map has specific obstruction data
    if self.map and self.map.getTileObstruction then
        factor = self.map:getTileObstruction(x, y) or factor
    end
    
    return factor
end

-- Get height of a tile
function SightManager:getTileHeight(x, y)
    if self.map and self.map.getTileHeight then
        return self.map:getTileHeight(x, y) or 0
    end
    return 0
end

-- Get combined height of all objects on a tile
function SightManager:getObjectsHeight(x, y)
    if self.map and self.map.getObjectsHeight then
        return self.map:getObjectsHeight(x, y) or 0
    end
    return 0
end

-- Get light level at a position (0 = dark, 1 = fully lit)
function SightManager:getLightLevel(x, y)
    if self.map and self.map.getLightLevel then
        return self.map:getLightLevel(x, y) or 1
    end
    return 1  -- Default to fully lit
end

-- Calculate distance between two entities
function SightManager:getDistance(entityA, entityB)
    local dx = entityA.gridX - entityB.gridX
    local dy = entityA.gridY - entityB.gridY
    return math.sqrt(dx * dx + dy * dy)
end

-- Calculate angle from entity A to entity B (in degrees)
function SightManager:calculateAngle(entityA, entityB)
    local dx = entityB.gridX - entityA.gridX
    local dy = entityB.gridY - entityA.gridY
    return math.deg(math.atan2(dy, dx))
end

-- Calculate the smallest difference between two angles
function SightManager:angleDifference(angle1, angle2)
    local diff = (angle1 - angle2) % 360
    if diff > 180 then
        diff = diff - 360
    end
    return diff
end

-- Generate a unique cache key for two entities
function SightManager:getCacheKey(entityA, entityB)
    return entityA.id .. "-" .. entityB.id
end

-- Get all points along a line using Bresenham's line algorithm
function SightManager:getLinePoints(x1, y1, x2, y2)
    local points = {}
    
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy
    
    while true do
        table.insert(points, {x = x1, y = y1})
        
        if x1 == x2 and y1 == y2 then
            break
        end
        
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
    
    return points
end

-- Update sight for all entities
function SightManager:updateAllSight()
    -- Clear the cache when doing a full update
    self.losCache = {}
    
    -- If we have no map or the map has no entities, return
    if not self.map or not self.map.entities then
        return
    end
    
    -- For each entity with sight capability
    for _, observer in ipairs(self.map.entities) do
        if observer.hasSight then
            -- Reset visible entities
            observer.visibleEntities = {}
            
            -- Check visibility of all other entities
            for _, target in ipairs(self.map.entities) do
                if observer ~= target then
                    local canSee = self:canSee(observer, target)
                    
                    if canSee then
                        table.insert(observer.visibleEntities, target)
                    end
                end
            end
        end
    end
end

-- Draw debug visualization
function SightManager:drawDebug()
    if not self.visualizeLoS then return end
    
    -- Find player or first entity with sight
    local observer = nil
    for _, entity in ipairs(self.map.entities or {}) do
        if entity.isPlayerControlled or entity.hasSight then
            observer = entity
            if entity.isPlayerControlled then break end
        end
    end
    
    if not observer then return end
    
    -- Draw sight cone
    love.graphics.setColor(0.2, 0.8, 0.2, 0.3)
    
    -- Draw visible entities
    if observer.visibleEntities then
        for _, target in ipairs(observer.visibleEntities) do
            -- Draw line to visible entity
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.line(
                observer.x + observer.width/2, 
                observer.y + observer.height/2,
                target.x + target.width/2,
                target.y + target.height/2
            )
            
            -- Highlight visible entity
            love.graphics.setColor(1, 1, 0, 0.3)
            love.graphics.rectangle(
                "fill", 
                target.x, 
                target.y, 
                target.width, 
                target.height
            )
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return SightManager
