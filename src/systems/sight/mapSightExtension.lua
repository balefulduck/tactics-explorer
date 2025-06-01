-- Map Sight Extension
-- Extends map with properties needed for sight calculations

local MapSightExtension = {}

-- Add sight-related properties to a map
function MapSightExtension.extend(map)
    -- Initialize height and obstruction data
    map.tileHeights = {}
    map.tileObstructions = {}
    map.lightLevels = {}
    
    -- Set default height for all tiles
    for y = 1, map.height do
        map.tileHeights[y] = {}
        map.tileObstructions[y] = {}
        map.lightLevels[y] = {}
        
        for x = 1, map.width do
            -- Default values
            map.tileHeights[y][x] = 0  -- Floor level
            map.tileObstructions[y][x] = 0  -- No obstruction
            map.lightLevels[y][x] = 1  -- Fully lit
        end
    end
    
    -- Add method to get tile height
    if not map.getTileHeight then
        map.getTileHeight = function(self, x, y)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return 0
            end
            return self.tileHeights[y][x] or 0
        end
    end
    
    -- Add method to set tile height
    if not map.setTileHeight then
        map.setTileHeight = function(self, x, y, height)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return false
            end
            self.tileHeights[y][x] = height
            return true
        end
    end
    
    -- Add method to get tile obstruction factor
    if not map.getTileObstruction then
        map.getTileObstruction = function(self, x, y)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return 0
            end
            return self.tileObstructions[y][x] or 0
        end
    end
    
    -- Add method to set tile obstruction factor
    if not map.setTileObstruction then
        map.setTileObstruction = function(self, x, y, factor)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return false
            end
            self.tileObstructions[y][x] = factor
            return true
        end
    end
    
    -- Add method to get light level
    if not map.getLightLevel then
        map.getLightLevel = function(self, x, y)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return 1
            end
            return self.lightLevels[y][x] or 1
        end
    end
    
    -- Add method to set light level
    if not map.setLightLevel then
        map.setLightLevel = function(self, x, y, level)
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return false
            end
            self.lightLevels[y][x] = level
            return true
        end
    end
    
    -- Add method to get objects height at a position
    if not map.getObjectsHeight then
        map.getObjectsHeight = function(self, x, y)
            local maxHeight = 0
            
            -- Check all entities at this position
            for _, entity in ipairs(self.entities or {}) do
                if entity.gridX == x and entity.gridY == y and entity.height then
                    maxHeight = math.max(maxHeight, entity.height)
                end
            end
            
            return maxHeight
        end
    end
    
    -- Add method to initialize heights based on tile types
    if not map.initializeHeightsFromTiles then
        map.initializeHeightsFromTiles = function(self)
            MapSightExtension.initializeHeightsFromTiles(self)
        end
    end
    
    -- Initialize heights based on existing tile types
    map:initializeHeightsFromTiles()
    
    return map
end

-- Initialize heights based on tile types
function MapSightExtension.initializeHeightsFromTiles(map)
    if not map.tiles then return end
    
    for y = 1, map.height do
        for x = 1, map.width do
            local tile = map:getTile(x, y)
            if tile then
                -- Set heights based on tile type
                if tile.type == "wall" then
                    map:setTileHeight(x, y, 3)  -- Walls are tall
                    map:setTileObstruction(x, y, 1.0)  -- Walls fully obstruct
                    
                    -- Windows partially obstruct
                    if tile.isWindow then
                        map:setTileObstruction(x, y, 0.3)
                    end
                elseif tile.type == "door" then
                    map:setTileHeight(x, y, 3)  -- Doors are tall
                    map:setTileObstruction(x, y, 0.8)  -- Doors mostly obstruct
                    
                    -- Open doors don't obstruct
                    if tile.isOpen then
                        map:setTileObstruction(x, y, 0)
                    end
                elseif tile.type == "water" then
                    map:setTileHeight(x, y, 0.5)  -- Water is shallow
                    map:setTileObstruction(x, y, 0.2)  -- Water slightly obstructs
                end
            end
        end
    end
end

-- Add lighting to the map
function MapSightExtension.addLightSource(map, x, y, intensity, radius)
    intensity = intensity or 1.0
    radius = radius or 5
    
    -- Apply light in a radius
    for ly = math.max(1, y - radius), math.min(map.height, y + radius) do
        for lx = math.max(1, x - radius), math.min(map.width, x + radius) do
            -- Calculate distance
            local dx = lx - x
            local dy = ly - y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Apply light based on distance
            if distance <= radius then
                local lightFactor = intensity * (1 - distance / radius)
                local currentLight = map:getLightLevel(lx, ly)
                
                -- Light levels add up (capped at 1.0)
                map:setLightLevel(lx, ly, math.min(1.0, currentLight + lightFactor))
            end
        end
    end
end

-- Create a sight integration for the map
function MapSightExtension.createSightSystem(map)
    local SightManager = require("src.systems.sight.sightManager")
    
    -- Create the sight manager
    local sightManager = SightManager:new(map)
    
    -- Store it in the map
    map.sightManager = sightManager
    
    -- Add update method to map
    if not map.updateSight then
        map.updateSight = function(self)
            if self.sightManager then
                self.sightManager:updateAllSight()
            end
        end
    end
    
    -- Add draw method to map
    if not map.drawSightDebug then
        map.drawSightDebug = function(self)
            if self.sightManager then
                self.sightManager:drawDebug()
            end
        end
    end
    
    return sightManager
end

return MapSightExtension
