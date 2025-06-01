-- Map Editor
-- A standalone editor for creating and editing maps

local Grid = require("src.core.grid")
local Map = require("src.core.map")
local Tile = require("src.core.tile")
local Furniture = require("src.core.furniture")
local MapBrowser = require("src.editor.mapBrowser")
local TileCreator = require("src.editor.tileCreator")
local EntityComposer = require("src.editor.entityComposer")
local EditorTabs = require("src.editor.editorTabs")

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
    
    -- Initialize tabs
    self.editorTabs = EditorTabs:new()
    
    -- Calculate UI panel dimensions (20% of screen width)
    self.panelWidth = love.graphics.getWidth() * 0.20
    self.panelX = love.graphics.getWidth() * 0.80
    
    -- Track window size for resize handling
    self.lastWindowWidth = love.graphics.getWidth()
    self.lastWindowHeight = love.graphics.getHeight()
    
    -- Zoom and pan settings
    self.zoomLevel = 1.0
    self.minZoom = 0.25
    self.maxZoom = 2.0
    self.zoomStep = 0.1
    self.panX = 0
    self.panY = 0
    self.isPanning = false
    self.lastMouseX = 0
    self.lastMouseY = 0
    
    -- Background color (can be set by the editor mode)
    self.backgroundColor = {0.15, 0.15, 0.2, 1}  -- Darker blue-gray
    
    -- Initialize map browser
    self.mapBrowser = MapBrowser:new()
    
    -- Initialize tile creator and entity composer
    self.tileCreator = TileCreator:new()
    self.entityComposer = EntityComposer:new()
    
    -- Pass the editorTabs reference to the other editors
    self.tileCreator.editorTabs = self.editorTabs
    self.entityComposer.editorTabs = self.editorTabs
    
    -- UI state
    self.selectedTool = "tile"  -- tile, entity, erase, toggle
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
        {id = "couch", name = "Couch", color = {0.8, 0.5, 0.3}, description = "A comfortable couch"},
        {id = "tv", name = "TV", color = {0.2, 0.2, 0.2}, description = "Television"},
        {id = "coffee_table", name = "Coffee Table", color = {0.6, 0.4, 0.2}, description = "Small table"},
        {id = "cupboard", name = "Cupboard", color = {0.5, 0.3, 0.2}, description = "Storage cupboard"},
        {id = "plant", name = "Plant", color = {0.3, 0.7, 0.3}, description = "Decorative plant"},
        {id = "bed", name = "Bed", color = {0.7, 0.7, 0.9}, description = "A bed"},
        {id = "desk", name = "Desk", color = {0.5, 0.4, 0.3}, description = "Work desk"},
        {id = "chair", name = "Chair", color = {0.7, 0.5, 0.3}, description = "Chair"}
    }
    
    -- Entity rotation state
    self.entityRotation = 0 -- 0, 90, 180, or 270 degrees
    
    -- UI elements
    self.buttonSize = 40  -- Smaller buttons for minimalist design
    self.buttonPadding = 6  -- Reduced padding
    -- Panel is already initialized in new() function
    self.panelHeight = love.graphics.getHeight() -- Full height panel
    self.showUI = true  -- Ensure UI is visible by default
    self.panelY = 0  -- Start from the top of the screen
    
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
    
    -- Initialize tile creator and entity composer but keep them inactive
    self.tileCreator:initialize()
    self.tileCreator.active = false
    
    self.entityComposer:initialize()
    self.entityComposer.active = false
    
    print("MapEditor initialized. Tile Creator active: " .. tostring(self.tileCreator.active) .. ", Entity Composer active: " .. tostring(self.entityComposer.active))
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
    
    -- Check if tile creator or entity composer is active
    if self.tileCreator.active then
        self.tileCreator:update(dt)
        return
    end
    
    if self.entityComposer.active then
        self.entityComposer:update(dt)
        return
    end
    
    -- Update panel position on window resize
    local currentWidth = love.graphics.getWidth()
    local currentHeight = love.graphics.getHeight()
    
    if currentWidth ~= self.lastWindowWidth or currentHeight ~= self.lastWindowHeight then
        -- Recalculate panel position
        self.panelWidth = currentWidth * 0.20
        self.panelX = currentWidth * 0.80
        self.panelHeight = currentHeight
        
        -- Update stored window size
        self.lastWindowWidth = currentWidth
        self.lastWindowHeight = currentHeight
    end
    
    -- Get mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    self.mouseX = mouseX
    self.mouseY = mouseY
    
    -- Handle panning with middle mouse button
    if self.isPanning then
        local dx = mouseX - self.lastMouseX
        local dy = mouseY - self.lastMouseY
        
        self.panX = self.panX + dx
        self.panY = self.panY + dy
        self.lastMouseX = mouseX
        self.lastMouseY = mouseY
    end
    
    -- Convert mouse position to grid coordinates (accounting for zoom and pan)
    local worldX = (mouseX - self.panX) / self.zoomLevel
    local worldY = (mouseY - self.panY) / self.zoomLevel
    self.gridX, self.gridY = self.grid:worldToGrid(worldX, worldY)
    
    -- Handle continuous drawing while mouse is held down
    if self.isDragging and self:isMouseOverMap() then
        self:applyTool(self.gridX, self.gridY)
    end
end

