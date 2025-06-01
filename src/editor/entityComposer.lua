-- Entity Composer
-- A dedicated editor for creating new entity types composed of tiles

local Grid = require("src.core.grid")
local Furniture = require("src.core.furniture")

local EntityComposer = {}
EntityComposer.__index = EntityComposer

function EntityComposer:new()
    local self = setmetatable({}, EntityComposer)
    
    -- State
    self.active = false
    self.tileSize = 64
    self.grid = nil
    
    -- Reference to editorTabs (will be set by MapEditor)
    
    -- New entity properties
    self.newEntity = {
        id = "custom_entity",
        name = "Custom Entity",
        width = 2,
        height = 2,
        color = {0.7, 0.5, 0.3},
        description = "A custom entity",
        tiles = {} -- Will hold the tile grid for this entity
    }
    
    -- UI state
    self.backgroundColor = {0.93, 0.93, 0.93, 1} -- Light gray background (#eeeeee)
    self.panelWidth = love.graphics.getWidth() * 0.25
    self.panelX = 0
    self.panelY = 0
    
    -- Grid editor
    self.editorX = self.panelWidth + 50
    self.editorY = 100
    self.editorWidth = 8
    self.editorHeight = 8
    self.selectedTileType = "floor"
    
    -- Available tile types
    self.tileTypes = {
        {id = "floor", name = "Floor", color = {0.8, 0.8, 0.7}},
        {id = "wall", name = "Wall", color = {0.6, 0.6, 0.6}},
        {id = "window", name = "Window", color = {0.7, 0.9, 1.0}},
        {id = "water", name = "Water", color = {0.3, 0.5, 0.9}},
        {id = "grass", name = "Grass", color = {0.4, 0.8, 0.4}}
    }
    
    -- Mouse state
    self.mouseX = 0
    self.mouseY = 0
    self.gridX = 0
    self.gridY = 0
    self.isDragging = false
    
    -- Fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 20)
    self.labelFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    self.buttonFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    
    -- Input fields
    self.activeField = nil
    self.fields = {
        id = {value = self.newEntity.id, x = 0, y = 0, width = 0, height = 0, label = "ID:"},
        name = {value = self.newEntity.name, x = 0, y = 0, width = 0, height = 0, label = "Name:"},
        description = {value = self.newEntity.description, x = 0, y = 0, width = 0, height = 0, label = "Description:"}
    }
    
    -- Tile previews
    self.tilePreviews = {}
    
    return self
end

function EntityComposer:initialize()
    -- Create a grid for the editor
    self.grid = Grid:new(self.tileSize)
    
    -- Set as active
    self.active = true
    
    -- Reset new entity properties
    self.newEntity = {
        id = "custom_entity",
        name = "Custom Entity",
        width = 2,
        height = 2,
        color = {0.7, 0.5, 0.3},
        description = "A custom entity",
        tiles = {} -- Will hold the tile grid for this entity
    }
    
    -- Initialize empty tile grid
    for y = 1, self.editorHeight do
        self.newEntity.tiles[y] = {}
        for x = 1, self.editorWidth do
            self.newEntity.tiles[y][x] = nil -- No tile by default
        end
    end
    
    -- Update field values
    self.fields.id.value = self.newEntity.id
    self.fields.name.value = self.newEntity.name
    self.fields.description.value = self.newEntity.description
    
    -- Create tile previews
    self:createTilePreviews()
end

function EntityComposer:createTilePreviews()
    -- Create preview images for tiles
    self.tilePreviews = {}
    
    -- Create tile previews
    for _, tileType in ipairs(self.tileTypes) do
        -- Create a canvas for the tile preview
        local canvas = love.graphics.newCanvas(40, 40)
        
        -- Draw to the canvas
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        
        -- Draw tile background
        love.graphics.setColor(tileType.color)
        love.graphics.rectangle("fill", 0, 0, 40, 40)
        
        -- Draw border
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("line", 0, 0, 40, 40)
        
        -- Reset canvas
        love.graphics.setCanvas()
        
        -- Store the preview
        self.tilePreviews[tileType.id] = canvas
    end
end

