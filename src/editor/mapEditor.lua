-- Map Editor
-- A standalone editor for creating and editing maps

local Grid = require("src.core.grid")
local Map = require("src.core.map")
local Tile = require("src.core.tile")
local Furniture = require("src.core.furniture")
local MapBrowser = require("src.editor.mapBrowser")

local MapEditor = {}
MapEditor.__index = MapEditor

function MapEditor:new()
    local self = setmetatable({}, MapEditor)
    
    -- Editor state
    self.active = false
    self.width = 12
    self.height = 14
    self.tileSize = 64
    self.grid = nil
    self.map = nil
    
    -- Background color (can be set by the editor mode)
    self.backgroundColor = {0.15, 0.15, 0.2, 1}  -- Darker blue-gray
    
    -- Initialize map browser
    self.mapBrowser = MapBrowser:new()
    
    -- UI state
    self.selectedTool = "tile"  -- tile, entity, erase
    self.selectedTileType = "floor"  -- floor, wall, window
    self.selectedEntityType = "couch"  -- couch, tv, etc.
    self.showGrid = true
    self.showUI = true
    
    -- Mouse state
    self.mouseX = 0
    self.mouseY = 0
    self.gridX = 0
    self.gridY = 0
    self.isDragging = false
    
    -- Available tile types with metadata for visual display
    self.tileTypes = {
        {id = "floor", name = "Floor", color = {0.8, 0.8, 0.7}, description = "Basic floor tile"},
        {id = "wall", name = "Wall", color = {0.6, 0.6, 0.6}, description = "Solid wall"},
        {id = "window", name = "Window", color = {0.7, 0.9, 1.0}, description = "Transparent window"}, 
        {id = "water", name = "Water", color = {0.3, 0.5, 0.9}, description = "Water tile"},
        {id = "grass", name = "Grass", color = {0.4, 0.8, 0.4}, description = "Grass tile"}
    }
    
    -- Available entity types with metadata for visual display
    self.entityTypes = {
        {id = "couch", name = "Couch", color = {0.8, 0.5, 0.3}, width = 2, height = 1, description = "A comfortable couch"},
        {id = "tv", name = "TV", color = {0.2, 0.2, 0.2}, width = 1, height = 1, description = "Television"},
        {id = "coffee_table", name = "Coffee Table", color = {0.6, 0.4, 0.2}, width = 2, height = 1, description = "Small table"},
        {id = "cupboard", name = "Cupboard", color = {0.5, 0.3, 0.2}, width = 1, height = 2, description = "Storage cupboard"},
        {id = "plant", name = "Plant", color = {0.3, 0.7, 0.3}, width = 1, height = 1, description = "Decorative plant"},
        {id = "bed", name = "Bed", color = {0.7, 0.7, 0.9}, width = 2, height = 2, description = "A bed"},
        {id = "desk", name = "Desk", color = {0.5, 0.4, 0.3}, width = 2, height = 1, description = "Work desk"},
        {id = "chair", name = "Chair", color = {0.7, 0.5, 0.3}, width = 1, height = 1, description = "Chair"}
    }
    
    -- UI elements
    self.buttonSize = 60  -- Increased for better visibility
    self.buttonPadding = 10
    self.panelWidth = 280  -- Increased for tile previews
    self.panelHeight = 0  -- Will be calculated based on content
    self.panelX = 20
    self.panelY = 20
    
    -- Map name for saving/loading
    self.mapName = "custom_map"
    self.isEditingMapName = false
    self.mapNameInput = ""
    
    -- Map browser
    self.showMapBrowser = false
    self.availableMaps = {}
    self.selectedMapIndex = 1
    
    -- Dimension input fields
    self.isEditingWidth = false
    self.isEditingHeight = false
    self.widthInput = tostring(self.width)
    self.heightInput = tostring(self.height)
    
    -- Create fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 18)
    self.buttonFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Medium.ttf", 14)
    self.labelFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12)
    
    -- Create tile preview images
    self:createTilePreviews()
    
    return self
end