function MapEditor:draw()
    if not self.active then return end
    
    -- Draw the background for the entire screen
    love.graphics.setColor(0.93, 0.93, 0.93, 1) -- #eeeeee
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw the tabs at the top
    self.editorTabs:draw()
    
    -- Get the active tab
    local activeTab = self.editorTabs:getActiveTab()
    
    -- Draw the appropriate editor based on the active tab
    if activeTab == "tile" then
        -- Draw tile creator content (without its own background)
        self.tileCreator:draw()
        return
    elseif activeTab == "entity" then
        -- Draw entity composer content (without its own background)
        self.entityComposer:draw()
        return
    end
    
    -- If we get here, we're drawing the map editor tab
    
    -- Get tab height to properly position map container
    local tabHeight = self.editorTabs.tabHeight
    
    -- Define map container (left 80% of screen, starting below tabs)
    local mapContainerWidth = love.graphics.getWidth() * 0.80
    local mapContainerHeight = love.graphics.getHeight() - tabHeight
    local mapContainerY = tabHeight
    
    -- Create a stencil to constrain map rendering to the left 80% of screen below tabs
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", 0, mapContainerY, mapContainerWidth, mapContainerHeight)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    
    -- Apply zoom and pan transformation within the map container
    love.graphics.push()
    love.graphics.translate(self.panX, self.panY + mapContainerY) -- Add tabHeight offset to Y translation
    love.graphics.scale(self.zoomLevel, self.zoomLevel)
    
    -- Draw the map
    self.map:draw()
    
    -- Draw grid if enabled
    if self.showGrid then
        self:drawGrid()
    end
    
    -- Draw cursor highlight
    if self:isMouseOverMap() and not self.mapBrowser.visible then
        self:drawCursorHighlight()
    end
    
    -- Reset transformation for UI elements
    love.graphics.pop()
    
    -- Disable stencil test
    love.graphics.setStencilTest()
    
    -- Draw UI if enabled (not affected by zoom)
    if self.showUI then
        self:drawUI()
    end
    
    -- Draw zoom level indicator
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Zoom: " .. string.format("%.1fx", self.zoomLevel), 10, love.graphics.getHeight() - 30)
    
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
    -- Set panel to full height
    self.panelHeight = love.graphics.getHeight()
    self.panelY = 0
    
    -- Define buttons per row for tile/entity grids based on panel width
    local buttonsPerRow = math.floor((self.panelWidth - 20) / (self.buttonSize + self.buttonPadding))
    if buttonsPerRow < 1 then buttonsPerRow = 1 end
    
    -- Calculate section heights and padding
    local sectionPadding = 15
    
    -- Draw panel background with a modern, minimalist black design
    love.graphics.setColor(0.12, 0.12, 0.12, 0.95) -- Dark gray, almost black
    love.graphics.rectangle("fill", self.panelX, self.panelY, self.panelWidth, self.panelHeight)
    
    -- Subtle separator line
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(self.panelX, 0, self.panelX, self.panelHeight)
    
    -- Set font for title
    love.graphics.setFont(self.titleFont)
    
    -- Draw title with minimalist style
    love.graphics.setColor(1, 1, 1, 1) -- Pure white
    love.graphics.print("MAP EDITOR", self.panelX + 10, self.panelY + 15)
    
    -- TOOLS SECTION
    local y = self.panelY + 50
    
    -- Section header
    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("TOOLS", self.panelX + 10, y)
    y = y + 25
    
    -- Tool buttons
    local toolButtonWidth = 70
    local toolButtonHeight = 30
    local toolButtonSpacing = 10
    
    -- Tile tool
    if self:drawButton(self.panelX + 10, y, toolButtonWidth, toolButtonHeight, "Tile", true, self.selectedTool == "tile") then
        self.selectedTool = "tile"
    end
    
    -- Entity tool
    if self:drawButton(self.panelX + 10 + toolButtonWidth + toolButtonSpacing, y, toolButtonWidth, toolButtonHeight, "Entity", true, self.selectedTool == "entity") then
        self.selectedTool = "entity"
    end
    
    -- Erase tool
    if self:drawButton(self.panelX + 10 + (toolButtonWidth + toolButtonSpacing) * 2, y, toolButtonWidth, toolButtonHeight, "Erase", true, self.selectedTool == "erase") then
        self.selectedTool = "erase"
    end
    
    -- Toggle tool
    y = y + toolButtonHeight + 10
    if self:drawButton(self.panelX + 10, y, toolButtonWidth * 2 + toolButtonSpacing, toolButtonHeight, "Toggle Tile", true, self.selectedTool == "toggle") then
        self.selectedTool = "toggle"
    end
    
    -- Add description for toggle tool when selected
    if self.selectedTool == "toggle" then
        y = y + toolButtonHeight + 10
        love.graphics.setFont(self.labelFont)
        love.graphics.setColor(1, 0.9, 0.6, 1)
        love.graphics.print("Use Toggle to create irregular maps", self.panelX + 10, y)
        y = y + 20
        love.graphics.print("Click to activate/deactivate tiles", self.panelX + 10, y)
        y = y + 25
    else
        y = y + 20
    end
    
    -- TILE/ENTITY SECTION
    if self.selectedTool == "tile" then
        -- Draw tile types section
        love.graphics.setFont(self.labelFont)
        love.graphics.setColor(0.7, 1, 0.7, 1)
        love.graphics.print("TILE TYPES", self.panelX + 10, y)
        y = y + 25
        
        -- Draw tile buttons
        local buttonsPerRow = math.floor((self.panelWidth - 20) / (self.buttonSize + self.buttonPadding))
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = self.panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding + 15)
            
            -- Draw button background
            if self.selectedTileType == tileType.id then
                love.graphics.setColor(0.3, 0.7, 1, 1) -- Highlighted
            else
                love.graphics.setColor(0.4, 0.4, 0.6, 1) -- Normal
            end
            
            -- Check for button click
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) and 
               love.mouse.isDown(1) and not self.isDragging then
                self.selectedTileType = tileType.id
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
            
            -- Draw tile name
            love.graphics.setFont(self.labelFont)
            local labelWidth = self.labelFont:getWidth(tileType.name)
            local labelX = buttonX + (self.buttonSize - labelWidth) / 2
            love.graphics.print(tileType.name, labelX, buttonY + self.buttonSize + 2)
        end
        
        -- Update y position based on tile buttons
        local tileRows = math.ceil(#self.tileTypes / buttonsPerRow)
        y = y + tileRows * (self.buttonSize + self.buttonPadding + 15) + 20
    elseif self.selectedTool == "entity" then
        -- Draw entity types section
        love.graphics.setFont(self.labelFont)
        love.graphics.setColor(1, 0.7, 0.7, 1)
        love.graphics.print("ENTITY TYPES", self.panelX + 10, y)
        y = y + 25
        
        -- Draw entity buttons
        local buttonsPerRow = math.floor((self.panelWidth - 20) / (self.buttonSize + self.buttonPadding))
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = self.panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding + 25)
            
            -- Draw button background
            if self.selectedEntityType == entityType.id then
                love.graphics.setColor(1, 0.5, 0.5, 1) -- Highlighted
            else
                love.graphics.setColor(0.6, 0.4, 0.4, 1) -- Normal
            end
            
            -- Check for button click
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) and 
               love.mouse.isDown(1) and not self.isDragging then
                self.selectedEntityType = entityType.id
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
            
            -- Draw entity name
            love.graphics.setFont(self.labelFont)
            local labelWidth = self.labelFont:getWidth(entityType.name)
            local labelX = buttonX + (self.buttonSize - labelWidth) / 2
            love.graphics.print(entityType.name, labelX, buttonY + self.buttonSize + 2)
            
            -- Draw entity dimensions
            local width, height = self:getEntityDimensions(entityType.id)
            local dimText = width .. "x" .. height
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print(dimText, buttonX, buttonY + self.buttonSize + 15)
        end
        
        -- Update y position based on entity buttons
        local entityRows = math.ceil(#self.entityTypes / buttonsPerRow)
        y = y + entityRows * (self.buttonSize + self.buttonPadding + 25) + 20
    end
    
    -- MAP PROPERTIES SECTION
    y = self.panelHeight - 180
    
    -- Section header
    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("MAP PROPERTIES", self.panelX + 10, y)
    y = y + 25
    
    -- Map name input
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("Name:", self.panelX + 10, y)
    
    -- Draw map name input field
    local inputWidth = self.panelWidth - 20
    local inputHeight = 24
    local inputX = self.panelX + 10
    local inputY = y + 18
    
    -- Input background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8) -- Dark background
    love.graphics.rectangle("fill", inputX, inputY, inputWidth, inputHeight, 2, 2)
    
    -- Input border (highlighted if active)
    if self.isEditingMapName then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Bright border when active
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8) -- Subtle border when inactive
    end
    love.graphics.rectangle("line", inputX, inputY, inputWidth, inputHeight, 2, 2)
    
    -- Input text
    love.graphics.setColor(1, 1, 1, 0.9) -- White text
    if self.isEditingMapName then
        love.graphics.print(self.mapNameInput .. "_", inputX + 5, inputY + 4)
    else
        love.graphics.print(self.mapName, inputX + 5, inputY + 4)
    end
    
    -- Map dimensions
    y = inputY + inputHeight + 20
    
    -- Width and height labels
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("Width:", self.panelX + 10, y)
    love.graphics.print("Height:", self.panelX + (self.panelWidth/2), y)
    
    -- Width input
    local dimensionInputWidth = (self.panelWidth / 2) - 20
    local dimensionInputX = self.panelX + 10
    local dimensionInputY = y + 18
    
    -- Width input background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", dimensionInputX, dimensionInputY, dimensionInputWidth, inputHeight, 2, 2)
    
    -- Width input border
    if self.isEditingWidth then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Bright border when active
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8) -- Subtle border when inactive
    end
    love.graphics.rectangle("line", dimensionInputX, dimensionInputY, dimensionInputWidth, inputHeight, 2, 2)
    
    -- Width input text
    love.graphics.setColor(1, 1, 1, 0.9)
    if self.isEditingWidth then
        love.graphics.print(self.widthInput .. "_", dimensionInputX + 5, dimensionInputY + 4)
    else
        love.graphics.print(self.width, dimensionInputX + 5, dimensionInputY + 4)
    end
    
    -- Height input
    local heightInputX = self.panelX + (self.panelWidth/2)
    
    -- Height input background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", heightInputX, dimensionInputY, dimensionInputWidth, inputHeight, 2, 2)
    
    -- Height input border
    if self.isEditingHeight then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Bright border when active
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8) -- Subtle border when inactive
    end
    love.graphics.rectangle("line", heightInputX, dimensionInputY, dimensionInputWidth, inputHeight, 2, 2)
    
    -- Height input text
    love.graphics.setColor(1, 1, 1, 0.9)
    if self.isEditingHeight then
        love.graphics.print(self.heightInput .. "_", heightInputX + 5, dimensionInputY + 4)
    else
        love.graphics.print(self.height, heightInputX + 5, dimensionInputY + 4)
    end
    
    -- End of top section
    local topSectionEnd = dimensionInputY + inputHeight + sectionPadding
    
    -- MIDDLE SECTION: Tool selection
    y = topSectionEnd
    
    -- Section divider
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.line(self.panelX + 10, y, self.panelX + self.panelWidth - 10, y)
    y = y + 10
    
    -- Section header
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("TOOLS", self.panelX + 10, y)
    y = y + 25
    
    -- Tool buttons
    local toolButtonWidth = (self.panelWidth - 30) / 2
    local toolButtonHeight = 30
    local toolButtonSpacing = 10
    
    -- Tile tool button
    if self.selectedTool == "tile" then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.9) -- Selected
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7) -- Normal
    end
    love.graphics.rectangle("fill", self.panelX + 10, y, toolButtonWidth, toolButtonHeight, 2, 2)
    
    -- Entity tool button
    if self.selectedTool == "entity" then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.9) -- Selected
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7) -- Normal
    end
    love.graphics.rectangle("fill", self.panelX + 10 + toolButtonWidth + toolButtonSpacing, y, toolButtonWidth, toolButtonHeight, 2, 2)
    
    -- Tool button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("TILES", self.panelX + 10 + (toolButtonWidth - self.labelFont:getWidth("TILES")) / 2, y + 8)
    love.graphics.print("ENTITIES", self.panelX + 10 + toolButtonWidth + toolButtonSpacing + (toolButtonWidth - self.labelFont:getWidth("ENTITIES")) / 2, y + 8)
    
    -- BOTTOM SECTION: Tile/Entity selection based on selected tool
    y = y + toolButtonHeight + 20
    
    -- Section header
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    if self.selectedTool == "tile" then
        love.graphics.print("TILE TYPES", self.panelX + 10, y)
    else
        love.graphics.print("ENTITY TYPES", self.panelX + 10, y)
    end
    y = y + 25
    
    -- Display tile or entity buttons based on selected tool
    if self.selectedTool == "tile" then
        -- Tile buttons
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = self.panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding + 15)
            
            -- Button background
            if self.selectedTileType == tileType.id then
                love.graphics.setColor(0.6, 0.6, 0.6, 0.9) -- Selected
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 0.7) -- Normal
            end
            love.graphics.rectangle("fill", buttonX, buttonY, self.buttonSize, self.buttonSize, 2, 2)
            
            -- Draw tile preview
            love.graphics.setColor(1, 1, 1, 1)
            if self.tilePreviews[tileType.id] then
                love.graphics.draw(self.tilePreviews[tileType.id], buttonX, buttonY)
            end
            
            -- Draw tile name below the preview
            love.graphics.setFont(self.labelFont)
            local nameWidth = self.labelFont:getWidth(tileType.name)
            local maxWidth = self.buttonSize
            if nameWidth > maxWidth then
                -- Truncate name if too long
                local truncatedName = tileType.name:sub(1, 5) .. "..."
                love.graphics.print(truncatedName, buttonX, buttonY + self.buttonSize + 2)
            else
                love.graphics.print(tileType.name, buttonX, buttonY + self.buttonSize + 2)
            end
        end
    else
        -- Entity buttons
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = self.panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding + 15)
            
            -- Button background
            if self.selectedEntityType == entityType.id then
                love.graphics.setColor(0.6, 0.6, 0.6, 0.9) -- Selected
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 0.7) -- Normal
            end
            love.graphics.rectangle("fill", buttonX, buttonY, self.buttonSize, self.buttonSize, 2, 2)
            
            -- Draw entity preview
            love.graphics.setColor(1, 1, 1, 1)
            if self.entityPreviews[entityType.id] then
                love.graphics.draw(self.entityPreviews[entityType.id], buttonX, buttonY)
            end
            
            -- Draw entity name below the preview
            love.graphics.setFont(self.labelFont)
            local nameWidth = self.labelFont:getWidth(entityType.name)
            local maxWidth = self.buttonSize
            if nameWidth > maxWidth then
                -- Truncate name if too long
                local truncatedName = entityType.name:sub(1, 5) .. "..."
                love.graphics.print(truncatedName, buttonX, buttonY + self.buttonSize + 2)
            else
                love.graphics.print(entityType.name, buttonX, buttonY + self.buttonSize + 2)
            end
            
            -- Draw entity dimensions
            local width, height = self:getEntityDimensions(entityType.id)
            local dimText = width .. "x" .. height
            love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
            love.graphics.print(dimText, buttonX, buttonY + self.buttonSize + 15)
        end
    end
    
    -- Draw map name input field
    y = self.panelHeight - 120
    
    love.graphics.setFont(self.labelFont)
    local x = self.panelX + 20  -- Define x here
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
    
    -- Draw map dimensions
    y = y + 35
    
    love.graphics.print("Width:", x, y)
    love.graphics.print("Height:", x + (self.panelWidth / 2), y)
    
    -- Width input
    local dimensionInputWidth = (self.panelWidth / 2) - 20
    local dimensionInputX = x
    local dimensionInputY = y + 18
    
    -- Width input background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", dimensionInputX, dimensionInputY, dimensionInputWidth, 25, 2, 2)
    
    -- Width input border
    if self.isEditingWidth then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Bright border when active
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8) -- Subtle border when inactive
    end
    love.graphics.rectangle("line", dimensionInputX, dimensionInputY, dimensionInputWidth, 25, 2, 2)
    
    -- Width input text
    love.graphics.setColor(1, 1, 1, 0.9)
    if self.isEditingWidth then
        love.graphics.print(self.widthInput .. "_", dimensionInputX + 5, dimensionInputY + 5)
    else
        love.graphics.print(self.width, dimensionInputX + 5, dimensionInputY + 5)
    end
    
    -- Height input
    local heightInputX = x + (self.panelWidth / 2)
    
    -- Height input background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", heightInputX, dimensionInputY, dimensionInputWidth, 25, 2, 2)
    
    -- Height input border
    if self.isEditingHeight then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Bright border when active
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8) -- Subtle border when inactive
    end
    love.graphics.rectangle("line", heightInputX, dimensionInputY, dimensionInputWidth, 25, 2, 2)
    
    -- Height input text
    love.graphics.setColor(1, 1, 1, 0.9)
    if self.isEditingHeight then
        love.graphics.print(self.heightInput .. "_", heightInputX + 5, dimensionInputY + 5)
    else
        love.graphics.print(self.height, heightInputX + 5, dimensionInputY + 5)
    end
    
    -- Draw creator buttons
    y = self.panelHeight - 100
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("CREATORS", x, y - 20)
    
    -- Store button positions for click detection in mousepressed
    self.tileButtonX = x
    self.tileButtonY = y
    self.tileButtonWidth = 80
    self.tileButtonHeight = 30
    
    -- Create Tile button - make it more visible with a distinct color
    love.graphics.setColor(0.3, 0.7, 0.3, 1) -- Green background for better visibility
    love.graphics.rectangle("fill", self.tileButtonX, self.tileButtonY, self.tileButtonWidth, self.tileButtonHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.tileButtonX, self.tileButtonY, self.tileButtonWidth, self.tileButtonHeight)
    
    -- Highlight on hover
    if self:isMouseOver(self.tileButtonX, self.tileButtonY, self.tileButtonWidth, self.tileButtonHeight) then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", self.tileButtonX, self.tileButtonY, self.tileButtonWidth, self.tileButtonHeight)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    local tileText = "New Tile"
    local tileTextWidth = self.buttonFont:getWidth(tileText)
    love.graphics.print(tileText, self.tileButtonX + (self.tileButtonWidth - tileTextWidth) / 2, self.tileButtonY + 5)
    
    -- Store entity button positions for click detection in mousepressed
    self.entityButtonX = x + 90
    self.entityButtonY = y
    self.entityButtonWidth = 80
    self.entityButtonHeight = 30
    
    -- Create Entity button - make it more visible with a distinct color
    love.graphics.setColor(0.7, 0.3, 0.3, 1) -- Red background for better visibility
    love.graphics.rectangle("fill", self.entityButtonX, self.entityButtonY, self.entityButtonWidth, self.entityButtonHeight)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.entityButtonX, self.entityButtonY, self.entityButtonWidth, self.entityButtonHeight)
    
    -- Highlight on hover
    if self:isMouseOver(self.entityButtonX, self.entityButtonY, self.entityButtonWidth, self.entityButtonHeight) then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", self.entityButtonX, self.entityButtonY, self.entityButtonWidth, self.entityButtonHeight)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    local entityText = "New Entity"
    local entityTextWidth = self.buttonFont:getWidth(entityText)
    love.graphics.print(entityText, self.entityButtonX + (self.entityButtonWidth - entityTextWidth) / 2, self.entityButtonY + 5)
    
    -- Draw save/load buttons
    y = self.panelHeight - 60
    
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

