-- Simple Test Map with sight system and ambient occlusion

local Map = require("src.core.map")
local Player = require("src.entities.player")
local MapSightExtension = require("src.systems.sight.mapSightExtension")
local EntitySightExtension = require("src.systems.sight.entitySightExtension")

local TestMap = {}

function TestMap.create(game)
    -- Create a new map with dimensions 5x5
    local map = Map:new(game.grid, 5, 5)
    
    -- Fill the map with stone floor tiles
    for x = 1, map.width do
        for y = 1, map.height do
            map:setTile(x, y, "stoneFloor")
        end
    end
    
    -- Add a wall at position B3 (2,3)
    map:setTile(2, 3, "wall")
    
    -- Create a custom player entity with fixed movement handling
    local player = Player:new(map, 1, 1)
    
    -- Override the player's move method to properly update tile walkability
    local originalMove = player.move
    player.move = function(self, dx, dy)
        -- Store the old position
        local oldX, oldY = self.gridX, self.gridY
        
        -- Call the original move method
        local result = originalMove(self, dx, dy)
        
        -- If movement was successful, update tile walkability
        if result and self.isMoving then
            -- Reset the old tile to walkable
            local oldTile = map:getTile(oldX, oldY)
            if oldTile then
                oldTile.walkable = true
            end
            
            -- Mark the new tile as not walkable during movement
            local newTile = map:getTile(self.targetX, self.targetY)
            if newTile then
                newTile.walkable = false
            end
        end
        
        return result
    end
    
    -- Override the update method to fix tile walkability after movement completes
    local originalUpdate = player.update
    player.update = function(self, dt)
        local wasMoving = self.isMoving
        
        -- Call the original update method
        originalUpdate(self, dt)
        
        -- If movement just completed, ensure current tile is properly marked
        if wasMoving and not self.isMoving then
            -- Reset walkability based on actual entity positions
            for y = 1, map.height do
                for x = 1, map.width do
                    local tile = map:getTile(x, y)
                    if tile and tile.tileType ~= "wall" then
                        tile.walkable = true
                    end
                end
            end
            
            -- Mark tiles occupied by entities as not walkable
            for _, entity in ipairs(map.entities) do
                if not entity.walkable and entity.containsPosition then
                    local entityWidth = entity.gridWidth or entity.width or 1
                    local entityHeight = entity.gridHeight or entity.height or 1
                    
                    for y = entity.gridY, entity.gridY + entityHeight - 1 do
                        for x = entity.gridX, entity.gridX + entityWidth - 1 do
                            local tile = map:getTile(x, y)
                            if tile then
                                tile.walkable = false
                            end
                        end
                    end
                end
            end
        end
    end
    
    map:addEntity(player)
    game.player = player
    
    -- Add an NPC at position C3 (3,3) - using a modified player entity that's uncontrollable
    local npc = Player:new(map, 3, 3)
    npc.isPlayerControlled = false
    npc.name = "NPC"
    npc.color = {0.8, 0.2, 0.2, 1} -- Red color
    npc.borderColor = {0.6, 0.1, 0.1, 1}
    map:addEntity(npc)
    
    -- Apply sight extensions to map and entities
    MapSightExtension.extend(map)
    
    -- Set wall height to 2 (fully blocks sight)
    for y = 1, map.height do
        for x = 1, map.width do
            local tile = map:getTile(x, y)
            if tile and tile.tileType == "wall" then
                map:setTileHeight(x, y, 2) -- Height 2 fully blocks sight
                map:setTileObstruction(x, y, 1.0) -- Walls fully obstruct
            end
        end
    end
    
    -- Add sight capability to player
    EntitySightExtension.extend(player)
    player.hasSight = true
    player.height = 1.0 -- Player height (standard 1-tile height)
    player.perception = 1.0 -- Normal perception
    
    -- Add sight capability to NPC
    EntitySightExtension.extend(npc)
    npc.hasSight = true
    npc.height = 1.0 -- NPC height (standard 1-tile height)
    npc.perception = 1.0 -- Normal perception
    
    -- Create the sight system
    local sightManager = MapSightExtension.createSightSystem(map)
    sightManager.debug = true -- Enable debug output
    
    -- Update the map's update function
    local originalUpdate = map.update
    map.update = function(self, dt)
        if originalUpdate then
            originalUpdate(self, dt)
        end
        
        -- Update all entities
        for _, entity in ipairs(self.entities) do
            if entity.update then
                entity:update(dt)
            end
        end
        
        -- Update sight system
        if self.sightManager then
            self.sightManager:updateAllSight()
        end
    end
    
    -- Override the map's draw function
    local originalDraw = map.draw
    map.draw = function(self)
        if originalDraw then
            originalDraw(self)
        end
        
        -- Draw sight debug overlays
        if self.sightManager then
            self.sightManager:drawDebug()
        end
    end
    
    -- Initial sight update
    map:updateSight()
    
    print("Test map loaded successfully with sight system")
    return map
end

return TestMap
