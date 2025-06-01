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
        
        -- Ambient occlusion settings
        AMBIENT_OCCLUSION_LEVELS = 3,  -- Number of occlusion levels
        AMBIENT_OCCLUSION_MISS_CHANCE = {0.05, 0.2, 1.0}, -- Miss chance for each level
        AMBIENT_OCCLUSION_COLORS = {   -- Colors for each occlusion level
            {0, 0, 0, 0.2},  -- Level 1: Slight occlusion
            {0, 0, 0, 0.4},  -- Level 2: Sharp occlusion
            {0, 0, 0, 0.7}   -- Level 3: Full occlusion
        },
        CORNER_PEEK_ENABLED = true     -- Allow peeking around corners
    }
    
    -- Cache for line of sight calculations
    self.losCache = {}
    self.cacheLifetime = 5             -- How many turns before cache is invalidated
    
    -- Visibility map for ambient occlusion rendering
    self.visibilityMap = {}
    
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
    
    -- Check if this is a corner peek case
    local isCornerPeek = false
    if self.constants.CORNER_PEEK_ENABLED then
        -- Check if observer is diagonally adjacent to a wall
        isCornerPeek = self:isCornerPeekCase(x1, y1, x2, y2)
    end
    
    -- Check each tile along the line (except the start and end points)
    for i = 2, #tiles - 1 do
        local tile = tiles[i]
        
        -- Get tile and objects at this position
        local tileHeight = self:getTileHeight(tile.x, tile.y)
        local objectsHeight = self:getObjectsHeight(tile.x, tile.y)
        
        -- Use the higher of tile or objects
        local totalHeight = math.max(tileHeight, objectsHeight)
        
        -- If height is greater than observer, potential obstruction
        if totalHeight >= observerHeight and totalHeight > highestObstruction then
            highestObstruction = totalHeight
            
            -- Full obstruction
            if totalHeight >= self.constants.HEIGHT_THRESHOLD then
                -- If this is a corner peek case, allow partial visibility
                if isCornerPeek then
                    -- Reduce factor but don't block completely
                    factor = factor * 0.8
                else
                    factor = 0
                    break
                end
            else
                -- Partial obstruction
                factor = factor * (1 - self:getObstructionFactor(tile.x, tile.y))
            end
        end
    end
    
    return factor
end

-- Check if this is a corner peek case (observer diagonally adjacent to a wall)
function SightManager:isCornerPeekCase(x1, y1, x2, y2)
    -- Check if there's a wall diagonally adjacent to the observer
    local diagonalDirections = {
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    }
    
    for _, dir in ipairs(diagonalDirections) do
        local diagX, diagY = x1 + dir[1], y1 + dir[2]
        
        -- Check if there's a wall at this diagonal position
        if self:getTileHeight(diagX, diagY) >= self.constants.HEIGHT_THRESHOLD or
           self:getObjectsHeight(diagX, diagY) >= self.constants.HEIGHT_THRESHOLD then
            
            -- Check if the target is on the other side of this wall
            -- This is a simplified check - we're looking if the target is in the general direction
            -- of the diagonal wall
            local dirToTarget = {
                math.sign(x2 - x1),
                math.sign(y2 - y1)
            }
            
            -- If the direction to target matches the diagonal direction, this is a corner peek case
            if (dirToTarget[1] == dir[1] and dirToTarget[2] == dir[2]) or
               (dirToTarget[1] == dir[1] and dirToTarget[2] == 0) or
               (dirToTarget[1] == 0 and dirToTarget[2] == dir[2]) then
                return true
            end
        end
    end
    
    return false
end

-- Helper function for sign of a number
function math.sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
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
    
    -- Reset visibility map
    self.visibilityMap = {}
    
    -- Find the player entity
    local player = nil
    for _, entity in ipairs(self.map.entities) do
        if entity.isPlayerControlled then
            player = entity
            break
        end
    end
    
    if not player then return end
    
    -- Calculate visibility and ambient occlusion from player's perspective
    self:calculateVisibilityMap(player)
    
    -- For each entity with sight capability
    for _, observer in ipairs(self.map.entities) do
        if observer.hasSight then
            -- Reset visible entities
            observer.visibleEntities = {}
            
            -- Check visibility of all other entities
            for _, target in ipairs(self.map.entities) do
                if observer ~= target then
                    local canSee = false
                    
                    if observer.isPlayerControlled then
                        -- For player, just use standard line of sight for now
                        -- This ensures movement works correctly
                        canSee = self:canSee(observer, target)
                        
                        -- Uncomment below to use ambient occlusion for detection
                        -- local targetX, targetY = target.gridX, target.gridY
                        -- local visLevel = self:getVisibilityLevel(targetX, targetY)
                        -- local missChance = self.constants.AMBIENT_OCCLUSION_MISS_CHANCE[visLevel] or 1.0
                        -- local roll = math.random()
                        -- canSee = roll > missChance
                    else
                        -- Non-player entities use the standard line of sight
                        canSee = self:canSee(observer, target)
                    end
                    
                    if canSee then
                        table.insert(observer.visibleEntities, target)
                    end
                end
            end
        end
    end
end