-- Get entity dimensions from the furniture module
function MapEditor:getEntityDimensions(entityType)
    -- Create a temporary entity to get its dimensions
    local tempEntity = Furniture.create(entityType, self.grid, 1, 1)
    if tempEntity then
        local width = tempEntity.width or 1
        local height = tempEntity.height or 1
        return width, height
    end
    return 1, 1  -- Default to 1x1 if entity type not found
end

-- Rotate the current entity dimensions
function MapEditor:rotateEntity()
    -- Rotate by 90 degrees clockwise
    self.entityRotation = (self.entityRotation + 90) % 360
    print("Entity rotated to " .. self.entityRotation .. " degrees")
end

-- Get rotated entity dimensions
function MapEditor:getRotatedEntityDimensions(entityType)
    local width, height = self:getEntityDimensions(entityType)
    
    -- If rotation is 90 or 270 degrees, swap width and height
    if self.entityRotation == 90 or self.entityRotation == 270 then
        return height, width
    end
    
    return width, height
end

-- Apply rotation to an entity
function MapEditor:applyRotationToEntity(entity)
    if entity and self.entityRotation > 0 then
        entity.rotation = self.entityRotation
        
        -- If rotation is 90 or 270 degrees, swap width and height
        if self.entityRotation == 90 or self.entityRotation == 270 then
            local temp = entity.width
            entity.width = entity.height
            entity.height = temp
        end
    end
    
    return entity