function MapEditor:initialize()
    -- Create a new grid and map
    self.grid = Grid:new(self.tileSize)
    self.map = Map:new(self.grid, self.width, self.height)
    
    -- Fill the map with floor tiles
    for y = 1, self.height do
        for x = 1, self.width do
            self.map:setTile(x, y, "floor")
        end
    end
    
    -- Set editor as active
    self.active = true
    
    -- Create tile preview images if they don't exist
    if not self.tilePreviews then
        self:createTilePreviews()
    end
end

function MapEditor:createTilePreviews()
    -- Create preview images for tiles and entities
    self.tilePreviews = {}
    self.entityPreviews = {}
    
    -- Create tile previews
    for _, tileType in ipairs(self.tileTypes) do
        -- Create a canvas for the tile preview
        local canvas = love.graphics.newCanvas(self.buttonSize, self.buttonSize)
        
        -- Draw to the canvas
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw tile preview
        love.graphics.setColor(tileType.color)
        love.graphics.rectangle("fill", 2, 2, self.buttonSize - 4, self.buttonSize - 4)
        
        -- Add border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", 2, 2, self.buttonSize - 4, self.buttonSize - 4)
        
        -- Reset canvas
        love.graphics.setCanvas()
        
        -- Store the preview
        self.tilePreviews[tileType.id] = canvas
    end
    
    -- Create entity previews
    for _, entityType in ipairs(self.entityTypes) do
        -- Create a canvas for the entity preview
        local canvas = love.graphics.newCanvas(self.buttonSize, self.buttonSize)
        
        -- Draw to the canvas
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw entity preview - scale based on entity size
        local width = entityType.width or 1
        local height = entityType.height or 1
        local maxDim = math.max(width, height)
        local scale = (self.buttonSize - 8) / (maxDim * self.tileSize)
        
        -- Calculate centered position
        local x = (self.buttonSize - width * self.tileSize * scale) / 2
        local y = (self.buttonSize - height * self.tileSize * scale) / 2
        
        -- Draw entity
        love.graphics.setColor(entityType.color)
        love.graphics.rectangle("fill", x, y, width * self.tileSize * scale, height * self.tileSize * scale)
        
        -- Add border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", x, y, width * self.tileSize * scale, height * self.tileSize * scale)
        
        -- Reset canvas
        love.graphics.setCanvas()
        
        -- Store the preview
        self.entityPreviews[entityType.id] = canvas
    end
end

function MapEditor:update(dt)
    if not self.active then return end
    
    -- Update map browser if it's visible
    if self.mapBrowser.visible then
        self.mapBrowser:update(dt)
        return
    end
    
    -- Update mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    self.mouseX = mouseX
    self.mouseY = mouseY
    
    -- Convert mouse position to grid coordinates
    local worldX, worldY = mouseX, mouseY  -- No camera transform in editor
    self.gridX, self.gridY = self.grid:worldToGrid(worldX, worldY)
    
    -- Handle continuous drawing while mouse is held down
    if self.isDragging and self:isMouseOverMap() then
        self:applyTool(self.gridX, self.gridY)
    end
end

function MapEditor:draw()
    if not self.active then return end
    
    -- Draw the map
    self.map:draw()
    
    -- Draw grid if enabled
    if self.showGrid then
        self:drawGrid()
    end
    
    -- Draw UI if enabled
    if self.showUI then
        self:drawUI()
    end
    
    -- Draw cursor highlight
    if self:isMouseOverMap() and not self.mapBrowser.visible then
        self:drawCursorHighlight()
    end
    
    -- Draw map browser if it's visible
    if self.mapBrowser.visible then
        self.mapBrowser:draw()
    end
end

