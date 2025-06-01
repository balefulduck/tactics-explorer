-- Tile Creator
-- A dedicated editor for creating new tile types

local Grid = require("src.core.grid")
local Tile = require("src.core.tile")

local TileCreator = {}
TileCreator.__index = TileCreator

function TileCreator:new()
    local self = setmetatable({}, TileCreator)
    
    -- State
    self.active = false
    self.tileSize = 64
    self.grid = nil
    self.previewGrid = nil
    
    -- Reference to editorTabs (will be set by MapEditor)
    
    -- New tile properties
    self.newTileType = {
        id = "custom_tile",
        name = "Custom Tile",
        color = {0.8, 0.8, 0.8},
        borderColor = {0.7, 0.7, 0.7},
        walkable = true,
        description = "A custom tile"
    }
    
    -- UI state
    self.backgroundColor = {0.93, 0.93, 0.93, 1} -- Light gray background (#eeeeee)
    self.panelWidth = love.graphics.getWidth() * 0.25
    self.panelX = 0
    self.panelY = 0
    
    -- Preview area
    self.previewX = self.panelWidth + 50
    self.previewY = 100
    self.previewSize = 128 -- Larger preview
    
    -- Color picker
    self.colorPickerActive = false
    self.colorPickerTarget = "color" -- "color" or "borderColor"
    self.colorPickerX = 0
    self.colorPickerY = 0
    self.colorPickerWidth = 200
    self.colorPickerHeight = 200
    
    -- Mouse state
    self.mouseX = 0
    self.mouseY = 0
    self.isDragging = false
    
    -- Fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 20)
    self.labelFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    self.buttonFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    
    -- Input fields
    self.activeField = nil
    self.fields = {
        id = {value = self.newTileType.id, x = 0, y = 0, width = 0, height = 0, label = "ID:"},
        name = {value = self.newTileType.name, x = 0, y = 0, width = 0, height = 0, label = "Name:"},
        description = {value = self.newTileType.description, x = 0, y = 0, width = 0, height = 0, label = "Description:"}
    }
    
    return self
end

function TileCreator:initialize()
    -- Create a grid for preview
    self.grid = Grid:new(self.tileSize)
    self.previewGrid = Grid:new(self.previewSize)
    
    -- Set as active
    self.active = true
    
    -- Reset new tile properties
    self.newTileType = {
        id = "custom_tile",
        name = "Custom Tile",
        color = {0.8, 0.8, 0.8},
        borderColor = {0.7, 0.7, 0.7},
        walkable = true,
        description = "A custom tile"
    }
    
    -- Update field values
    self.fields.id.value = self.newTileType.id
    self.fields.name.value = self.newTileType.name
    self.fields.description.value = self.newTileType.description
end

function TileCreator:update(dt)
    if not self.active then return end
    
    -- Update mouse position
    self.mouseX, self.mouseY = love.mouse.getPosition()
    
    -- Update panel position
    self.panelWidth = love.graphics.getWidth() * 0.25
    self.panelX = 0
    
    -- Update preview position
    self.previewX = self.panelWidth + 50
    self.previewY = 100
end

