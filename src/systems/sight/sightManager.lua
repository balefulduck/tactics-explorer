-- Sight Manager
-- Handles line of sight calculations for entities

local SightManager = {}
SightManager.__index = SightManager

function SightManager:new(map)
    local self = setmetatable({}, SightManager)
    
    -- Store reference to the map
    self.map = map
    
    -- Cache for walls and obstacles to avoid rescanning the map
    self.wallCache = nil
    
    -- Track player position for incremental updates
    self.lastPlayerPos = nil
    
    -- Flag to indicate if wall cache needs updating
    self.wallCacheNeedsUpdate = true
    
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

-- Cache all walls and obstacles on the map
function SightManager:updateWallCache()
    if not self.map then return end
    
    print("Updating wall cache...")
    self.wallCache = {}
    
    -- Scan the map once for all walls and obstacles
    for x = 1, self.map.width do
        for y = 1, self.map.height do
            -- Check if this is a wall or obstacle that affects sight
            local tile = self.map:getTile(x, y)
            if tile and tile.tileType == "wall" then
                table.insert(self.wallCache, {x = x, y = y})
                print("✅ Added wall at (" .. x .. "," .. y .. ") to cache")
            end
        end
    end
    
    print("Wall cache updated. Found " .. #self.wallCache .. " walls.")
    self.wallCacheNeedsUpdate = false
end

-- Update sight for all entities
function SightManager:updateAllSight()
    -- Reset the occlusion check flag to ensure we check values again
    self.hasCheckedOcclusion = false
    
    -- Clear cache every update to ensure fresh calculations
    self.losCache = {}
    
    -- Update wall cache if needed
    if self.wallCacheNeedsUpdate or not self.wallCache then
        self:updateWallCache()
    end
    
    -- Find player entity
    local player = nil
    
    -- First check if there's a player reference in the map
    if self.map.game and self.map.game.player then
        player = self.map.game.player
    else
        -- Fallback to searching entities
        for _, entity in ipairs(self.map.entities or {}) do
            if entity.isPlayerControlled then
                player = entity
                break
            end
        end
    end
    
    if not player then
        print("ERROR: No player entity found!")
        return
    end
    
    print("Found player at position: (" .. player.gridX .. "," .. player.gridY .. ")")
    
    -- Initialize visibility map if it doesn't exist
    if not self.visibilityMap then
        print("Creating new visibility map")
        self.visibilityMap = {}
    end
    
    if not self.map then
        print("ERROR: No map reference in SightManager!")
        return
    end
    
    -- Reset all ambient occlusion values to 0 before recalculating
    print("Resetting ambient occlusion values")
    for x = 1, self.map.width do
        if not self.visibilityMap[x] then
            self.visibilityMap[x] = {}
        end
        
        for y = 1, self.map.height do
            if not self.visibilityMap[x][y] then
                self.visibilityMap[x][y] = {
                    visible = true,
                    explored = true
                }
            end
            
            -- Only reset the ambient occlusion value, keep other visibility data
            self.visibilityMap[x][y].ambientOcclusion = 0
        end
    end
    
    print("Map dimensions: " .. self.map.width .. "x" .. self.map.height)
    
    -- Use the wall cache to cast shadows
    if not self.wallCache or #self.wallCache == 0 then
        print("No walls found in cache, updating...")
        self:updateWallCache()
    end
    
    -- Check if player position has changed
    local playerMoved = false
    if not self.lastPlayerPos or 
       self.lastPlayerPos.x ~= player.gridX or 
       self.lastPlayerPos.y ~= player.gridY then
        playerMoved = true
        self.lastPlayerPos = {x = player.gridX, y = player.gridY}
        print("Player moved to (" .. player.gridX .. "," .. player.gridY .. ")")
    end
    
    -- Only cast shadows if the player has moved or we're forcing an update
    if playerMoved then
        print("Casting shadows from " .. #self.wallCache .. " walls")
        
        -- Cast shadows from each wall in the cache
        for _, wall in ipairs(self.wallCache) do
            -- Only process walls within a reasonable distance from player
            local distToWall = math.sqrt((wall.x - player.gridX)^2 + (wall.y - player.gridY)^2)
            if distToWall <= 15 then -- Only process walls within 15 tiles
                self:castShadow(player.gridX, player.gridY, wall.x, wall.y)
            end
        end
    else
        print("Player hasn't moved, skipping shadow recalculation")
    end
    
    -- Debug: Check if any occlusion values were set
    local hasOcclusion = false
    for x = 1, self.map.width do
        if self.visibilityMap[x] then
            for y = 1, self.map.height do
                if self.visibilityMap[x][y] and self.visibilityMap[x][y].ambientOcclusion and self.visibilityMap[x][y].ambientOcclusion > 0 then
                    hasOcclusion = true
                    break
                end
            end
            if hasOcclusion then break end
        end
    end
    
    if not hasOcclusion then
        print("WARNING: No occlusion values were set after shadow casting!")
    end
    
    -- Debug output of the visibility map
    print("Visibility map for observer at (" .. player.gridX .. "," .. player.gridY .. "):")
    for y = 1, self.map.height do
        local row = ""
        for x = 1, self.map.width do
            if self.visibilityMap[x] and self.visibilityMap[x][y] then
                local occlusion = self.visibilityMap[x][y].ambientOcclusion or 0
                row = row .. occlusion .. " "
            else
                row = row .. "? "
            end
        end
        print(row)
    end
    
    -- Update visible entities for each entity with sight
    for _, observer in ipairs(self.map.entities or {}) do
        if observer.hasSight then
            observer.visibleEntities = {}
            
            for _, target in ipairs(self.map.entities or {}) do
                if target ~= observer then
                    -- For the player, we use standard LoS to avoid movement issues
                    if observer.isPlayerControlled then
                        -- For player, use standard LoS (non-probabilistic)
                        if self:calculateObstructionFactor(observer.gridX, observer.gridY, target.gridX, target.gridY, observer.height or 1) > 0 then
                            table.insert(observer.visibleEntities, target)
                        end
                    else
                        -- For NPCs, consider ambient occlusion with probabilistic detection
                        local level = self:getVisibilityLevel(target.gridX, target.gridY)
                        local missChance = level > 0 and self.constants.AMBIENT_OCCLUSION_MISS_CHANCE[level] or 0
                        
                        -- Calculate standard LoS
                        local factor = self:calculateObstructionFactor(observer.gridX, observer.gridY, target.gridX, target.gridY, observer.height or 1)
                        
                        -- Only consider detection if there's a line of sight
                        if factor > 0 then
                            -- Roll for detection based on ambient occlusion
                            if math.random() > missChance then
                                table.insert(observer.visibleEntities, target)
                            end
                        end
                    end
                end
            end
        end
    end
    
    print("Sight update complete!")
end

-- Calculate visibility map method is now directly integrated into updateAllSight
-- for better efficiency and to avoid redundant calculations

-- Apply ambient occlusion to tiles behind walls using shadow casting
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
    
    -- For each wall, cast shadows to create occlusion
    for _, wall in ipairs(walls) do
        -- Vector from observer to wall
        local dx = wall.x - obsX
        local dy = wall.y - obsY
        
        -- Skip walls at observer position
        if dx ~= 0 or dy ~= 0 then
            -- Calculate the shadow region behind the wall
            self:castShadow(obsX, obsY, wall.x, wall.y)
        end
    end
end

-- Cast a shadow from a wall to create ambient occlusion using Bresenham's algorithm
function SightManager:castShadow(obsX, obsY, wallX, wallY)
    if not self.map then 
        print("ERROR: No map in castShadow")
        return 
    end
    
    local mapWidth = self.map.width
    local mapHeight = self.map.height
    
    -- Skip if wall is too far from observer (optimization)
    local distToWall = math.sqrt((wallX - obsX)^2 + (wallY - obsY)^2)
    if distToWall > 10 then
        return
    end
    
    -- Calculate direction vector from observer to wall
    local dirX = wallX - obsX
    local dirY = wallY - obsY
    
    -- Calculate the shadow projection point (extend beyond the wall)
    local maxShadowLength = 5 -- Reduced shadow length for more precise control
    local shadowEndX = wallX + math.floor((dirX / distToWall) * maxShadowLength + 0.5)
    local shadowEndY = wallY + math.floor((dirY / distToWall) * maxShadowLength + 0.5)
    
    -- Ensure shadow end point is within map bounds
    shadowEndX = math.max(1, math.min(mapWidth, shadowEndX))
    shadowEndY = math.max(1, math.min(mapHeight, shadowEndY))
    
    -- Use Bresenham's algorithm to get all points along the shadow line
    local shadowPoints = self:getLinePoints(wallX, wallY, shadowEndX, shadowEndY)
    
    -- Maximum occlusion level
    local maxLevel = 3
    
    -- Set occlusion for each point along the shadow line
    for i, point in ipairs(shadowPoints) do
        -- Skip the wall itself (first point)
        if i > 1 then
            local x, y = point.x, point.y
            
            -- Calculate distance from wall (i-1 because we skip the first point)
            local distFromWall = i - 1
            
            -- Simplified occlusion level calculation: decreases by 1 for each tile away
            local level = maxLevel - (distFromWall - 1)
            
            -- Stop if we've reached zero occlusion
            if level <= 0 then break end
            
            -- Set occlusion at this point
            self:setOcclusion(x, y, level)
        end
    end
    
    -- For each wall, also check diagonal sight lines to allow peeking around corners
    -- These are the 8 possible directions to check from the wall
    local directions = {
        {1, 0}, {1, 1}, {0, 1}, {-1, 1}, 
        {-1, 0}, {-1, -1}, {0, -1}, {1, -1}
    }
    
    -- Direction from observer to wall
    local mainDirX = math.sign(dirX)
    local mainDirY = math.sign(dirY)
    
    for _, dir in ipairs(directions) do
        -- Skip the direction that points back toward the observer
        if not (dir[1] == -mainDirX and dir[2] == -mainDirY) then
            -- Check up to 3 tiles in this direction
            for dist = 1, 3 do
                local checkX = wallX + dir[1] * dist
                local checkY = wallY + dir[2] * dist
                
                -- Ensure we're within map bounds
                if checkX >= 1 and checkX <= mapWidth and checkY >= 1 and checkY <= mapHeight then
                    -- Calculate occlusion level based on distance
                    local level = maxLevel - dist
                    
                    -- Only set occlusion if level is positive
                    if level > 0 then
                        self:setOcclusion(checkX, checkY, level)
                    end
                end
            end
        end
    end
end

-- Helper function to set occlusion level in the visibility map
function SightManager:setOcclusion(x, y, level)
    -- Ensure the visibility map is properly initialized
    if not self.visibilityMap[x] then
        self.visibilityMap[x] = {}
    end
    
    -- Initialize the position if needed
    if not self.visibilityMap[x][y] then
        self.visibilityMap[x][y] = {}
    end
    
    -- Store occlusion level in the ambientOcclusion field
    if not self.visibilityMap[x][y].ambientOcclusion or self.visibilityMap[x][y].ambientOcclusion < level then
        self.visibilityMap[x][y].ambientOcclusion = level
        print("Set occlusion level " .. level .. " at (" .. x .. "," .. y .. ")")
    end
end

-- Legacy method kept for compatibility
function SightManager:applyAmbientOcclusion(obsX, obsY, x, y)
    -- This is now handled by applyAllAmbientOcclusion
    return
end

-- Draw ambient occlusion overlay
function SightManager:drawAmbientOcclusion(forceDebug)
    if not self.map or not self.map.grid then
        print("⚠️ Cannot draw ambient occlusion: no map or grid")
        return
    end
    
    -- Set default colors if they haven't been set
    if not self.constants.AMBIENT_OCCLUSION_COLORS then
        self.constants.AMBIENT_OCCLUSION_COLORS = {
            {0, 0, 0, 0.2},  -- Level 1: Light occlusion
            {0, 0, 0, 0.5},  -- Level 2: Medium occlusion
            {0, 0, 0, 0.7}   -- Level 3: Heavy occlusion
        }
    end
    
    -- Draw ambient occlusion overlays
    for x = 1, self.map.width do
        for y = 1, self.map.height do
            -- Get occlusion level from visibility map, defaulting to 0 if not found
            local occlusionLevel = 0
            
            -- Check if this position has occlusion data
            if self.visibilityMap[x] and self.visibilityMap[x][y] and self.visibilityMap[x][y].ambientOcclusion then
                occlusionLevel = self.visibilityMap[x][y].ambientOcclusion
            end
            
            -- Convert to world coordinates
            local worldX, worldY = self.map.grid:gridToWorld(x, y)
            local tileSize = self.map.grid.tileSize
            
            -- Use a small padding for visual cleanliness
            local padding = 1
            
            -- Always draw in debug mode, otherwise only for levels > 0
            if occlusionLevel > 0 or forceDebug then
                -- Select color based on occlusion level
                local color = {0, 0, 0, 0.1} -- Default minimal occlusion
                if occlusionLevel > 0 and occlusionLevel <= #self.constants.AMBIENT_OCCLUSION_COLORS then
                    color = self.constants.AMBIENT_OCCLUSION_COLORS[occlusionLevel]
                end
                
                -- Draw the overlay
                love.graphics.setColor(unpack(color))
                love.graphics.rectangle("fill", worldX + padding, worldY + padding, tileSize - padding * 2, tileSize - padding * 2)
                
                -- In debug mode, display the occlusion level as text
                if forceDebug then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(occlusionLevel, worldX + tileSize / 2 - 5, worldY + tileSize / 2 - 8)
                end
            end
        end
    end
end

-- Get ambient occlusion level for a specific tile
function SightManager:getAmbientOcclusionLevel(x, y)
    if not self.visibilityMap or not self.visibilityMap[x] or not self.visibilityMap[x][y] then
        return 0 -- Default to NO occlusion
    end
    
    return self.visibilityMap[x][y].ambientOcclusion or 0 -- Default to NO occlusion if not explicitly set
end

-- Legacy method kept for compatibility
function SightManager:getVisibilityLevel(x, y)
    return self:getAmbientOcclusionLevel(x, y)
end

-- Draw debug visualization
function SightManager:drawDebug()
    -- Draw a bright red outline around the entire map to confirm rendering is working
    if self.map then
        local tileSize = self.map.grid and self.map.grid.tileSize or 32
        local mapWidth = self.map.width * tileSize
        local mapHeight = self.map.height * tileSize
        
        love.graphics.setColor(1, 0, 0, 1) -- Bright red
        love.graphics.rectangle("line", 0, 0, mapWidth, mapHeight)
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Print debug message on screen
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("DEBUG: SightManager is drawing!", 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
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
    local forceDebug = true -- Force debug mode to visualize all occlusion levels
    
    print("🌓 Drawing ambient occlusion overlays")
    
    -- Only proceed if we have a valid map
    if not self.map then
        print("⚠️ Cannot draw ambient occlusion - missing map")
        return
    end
    
    -- Define occlusion colors if not already defined
    if not self.constants then
        self.constants = {}
    end
    
    if not self.constants.AMBIENT_OCCLUSION_COLORS then
        self.constants.AMBIENT_OCCLUSION_COLORS = {
            {0, 0, 0, 0.3},  -- Level 1: Light occlusion
            {0, 0, 0, 0.5},  -- Level 2: Medium occlusion
            {0, 0, 0, 0.7}   -- Level 3: Heavy occlusion
        }
    end
    
    -- Initialize visibility map if it doesn't exist
    if not self.visibilityMap then
        print("⚠️ Visibility map missing, creating it now")
        self.visibilityMap = {}
    end
    
    -- We'll use the existing visibility map created by updateAllSight
    -- Only check if we have valid data, don't force test values anymore
    
        -- Find player entity to determine position-based occlusion
    local player = nil
    
    -- First check if there's a player reference in the map
    if self.map.game and self.map.game.player then
        player = self.map.game.player
    else
        -- Fallback to searching entities
        for _, entity in ipairs(self.map.entities or {}) do
            if entity.isPlayerControlled then
                player = entity
                break
            end
        end
    end
    
    if player then
        -- Only print this once to reduce spam
        if not self.lastPlayerPos or self.lastPlayerPos.x ~= player.gridX or self.lastPlayerPos.y ~= player.gridY then
            print("Player position for occlusion: (" .. player.gridX .. "," .. player.gridY .. ")")
            self.lastPlayerPos = {x = player.gridX, y = player.gridY}
        end
    else
        if not self.playerNotFoundWarningShown then
            print("⚠️ No player found for occlusion calculation")
            self.playerNotFoundWarningShown = true
        end
    end
    
    -- Update wall cache if needed
    if self.wallCacheNeedsUpdate or not self.wallCache then
        self:updateWallCache()
    end
    
    -- Only check for occlusion values once at startup, not every frame
    if not self.hasCheckedOcclusion then
        local hasOcclusion = false
        for x = 1, self.map.width do
            if self.visibilityMap[x] then
                for y = 1, self.map.height do
                    if self.visibilityMap[x] and self.visibilityMap[x][y] and self.visibilityMap[x][y].ambientOcclusion and self.visibilityMap[x][y].ambientOcclusion > 0 then
                        print("Found occlusion level " .. self.visibilityMap[x][y].ambientOcclusion .. " at (" .. x .. "," .. y .. ")")
                        hasOcclusion = true
                    end
                end
            end
        end
        
        if not hasOcclusion then
            print("⚠️ No occlusion values found in visibility map!")
        end
        self.hasCheckedOcclusion = true
    end
    
    -- Draw ambient occlusion directly here instead of calling the method again
    -- (This prevents the recursive call that was causing stack overflow)
    for x = 1, self.map.width do
        for y = 1, self.map.height do
            -- Get occlusion level from visibility map, defaulting to 0 if not found
            local occlusionLevel = 0
            
            -- Check if this position has occlusion data
            if self.visibilityMap[x] and self.visibilityMap[x][y] and self.visibilityMap[x][y].ambientOcclusion then
                occlusionLevel = self.visibilityMap[x][y].ambientOcclusion
            end
            
            -- Convert to world coordinates
            local worldX, worldY = self.map.grid:gridToWorld(x, y)
            local tileSize = self.map.grid.tileSize
            
            -- Use a small padding for visual cleanliness
            local padding = 1
            
            -- Always draw in debug mode, otherwise only for levels > 0
            if occlusionLevel > 0 or forceDebug then
                -- Select color based on occlusion level
                local color = {0, 0, 0, 0.1} -- Default minimal occlusion
                if occlusionLevel > 0 and occlusionLevel <= #self.constants.AMBIENT_OCCLUSION_COLORS then
                    color = self.constants.AMBIENT_OCCLUSION_COLORS[occlusionLevel]
                end
                
                -- Draw the overlay
                love.graphics.setColor(unpack(color))
                love.graphics.rectangle("fill", worldX + padding, worldY + padding, tileSize - padding * 2, tileSize - padding * 2)
                
                -- In debug mode, display the occlusion level as text
                if forceDebug then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(occlusionLevel, worldX + tileSize / 2 - 5, worldY + tileSize / 2 - 8)
                end
            end
        end
    end
    
    -- Draw player position for reference
    local player = nil
    for _, entity in ipairs(self.map.entities or {}) do
        if entity.isPlayerControlled then
            player = entity
            break
        end
    end
    
    if player then
        local worldX, worldY = self.map.grid:gridToWorld(player.gridX, player.gridY)
        local tileSize = self.map.grid.tileSize
        
        love.graphics.setColor(0, 1, 0, 1) -- Bright green
        love.graphics.rectangle("line", worldX, worldY, tileSize, tileSize)
        love.graphics.print("P", worldX + tileSize / 2 - 5, worldY + tileSize / 2 - 8)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return SightManager