function MapEditor:drawGrid()
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(1)
    
    -- Draw vertical lines
    for x = 0, self.width do
        local worldX = x * self.tileSize
        love.graphics.line(worldX, 0, worldX, self.height * self.tileSize)
    end
    
    -- Draw horizontal lines
    for y = 0, self.height do
        local worldY = y * self.tileSize
        love.graphics.line(0, worldY, self.width * self.tileSize, worldY)
    end
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function MapEditor:drawUI()
    -- Calculate panel height based on content
    local numTileButtons = #self.tileTypes
    local numEntityButtons = #self.entityTypes
    local numSections = 3  -- Tools, Tiles, Entities
    local sectionHeight = 30
    local buttonsPerRow = 4
    local tileRows = math.ceil(numTileButtons / buttonsPerRow)
    local entityRows = math.ceil(numEntityButtons / buttonsPerRow)
    
    self.panelHeight = sectionHeight * numSections + 
                      (tileRows + entityRows) * (self.buttonSize + self.buttonPadding) +
                      self.buttonPadding * 4 + 100  -- Extra space for other controls
    
    -- Draw panel background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", self.panelX, self.panelY, self.panelWidth, self.panelHeight, 10, 10)
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("line", self.panelX, self.panelY, self.panelWidth, self.panelHeight, 10, 10)
    
    -- Current position
    local x = self.panelX + self.buttonPadding
    local y = self.panelY + self.buttonPadding
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Map Editor", x, y)
    y = y + self.titleFont:getHeight() + self.buttonPadding
    
    -- Draw map size controls
    love.graphics.setFont(self.labelFont)
    love.graphics.print("Map Size: " .. self.width .. "x" .. self.height, x, y)
    y = y + self.labelFont:getHeight() + 5
    
    -- Width controls
    love.graphics.print("Width:", x, y)
    
    -- Width input field
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", x + 50, y, 40, 20)
    
    if self.isEditingWidth then
        love.graphics.setColor(1, 1, 0.8, 1)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end
    
    love.graphics.rectangle("line", x + 50, y, 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
    
    local displayWidth = self.isEditingWidth and self.widthInput or tostring(self.width)
    love.graphics.print(displayWidth, x + 55, y + 2)
    
    -- Width input field click detection
    if self:isMouseOver(x + 50, y, 40, 20) and love.mouse.isDown(1) and not self.isDragging then
        self.isEditingWidth = true
        self.isEditingHeight = false
        self.isEditingMapName = false
        self.widthInput = tostring(self.width)
    end
    
    -- Minus button
    if self:drawButton(x + 100, y, 20, 20, "-", self.width > 5) then
        if self.width > 5 then
            self.width = self.width - 1
            self.widthInput = tostring(self.width)
            self:resizeMap(self.width, self.height)
        end
    end
    
    -- Plus button
    if self:drawButton(x + 130, y, 20, 20, "+", self.width < 50) then
        if self.width < 50 then
            self.width = self.width + 1
            self.widthInput = tostring(self.width)
            self:resizeMap(self.width, self.height)
        end
    end
    
    y = y + 25
    
    -- Height controls
    love.graphics.print("Height:", x, y)
    
    -- Height input field
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", x + 50, y, 40, 20)
    
    if self.isEditingHeight then
        love.graphics.setColor(1, 1, 0.8, 1)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end
    
    love.graphics.rectangle("line", x + 50, y, 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
    
    local displayHeight = self.isEditingHeight and self.heightInput or tostring(self.height)
    love.graphics.print(displayHeight, x + 55, y + 2)
    
    -- Height input field click detection
    if self:isMouseOver(x + 50, y, 40, 20) and love.mouse.isDown(1) and not self.isDragging then
        self.isEditingHeight = true
        self.isEditingWidth = false
        self.isEditingMapName = false
        self.heightInput = tostring(self.height)
    end
    
    -- Minus button
    if self:drawButton(x + 100, y, 20, 20, "-", self.height > 5) then
        if self.height > 5 then
            self.height = self.height - 1
            self.heightInput = tostring(self.height)
            self:resizeMap(self.width, self.height)
        end
    end
    
    -- Plus button
    if self:drawButton(x + 130, y, 20, 20, "+", self.height < 50) then
        if self.height < 50 then
            self.height = self.height + 1
            self.heightInput = tostring(self.height)
            self:resizeMap(self.width, self.height)
        end
    end
    
    y = y + 30
    
    -- Draw tools section
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(0.7, 0.7, 1, 1)
    love.graphics.print("Tools", x, y)
    y = y + self.titleFont:getHeight() + 5
    
    -- Tool buttons
    local toolButtons = {
        {name = "tile", label = "Tile"},
        {name = "entity", label = "Entity"},
        {name = "erase", label = "Erase"}
    }
    
    for i, tool in ipairs(toolButtons) do
        local buttonX = x + (i-1) * (self.buttonSize + self.buttonPadding)
        local isSelected = self.selectedTool == tool.name
        
        if self:drawButton(buttonX, y, self.buttonSize, self.buttonSize, tool.label, true, isSelected) then
            self.selectedTool = tool.name
        end
    end
    
    y = y + self.buttonSize + self.buttonPadding * 2
    
    -- Draw tile types section if tile tool is selected
    if self.selectedTool == "tile" then
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(0.7, 1, 0.7, 1)
        love.graphics.print("Tile Types", x, y)
        y = y + self.titleFont:getHeight() + 5
        
        -- Tile type buttons with previews
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = x + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding)
            local isSelected = self.selectedTileType == tileType.id
            
            -- Draw button background
            if isSelected then
                love.graphics.setColor(0.3, 0.7, 1, 1)
            else
                love.graphics.setColor(0.4, 0.4, 0.6, 1)
            end
            
            love.graphics.rectangle("fill", buttonX, buttonY, self.buttonSize, self.buttonSize, 4, 4)
            
            -- Draw button border
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.rectangle("line", buttonX, buttonY, self.buttonSize, self.buttonSize, 4, 4)
            
            -- Draw tile preview
            love.graphics.setColor(1, 1, 1, 1)
            if self.tilePreviews[tileType.id] then
                love.graphics.draw(self.tilePreviews[tileType.id], buttonX, buttonY)
            end
            
            -- Draw tile name below the preview
            love.graphics.setFont(self.labelFont)
            local labelWidth = self.labelFont:getWidth(tileType.name)
            local labelX = buttonX + (self.buttonSize - labelWidth) / 2
            love.graphics.print(tileType.name, labelX, buttonY + self.buttonSize + 2)
            
            -- Check for button click
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) and 
               love.mouse.isDown(1) and not self.isDragging then
                self.selectedTileType = tileType.id
            end
        end
        
        y = y + tileRows * (self.buttonSize + self.buttonPadding + 15) + self.buttonPadding
    end
    
    -- Draw entity types section if entity tool is selected
    if self.selectedTool == "entity" then
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(1, 0.7, 0.7, 1)
        love.graphics.print("Entity Types", x, y)
        y = y + self.titleFont:getHeight() + 5
        
        -- Entity type buttons with previews
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = x + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding)
            local isSelected = self.selectedEntityType == entityType.id
            
            -- Draw button background
            if isSelected then
                love.graphics.setColor(1, 0.5, 0.5, 1)
            else
                love.graphics.setColor(0.6, 0.4, 0.4, 1)
            end
            
            love.graphics.rectangle("fill", buttonX, buttonY, self.buttonSize, self.buttonSize, 4, 4)
            
            -- Draw button border
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.rectangle("line", buttonX, buttonY, self.buttonSize, self.buttonSize, 4, 4)
            
            -- Draw entity preview
            love.graphics.setColor(1, 1, 1, 1)
            if self.entityPreviews[entityType.id] then
                love.graphics.draw(self.entityPreviews[entityType.id], buttonX, buttonY)
            end
            
            -- Draw entity name below the preview
            love.graphics.setFont(self.labelFont)
            local labelWidth = self.labelFont:getWidth(entityType.name)
            local labelX = buttonX + (self.buttonSize - labelWidth) / 2
            love.graphics.print(entityType.name, labelX, buttonY + self.buttonSize + 2)
            
            -- Draw entity dimensions
            local dimText = entityType.width .. "x" .. entityType.height
            local dimWidth = self.labelFont:getWidth(dimText)
            local dimX = buttonX + (self.buttonSize - dimWidth) / 2
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print(dimText, dimX, buttonY + self.buttonSize + 15)
            
            -- Check for button click
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) and 
               love.mouse.isDown(1) and not self.isDragging then
                self.selectedEntityType = entityType.id
            end
        end
        
        y = y + entityRows * (self.buttonSize + self.buttonPadding + 25) + self.buttonPadding
    end
    
    -- Draw map name input field
    y = y + 30
    
    love.graphics.setFont(self.labelFont)
    love.graphics.print("Map Name:", x, y)
    y = y + self.labelFont:getHeight() + 5
    
    -- Draw text input box
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", x, y, self.panelWidth - 20, 25)
    
    if self.isEditingMapName then
        love.graphics.setColor(1, 1, 0.8, 1)
    else
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end
    
    love.graphics.rectangle("line", x, y, self.panelWidth - 20, 25)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw map name or input text
    local displayText = self.isEditingMapName and self.mapNameInput or self.mapName
    love.graphics.print(displayText, x + 5, y + 5)
    
    -- Check if text field was clicked
    if love.mouse.isDown(1) and self:isMouseOver(x, y, self.panelWidth - 20, 25) and not self.isDragging then
        self.isEditingMapName = true
        self.mapNameInput = self.mapName
    elseif love.mouse.isDown(1) and not self:isMouseOver(x, y, self.panelWidth - 20, 25) then
        if self.isEditingMapName then
            self.mapName = self.mapNameInput
            self.isEditingMapName = false
        end
    end
    
    -- Draw save/load buttons
    y = y + 35
    
    if self:drawButton(x, y, 80, 30, "Save Map", true) then
        self:saveMap()
    end
    
    if self:drawButton(x + 90, y, 80, 30, "Load Map", true) then
        self:showMapBrowser()
    end
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.getFont())
end