function EntityComposer:update(dt)
    if not self.active then return end
    
    -- Update mouse position
    self.mouseX, self.mouseY = love.mouse.getPosition()
    
    -- Update panel position
    self.panelWidth = love.graphics.getWidth() * 0.25
    self.panelX = 0
    
    -- Update editor position
    self.editorX = self.panelWidth + 50
    self.editorY = 100
    
    -- Convert mouse position to grid coordinates
    if self.mouseX >= self.editorX and self.mouseX < self.editorX + self.editorWidth * self.tileSize and
       self.mouseY >= self.editorY and self.mouseY < self.editorY + self.editorHeight * self.tileSize then
        
        self.gridX = math.floor((self.mouseX - self.editorX) / self.tileSize) + 1
        self.gridY = math.floor((self.mouseY - self.editorY) / self.tileSize) + 1
    else
        self.gridX = 0
        self.gridY = 0
    end
    
    -- Handle continuous drawing while mouse is held down
    if self.isDragging and self.gridX > 0 and self.gridY > 0 then
        self:placeTile(self.gridX, self.gridY)
    end
end

function EntityComposer:draw()
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
    love.graphics.print("Entity Composer", self.panelX + 20, 20)
    
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
    
    -- Dimensions
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Width: " .. self.newEntity.width .. "   Height: " .. self.newEntity.height, self.panelX + 20, y)
    y = y + 30
    
    -- Tile types section
    love.graphics.print("TILE TYPES", self.panelX + 20, y)
    y = y + 30
    
    -- Draw tile buttons
    local buttonSize = 40
    local buttonPadding = 6
    local buttonsPerRow = math.floor((self.panelWidth - 40) / (buttonSize + buttonPadding))
    
    for i, tileType in ipairs(self.tileTypes) do
        local row = math.floor((i-1) / buttonsPerRow)
        local col = (i-1) % buttonsPerRow
        local buttonX = self.panelX + 20 + col * (buttonSize + buttonPadding)
        local buttonY = y + row * (buttonSize + buttonPadding + 20)
        
        -- Draw button background
        if self.selectedTileType == tileType.id then
            love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Highlight selected
        else
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
        end
        love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize)
        
        -- Draw button border
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", buttonX, buttonY, buttonSize, buttonSize)
        
        -- Draw tile preview
        love.graphics.setColor(1, 1, 1, 1)
        if self.tilePreviews[tileType.id] then
            love.graphics.draw(self.tilePreviews[tileType.id], buttonX, buttonY)
        end
        
        -- Draw tile name
        love.graphics.setColor(0, 0, 0, 1)
        local nameWidth = self.labelFont:getWidth(tileType.name)
        local maxWidth = buttonSize
        
        if nameWidth > maxWidth then
            -- Truncate name if too long
            local truncatedName = tileType.name:sub(1, 5) .. "..."
            love.graphics.print(truncatedName, buttonX, buttonY + buttonSize + 2)
        else
            love.graphics.print(tileType.name, buttonX, buttonY + buttonSize + 2)
        end
    end
    
    -- Update y position based on tile buttons
    local tileRows = math.ceil(#self.tileTypes / buttonsPerRow)
    y = y + tileRows * (buttonSize + buttonPadding + 20) + 20
    
    -- Save button
    local buttonWidth = self.panelWidth - 40
    local buttonHeight = 40
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle("fill", self.panelX + 20, y, buttonWidth, buttonHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.panelX + 20, y, buttonWidth, buttonHeight)
    
    love.graphics.setFont(self.buttonFont)
    local saveText = "Save Entity"
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
    
    -- Draw editor title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Entity Grid Editor", self.editorX, 20)
    
    -- Draw instructions
    love.graphics.setFont(self.labelFont)
    love.graphics.print("Click to place tiles. Right-click to remove.", self.editorX, 50)
    
    -- Draw grid
    self:drawGrid()
    
    -- Draw cursor highlight
    if self.gridX > 0 and self.gridY > 0 then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", 
            self.editorX + (self.gridX - 1) * self.tileSize,
            self.editorY + (self.gridY - 1) * self.tileSize,
            self.tileSize, self.tileSize)
    end
end

function EntityComposer:drawField(fieldName, x, y, width, height)
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

function EntityComposer:drawGrid()
    -- Draw grid background
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    love.graphics.rectangle("fill", 
        self.editorX - 1, self.editorY - 1, 
        self.editorWidth * self.tileSize + 2, 
        self.editorHeight * self.tileSize + 2)
    
    -- Draw grid cells
    for y = 1, self.editorHeight do
        for x = 1, self.editorWidth do
            local cellX = self.editorX + (x - 1) * self.tileSize
            local cellY = self.editorY + (y - 1) * self.tileSize
            
            -- Draw cell background based on tile type
            local tileType = self.newEntity.tiles[y][x]
            if tileType then
                -- Find the tile type in our list
                for _, tile in ipairs(self.tileTypes) do
                    if tile.id == tileType then
                        love.graphics.setColor(tile.color)
                        break
                    end
                end
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            love.graphics.rectangle("fill", cellX, cellY, self.tileSize, self.tileSize)
            
            -- Draw cell border
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("line", cellX, cellY, self.tileSize, self.tileSize)
        end
    end
    
    -- Draw entity boundary
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 
        self.editorX, self.editorY,
        self.newEntity.width * self.tileSize,
        self.newEntity.height * self.tileSize)
    love.graphics.setLineWidth(1)
