-- Simple Test Map with sight system and ambient occlusion

local Map = require("src.core.map")
local Player = require("src.entities.player")
local MapSightExtension = require("src.systems.sight.mapSightExtension")
local EntitySightExtension = require("src.systems.sight.entitySightExtension")
local SightManager = require("src.systems.sight.sightManager")

local TestMap = {}

function TestMap.create(game)
    -- Create a new map with dimensions 5x5
    local map = Map:new(game.grid, 5, 5)
    
    -- Store the game reference in the map
    map.game = game
    
    -- Fill the map with stone floor tiles
    for x = 1, map.width do
        for y = 1, map.height do
            map:setTile(x, y, "stoneFloor")
        end
    end
    
    -- Add walls for testing ambient occlusion
    map:setTile(2, 3, "wall")
    print("⭐ Added wall at position (2,3)")
    
    -- Add more walls to create an interesting occlusion pattern
    map:setTile(3, 3, "wall")
    print("⭐ Added wall at position (3,3)")
    
    map:setTile(4, 3, "wall")
    print("⭐ Added wall at position (4,3)")
    
    -- Verify walls were added correctly
    for x = 2, 4 do
        local wallTile = map:getTile(x, 3)
        if wallTile and wallTile.tileType == "wall" then
            print("✅ Wall tile confirmed at (" .. x .. ",3)")
        else
            print("❌ ERROR: Wall tile not set correctly at (" .. x .. ",3)")
        end
    end
    
    -- Create a custom player entity with fixed movement handling
    local player = Player:new(map, 1, 1)
    
    map:addEntity(player)
    game.player = player
    print("⭐ Added player at (1,1)")
    
    -- Add an NPC at position C3 (3,3)
    local npc = Player:new(map, 3, 3)
    npc.isPlayerControlled = false
    npc.name = "NPC"
    npc.color = {0.8, 0.2, 0.2, 1} -- Red color
    npc.borderColor = {0.6, 0.1, 0.1, 1}
    map:addEntity(npc)
    print("⭐ Added NPC at (3,3)")
    
    -- Apply sight extensions to map
    print("⭐ Extending map with sight capabilities")
    MapSightExtension.extend(map)
    
    -- Set wall height to 2 (fully blocks sight)
    map:setTileHeight(2, 3, 2) -- Height 2 fully blocks sight
    map:setTileObstruction(2, 3, 1.0) -- Walls fully obstruct
    print("⭐ Set wall height to 2 and obstruction to 1.0")
    
    -- Add sight capability to player
    EntitySightExtension.extend(player)
    player.hasSight = true
    player.height = 1.0
    player.perception = 1.0
    print("⭐ Extended player with sight capabilities")
    
    -- Add sight capability to NPC
    EntitySightExtension.extend(npc)
    npc.hasSight = true
    npc.height = 1.0
    npc.perception = 1.0
    
    -- Create and attach the sight manager
    local sightManager = SightManager:new(map)
    sightManager.debug = true -- Enable debug output
    map.sightManager = sightManager
    print("⭐ Created and attached sight manager to map")
    
    -- Override player's move function to update sight after movement
    local originalMove = player.move
    player.move = function(self, dx, dy)
        local moved = originalMove(self, dx, dy)
        if moved and map.sightManager then
            -- Force a complete recalculation of ambient occlusion
            map.sightManager.visibilityMap = nil -- Reset visibility map to force full recalculation
            map.sightManager:updateAllSight()
        end
        return moved
    end
    
    -- Override the map's update function
    local originalUpdate = map.update
    map.update = function(self, dt)
        if originalUpdate then
            originalUpdate(self, dt)
        end
        
        -- Don't update sight every frame - that causes infinite loops
        -- Sight updates will happen on player movement instead
    end
    
    -- Override the map's draw function to add ambient occlusion
    local originalDraw = map.draw
    map.draw = function(self)
        -- Draw tiles and entities first
        if originalDraw then
            originalDraw(self)
        end
        
        -- Draw bright yellow test border
        love.graphics.setColor(1, 1, 0, 1) -- Yellow
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", 0, 0, self.width * self.grid.tileSize, self.height * self.grid.tileSize)
        love.graphics.setLineWidth(1)
        
        -- Draw occlusion overlays if sight manager is attached
        if self.sightManager then
            -- Draw ambient occlusion overlay
            self.sightManager:drawAmbientOcclusion()
            
            -- Draw debug text
            love.graphics.setColor(1, 0, 0, 1) -- Red
            love.graphics.print("Ambient Occlusion Test Map", 10, 10)
            love.graphics.print("Player: (" .. player.gridX .. "," .. player.gridY .. ")", 10, 30)
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0, 0, 1) -- Red
            love.graphics.print("ERROR: No SightManager!", 10, 10)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    -- Initialize sight
    sightManager:updateAllSight()
    print("⭐ Initial sight update complete")
    
    -- Force some test occlusion values directly
    print("⭐ Forcing test occlusion values for debugging")
    
    -- Initialize visibility map if it doesn't exist
    if not sightManager.visibilityMap then
        print("⭐ Creating visibility map")
        sightManager.visibilityMap = {}
    end
    
    -- Initialize the nested tables
    if not sightManager.visibilityMap[2] then sightManager.visibilityMap[2] = {} end
    if not sightManager.visibilityMap[3] then sightManager.visibilityMap[3] = {} end
    
    -- Set test occlusion values
    sightManager.visibilityMap[2][4] = { ambientOcclusion = 3, visible = true, explored = true } -- Full occlusion
    sightManager.visibilityMap[2][5] = { ambientOcclusion = 2, visible = true, explored = true } -- Medium occlusion
    sightManager.visibilityMap[3][4] = { ambientOcclusion = 1, visible = true, explored = true } -- Light occlusion
    
    return map
end

return TestMap