function MapEditor:mousepressed(x, y, button)
    if not self.active then return end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        local result = self.mapBrowser:mousepressed(x, y, button)
        if result == "load" then
            local mapName = self.mapBrowser:getSelectedMap()
            if mapName then
                self.mapName = mapName
                self:loadMap()
            end
            self.mapBrowser:hide()
        elseif result == "cancel" then
            self.mapBrowser:hide()
        end
        return
    end
    
    if button == 1 then  -- Left click
        -- Check if clicking on UI
        if self:isMouseOverUI() then
            -- UI interaction handled in drawUI
            return
        end
        
        -- Check if clicking on map
        if self:isMouseOverMap() then
            -- Start dragging for continuous drawing
            self.isDragging = true
            
            -- Apply the selected tool
            self:applyTool(self.gridX, self.gridY)
        end
    end
end

function MapEditor:keypressed(key)
    if not self.active then return end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        local result = self.mapBrowser:keypressed(key)
        if result == "load" then
            local mapName = self.mapBrowser:getSelectedMap()
            if mapName then
                self.mapName = mapName
                self:loadMap()
            end
            self.mapBrowser:hide()
        elseif result == "cancel" then
            self.mapBrowser:hide()
        end
        return
    end
    
    -- Handle map name editing
    if self.isEditingMapName then
        if key == "return" or key == "escape" then
            -- Finish editing
            self.isEditingMapName = false
            if key == "return" and self.mapNameInput ~= "" then
                self.mapName = self.mapNameInput
            end
            self.mapNameInput = ""
        elseif key == "backspace" then
            -- Remove the last character
            self.mapNameInput = self.mapNameInput:sub(1, -2)
        end
        return
    end
    
    -- Handle width editing
    if self.isEditingWidth then
        if key == "return" or key == "escape" then
            -- Finish editing
            self.isEditingWidth = false
            if key == "return" and self.widthInput ~= "" then
                local newWidth = tonumber(self.widthInput)
                if newWidth and newWidth >= 5 and newWidth <= 50 then
                    self:resizeMap(newWidth, self.height)
                end
            end
            self.widthInput = tostring(self.width)
        elseif key == "backspace" then
            -- Remove the last character
            self.widthInput = self.widthInput:sub(1, -2)
        elseif key:match("^%d$") then
            -- Only allow digits
            self.widthInput = self.widthInput .. key
        end
        return
    end
    
    -- Handle height editing
    if self.isEditingHeight then
        if key == "return" or key == "escape" then
            -- Finish editing
            self.isEditingHeight = false
            if key == "return" and self.heightInput ~= "" then
                local newHeight = tonumber(self.heightInput)
                if newHeight and newHeight >= 5 and newHeight <= 50 then
                    self:resizeMap(self.width, newHeight)
                end
            end
            self.heightInput = tostring(self.height)
        elseif key == "backspace" then
            -- Remove the last character
            self.heightInput = self.heightInput:sub(1, -2)
        elseif key:match("^%d$") then
            -- Only allow digits
            self.heightInput = self.heightInput .. key
        end
        return
    end
    
    -- Global keyboard shortcuts
    if key == "s" and love.keyboard.isDown("lctrl") then
        -- Ctrl+S to save
        self:saveMap()
    elseif key == "l" and love.keyboard.isDown("lctrl") then
        -- Ctrl+L to load
        self:showMapBrowser()
    elseif key == "g" then
        -- G to toggle grid
        self.showGrid = not self.showGrid
    elseif key == "u" then
        -- U to toggle UI
        self.showUI = not self.showUI
    end