end

function MapEditor:mousepressed(x, y, button)
    if not self.active then return end
    
    -- Check if tile creator or entity composer is active
    if self.tileCreator.active then
        local tabClicked = self.tileCreator:mousepressed(x, y, button)
        if tabClicked then
            self:handleTabClick(tabClicked)
        end
        return
    end
    
    if self.entityComposer.active then
        local tabClicked = self.entityComposer:mousepressed(x, y, button)
        if tabClicked then
            self:handleTabClick(tabClicked)
        end
        return
    end
    
    -- Handle tab clicks first
    local selectedTab = self.editorTabs:mousepressed(x, y, button)
    if selectedTab then
        print("Selected tab: " .. selectedTab)
        
        -- Update active state based on selected tab
        self.tileCreator.active = (selectedTab == "tile")
        self.entityComposer.active = (selectedTab == "entity")
        
        -- Initialize the selected editor if needed
        if selectedTab == "tile" then
            self.tileCreator:initialize()
        elseif selectedTab == "entity" then
            self.entityComposer:initialize()
        end
        
        return
    end
    
    -- Get the active tab
    local activeTab = self.editorTabs:getActiveTab()
    
    -- Handle mouse events based on the active tab
    if activeTab == "tile" then
        self.tileCreator:mousepressed(x, y, button)
        return
    elseif activeTab == "entity" then
        self.entityComposer:mousepressed(x, y, button)
        return
    end
    
    -- Check for UI panel button clicks
    if button == 1 then -- Left click
        -- Check if clicked on the tile creator button
        if self.tileButtonX and self:isMouseOver(self.tileButtonX, self.tileButtonY, self.tileButtonWidth, self.tileButtonHeight) then
            print("Tile Creator button clicked")
            self.editorTabs:setActiveTab("tile")
            self.tileCreator.active = true
            self.entityComposer.active = false
            self.tileCreator:initialize()
            return
        end
        
        -- Check if clicked on the entity composer button
        if self.entityButtonX and self:isMouseOver(self.entityButtonX, self.entityButtonY, self.entityButtonWidth, self.entityButtonHeight) then
            print("Entity Composer button clicked")
            self.editorTabs:setActiveTab("entity")
            self.tileCreator.active = false
            self.entityComposer.active = true
            self.entityComposer:initialize()
            return
        end
    end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        local result = self.mapBrowser:mousepressed(x, y, button)
        if result == "load" then
            self:loadMap()
        end
        return
    end
    
    -- Store mouse position for panning
    self.mouseX, self.mouseY = x, y
    
    if button == 1 then  -- Left click
        -- Check if clicking on UI
        if self:isMouseOverUI() then
            self:handleUIClick(x, y)
        elseif self:isMouseOverMap() then
            -- Start dragging
            self.isDragging = true
            -- Apply tool immediately
            self:applyTool(self.gridX, self.gridY)
        end
    elseif button == 2 then  -- Right click
        -- Rotate entity if in entity placement mode
        if self.selectedTool == "entity" then
            self:rotateEntity()
        end
    elseif button == 3 then  -- Middle mouse button
        -- Start panning
        self.isPanning = true
        self.lastMouseX = x
        self.lastMouseY = y
    elseif button == 4 then  -- Mouse wheel button (if available)
        -- Reset zoom and pan
        self.zoomLevel = 1.0
        self.panX = 0
        self.panY = 0
    end
