-- Editor Mode
-- Handles launching the map editor as a separate entity

local MapEditor = require("src.editor.mapEditor")

local EditorMode = {}
EditorMode.__index = EditorMode

function EditorMode:new(game)
    local self = setmetatable({}, EditorMode)
    
    self.game = game
    self.editor = nil  -- Will be created when launched
    self.isEditorActive = false
    self.separateWindow = true  -- Flag to indicate separate window mode
    
    return self
end

function EditorMode:launchEditor()
    if self.isEditorActive then return end
    
    -- Create a new editor instance
    self.editor = MapEditor:new()
    self.editor:initialize()
    self.isEditorActive = true
    
    if self.separateWindow then
        -- Create a separate window for the editor
        local width, height = 1024, 768  -- Default editor window size
        love.window.setMode(width, height, {
            fullscreen = false,
            resizable = true,
            x = nil,  -- Center on screen
            y = nil,
            minwidth = 800,
            minheight = 600,
            borderless = false
        })
        
        -- Set the window title separately
        love.window.setTitle("Map Editor - Tactics Explorer")
        
        -- Set editor background color to distinguish from main game
        self.editor.backgroundColor = {0.15, 0.15, 0.2, 1}  -- Darker blue-gray
        
        -- Set the game state to editor
        self.game.state = "editor"
    end
end

function EditorMode:closeEditor()
    if not self.isEditorActive then return end
    
    self.isEditorActive = false
    self.editor = nil
    
    -- Return to the main game window
    if self.separateWindow then
        -- Restore the main game window
        love.window.setMode(self.game.width, self.game.height, {
            fullscreen = false,
            resizable = true,
            x = nil,  -- Center on screen
            y = nil,
            minwidth = 800,
            minheight = 600,
            borderless = false
        })
        
        -- Set the window title separately
        love.window.setTitle("Tactics Explorer")
    end
    
    -- Resume the game
    self.game.state = "playing"
end

function EditorMode:update(dt)
    if self.isEditorActive and self.editor then
        self.editor:update(dt)
    end
end

function EditorMode:draw()
    if self.isEditorActive and self.editor then
        -- Clear the screen with the editor background color
        if self.separateWindow and self.editor.backgroundColor then
            love.graphics.clear(self.editor.backgroundColor)
        end
        self.editor:draw()
    end
end

function EditorMode:keypressed(key)
    if key == "f2" then
        -- F2 toggles editor mode
        if self.isEditorActive then
            self:closeEditor()
        else
            self:launchEditor()
        end
    elseif self.isEditorActive and self.editor then
        if key == "escape" then
            -- Escape key closes the editor
            self:closeEditor()
        else
            self.editor:keypressed(key)
        end
    end
end

function EditorMode:textinput(text)
    if self.isEditorActive and self.editor then
        self.editor:textinput(text)
    end
end

function EditorMode:mousepressed(x, y, button)
    if self.isEditorActive and self.editor then
        self.editor:mousepressed(x, y, button)
    end
end

function EditorMode:mousereleased(x, y, button)
    if self.isEditorActive and self.editor then
        self.editor:mousereleased(x, y, button)
    end
end

function EditorMode:applyMapToGame()
    if not self.isEditorActive or not self.editor then return end
    
    -- Save the current map
    self.editor:saveMap()
    
    -- Get the map name
    local mapName = self.editor.mapName
    
    -- Close the editor
    self:closeEditor()
    
    -- Load the map in the main game
    self.game:loadMap(mapName)
    
    -- Update the camera
    self.game.camera:setTarget(self.game.player)
    
    -- Move the player to a valid position
    local validX, validY = self:findValidPlayerPosition()
    self.game.player.gridX = validX
    self.game.player.gridY = validY
    self.game.player.x, self.game.player.y = self.game.grid:gridToWorld(validX, validY)
end

function EditorMode:findValidPlayerPosition()
    -- Find a walkable tile for the player
    for y = 2, self.game.currentMap.height - 1 do
        for x = 2, self.game.currentMap.width - 1 do
            if self.game.grid:isWalkable(x, y) then
                return x, y
            end
        end
    end
    
    -- Default to center if no walkable tile found
    return math.floor(self.game.currentMap.width / 2), math.floor(self.game.currentMap.height / 2)
end

return EditorMode
