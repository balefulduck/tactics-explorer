-- Map Editor
-- A simple editor for creating and editing maps

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
    
    -- Available tile types
    self.tileTypes = {
        "floor",
        "wall",
        "window", -- Special wall type with isWindow=true
        "water",
        "grass"
    }
    
    -- Available entity types
    self.entityTypes = {
        "couch",
        "tv",
        "coffee_table",
        "cupboard",
        "plant",
        "bed",
        "desk",
        "chair"
    }
    
    -- UI elements
    self.buttonSize = 40
    self.buttonPadding = 10
    self.panelWidth = 200
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
    
    -- Create fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 18)
    self.buttonFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Medium.ttf", 14)
    self.labelFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12)
    
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
    
    -- Minus button
    if self:drawButton(x + 50, y, 20, 20, "-", self.width > 5) then
        if self.width > 5 then
            self.width = self.width - 1
            self:initialize()
        end
    end
    
    -- Plus button
    if self:drawButton(x + 80, y, 20, 20, "+", self.width < 30) then
        if self.width < 30 then
            self.width = self.width + 1
            self:initialize()
        end
    end
    
    y = y + 25
    
    -- Height controls
    love.graphics.print("Height:", x, y)
    
    -- Minus button
    if self:drawButton(x + 50, y, 20, 20, "-", self.height > 5) then
        if self.height > 5 then
            self.height = self.height - 1
            self:initialize()
        end
    end
    
    -- Plus button
    if self:drawButton(x + 80, y, 20, 20, "+", self.height < 30) then
        if self.height < 30 then
            self.height = self.height + 1
            self:initialize()
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
        
        -- Tile type buttons
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = x + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding)
            local isSelected = self.selectedTileType == tileType
            
            if self:drawButton(buttonX, buttonY, self.buttonSize, self.buttonSize, tileType:sub(1,1):upper(), true, isSelected) then
                self.selectedTileType = tileType
            end
        end
        
        y = y + tileRows * (self.buttonSize + self.buttonPadding) + self.buttonPadding
    end
    
    -- Draw entity types section if entity tool is selected
    if self.selectedTool == "entity" then
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(1, 0.7, 0.7, 1)
        love.graphics.print("Entity Types", x, y)
        y = y + self.titleFont:getHeight() + 5
        
        -- Entity type buttons
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            local buttonX = x + col * (self.buttonSize + self.buttonPadding)
            local buttonY = y + row * (self.buttonSize + self.buttonPadding)
            local isSelected = self.selectedEntityType == entityType
            
            if self:drawButton(buttonX, buttonY, self.buttonSize, self.buttonSize, entityType:sub(1,1):upper(), true, isSelected) then
                self.selectedEntityType = entityType
            end
        end
        
        y = y + entityRows * (self.buttonSize + self.buttonPadding) + self.buttonPadding
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

function MapEditor:drawCursorHighlight()
    -- Draw a highlight at the current grid position
    local worldX, worldY = self.grid:gridToWorld(self.gridX, self.gridY)
    
    -- Set color based on selected tool
    if self.selectedTool == "tile" then
        love.graphics.setColor(0.3, 1, 0.3, 0.3)
    elseif self.selectedTool == "entity" then
        love.graphics.setColor(1, 0.3, 0.3, 0.3)
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

function MapEditor:mousepressed(x, y, button)
    if not self.active then return end
    
    -- Handle map browser clicks if it's visible
    if self.mapBrowser.visible then
        local result = self.mapBrowser:mousepressed(x, y, button)
        if result == "load" then
            local selectedMap = self.mapBrowser:getSelectedMap()
            if selectedMap then
                self.mapName = selectedMap
                self:loadMap()
            end
            self.mapBrowser:hide()
        end
        return
    end
    
    if button == 1 then -- Left click
        self.isDragging = true
        
        -- Apply tool if clicked on the map
        if self:isMouseOverMap() then
            self:applyTool(self.gridX, self.gridY)
        end
    end
end

function MapEditor:mousereleased(x, y, button)
    if not self.active then return end
    
    if button == 1 then -- Left click
        self.isDragging = false
    end
end

function MapEditor:keypressed(key)
    if not self.active then return end
    
    -- Handle map browser key presses if it's visible
    if self.mapBrowser.visible then
        local result = self.mapBrowser:keypressed(key)
        if result == "load" then
            local selectedMap = self.mapBrowser:getSelectedMap()
            if selectedMap then
                self.mapName = selectedMap
                self:loadMap()
            end
            self.mapBrowser:hide()
        end
        return
    end
    
    -- Handle text input for map name
    if self.isEditingMapName then
        if key == "return" or key == "escape" then
            -- Finish editing
            self.mapName = self.mapNameInput
            self.isEditingMapName = false
        elseif key == "backspace" then
            -- Remove the last character
            self.mapNameInput = string.sub(self.mapNameInput, 1, -2)
        end
        return -- Skip other key handling while editing text
    end
    
    -- Toggle grid
    if key == "g" then
        self.showGrid = not self.showGrid
    end
    
    -- Toggle UI
    if key == "u" then
        self.showUI = not self.showUI
    end
    
    -- Tool selection shortcuts
    if key == "1" then
        self.selectedTool = "tile"
    elseif key == "2" then
        self.selectedTool = "entity"
    elseif key == "3" then
        self.selectedTool = "erase"
    end
    
    -- Save/Load
    if key == "s" and love.keyboard.isDown("lctrl") then
        self:saveMap()
    elseif key == "l" and love.keyboard.isDown("lctrl") then
        self:showMapBrowser()
    end
    
    -- Escape key to close editor
    if key == "escape" and not self.mapBrowser.visible then
        -- TODO: Prompt to save changes before exiting
        self.active = false
    end
end

function MapEditor:textinput(text)
    if self.isEditingMapName then
        -- Only allow valid filename characters
        if text:match("[%w_%-%.]") then
            self.mapNameInput = self.mapNameInput .. text
        end
    end
end

function MapEditor:applyTool(gridX, gridY)
    -- Check if the position is valid
    if gridX < 1 or gridX > self.width or gridY < 1 or gridY > self.height then
        return
    end
    
    if self.selectedTool == "tile" then
        -- Place a tile
        if self.selectedTileType == "window" then
            -- Special case for window tiles
            self.map:setTile(gridX, gridY, "wall", {isWindow = true})
        else
            self.map:setTile(gridX, gridY, self.selectedTileType)
        end
    elseif self.selectedTool == "entity" then
        -- Place an entity
        -- First check if there's already an entity at this position
        local existingEntities = self.map:getEntitiesAt(gridX, gridY)
        
        -- Remove existing entities at this position
        for _, entity in ipairs(existingEntities) do
            self.map:removeEntity(entity)
        end
        
        -- Create and add the new entity
        local entity = Furniture.create(self.selectedEntityType, self.grid, gridX, gridY)
        self.map:addEntity(entity)
    elseif self.selectedTool == "erase" then
        -- Erase tile and entities
        -- First remove entities
        local existingEntities = self.map:getEntitiesAt(gridX, gridY)
        
        for _, entity in ipairs(existingEntities) do
            self.map:removeEntity(entity)
        end
        
        -- Then set tile to floor
        self.map:setTile(gridX, gridY, "floor")
    end
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

function MapEditor:isMouseOverMap()
    return self.gridX >= 1 and self.gridX <= self.width and
           self.gridY >= 1 and self.gridY <= self.height
end

function MapEditor:showMapBrowser()
    -- Refresh the map list and show the browser
    self.mapBrowser:show()
end

return MapEditor