end

function MapEditor:keypressed(key)
    if not self.active then return end
    
    -- Handle tile creator keypresses if it's active
    if self.tileCreator.active then
        self.tileCreator:keypressed(key)
        return
    end
    
    -- Handle entity composer keypresses if it's active
    if self.entityComposer.active then
        self.entityComposer:keypressed(key)
        return
    end
    
    -- Handle map browser keypresses if it's visible
    if self.mapBrowser.visible then
        self.mapBrowser:keypressed(key)
        return
    end
    
    if key == "escape" then
        -- Cancel any active editing
        if self.isEditingMapName then
            self.isEditingMapName = false
        elseif self.isEditingWidth then
            self.isEditingWidth = false
        elseif self.isEditingHeight then
            self.isEditingHeight = false
        end
    elseif key == "tab" then
        -- Tab navigation between input fields
        if self.isEditingMapName then
            -- Apply current changes
            self.mapName = self.mapNameInput
            self.isEditingMapName = false
            -- Move to width field
            self.isEditingWidth = true
            self.widthInput = tostring(self.width)
        elseif self.isEditingWidth then
            -- Apply current changes
            local newWidth = tonumber(self.widthInput)
            if newWidth and newWidth >= 5 and newWidth <= 50 then
                self.width = newWidth
                self:resizeMap(self.width, self.height)
            end
            self.isEditingWidth = false
            -- Move to height field
            self.isEditingHeight = true
            self.heightInput = tostring(self.height)
        elseif self.isEditingHeight then
            -- Apply current changes
            local newHeight = tonumber(self.heightInput)
            if newHeight and newHeight >= 5 and newHeight <= 50 then
                self.height = newHeight
                self:resizeMap(self.width, self.height)
            end
            self.isEditingHeight = false
            -- Move back to map name field
            self.isEditingMapName = true
            self.mapNameInput = self.mapName
        else
            -- If no field is active, start with map name
            self.isEditingMapName = true
            self.mapNameInput = self.mapName
        end
    elseif key == "backspace" then
        if self.isEditingMapName then
            self.mapNameInput = self.mapNameInput:sub(1, -2)
        elseif self.isEditingWidth then
            self.widthInput = self.widthInput:sub(1, -2)
        elseif self.isEditingHeight then
            self.heightInput = self.heightInput:sub(1, -2)
        end
    elseif key:match("^[0-9]$") then
        if self.isEditingWidth then
            self.widthInput = self.widthInput .. key
        elseif self.isEditingHeight then
            self.heightInput = self.heightInput .. key
        end
        return
    end
    
    -- Toggle grid visibility with G key
    if key == "g" then
        self.showGrid = not self.showGrid
    end
    
    -- Toggle UI visibility with U key
    if key == "u" then
        self.showUI = not self.showUI
    end
    
    -- Reset zoom and pan with R key
    if key == "r" then
        self.zoomLevel = 1.0
        self.panX = 0
        self.panY = 0
    end
    
    -- Toggle panning mode with P key
    if key == "p" then
        self.isPanning = not self.isPanning
        if self.isPanning then
            -- Store current mouse position for panning
            self.lastMouseX, self.lastMouseY = love.mouse.getPosition()
            print("Panning mode enabled - Move mouse to pan")
        else
            print("Panning mode disabled")
        end
    end
    
    -- Global keyboard shortcuts
    if key == "s" and love.keyboard.isDown("lctrl") then
        -- Ctrl+S to save
        self:saveMap()
    elseif key == "l" and love.keyboard.isDown("lctrl") then
        -- Ctrl+L to load
        self:showMapBrowser()
    end
    
    -- F2 toggles between editor mode and game mode
    if key == "f2" then
        -- Toggle editor mode on/off (return to game)
        self.active = false
        print("F2 pressed: Returning to game")
        return
    end
    
    -- Handle tab key to cycle through editor modes
    if key == "tab" then
        local activeTab = self.editorTabs:getActiveTab()
        
        if activeTab == "map" then
            self:handleTabClick("tile")
        elseif activeTab == "tile" then
            self:handleTabClick("entity")
        elseif activeTab == "entity" then
            self:handleTabClick("map")
        end
        print("Tab pressed: Active tab: " .. self.editorTabs:getActiveTab())
    end
