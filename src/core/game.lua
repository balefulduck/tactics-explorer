-- Game class - main game controller
-- Redesigned to use the new entity-based system

local Grid = require("src.core.grid")
local Map = require("src.core.map")
local Player = require("src.core.player")
local Furniture = require("src.core.furniture")
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
    self.debug = false
    
    return self
end

function Game:load()
    -- Initialize systems
    self.grid = Grid:new(self.tileSize)
    self.camera = Camera:new(self.width, self.height)
    self.ui = UI:new(self)
    
    -- Create a room map (12x14 grid)
    self.currentMap = Map:new(self.grid, 12, 14)
    
    -- Define window positions (centered on east and south walls)
    local windowPositions = {
        {x = 12, y = 7},  -- East wall, centered
        {x = 6, y = 14}   -- South wall, centered
    }
    
    -- Create the room with windows
    self.currentMap:createRoomMap(windowPositions)
    
    -- Create player in the center of the room
    self.player = Player:new(self.grid, 6, 7)
    
    -- Add furniture to the room
    self:setupRoom()
    
    -- Center camera on player
    self.camera:setTarget(self.player)
end

function Game:setupRoom()
    -- Create furniture items based on the new 12x14 grid layout
    
    -- Couch in the top right corner
    local couch = Furniture.create("couch", self.grid, 9, 3)
    self.currentMap:addEntity(couch)
    
    -- TV opposite of the couch (across the room)
    local tv = Furniture.create("tv", self.grid, 3, 3)
    self.currentMap:addEntity(tv)
    
    -- Coffee table in front of the sofa
    local coffeeTable = Furniture.create("coffee_table", self.grid, 9, 5, {
        labelText = "coffee table"
    })
    self.currentMap:addEntity(coffeeTable)
    
    -- Cupboard vertically oriented on the left side / west wall
    local cupboard = Furniture.create("cupboard", self.grid, 2, 7, {
        orientation = "vertical" -- Assuming the furniture system supports this
    })
    self.currentMap:addEntity(cupboard)
    
    -- Plants for decoration
    local plant1 = Furniture.create("plant", self.grid, 4, 10)
    self.currentMap:addEntity(plant1)
    
    local plant2 = Furniture.create("plant", self.grid, 8, 10)
    self.currentMap:addEntity(plant2)
end

function Game:update(dt)
    if self.state == "playing" then
        -- Update player
        self.player:update(dt)
        
        -- Update map (which updates all entities and tiles)
        self.currentMap:update(dt)
        
        -- Update camera
        self.camera:update(dt)
        
        -- Update UI
        self.ui:update(dt)
    end
end

function Game:draw()
    -- Draw background pattern (not affected by camera)
    self:drawBackground()
    
    -- Begin camera transformation
    self.camera:set()
    
    -- Draw board frame
    self:drawBoardFrame()
    
    -- Draw the map (which draws all tiles and entities)
    self.currentMap:draw()
    
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

function Game:drawBackground()
    -- Draw a subtle background pattern
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Set background color
    love.graphics.setColor(0.12, 0.12, 0.14, 1) -- Dark gray with slight blue tint
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw subtle grid pattern
    love.graphics.setColor(0.15, 0.15, 0.17, 1) -- Slightly lighter than background
    love.graphics.setLineWidth(1)
    
    local gridSpacing = 40
    
    -- Draw vertical lines
    for x = 0, screenWidth, gridSpacing do
        love.graphics.line(x, 0, x, screenHeight)
    end
    
    -- Draw horizontal lines
    for y = 0, screenHeight, gridSpacing do
        love.graphics.line(0, y, screenWidth, y)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Game:drawBoardFrame()
    if not self.currentMap then return end
    
    local mapWidth = self.currentMap.width * self.grid.tileSize
    local mapHeight = self.currentMap.height * self.grid.tileSize
    
    -- Draw shadow under the board
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", -10, -10, mapWidth + 20, mapHeight + 20)
    
    -- Draw outer frame
    love.graphics.setColor(0.3, 0.3, 0.35, 1) -- Dark gray with slight blue tint
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", -5, -5, mapWidth + 10, mapHeight + 10)
    
    -- Draw inner frame highlight
    love.graphics.setColor(0.5, 0.5, 0.55, 1) -- Lighter gray
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", -2, -2, mapWidth + 4, mapHeight + 4)
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
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
            self.player:move(dx, dy)
        end
        
        -- Toggle debug mode
        if key == "f1" then
            self.debug = not self.debug
        end
        
        -- Interaction key
        if key == "e" or key == "space" then
            self:interact()
        end
        
        -- Info screen (shift key)
        if key == "lshift" or key == "rshift" then
            self:showEntityInfo()
        end
    end
end

function Game:interact()
    -- Get the tile in front of the player (based on facing direction)
    -- For now, just check all adjacent tiles
    local adjacentPositions = {
        {x = self.player.gridX + 1, y = self.player.gridY},
        {x = self.player.gridX - 1, y = self.player.gridY},
        {x = self.player.gridX, y = self.player.gridY + 1},
        {x = self.player.gridX, y = self.player.gridY - 1}
    }
    
    for _, pos in ipairs(adjacentPositions) do
        local entities = self.currentMap:getEntitiesAt(pos.x, pos.y)
        
        for _, entity in ipairs(entities) do
            if entity.interactable then
                local result = entity:interact()
                
                if result.success then
                    -- Show interaction result
                    self.ui:showMessage(result.message, 2)
                    return true
                end
            end
        end
    end
    
    return false
end

function Game:showEntityInfo()
    -- Get all adjacent entities
    local adjacentPositions = {
        {x = self.player.gridX + 1, y = self.player.gridY},
        {x = self.player.gridX - 1, y = self.player.gridY},
        {x = self.player.gridX, y = self.player.gridY + 1},
        {x = self.player.gridX, y = self.player.gridY - 1}
    }
    
    local adjacentEntities = {}
    
    for _, pos in ipairs(adjacentPositions) do
        local entities = self.currentMap:getEntitiesAt(pos.x, pos.y)
        for _, entity in ipairs(entities) do
            table.insert(adjacentEntities, entity)
        end
    end
    
    -- If there's exactly one entity, show its info screen
    if #adjacentEntities == 1 then
        self.ui:toggleInfoScreen(adjacentEntities[1])
        return true
    elseif #adjacentEntities > 1 then
        -- If there are multiple entities, show a message
        self.ui:showMessage("Multiple objects nearby. Move closer to a specific object.", 2)
        return false
    else
        -- If there are no entities, show a message
        self.ui:showMessage("No objects nearby to inspect.", 2)
        return false
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