end

function MapEditor:textinput(text)
    if not self.active then return end
    
    -- Handle map name editing
    if self.isEditingMapName then
        self.mapNameInput = self.mapNameInput .. text
    end
    
    -- Handle width editing
    if self.isEditingWidth then
        -- Only allow digits
        if text:match("^%d$") then
            self.widthInput = self.widthInput .. text
        end
    end
    
    -- Handle height editing
    if self.isEditingHeight then
        -- Only allow digits
        if text:match("^%d$") then
            self.heightInput = self.heightInput .. text
        end
    end
end

function MapEditor:applyTool(gridX, gridY)
    -- Check if the position is valid
    if not self:isValidGridPosition(gridX, gridY) then return end
    
    if self.selectedTool == "tile" then
        -- Place a tile
        local tileType = nil
        local options = {}
        
        -- Find the selected tile type from our tile types array
        for _, tile in ipairs(self.tileTypes) do
            if tile.id == self.selectedTileType then
                tileType = tile.id
                if tile.id == "window" then
                    -- Windows are special wall tiles with isWindow=true
                    tileType = "wall"
                    options.isWindow = true
                end
                break
            end
        end
        
        if tileType then
            self.map:setTile(gridX, gridY, tileType, options)
            print("Placed tile: " .. tileType .. " at " .. gridX .. "," .. gridY)
        end
    elseif self.selectedTool == "entity" then
        -- Place an entity
        local entityType = nil
        
        -- Find the selected entity type from our entity types array
        for _, entity in ipairs(self.entityTypes) do
            if entity.id == self.selectedEntityType then
                entityType = entity.id
                break
            end
        end
        
        if entityType then
            local entity = Furniture.create(entityType, self.grid, gridX, gridY)
            if entity then
                -- Check if the entity can be placed here
                if self.map:canPlaceEntity(entity) then
                    self.map:addEntity(entity)
                    print("Placed entity: " .. entityType .. " at " .. gridX .. "," .. gridY)
                else
                    print("Cannot place entity here: collision detected")
                end
            end
        end
    elseif self.selectedTool == "erase" then
        -- Erase tile or entity
        local entity = self.map:getEntityAt(gridX, gridY)
        if entity then
            self.map:removeEntity(entity)
            print("Removed entity at " .. gridX .. "," .. gridY)
        else
            -- If no entity, set to floor tile
            self.map:setTile(gridX, gridY, "floor")
            print("Reset tile to floor at " .. gridX .. "," .. gridY)
        end
    end
