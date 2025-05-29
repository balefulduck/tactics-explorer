-- Editor Mode
-- Handles switching between game and editor modes

local MapEditor = require("src.editor.mapEditor")

local EditorMode = {}
EditorMode.__index = EditorMode

function EditorMode:new(game)
    local self = setmetatable({}, EditorMode)
    
    self.game = game
    self.editor = MapEditor:new()
    self.isEditorActive = false
    
    return self
end

function EditorMode:toggleEditor()
    self.isEditorActive = not self.isEditorActive
    
    if self.isEditorActive then
        -- Initialize the editor
        self.editor:initialize()
        
        -- Pause the game
        self.game.state = "editor"
    else
        -- Resume the game
        self.game.state = "playing"
    end
end

function EditorMode:update(dt)
    if self.isEditorActive then
        self.editor:update(dt)
    end
end

function EditorMode:draw()
    if self.isEditorActive then
        self.editor:draw()
    end
end

function EditorMode:keypressed(key)
    if key == "f2" then
        -- F2 toggles editor mode
        self:toggleEditor()
    elseif self.isEditorActive then
        self.editor:keypressed(key)
    end
end

function EditorMode:textinput(text)
    if self.isEditorActive then
        self.editor:textinput(text)
    end
end

function EditorMode:mousepressed(x, y, button)
    if self.isEditorActive then
        self.editor:mousepressed(x, y, button)
    end
end

function EditorMode:mousereleased(x, y, button)
    if self.isEditorActive then
        self.editor:mousereleased(x, y, button)
    end
end

function EditorMode:applyMapToGame()
    if not self.isEditorActive then return end
    
    -- Replace the current game map with the editor map
    self.game.currentMap = self.editor.map
    
    -- Update the grid reference
    self.game.grid = self.editor.grid
    
    -- Update the camera
    self.game.camera:setTarget(self.game.player)
    
    -- Move the player to a valid position
    local validX, validY = self:findValidPlayerPosition()
    self.game.player.gridX = validX
    self.game.player.gridY = validY
    self.game.player.x, self.game.player.y = self.game.grid:gridToWorld(validX, validY)
    
    -- Exit editor mode
    self:toggleEditor()
end

function EditorMode:findValidPlayerPosition()
    -- Find a walkable tile for the player
    for y = 2, self.editor.height - 1 do
        for x = 2, self.editor.width - 1 do
            if self.editor.grid:isWalkable(x, y) then
                return x, y
            end
        end
    end
    
    -- Default to center if no walkable tile found
    return math.floor(self.editor.width / 2), math.floor(self.editor.height / 2)
end

return EditorMode
