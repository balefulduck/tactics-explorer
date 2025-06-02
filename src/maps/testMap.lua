-- Simple Test Map with sight system and ambient occlusion

local Map = require("src.core.map")
local Player = require("src.entities.player")
local MapSightExtension = require("src.systems.sight.mapSightExtension")
local EntitySightExtension = require("src.systems.sight.entitySightExtension")
local SightManager = require("src.systems.sight.sightManager")
local Timer = require("src.utils.timer") -- For smooth transitions

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
    
    -- Store the player reference in the map for easy access
    map.player = player
    player.map = map
    
    -- Create a timer for sight transitions
    map.transitionTimer = Timer:new()
    map.transitionProgress = 0
    map.isTransitioning = false
    map.transitionDuration = 0.2 -- Match with player movement speed
    map.oldVisibilityMap = nil
    map.newVisibilityMap = nil
    
    -- Add movement callbacks to handle sight transitions
    function map:onEntityMovementStart(entity, targetX, targetY)
        if entity.isPlayerControlled and self.sightManager then
            print("⭐ Movement start detected: Player moving to " .. targetX .. "," .. targetY)
            
            -- Store the current visibility map for transition
            self.oldVisibilityMap = self:cloneVisibilityMap(self.sightManager.visibilityMap)
            if not self.oldVisibilityMap then
                print("⚠️ Failed to clone old visibility map!")
            else
                print("✅ Old visibility map cloned successfully")
            end
            
            -- Update player's logical position temporarily to calculate new sight
            local oldX, oldY = entity.gridX, entity.gridY
            entity.gridX, entity.gridY = targetX, targetY
            
            -- Calculate new visibility without showing it yet
            self.sightManager:updateAllSight()
            self.newVisibilityMap = self:cloneVisibilityMap(self.sightManager.visibilityMap)
            
            -- Restore player's logical position (will be updated by movement animation)
            entity.gridX, entity.gridY = oldX, oldY
            
            if not self.newVisibilityMap then
                print("⚠️ Failed to clone new visibility map!")
            else
                print("✅ New visibility map cloned successfully")
            end
            
            -- Start transition
            self.isTransitioning = true
            self.transitionProgress = 0
            self.transitionTimer:reset()
            print("✅ Transition started")
        end
    end
    
    function map:onEntityMovementComplete(entity)
        if entity.isPlayerControlled and self.sightManager then
            -- Finalize the transition
            self.isTransitioning = false
            self.sightManager.visibilityMap = self.newVisibilityMap
            self.oldVisibilityMap = nil
            self.newVisibilityMap = nil
        end
    end
    
    -- Helper function to clone visibility map
    function map:cloneVisibilityMap(visMap)
        if not visMap then return nil end
        
        local clone = {}
        for x, row in pairs(visMap) do
            clone[x] = {}
            for y, cell in pairs(row) do
                clone[x][y] = {}
                for k, v in pairs(cell) do
                    clone[x][y][k] = v
                end
            end
        end
        return clone
    end
    
    -- Override the map's update function
    local originalUpdate = map.update
    map.update = function(self, dt)
        if originalUpdate then
            originalUpdate(self, dt)
        end
        
        -- Update transition timer if transitioning
        if self.isTransitioning then
            self.transitionTimer:update(dt)
            self.transitionProgress = math.min(1, self.transitionTimer:getTime() / self.transitionDuration)
            
            -- If transition complete, finalize it
            if self.transitionProgress >= 1 and self.player and not self.player.isMoving then
                print("Transition complete, visibility map updated")
                self.isTransitioning = false
                self.sightManager.visibilityMap = self.newVisibilityMap
                self.oldVisibilityMap = nil
                self.newVisibilityMap = nil
            end
        end
    end
    
    -- Function to draw transitioning occlusion between old and new visibility maps
    function map:drawTransitionOcclusion()
        if not self.oldVisibilityMap or not self.newVisibilityMap then
            return
        end
        
        -- Use easing function for smoother transition
        local progress = self:easeInOutQuad(self.transitionProgress)
        
        -- Get ambient occlusion colors from sight manager
        local colors = self.sightManager.constants.AMBIENT_OCCLUSION_COLORS
        if not colors then
            colors = {
                {0, 0, 0, 0.2},  -- Level 1: Light occlusion
                {0, 0, 0, 0.5},  -- Level 2: Medium occlusion
                {0, 0, 0, 0.7}   -- Level 3: Heavy occlusion
            }
        end
        
        -- Draw interpolated ambient occlusion for each tile
        for x = 1, self.width do
            for y = 1, self.height do
                -- Get old and new occlusion levels and visibility states
                local oldLevel = 0
                local newLevel = 0
                local oldVisible = false
                local newVisible = false
                
                if self.oldVisibilityMap[x] and self.oldVisibilityMap[x][y] then
                    if self.oldVisibilityMap[x][y].ambientOcclusion then
                        oldLevel = self.oldVisibilityMap[x][y].ambientOcclusion
                    end
                    if self.oldVisibilityMap[x][y].isVisible then
                        oldVisible = self.oldVisibilityMap[x][y].isVisible
                    end
                end
                
                if self.newVisibilityMap[x] and self.newVisibilityMap[x][y] then
                    if self.newVisibilityMap[x][y].ambientOcclusion then
                        newLevel = self.newVisibilityMap[x][y].ambientOcclusion
                    end
                    if self.newVisibilityMap[x][y].isVisible then
                        newVisible = self.newVisibilityMap[x][y].isVisible
                    end
                end
                
                -- Convert to world coordinates
                local worldX, worldY = self.grid:gridToWorld(x, y)
                local tileSize = self.grid.tileSize
                local padding = 1
                
                -- Get colors for interpolation based on occlusion level
                local oldColor = {0, 0, 0, 0}
                local newColor = {0, 0, 0, 0}
                
                if oldLevel > 0 and oldLevel <= #colors then
                    oldColor = colors[oldLevel]
                end
                
                if newLevel > 0 and newLevel <= #colors then
                    newColor = colors[newLevel]
                end
                
                -- Special case: handle visibility changes (appearing/disappearing tiles)
                if oldVisible ~= newVisible then
                    -- If becoming visible, fade in from black
                    if newVisible and not oldVisible then
                        oldColor = {0, 0, 0, 0.9} -- Start with near-black
                    end
                    -- If becoming invisible, fade to black
                    if oldVisible and not newVisible then
                        newColor = {0, 0, 0, 0.9} -- End with near-black
                    end
                end
                
                -- Always draw during transitions to ensure smooth fades
                -- Interpolate between colors
                local r = oldColor[1] + (newColor[1] - oldColor[1]) * progress
                local g = oldColor[2] + (newColor[2] - oldColor[2]) * progress
                local b = oldColor[3] + (newColor[3] - oldColor[3]) * progress
                local a = oldColor[4] + (newColor[4] - oldColor[4]) * progress
                
                -- Only draw if there's some opacity
                if a > 0.01 then
                    -- Draw the overlay
                    love.graphics.setColor(r, g, b, a)
                    love.graphics.rectangle("fill", worldX + padding, worldY + padding, tileSize - padding * 2, tileSize - padding * 2)
                end
            end
        end
        
        -- Small debug indicator in corner
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.rectangle("fill", 5, 5, 5, 5)
    end
    
    -- Easing function for smooth transitions
    function map:easeInOutQuad(t)
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
    end
    
    -- Override the map's draw function to add ambient occlusion with transition effect
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
            -- IMPORTANT: Force transition to be active when player is moving
            if self.player and self.player.isMoving then
                -- Make sure we have visibility maps for transition
                if not self.isTransitioning or not self.oldVisibilityMap or not self.newVisibilityMap then
                    -- If we don't have transition data, create it now
                    local oldX, oldY = self.player.gridX, self.player.gridY
                    
                    -- Get current visibility as old map
                    self.oldVisibilityMap = self:cloneVisibilityMap(self.sightManager.visibilityMap)
                    
                    -- Calculate visibility at target position for new map
                    self.player.gridX, self.player.gridY = self.player.targetGridX, self.player.targetGridY
                    self.sightManager:updateAllSight()
                    self.newVisibilityMap = self:cloneVisibilityMap(self.sightManager.visibilityMap)
                    
                    -- Restore player position
                    self.player.gridX, self.player.gridY = oldX, oldY
                    self.sightManager:updateAllSight() -- Update sight for current position
                    
                    -- Start transition
                    self.isTransitioning = true
                    self.transitionProgress = self.player.movementProgress or 0
                else
                    -- Update transition progress to match player movement
                    self.transitionProgress = self.player.movementProgress or 0
                end
            end
            
            -- Draw ambient occlusion overlay
            if self.isTransitioning and self.oldVisibilityMap and self.newVisibilityMap then
                self:drawTransitionOcclusion()
            else
                -- Draw regular ambient occlusion overlay
                self.sightManager:drawAmbientOcclusion()
            end
            
            -- Draw debug text
            love.graphics.setColor(1, 0, 0, 1) -- Red
            love.graphics.print("Ambient Occlusion Test Map", 10, 10)
            love.graphics.print("Player: (" .. self.player.gridX .. "," .. self.player.gridY .. ")", 10, 30)
            
            -- Debug transition state
            if self.isTransitioning then
                love.graphics.setColor(0, 1, 0, 1) -- Green
                love.graphics.print("Transition: " .. string.format("%.2f", self.transitionProgress), 10, 50)
                love.graphics.print("Moving: " .. tostring(self.player.isMoving), 10, 70)
                
                -- Debug visibility maps
                local hasOld = self.oldVisibilityMap ~= nil
                local hasNew = self.newVisibilityMap ~= nil
                love.graphics.print("Old Map: " .. tostring(hasOld), 10, 90)
                love.graphics.print("New Map: " .. tostring(hasNew), 10, 110)
            else
                love.graphics.setColor(1, 1, 0, 1) -- Yellow
                love.graphics.print("No Transition Active", 10, 50)
            end
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0, 0, 1) -- Red
            love.graphics.print("ERROR: No SightManager!", 10, 10)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    -- Draw transitioning occlusion
    function map:drawTransitionOcclusion()
        local tileSize = self.grid.tileSize
        local padding = 1
        local progress = self:easeInOutQuad(self.transitionProgress) -- Smooth easing
        
        for x = 1, self.width do
            for y = 1, self.height do
                -- Get old and new occlusion levels
                local oldLevel = 0
                local newLevel = 0
                
                if self.oldVisibilityMap[x] and self.oldVisibilityMap[x][y] and self.oldVisibilityMap[x][y].ambientOcclusion then
                    oldLevel = self.oldVisibilityMap[x][y].ambientOcclusion
                end
                
                if self.newVisibilityMap[x] and self.newVisibilityMap[x][y] and self.newVisibilityMap[x][y].ambientOcclusion then
                    newLevel = self.newVisibilityMap[x][y].ambientOcclusion
                end
                
                -- If levels are different, apply transition
                if oldLevel ~= newLevel then
                    -- Convert to world coordinates
                    local worldX, worldY = self.grid:gridToWorld(x, y)
                    
                    -- Interpolate between old and new colors
                    local oldColor = self.sightManager.constants.AMBIENT_OCCLUSION_COLORS[oldLevel] or {0,0,0,0}
                    local newColor = self.sightManager.constants.AMBIENT_OCCLUSION_COLORS[newLevel] or {0,0,0,0}
                    
                    -- If either color is nil, use transparent black
                    if not oldColor then oldColor = {0,0,0,0} end
                    if not newColor then newColor = {0,0,0,0} end
                    
                    -- Interpolate colors
                    local r = oldColor[1] + (newColor[1] - oldColor[1]) * progress
                    local g = oldColor[2] + (newColor[2] - oldColor[2]) * progress
                    local b = oldColor[3] + (newColor[3] - oldColor[3]) * progress
                    local a = oldColor[4] + (newColor[4] - oldColor[4]) * progress
                    
                    -- Draw the transitioning overlay
                    love.graphics.setColor(r, g, b, a)
                    love.graphics.rectangle("fill", worldX + padding, worldY + padding, tileSize - padding * 2, tileSize - padding * 2)
                else
                    -- If levels are the same, just draw the current level
                    local level = newLevel
                    if level > 0 then
                        local worldX, worldY = self.grid:gridToWorld(x, y)
                        local color = self.sightManager.constants.AMBIENT_OCCLUSION_COLORS[level] or {0,0,0,0}
                        love.graphics.setColor(unpack(color))
                        love.graphics.rectangle("fill", worldX + padding, worldY + padding, tileSize - padding * 2, tileSize - padding * 2)
                    end
                end
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Easing function for smoother transitions
    function map:easeInOutQuad(t)
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
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