end

function MapEditor:resizeMap(newWidth, newHeight)
    -- Validate dimensions
    newWidth = math.max(5, math.min(50, newWidth))
    newHeight = math.max(5, math.min(50, newHeight))
    
    -- If no change, return
    if newWidth == self.width and newHeight == self.height then
        return
    end
    
    print("Resizing map from " .. self.width .. "x" .. self.height .. " to " .. newWidth .. "x" .. newHeight)
    
    -- Create a new map with the new dimensions
    local newMap = Map:new(self.grid, newWidth, newHeight)
    
    -- Copy tiles from the old map to the new map
    for y = 1, math.min(self.height, newHeight) do
        for x = 1, math.min(self.width, newWidth) do
            local tile = self.map:getTile(x, y)
            if tile then
                if tile.isWindow then
                    newMap:setTile(x, y, "wall", {isWindow = true})
                else
                    newMap:setTile(x, y, tile.tileType)
                end
            end
        end
    end
    
    -- Fill any new tiles with floor
    for y = 1, newHeight do
        for x = 1, newWidth do
            if not newMap:getTile(x, y) then
                newMap:setTile(x, y, "floor")
            end
        end
    end
    
    -- Copy entities that are still within the map bounds
    for _, entity in ipairs(self.map.entities) do
        if entity.gridX <= newWidth and entity.gridY <= newHeight then
            newMap:addEntity(entity)
        end
    end
    
    -- Update map reference
    self.map = newMap
    self.width = newWidth
    self.height = newHeight
    
    -- Update input fields
    self.widthInput = tostring(newWidth)
    self.heightInput = tostring(newHeight)
