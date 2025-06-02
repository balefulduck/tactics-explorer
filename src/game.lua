-- Game class - main game controller
local Grid = require("src.systems.grid")
local Player = require("src.entities.player")
local Couch = require("src.entities.couch")
-- TV entity removed
local CoffeeTable = require("src.entities.coffeeTable")
local Cupboard = require("src.entities.cupboard")
local Window = require("src.entities.window")
-- Plant entity removed
local MapManager = require("src.systems.mapManager")
local Camera = require("src.systems.camera")
local UI = require("src.systems.ui")

local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)
    
    -- Game settings
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    self.tileSize = 64  -- Size of each grid tile in pixels
    
    -- Game state
    self.state = "playing"  -- playing, paused, menu, etc.
    
    return self
end

function Game:load()
    -- Initialize systems
    self.grid = Grid:new(self.tileSize)
    self.camera = Camera:new(self.width, self.height)
    self.mapManager = MapManager:new(self.grid)
    self.ui = UI:new(self)
    
    -- Create a custom room map (8x7 grid to account for walls)
    self.currentMap = self.mapManager:createRoomMap(8, 7)
    
    -- Create player in the center of the room
    self.player = Player:new(self.grid, 3, 3)
    
    -- Create entities
    self.entities = {}
    
    -- Create furniture items
    
    -- Couch in the upper right corner
    local couchX = 5
    local couchY = 2
    local couch = Couch:new(self.grid, couchX, couchY)
    table.insert(self.entities, couch)
    
    -- TV opposite of the couch
    local tvX = 2
    local tvY = 2
    local tv = TV:new(self.grid, tvX, tvY)
    table.insert(self.entities, tv)
    
    -- Coffee table in front of the sofa
    local coffeeTableX = 5
    local coffeeTableY = 3
    local coffeeTable = CoffeeTable:new(self.grid, coffeeTableX, coffeeTableY)
    table.insert(self.entities, coffeeTable)
    
    -- Cupboard on the bottom (1x4 tile)
    local cupboardX = 2
    local cupboardY = 5
    local cupboard = Cupboard:new(self.grid, cupboardX, cupboardY)
    table.insert(self.entities, cupboard)
    
    -- Window in the southern wall near the center
    local windowX = 4
    local windowY = 6
    local window = Window:new(self.grid, windowX, windowY)
    table.insert(self.entities, window)
    
    -- Plants diagonally in front of the window
    local plant1X = 3
    local plant1Y = 5
    local plant1 = Plant:new(self.grid, plant1X, plant1Y)
    table.insert(self.entities, plant1)
    
    local plant2X = 5
    local plant2Y = 5
    local plant2 = Plant:new(self.grid, plant2X, plant2Y)
    table.insert(self.entities, plant2)
    
    -- Mark furniture positions as not walkable
    self:markEntityPositionsAsBlocked()
    
    -- Center camera on player
    self.camera:setTarget(self.player)
end

function Game:markEntityPositionsAsBlocked()
    -- Mark all entity positions as not walkable
    for _, entity in ipairs(self.entities) do
        if entity.containsPosition then
            -- For multi-tile entities
            if entity.gridX and entity.width then
                local tilesWide = entity.width / self.grid.tileSize
                local tilesHigh = entity.height / self.grid.tileSize
                
                for x = 0, tilesWide - 1 do
                    for y = 0, tilesHigh - 1 do
                        local tile = self.currentMap:getTile(entity.gridX + x, entity.gridY + y)
                        if tile then
                            tile.walkable = false
                        end
                    end
                end
            else
                -- For single-tile entities
                local tile = self.currentMap:getTile(entity.gridX, entity.gridY)
                if tile then
                    tile.walkable = false
                end
            end
        end
    end
end

function Game:update(dt)
    if self.state == "playing" then
        -- Get player's previous position before update
        local prevGridX, prevGridY = self.player.gridX, self.player.gridY
        
        -- Update player
        self.player:update(dt)
        
        -- Check if player has moved to a new tile
        if prevGridX ~= self.player.gridX or prevGridY ~= self.player.gridY then
            -- Player has moved to a new tile, trigger dust animation
            local newTile = self.currentMap:getTile(self.player.gridX, self.player.gridY)
            if newTile and newTile.type == "floor" then
                newTile:stepOn()
            end
        end
        
        -- Update all entities
        for _, entity in ipairs(self.entities) do
            entity:update(dt)
        end
        
        -- Update all tiles
        for y = 1, self.currentMap.height do
            for x = 1, self.currentMap.width do
                local tile = self.currentMap:getTile(x, y)
                if tile and tile.update then
                    tile:update(dt)
                end
            end
        end
        
        self.camera:update(dt)
    end
end

function Game:draw()
    -- Begin camera transformation
    self.camera:set()
    
    -- Draw the map
    self.currentMap:draw()
    
    -- Draw all entities
    for _, entity in ipairs(self.entities) do
        entity:draw()
    end
    
    -- Draw player (on top of other entities)
    self.player:draw()
    
    -- Draw grid (for debugging)
    if self.debug then
        self.grid:draw()
    end
    
    -- End camera transformation
    self.camera:unset()
    
    -- Draw UI elements (not affected by camera)
    self.ui:draw()
end

function Game:keypressed(key)
    if self.state == "playing" then
        -- Movement controls
        local dx, dy = 0, 0
        
        if key == "up" or key == "w" then
            dy = -1
        elseif key == "down" or key == "s" then
            dy = 1
        elseif key == "left" or key == "a" then
            dx = -1
        elseif key == "right" or key == "d" then
            dx = 1
        end
        
        if dx ~= 0 or dy ~= 0 then
            -- Check if the player can move to the new position
            local newX = self.player.gridX + dx
            local newY = self.player.gridY + dy
            
            -- Check if any entity is blocking the movement
            local blocked = false
            for _, entity in ipairs(self.entities) do
                if entity.containsPosition and entity:containsPosition(newX, newY) then
                    blocked = true
                    break
                end
            end
            
            -- Move the player if not blocked
            if not blocked then
                self.player:move(dx, dy)
            end
        end
        
        -- Toggle debug mode
        if key == "f1" then
            self.debug = not self.debug
        end
    end
end

function Game:keyreleased(key)
    -- Handle key releases if needed
end

function Game:mousepressed(x, y, button)
    -- Convert screen coordinates to world coordinates
    local worldX, worldY = self.camera:screenToWorld(x, y)
    
    -- Convert world coordinates to grid coordinates
    local gridX, gridY = self.grid:worldToGrid(worldX, worldY)
    
    -- Handle grid-based interactions
    if button == 1 then  -- Left click
        -- Example: Select a tile or move to it
        print("Grid clicked: " .. gridX .. ", " .. gridY)
    end
end

function Game:mousereleased(x, y, button)
    -- Handle mouse releases if needed
end

return Game