end
-- Handle tab clicks and switching between editors
function MapEditor:handleTabClick(tabId)
    -- Update the active tab in the editor tabs
    self.editorTabs:setActiveTab(tabId)
    
    -- Activate/deactivate the appropriate editors based on the tab
    if tabId == "map" then
        -- Activate map editor, deactivate others
        self.tileCreator.active = false
        self.entityComposer.active = false
    elseif tabId == "tile" then
        -- Activate tile creator, deactivate others
        self.tileCreator.active = true
        self.entityComposer.active = false
        -- Initialize tile creator if needed
        if not self.tileCreator.grid then
            self.tileCreator:initialize()
        end
    elseif tabId == "entity" then
        -- Activate entity composer, deactivate others
        self.tileCreator.active = false
        self.entityComposer.active = true
        -- Initialize entity composer if needed
        if not self.entityComposer.grid then
            self.entityComposer:initialize()
        end
    end
    
    print("Switched to tab: " .. tabId)
end

function MapEditor:textinput(text)
    if not self.active then return end
    
    -- Get the active tab
    local activeTab = self.editorTabs:getActiveTab()
    
    -- Handle text input based on the active tab
    if activeTab == "tile" then
        self.tileCreator:textinput(text)
        return
    elseif activeTab == "entity" then
        self.entityComposer:textinput(text)
        return
    end
    
    -- Handle map browser text input if it's visible
    if self.mapBrowser.visible then
        return
    end
    
    -- Handle map name editing
    if self.isEditingMapName then
        self.mapNameInput = self.mapNameInput .. text
        print("Map name input: " .. self.mapNameInput)
    end
    
    -- Handle width editing
    if self.isEditingWidth then
        -- Only allow digits
        if text:match("^%d$") then
            self.widthInput = self.widthInput .. text
            print("Width input: " .. self.widthInput)
        end
    end
    
    -- Handle height editing
    if self.isEditingHeight then
        -- Only allow digits
        if text:match("^%d$") then
            self.heightInput = self.heightInput .. text
            print("Height input: " .. self.heightInput)
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
                -- Apply rotation to the entity
                self:applyRotationToEntity(entity)
                
                -- Check if the entity can be placed here
                if self.map:canPlaceEntity(entity) then
                    self.map:addEntity(entity)
                    print("Placed entity: " .. entityType .. " at " .. gridX .. "," .. gridY .. " with rotation " .. self.entityRotation)
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
    elseif self.selectedTool == "toggle" then
        -- Toggle tile activation for irregular maps
        self.map:toggleTileActive(gridX, gridY)
        local isActive = self.map:isTileActive(gridX, gridY)
        if isActive then
            print("Activated tile at " .. gridX .. "," .. gridY)
        else
            print("Deactivated tile at " .. gridX .. "," .. gridY)
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
    if self.selectedTool == "toggle" then
        -- For toggle tool, show red for deactivating and green for activating
        if self.map:isTileActive(self.gridX, self.gridY) then
            love.graphics.setColor(1, 0.3, 0.3, 0.5)  -- Red for deactivating
        else
            love.graphics.setColor(0.3, 1, 0.3, 0.5)  -- Green for activating
        end
        
        -- Draw tile highlight
        love.graphics.rectangle("fill", worldX, worldY, self.tileSize, self.tileSize)
        
        -- Draw border
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.rectangle("line", worldX, worldY, self.tileSize, self.tileSize)
    elseif self.selectedTool == "tile" then
        love.graphics.setColor(0.3, 1, 0.3, 0.3)
        love.graphics.rectangle("fill", worldX, worldY, self.tileSize, self.tileSize)
        
        -- Draw border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", worldX, worldY, self.tileSize, self.tileSize)
    elseif self.selectedTool == "entity" then
        love.graphics.setColor(1, 0.3, 0.3, 0.3)
        
        -- For entities, highlight the area they would occupy
        local entityWidth = 1
        local entityHeight = 1
        
        -- Get the entity dimensions from the furniture module and apply rotation
        if self.selectedEntityType then
            entityWidth, entityHeight = self:getRotatedEntityDimensions(self.selectedEntityType)
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
    elseif self.selectedTool == "erase" then
        love.graphics.setColor(1, 1, 0.3, 0.3)
        love.graphics.rectangle("fill", worldX, worldY, self.tileSize, self.tileSize)
        
        -- Draw border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", worldX, worldY, self.tileSize, self.tileSize)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function MapEditor:showMapBrowser()
    -- Refresh the map list and show the browser
    self.mapBrowser:show()