end

function MapEditor:saveMap()
    -- Create a map data table
    local mapData = {
        name = self.mapName,
        width = self.width,
        height = self.height,
        tiles = {},
        entities = {}
    }
    
    -- Save tiles
    for y = 1, self.height do
        mapData.tiles[y] = {}
        for x = 1, self.width do
            local tile = self.map:getTile(x, y)
            if tile then
                mapData.tiles[y][x] = {
                    type = tile.tileType,
                    isWindow = tile.isWindow or false
                }
            else
                mapData.tiles[y][x] = {
                    type = "floor",
                    isWindow = false
                }
            end
        end
    end
    
    -- Save entities
    for i, entity in ipairs(self.map.entities) do
        if entity.type == "furniture" then
            table.insert(mapData.entities, {
                type = entity.name:lower(),
                x = entity.gridX,
                y = entity.gridY,
                width = entity.width,
                height = entity.height
            })
        end
    end
    
    -- Serialize to JSON
    local json = require("lib.json")
    local mapJson = json.encode(mapData)
    
    -- Sanitize map name for filename
    local safeMapName = self.mapName:gsub("[^%w_%-%.]", "_")
    if safeMapName == "" then safeMapName = "custom_map" end
    
    -- Save to file
    local filename = "maps/" .. safeMapName .. ".json"
    
    -- Create maps directory if it doesn't exist
    love.filesystem.createDirectory("maps")
    
    -- Write to file
    local success, message = love.filesystem.write(filename, mapJson)
    
    if success then
        print("Map saved to " .. filename)
    else
        print("Failed to save map: " .. message)
    end
end

function MapEditor:loadMap()
    -- Sanitize map name for filename
    local safeMapName = self.mapName:gsub("[^%w_%-%.]", "_")
    if safeMapName == "" then safeMapName = "custom_map" end
    
    -- Load from file
    local filename = "maps/" .. safeMapName .. ".json"
    
    if not love.filesystem.getInfo(filename) then
        print("No saved map found: " .. filename)
        return
    end
    
    local mapJson, size = love.filesystem.read(filename)
    
    if not mapJson then
        print("Failed to read map file: " .. filename)
        return
    end
    
    -- Parse JSON
    local json = require("lib.json")
    local mapData = json.decode(mapJson)
    
    if not mapData then
        print("Failed to parse map data")
        return
    end
    
    -- Update map name if it exists in the data
    if mapData.name then
        self.mapName = mapData.name
    end
    
    -- Update map size
    self.width = mapData.width
    self.height = mapData.height
    
    -- Reinitialize map
    self:initialize()
    
    -- Load tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tileData = mapData.tiles[y][x]
            if tileData then
                if tileData.isWindow then
                    self.map:setTile(x, y, "wall", {isWindow = true})
                else
                    self.map:setTile(x, y, tileData.type)
                end
            end
        end
    end
    
    -- Load entities
    for _, entityData in ipairs(mapData.entities) do
        local entity = Furniture.create(entityData.type, self.grid, entityData.x, entityData.y)
        self.map:addEntity(entity)
    end
    
    print("Map loaded from " .. filename)