function TileCreator:draw()
    if not self.active then return end
    
    -- Draw background
    love.graphics.setColor(0.93, 0.93, 0.93, 1) -- #eeeeee
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw the tabs at the top if available
    if self.editorTabs then
        self.editorTabs:draw()
    end
    
    -- Draw panel background
    love.graphics.setColor(0.88, 0.88, 0.88, 1) -- Slightly darker
    love.graphics.rectangle("fill", self.panelX, self.panelY, self.panelWidth, love.graphics.getHeight())
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX, self.panelY, self.panelWidth, love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Tile Creator", self.panelX + 20, 20)
    
    -- Draw form fields
    love.graphics.setFont(self.labelFont)
    local y = 70
    
    -- ID field
    self:drawField("id", self.panelX + 20, y, self.panelWidth - 40, 30)
    y = y + 50
    
    -- Name field
    self:drawField("name", self.panelX + 20, y, self.panelWidth - 40, 30)
    y = y + 50
    
    -- Description field
    self:drawField("description", self.panelX + 20, y, self.panelWidth - 40, 60)
    y = y + 90
    
    -- Walkable checkbox
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Walkable:", self.panelX + 20, y)
    
    -- Checkbox
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.panelX + 120, y, 20, 20)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 120, y, 20, 20)
    
    if self.newTileType.walkable then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.line(self.panelX + 122, y + 10, self.panelX + 130, y + 18)
        love.graphics.line(self.panelX + 130, y + 18, self.panelX + 138, y + 2)
    end
    
    y = y + 40
    
    -- Color pickers
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Tile Color:", self.panelX + 20, y)
    
    -- Color preview
    love.graphics.setColor(self.newTileType.color)
    love.graphics.rectangle("fill", self.panelX + 120, y, 40, 20)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 120, y, 40, 20)
    
    y = y + 40
    
    -- Border color
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Border Color:", self.panelX + 20, y)
    
    -- Border color preview
    love.graphics.setColor(self.newTileType.borderColor)
    love.graphics.rectangle("fill", self.panelX + 120, y, 40, 20)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 120, y, 40, 20)
    
    y = y + 60
    
    -- Save button
    local buttonWidth = self.panelWidth - 40
    local buttonHeight = 40
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle("fill", self.panelX + 20, y, buttonWidth, buttonHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 20, y, buttonWidth, buttonHeight)
    
    love.graphics.setFont(self.buttonFont)
    local saveText = "Save Tile"
    local textWidth = self.buttonFont:getWidth(saveText)
    love.graphics.print(saveText, self.panelX + 20 + (buttonWidth - textWidth) / 2, y + 10)
    
    y = y + 60
    
    -- Cancel button
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle("fill", self.panelX + 20, y, buttonWidth, buttonHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 20, y, buttonWidth, buttonHeight)
    
    local cancelText = "Cancel"
    textWidth = self.buttonFont:getWidth(cancelText)
    love.graphics.print(cancelText, self.panelX + 20 + (buttonWidth - textWidth) / 2, y + 10)
    
    -- Draw preview area
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Preview", self.previewX, 20)
    
    -- Draw tile preview
    self:drawTilePreview()
    
    -- Draw color picker if active
    if self.colorPickerActive then
        self:drawColorPicker()
    end
end

function TileCreator:drawField(fieldName, x, y, width, height)
    local field = self.fields[fieldName]
    field.x = x
    field.y = y
    field.width = width
    field.height = height
    
    -- Draw label
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(field.label, x, y - 25)
    
    -- Draw input field background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw border (thicker if active)
    if self.activeField == fieldName then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(2)
    else
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.rectangle("line", x, y, width, height)
    love.graphics.setLineWidth(1)
    
    -- Draw text
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(field.value, x + 5, y + 5)
end

function TileCreator:drawTilePreview()
    -- Draw preview background
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    love.graphics.rectangle("fill", self.previewX - 10, self.previewY - 10, self.previewSize + 20, self.previewSize + 20)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.previewX - 10, self.previewY - 10, self.previewSize + 20, self.previewSize + 20)
    
    -- Draw tile preview
    love.graphics.setColor(self.newTileType.color)
    love.graphics.rectangle("fill", self.previewX, self.previewY, self.previewSize, self.previewSize)
    
    -- Draw border
    love.graphics.setColor(self.newTileType.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.previewX, self.previewY, self.previewSize, self.previewSize)
    love.graphics.setLineWidth(1)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function TileCreator:drawColorPicker()
    -- Draw color picker background
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", self.colorPickerX, self.colorPickerY, self.colorPickerWidth, self.colorPickerHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.colorPickerX, self.colorPickerY, self.colorPickerWidth, self.colorPickerHeight)
    
    -- Draw color grid
    local cellSize = 20
    local cols = math.floor(self.colorPickerWidth / cellSize)
    local rows = math.floor(self.colorPickerHeight / cellSize)
    
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local r = col / (cols - 1)
            local g = 1 - (col / (cols - 1) * row / (rows - 1))
            local b = 1 - (row / (rows - 1))
            
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", 
                self.colorPickerX + col * cellSize, 
                self.colorPickerY + row * cellSize, 
                cellSize, cellSize)
        end
    end
    
    -- Draw border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.colorPickerX, self.colorPickerY, self.colorPickerWidth, self.colorPickerHeight)
end