end

function MapEditor:showTileCreator()
    -- Show the tile creator screen and hide others
    self.tileCreator.active = true
    self.entityComposer.active = false
    print("Showing Tile Creator. Tile Creator active: " .. tostring(self.tileCreator.active) .. ", Entity Composer active: " .. tostring(self.entityComposer.active))
end

function MapEditor:showEntityComposer()
    -- Show the entity composer screen and hide others
    self.entityComposer.active = true
    self.tileCreator.active = false
    print("Showing Entity Composer. Tile Creator active: " .. tostring(self.tileCreator.active) .. ", Entity Composer active: " .. tostring(self.entityComposer.active))
end

function MapEditor:drawButton(x, y, width, height, text, enabled, isSelected)
    local isHovered = self:isMouseOver(x, y, width, height)
    local isClicked = isHovered and love.mouse.isDown(1) and enabled
    
    -- Set button colors based on state - minimalist black and white design
    if not enabled then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5) -- Dark gray, disabled
    elseif isSelected then
        love.graphics.setColor(1, 1, 1, 0.9) -- White for selected
    elseif isClicked then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Light gray when clicked
    elseif isHovered then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.8) -- Medium gray when hovered
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7) -- Dark gray normally
    end
    
    -- Draw button background - flat design with subtle rounded corners
    love.graphics.rectangle("fill", x, y, width, height, 2, 2)
    
    -- Only draw border for selected or hovered buttons
    if isSelected or isHovered then
        love.graphics.setColor(1, 1, 1, 0.5) -- Subtle white border
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x, y, width, height, 2, 2)
    end
    
    -- Draw button text - white for selected/hovered, light gray otherwise
    love.graphics.setFont(self.buttonFont)
    
    if isSelected or isHovered then
        love.graphics.setColor(1, 1, 1, 1) -- Pure white for selected/hovered
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 0.9) -- Light gray otherwise
    end
    
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
    
    -- Get the active tab
    local activeTab = self.editorTabs:getActiveTab()
    
    -- Handle mouse events based on the active tab
    if activeTab == "tile" then
        self.tileCreator:mousereleased(x, y, button)
        return
    elseif activeTab == "entity" then
        self.entityComposer:mousereleased(x, y, button)
        return
    end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        return
    end
    
    if button == 1 then  -- Left click
        self.isDragging = false
    elseif button == 3 then  -- Middle mouse button
        self.isPanning = false
    end
end

function MapEditor:wheelmoved(x, y)
    if not self.active then return end
    
    -- Handle tile creator if it's active
    if self.tileCreator.active then
        -- Pass wheel events to tile creator if needed
        return
    end
    
    -- Handle entity composer if it's active
    if self.entityComposer.active then
        -- Pass wheel events to entity composer if needed
        return
    end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        return
    end
    
    -- Don't zoom if mouse is over UI
    if self:isMouseOverUI() then
        return
    end
    
    -- Get mouse position before zoom for centering
    local mouseX, mouseY = love.mouse.getPosition()
    local worldX = (mouseX - self.panX) / self.zoomLevel
    local worldY = (mouseY - self.panY) / self.zoomLevel
    
    -- Adjust zoom level based on wheel movement
    local oldZoom = self.zoomLevel
    if y > 0 then
        -- Zoom in
        self.zoomLevel = math.min(self.maxZoom, self.zoomLevel + self.zoomStep)
    elseif y < 0 then
        -- Zoom out
        self.zoomLevel = math.max(self.minZoom, self.zoomLevel - self.zoomStep)
    end
    
    -- Adjust pan to keep the point under the cursor in the same position
    if oldZoom ~= self.zoomLevel then
        local newWorldX = (mouseX - self.panX) / self.zoomLevel
        local newWorldY = (mouseY - self.panY) / self.zoomLevel
        
        self.panX = self.panX - (newWorldX - worldX) * self.zoomLevel
        self.panY = self.panY - (newWorldY - worldY) * self.zoomLevel
    end