-- Calculate visibility map from an observer's perspective
function SightManager:calculateVisibilityMap(observer)
    if not observer or not self.map then return end
    
    local mapWidth = self.map.width
    local mapHeight = self.map.height
    
    -- Initialize visibility map with full occlusion
    for x = 1, mapWidth do
        self.visibilityMap[x] = {}
        for y = 1, mapHeight do
            self.visibilityMap[x][y] = 3 -- Level 3: Full occlusion
        end
    end
    
    -- Observer's position is always fully visible
    local obsX, obsY = observer.gridX, observer.gridY
    self.visibilityMap[obsX][obsY] = 0 -- Level 0: No occlusion
    
    -- Set adjacent tiles to visible as well
    for dx = -1, 1 do
        for dy = -1, 1 do
            local nx, ny = obsX + dx, obsY + dy
            if nx >= 1 and nx <= mapWidth and ny >= 1 and ny <= mapHeight then
                self.visibilityMap[nx][ny] = 0
            end
        end
    end
    
    -- Check each tile on the map
    for x = 1, mapWidth do
        for y = 1, mapHeight do
            -- Skip observer's position and adjacent tiles
            local isAdjacent = math.abs(x - obsX) <= 1 and math.abs(y - obsY) <= 1
            if not isAdjacent then
                -- Calculate base visibility
                local factor = self:calculateObstructionFactor(obsX, obsY, x, y, observer.height or 1)
                
                if factor > 0 then
                    -- Directly visible
                    self.visibilityMap[x][y] = 0
                end
            end
        end
    end
    
    -- Apply ambient occlusion after all direct visibility is calculated
    self:applyAllAmbientOcclusion(obsX, obsY)
end

-- Apply ambient occlusion to tiles behind walls
function SightManager:applyAllAmbientOcclusion(obsX, obsY)
    if not self.map then return end
    
    local mapWidth = self.map.width
    local mapHeight = self.map.height
    
    -- Find all walls
    local walls = {}
    for x = 1, mapWidth do
        for y = 1, mapHeight do
            local tile = self.map:getTile(x, y)
            if tile and tile.tileType == "wall" then
                table.insert(walls, {x = x, y = y})
            end
        end
    end
    
    -- For each wall, apply occlusion to tiles behind it
    for _, wall in ipairs(walls) do
        -- Direction vector from observer to wall
        local dx = wall.x - obsX
        local dy = wall.y - obsY
        
        -- Skip walls at observer position
        if dx ~= 0 or dy ~= 0 then
            -- Calculate distance
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- Normalize direction
            dx = dx / dist
            dy = dy / dist
            
            -- Check tiles in the same direction but further away from the wall
            for level = 1, self.constants.AMBIENT_OCCLUSION_LEVELS do
                -- Move further in the same direction
                local checkX = math.floor(wall.x + dx * level + 0.5)
                local checkY = math.floor(wall.y + dy * level + 0.5)
                
                -- Check if tile is within map bounds
                if checkX >= 1 and checkX <= mapWidth and 
                   checkY >= 1 and checkY <= mapHeight then
                    
                    -- Set occlusion level if it's higher than current
                    if self.visibilityMap[checkX][checkY] > level then
                        self.visibilityMap[checkX][checkY] = level
                    end
                end
            end
        end
    end
end

-- Legacy method kept for compatibility
function SightManager:applyAmbientOcclusion(obsX, obsY, x, y)
    -- This is now handled by applyAllAmbientOcclusion
    return
end

-- Get visibility level for a specific tile
function SightManager:getVisibilityLevel(x, y)
    if not self.visibilityMap or not self.visibilityMap[x] then
        return 3 -- Default to full occlusion
    end
    
    return self.visibilityMap[x][y] or 3
end

-- Draw debug visualization
function SightManager:drawDebug()
    -- Always draw ambient occlusion overlays
    self:drawAmbientOcclusion()
    
    -- Only draw lines and highlights if visualizeLoS is enabled
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

-- Draw ambient occlusion overlays
function SightManager:drawAmbientOcclusion()
    if not self.map or not self.visibilityMap then return end
    
    local tileSize = self.map.grid and self.map.grid.tileSize or 32
    
    -- Only draw occlusion for level 2 and 3 (moderate and heavy occlusion)
    -- Level 1 (light occlusion) is not visually represented to avoid cluttering the screen
    for x = 1, self.map.width do
        for y = 1, self.map.height do
            local level = self:getVisibilityLevel(x, y)
            
            -- Only draw level 2 and 3 occlusion
            if level >= 2 and level <= self.constants.AMBIENT_OCCLUSION_LEVELS then
                -- Get screen coordinates
                local screenX, screenY = (x-1) * tileSize, (y-1) * tileSize
                
                -- Account for the 2-pixel gap between tiles
                screenX = screenX + 2
                screenY = screenY + 2
                local adjustedSize = tileSize - 4
                
                -- Draw occlusion overlay
                local color = self.constants.AMBIENT_OCCLUSION_COLORS[level]
                love.graphics.setColor(color[1], color[2], color[3], color[4])
                love.graphics.rectangle("fill", screenX, screenY, adjustedSize, adjustedSize)
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return SightManager