end

function MapEditor:isMouseOver(x, y, width, height)
    return self.mouseX >= x and self.mouseX <= x + width and
           self.mouseY >= y and self.mouseY <= y + height
end

function MapEditor:isValidGridPosition(gridX, gridY)
    return gridX >= 1 and gridX <= self.width and
           gridY >= 1 and gridY <= self.height
end

function MapEditor:isMouseOverUI()
    -- Check if mouse is over the UI panel
    return self:isMouseOver(self.panelX, self.panelY, self.panelWidth, self.panelHeight)
end

function MapEditor:isMouseOverMap()
    -- Check if mouse is over the map area
    return self.gridX >= 1 and self.gridX <= self.width and
           self.gridY >= 1 and self.gridY <= self.height
end

function MapEditor:drawCursorHighlight()
    -- Draw a highlight at the current grid position
    local worldX, worldY = self.grid:gridToWorld(self.gridX, self.gridY)
    
    -- Set color based on selected tool
    if self.selectedTool == "tile" then
        love.graphics.setColor(0.3, 1, 0.3, 0.3)
    elseif self.selectedTool == "entity" then
        love.graphics.setColor(1, 0.3, 0.3, 0.3)
        
        -- For entities, highlight the area they would occupy
        local entityWidth = 1
        local entityHeight = 1
        
        -- Find the selected entity type to get its dimensions
        for _, entity in ipairs(self.entityTypes) do
            if entity.id == self.selectedEntityType then
                entityWidth = entity.width or 1
                entityHeight = entity.height or 1
                break
            end
        end
        
        -- Draw entity footprint
        love.graphics.rectangle("fill", worldX, worldY, 
                               self.tileSize * entityWidth, 
                               self.tileSize * entityHeight)
        
        -- Draw entity border
        love.graphics.setColor(1, 0.5, 0.5, 0.8)
        love.graphics.rectangle("line", worldX, worldY, 
                               self.tileSize * entityWidth, 
                               self.tileSize * entityHeight)
        
        -- Reset color and return early
        love.graphics.setColor(1, 1, 1, 1)
        return
    elseif self.selectedTool == "erase" then
        love.graphics.setColor(1, 1, 0.3, 0.3)
    end
    
    -- Draw highlight
    love.graphics.rectangle("fill", worldX, worldY, self.tileSize, self.tileSize)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", worldX, worldY, self.tileSize, self.tileSize)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end



function MapEditor:showMapBrowser()
    -- Refresh the map list and show the browser
    self.mapBrowser:show()
end

function MapEditor:drawButton(x, y, width, height, text, enabled, isSelected)
    local isHovered = self:isMouseOver(x, y, width, height)
    local isClicked = isHovered and love.mouse.isDown(1) and enabled
    
    -- Set button colors based on state
    if not enabled then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    elseif isSelected then
        love.graphics.setColor(0.3, 0.7, 1, 1)
    elseif isClicked then
        love.graphics.setColor(0.6, 0.6, 0.8, 1)
    elseif isHovered then
        love.graphics.setColor(0.5, 0.5, 0.7, 1)
    else
        love.graphics.setColor(0.4, 0.4, 0.6, 1)
    end
    
    -- Draw button background
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)
    
    -- Draw button border
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)
    
    -- Draw button text
    love.graphics.setFont(self.buttonFont)
    love.graphics.setColor(1, 1, 1, 1)
    
    local textWidth = self.buttonFont:getWidth(text)
    local textHeight = self.buttonFont:getHeight()
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - textHeight) / 2
    
    love.graphics.print(text, textX, textY)
    
    -- Return true if the button was clicked
    return isHovered and love.mouse.isDown(1) and not self.isDragging and enabled
end
function MapEditor:mousereleased(x, y, button)
    if not self.active then return end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        return
    end
    
    if button == 1 then  -- Left click
        self.isDragging = false
    end
end
return MapEditor