end
function MapEditor:handleUIClick(x, y)
    -- Get UI panel coordinates
    local panelX = self.panelX
    local panelY = self.panelY
    
    -- Reset all editing states
    self.isEditingMapName = false
    self.isEditingWidth = false
    self.isEditingHeight = false
    
    -- Handle tool selection buttons
    local toolsY = panelY + 75 -- Position of tools section (after title and section header)
    local toolButtonWidth = 70
    local toolButtonHeight = 30
    local toolButtonSpacing = 10
    
    -- Tile tool
    if self:isMouseOver(panelX + 10, toolsY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "tile"
        print("Selected tool: tile")
        return
    end
    
    -- Entity tool
    if self:isMouseOver(panelX + 10 + toolButtonWidth + toolButtonSpacing, toolsY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "entity"
        print("Selected tool: entity")
        return
    end
    
    -- Erase tool
    if self:isMouseOver(panelX + 10 + (toolButtonWidth + toolButtonSpacing) * 2, toolsY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "erase"
        print("Selected tool: erase")
        return
    end
    
    -- Toggle tool
    local toggleY = toolsY + toolButtonHeight + 10
    if self:isMouseOver(panelX + 10, toggleY, toolButtonWidth * 2 + toolButtonSpacing, toolButtonHeight) then
        self.selectedTool = "toggle"
        return
    end
    
    -- Handle tile/entity type selection
    local typesY = toggleY + toolButtonHeight + 10
    if self.selectedTool == "toggle" then
        typesY = typesY + 40 -- Add space for toggle tool description
    end
    typesY = typesY + 25 -- Add space for section title
    
    local buttonsPerRow = math.floor((self.panelWidth - 20) / (self.buttonSize + self.buttonPadding))
    
    if self.selectedTool == "tile" then
        -- Handle tile type selection
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = typesY + row * (self.buttonSize + self.buttonPadding + 15)
            
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) then
                self.selectedTileType = tileType.id
                return
            end
        end
    elseif self.selectedTool == "entity" then
        -- Handle entity type selection
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = panelX + 10 + col * (self.buttonSize + self.buttonPadding)
            local buttonY = typesY + row * (self.buttonSize + self.buttonPadding + 25)
            
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) then
                self.selectedEntityType = entityType.id
                -- Reset rotation when selecting a new entity
                self.entityRotation = 0
                return
            end
        end
    end
    
    -- Handle map name and dimensions input fields at the bottom of the panel
    local mapNameY = self.panelHeight - 120
    
    -- Handle map name input field
    if self:isMouseOver(panelX + 10, mapNameY + 18, self.panelWidth - 20, 25) then
        self.isEditingMapName = true
        self.mapNameInput = self.mapName
        print("Editing map name: " .. self.mapName)
        return
    end
    
    -- Calculate position of width/height inputs
    local dimensionInputY = mapNameY + 70
    local dimensionInputWidth = (self.panelWidth / 2) - 20
    
    -- Handle width input field
    if self:isMouseOver(panelX + 10, dimensionInputY, dimensionInputWidth, 25) then
        self.isEditingWidth = true
        self.widthInput = tostring(self.width)
        print("Editing width: " .. self.width)
        return
    end
    
    -- Handle height input field
    local heightInputX = panelX + (self.panelWidth/2)
    if self:isMouseOver(heightInputX, dimensionInputY, dimensionInputWidth, 25) then
        self.isEditingHeight = true
        self.heightInput = tostring(self.height)
        print("Editing height: " .. self.height)
        return
    end
    
    -- Calculate position of creator buttons
    local creatorY = self.panelHeight - 100
    
    -- Handle new tile button
    if self:isMouseOver(panelX + 10, creatorY, 80, 30) then
        self:showTileCreator()
        return
    end
    
    -- Handle new entity button
    if self:isMouseOver(panelX + 100, creatorY, 80, 30) then
        self:showEntityComposer()
        return
    end
    
    -- Calculate position of save/load buttons at the bottom of the panel
    local saveLoadY = self.panelHeight - 60
    
    -- Handle save button
    if self:isMouseOver(panelX + 10, saveLoadY, 80, 30) then
        self:saveMap()
        return
    end
    
    -- Handle load button
    if self:isMouseOver(panelX + 100, saveLoadY, 80, 30) then
        self:showMapBrowser()
        return
    end
end
-- Mouse interaction functions for the MapEditor class

-- Check if mouse is over a rectangle
function MapEditor:isMouseOver(x, y, width, height)
    return self.mouseX >= x and self.mouseX <= x + width and
           self.mouseY >= y and self.mouseY <= y + height
end

-- Check if position is valid on the grid
function MapEditor:isValidGridPosition(gridX, gridY)
    return gridX >= 1 and gridX <= self.width and
           gridY >= 1 and gridY <= self.height
end

-- Check if mouse is over the UI panel
function MapEditor:isMouseOverUI()
    -- Check if mouse is over the UI panel (right 20% of screen)
    local mx, my = love.mouse.getPosition()
    local panelX = love.graphics.getWidth() * 0.80
    
    -- Mouse is over UI if it's in the right 20% of the screen
    return mx >= panelX
end

-- Check if mouse is over the map area
function MapEditor:isMouseOverMap()
    -- First check if mouse is within the map container (left 80% of screen, below tabs)
    local mx, my = love.mouse.getPosition()
    local mapContainerWidth = love.graphics.getWidth() * 0.80
    local tabHeight = self.editorTabs.tabHeight
    
    -- Only consider mouse over map if it's within the left 80% of the screen,
    -- below the tab bar, and within the valid grid coordinates
    return mx < mapContainerWidth and my > tabHeight and
           self.gridX >= 1 and self.gridX <= self.width and
           self.gridY >= 1 and self.gridY <= self.height
end

return MapEditor