end

function EntityComposer:mousepressed(x, y, button)
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
        
        -- Check if clicking on a tile type
        local buttonSize = 40
        local buttonPadding = 6
        local buttonsPerRow = math.floor((self.panelWidth - 40) / (buttonSize + buttonPadding))
        local tileTypesY = 270
        
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = self.panelX + 20 + col * (buttonSize + buttonPadding)
            local buttonY = tileTypesY + row * (buttonSize + buttonPadding + 20)
            
            if x >= buttonX and x <= buttonX + buttonSize and
               y >= buttonY and y <= buttonY + buttonSize then
                self.selectedTileType = tileType.id
                return
            end
        end
        
        -- Check if clicking on save button
        local saveButtonY = tileTypesY + math.ceil(#self.tileTypes / buttonsPerRow) * (buttonSize + buttonPadding + 20) + 20
        if x >= self.panelX + 20 and x <= self.panelX + 20 + (self.panelWidth - 40) and
           y >= saveButtonY and y <= saveButtonY + 40 then
            self:saveEntity()
            return
        end
        
        -- Check if clicking on cancel button
        if x >= self.panelX + 20 and x <= self.panelX + 20 + (self.panelWidth - 40) and
           y >= saveButtonY + 60 and y <= saveButtonY + 60 + 40 then
            self:cancel()
            return
        end
        
        -- Check if clicking on grid
        if self.gridX > 0 and self.gridY > 0 then
            self:placeTile(self.gridX, self.gridY)
            self.isDragging = true
            return
        end
        
        -- If clicking elsewhere, deactivate field
        self.activeField = nil
    elseif button == 2 then -- Right click
        -- Remove tile if clicking on grid
        if self.gridX > 0 and self.gridY > 0 then
            self.newEntity.tiles[self.gridY][self.gridX] = nil
            return
        end
    end
end

function EntityComposer:mousereleased(x, y, button)
    if not self.active then return end
    
    if button == 1 then -- Left click
        self.isDragging = false
    end
end

function EntityComposer:placeTile(gridX, gridY)
    -- Only place tiles within the entity bounds
    if gridX <= self.newEntity.width and gridY <= self.newEntity.height then
        self.newEntity.tiles[gridY][gridX] = self.selectedTileType
    end
end

function EntityComposer:keypressed(key)
    if not self.active then return end
    
    if key == "escape" then
        self:cancel()
        return
    end
    
    if key == "return" or key == "tab" then
        if self.activeField then
            -- Move to next field
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
        
        -- Update entity property
        self.newEntity[self.activeField] = field.value
        return
    end
    
    -- Resize entity with number keys
    if key >= "1" and key <= "8" and love.keyboard.isDown("lctrl") then
        self.newEntity.width = tonumber(key)
        return
    end
    
    if key >= "1" and key <= "8" and love.keyboard.isDown("lshift") then
        self.newEntity.height = tonumber(key)
        return
    end
end

function EntityComposer:textinput(text)
    if not self.active or not self.activeField then return end
    
    local field = self.fields[self.activeField]
    field.value = field.value .. text
    
    -- Update entity property
    self.newEntity[self.activeField] = field.value
end

function EntityComposer:saveEntity()
    -- Create a new entity type
    print("Saving entity: " .. self.newEntity.id)
    
    -- Add to entity types list
    local entityType = {
        id = self.newEntity.id,
        name = self.newEntity.name,
        width = self.newEntity.width,
        height = self.newEntity.height,
        description = self.newEntity.description,
        tiles = {}
    }
    
    -- Copy tiles
    for y = 1, self.newEntity.height do
        entityType.tiles[y] = {}
        for x = 1, self.newEntity.width do
            entityType.tiles[y][x] = self.newEntity.tiles[y][x]
        end
    end
    
    -- Add to furniture types
    Furniture.registerType(entityType)
    
    -- Close the entity composer
    self.active = false
end

function EntityComposer:cancel()
    -- Close the entity composer and return to previous screen
    print("Canceling entity creation")
    self.active = false
    
    -- Switch back to map editor tab if tabs are available
    if self.editorTabs then
        self.editorTabs:setActiveTab("map")
    end
end

return EntityComposer
