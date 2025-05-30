function MapEditor:handleUIClick(x, y)
    -- Handle tool selection buttons
    local toolButtonWidth = 70
    local toolButtonHeight = 30
    local toolButtonSpacing = 10
    local toolButtonY = self.panelY + 40 + self.titleFont:getHeight() + 30
    
    -- Check tile tool button
    if self:isMouseOver(self.panelX + 20, toolButtonY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "tile"
        return
    end
    
    -- Check entity tool button
    if self:isMouseOver(self.panelX + 20 + toolButtonWidth + toolButtonSpacing, toolButtonY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "entity"
        return
    end
    
    -- Check erase tool button
    if self:isMouseOver(self.panelX + 20 + (toolButtonWidth + toolButtonSpacing) * 2, toolButtonY, toolButtonWidth, toolButtonHeight) then
        self.selectedTool = "erase"
        return
    end
    
    -- Check toggle tool button
    local toggleY = toolButtonY + toolButtonHeight + 10
    if self:isMouseOver(self.panelX + 20, toggleY, toolButtonWidth * 2 + toolButtonSpacing, toolButtonHeight) then
        self.selectedTool = "toggle"
        return
    end
    
    -- Handle tile type selection
    if self.selectedTool == "tile" then
        local tileTypesY = toggleY + toolButtonHeight + 10
        if self.selectedTool == "toggle" then
            tileTypesY = tileTypesY + 40  -- Add space for toggle tool description
        end
        tileTypesY = tileTypesY + self.titleFont:getHeight() + 5
        
        local buttonsPerRow = 4
        local buttonX, buttonY
        
        for i, tileType in ipairs(self.tileTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            buttonX = self.panelX + 20 + col * (self.buttonSize + self.buttonPadding)
            buttonY = tileTypesY + row * (self.buttonSize + self.buttonPadding)
            
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) then
                self.selectedTileType = tileType.id
                return
            end
        end
    end
    
    -- Handle entity type selection
    if self.selectedTool == "entity" then
        local entityTypesY = toggleY + toolButtonHeight + 10
        if self.selectedTool == "toggle" then
            entityTypesY = entityTypesY + 40  -- Add space for toggle tool description
        end
        entityTypesY = entityTypesY + self.titleFont:getHeight() + 5
        
        local buttonsPerRow = 4
        local buttonX, buttonY
        
        for i, entityType in ipairs(self.entityTypes) do
            local row = math.floor((i-1) / buttonsPerRow)
            local col = (i-1) % buttonsPerRow
            buttonX = self.panelX + 20 + col * (self.buttonSize + self.buttonPadding)
            buttonY = entityTypesY + row * (self.buttonSize + self.buttonPadding)
            
            if self:isMouseOver(buttonX, buttonY, self.buttonSize, self.buttonSize) then
                self.selectedEntityType = entityType.id
                return
            end
        end
    end
    
    -- Handle map name input field
    local mapNameY = self.panelY + 60
    if self:isMouseOver(self.panelX + 100, mapNameY - 5, 150, 25) then
        self.isEditingMapName = true
        self.mapNameInput = self.mapName
        return
    end
    
    -- Handle width input field
    local widthY = mapNameY + 40
    if self:isMouseOver(self.panelX + 70, widthY - 5, 50, 25) then
        self.isEditingWidth = true
        self.widthInput = tostring(self.width)
        return
    end
    
    -- Handle height input field
    local heightY = widthY + 30
    if self:isMouseOver(self.panelX + 70, heightY - 5, 50, 25) then
        self.isEditingHeight = true
        self.heightInput = tostring(self.height)
        return
    end
    
    -- Handle save button
    local saveY = heightY + 35
    if self:isMouseOver(self.panelX, saveY, 80, 30) then
        self:saveMap()
        return
    end
    
    -- Handle load button
    if self:isMouseOver(self.panelX + 90, saveY, 80, 30) then
        self:showMapBrowser()
        return
    end
end