function TileCreator:mousepressed(x, y, button)
    if not self.active then return end
    
    -- Handle tab clicks if tabs are available
    if self.editorTabs then
        local clickedTab = self.editorTabs:mousepressed(x, y, button)
        if clickedTab then
            -- Return the clicked tab ID to the map editor to handle the switch
            return clickedTab
        end
    end
    
    if button == 1 then -- Left click
        -- Check if clicking on a field
        for name, field in pairs(self.fields) do
            if x >= field.x and x <= field.x + field.width and
               y >= field.y and y <= field.y + field.height then
                self.activeField = name
                return
            end
        end
        
        -- Check if clicking on walkable checkbox
        if x >= self.panelX + 120 and x <= self.panelX + 140 and
           y >= 250 and y <= 270 then
            self.newTileType.walkable = not self.newTileType.walkable
            return
        end
        
        -- Check if clicking on tile color
        if x >= self.panelX + 120 and x <= self.panelX + 160 and
           y >= 290 and y <= 310 then
            self.colorPickerActive = true
            self.colorPickerTarget = "color"
            self.colorPickerX = x
            self.colorPickerY = y
            return
        end
        
        -- Check if clicking on border color
        if x >= self.panelX + 120 and x <= self.panelX + 160 and
           y >= 330 and y <= 350 then
            self.colorPickerActive = true
            self.colorPickerTarget = "borderColor"
            self.colorPickerX = x
            self.colorPickerY = y
            return
        end
        
        -- Check if clicking on save button
        if x >= self.panelX + 20 and x <= self.panelX + 20 + (self.panelWidth - 40) and
           y >= 390 and y <= 390 + 40 then
            self:saveTile()
            return
        end
        
        -- Check if clicking on cancel button
        if x >= self.panelX + 20 and x <= self.panelX + 20 + (self.panelWidth - 40) and
           y >= 450 and y <= 450 + 40 then
            self:cancel()
            return
        end
        
        -- Check if clicking on color picker
        if self.colorPickerActive then
            local cellSize = 20
            local cols = math.floor(self.colorPickerWidth / cellSize)
            local rows = math.floor(self.colorPickerHeight / cellSize)
            
            if x >= self.colorPickerX and x <= self.colorPickerX + self.colorPickerWidth and
               y >= self.colorPickerY and y <= self.colorPickerY + self.colorPickerHeight then
                
                local col = math.floor((x - self.colorPickerX) / cellSize)
                local row = math.floor((y - self.colorPickerY) / cellSize)
                
                local r = col / (cols - 1)
                local g = 1 - (col / (cols - 1) * row / (rows - 1))
                local b = 1 - (row / (rows - 1))
                
                if self.colorPickerTarget == "color" then
                    self.newTileType.color = {r, g, b}
                else
                    self.newTileType.borderColor = {r, g, b}
                end
                
                self.colorPickerActive = false
                return
            else
                self.colorPickerActive = false
                return
            end
        end
        
        -- If clicking elsewhere, deactivate field
        self.activeField = nil
    end
end

function TileCreator:keypressed(key)
    if not self.active then return end
    
    if key == "escape" then
        if self.colorPickerActive then
            self.colorPickerActive = false
        else
            self:cancel()
        end
        return
    end
    
    if key == "return" or key == "tab" then
        if self.activeField then
            -- Move to next field or save
            if self.activeField == "id" then
                self.activeField = "name"
            elseif self.activeField == "name" then
                self.activeField = "description"
            elseif self.activeField == "description" then
                self.activeField = nil
            end
        end
        return
    end
    
    if key == "backspace" and self.activeField then
        local field = self.fields[self.activeField]
        field.value = field.value:sub(1, -2)
        
        -- Update tile property
        self.newTileType[self.activeField] = field.value
        return
    end
end

function TileCreator:textinput(text)
    if not self.active or not self.activeField then return end
    
    local field = self.fields[self.activeField]
    field.value = field.value .. text
    
    -- Update tile property
    self.newTileType[self.activeField] = field.value
end

function TileCreator:mousereleased(x, y, button)
    -- Handle mouse release events
    if button == 1 then -- Left click
        -- Nothing specific to do on release for now
    end
end

function TileCreator:saveTile()
    -- Validate fields
    if self.fields.id.value == "" then
        -- Show error
        return
    end
    
    -- Create the tile config
    local tileConfig = {
        id = self.fields.id.value,
        name = self.fields.name.value,
        color = self.newTileType.color,
        borderColor = self.newTileType.borderColor,
        walkable = self.newTileType.walkable,
        description = self.fields.description.value,
        drawDetails = function(self, x, y, tileSize)
            -- Default rendering
        end
    }
    
    -- Add to tile configs in the Tile module
    -- This would need to be implemented in the Tile module
    
    -- Return to map editor
    self.active = false
    
    return tileConfig
end

function TileCreator:cancel()
    -- Return to map editor without saving
    self.active = false
    
    -- Switch back to map editor tab if tabs are available
    if self.editorTabs then
        self.editorTabs:setActiveTab("map")
    end
end

return TileCreator
