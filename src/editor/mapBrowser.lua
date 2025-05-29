-- Map Browser
-- Allows browsing and selecting saved maps

local MapBrowser = {}
MapBrowser.__index = MapBrowser

function MapBrowser:new()
    local self = setmetatable({}, MapBrowser)
    
    -- Browser state
    self.maps = {}
    self.selectedIndex = 1
    self.visible = false
    self.scrollOffset = 0
    self.maxVisibleItems = 8
    
    -- UI elements
    self.width = 400
    self.height = 350
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    
    -- Create fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 18)
    self.itemFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 14)
    
    return self
end

function MapBrowser:show()
    self.visible = true
    self:refreshMapList()
end

function MapBrowser:hide()
    self.visible = false
end

function MapBrowser:refreshMapList()
    self.maps = {}
    self.selectedIndex = 1
    self.scrollOffset = 0
    
    -- Get all map files from the maps directory
    local items = love.filesystem.getDirectoryItems("maps")
    
    for _, item in ipairs(items) do
        if item:match("%.json$") then
            local mapName = item:gsub("%.json$", "")
            local mapPath = "maps/" .. item
            
            -- Try to load the map to get its metadata
            local success, mapData = self:loadMapMetadata(mapPath)
            
            if success then
                table.insert(self.maps, {
                    name = mapData.name or mapName,
                    filename = mapName,
                    width = mapData.width,
                    height = mapData.height
                })
            else
                -- If we can't load the metadata, just use the filename
                table.insert(self.maps, {
                    name = mapName,
                    filename = mapName,
                    width = 0,
                    height = 0
                })
            end
        end
    end
    
    -- Sort maps alphabetically
    table.sort(self.maps, function(a, b) return a.name < b.name end)
end

function MapBrowser:loadMapMetadata(path)
    if not love.filesystem.getInfo(path) then
        return false, nil
    end
    
    local mapJson = love.filesystem.read(path)
    if not mapJson then
        return false, nil
    end
    
    -- Parse JSON
    local json = require("lib.json")
    local mapData = json.decode(mapJson)
    
    if not mapData then
        return false, nil
    end
    
    return true, mapData
end

function MapBrowser:update(dt)
    if not self.visible then return end
    
    -- Handle mouse wheel for scrolling
    local _, mouseWheelY = love.mouse.getWheel()
    if mouseWheelY ~= 0 then
        self.scrollOffset = self.scrollOffset - mouseWheelY
        self:clampScrollOffset()
    end
end

function MapBrowser:clampScrollOffset()
    local maxOffset = math.max(0, #self.maps - self.maxVisibleItems)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, maxOffset))
end

function MapBrowser:draw()
    if not self.visible then return end
    
    -- Draw background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Map Browser", self.x + 20, self.y + 20)
    
    -- Draw map list
    love.graphics.setFont(self.itemFont)
    local itemHeight = 30
    local listY = self.y + 60
    
    -- Draw visible items
    for i = 1, math.min(self.maxVisibleItems, #self.maps) do
        local mapIndex = i + self.scrollOffset
        if mapIndex <= #self.maps then
            local map = self.maps[mapIndex]
            
            -- Draw selection highlight
            if mapIndex == self.selectedIndex then
                love.graphics.setColor(0.3, 0.5, 0.7, 0.7)
                love.graphics.rectangle("fill", self.x + 10, listY + (i-1) * itemHeight, self.width - 20, itemHeight)
            end
            
            -- Draw map name and size
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(map.name, self.x + 20, listY + (i-1) * itemHeight + 5)
            
            if map.width > 0 and map.height > 0 then
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.print(map.width .. "x" .. map.height, self.x + self.width - 80, listY + (i-1) * itemHeight + 5)
            end
        end
    end
    
    -- Draw scrollbar if needed
    if #self.maps > self.maxVisibleItems then
        local scrollbarHeight = (self.maxVisibleItems / #self.maps) * (self.height - 80)
        local scrollbarY = self.y + 60 + (self.scrollOffset / (#self.maps - self.maxVisibleItems)) * (self.height - 80 - scrollbarHeight)
        
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        love.graphics.rectangle("fill", self.x + self.width - 15, scrollbarY, 10, scrollbarHeight)
    end
    
    -- Draw buttons
    local buttonY = self.y + self.height - 50
    
    -- Load button
    love.graphics.setColor(0.3, 0.6, 0.3, 1)
    love.graphics.rectangle("fill", self.x + 20, buttonY, 100, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Load", self.x + 55, buttonY + 7)
    
    -- Cancel button
    love.graphics.setColor(0.6, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", self.x + self.width - 120, buttonY, 100, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Cancel", self.x + self.width - 95, buttonY + 7)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function MapBrowser:mousepressed(x, y, button)
    if not self.visible then return false end
    
    if button == 1 then -- Left click
        -- Check if clicking on a map item
        local itemHeight = 30
        local listY = self.y + 60
        
        for i = 1, math.min(self.maxVisibleItems, #self.maps) do
            local mapIndex = i + self.scrollOffset
            if mapIndex <= #self.maps then
                if x >= self.x + 10 and x <= self.x + self.width - 10 and
                   y >= listY + (i-1) * itemHeight and y <= listY + i * itemHeight then
                    self.selectedIndex = mapIndex
                    return true
                end
            end
        end
        
        -- Check if clicking on Load button
        local buttonY = self.y + self.height - 50
        if x >= self.x + 20 and x <= self.x + 120 and
           y >= buttonY and y <= buttonY + 30 then
            return "load"
        end
        
        -- Check if clicking on Cancel button
        if x >= self.x + self.width - 120 and x <= self.x + self.width - 20 and
           y >= buttonY and y <= buttonY + 30 then
            self:hide()
            return "cancel"
        end
    end
    
    return false
end

function MapBrowser:keypressed(key)
    if not self.visible then return false end
    
    if key == "escape" then
        self:hide()
        return "cancel"
    elseif key == "return" or key == "space" then
        return "load"
    elseif key == "up" then
        self.selectedIndex = math.max(1, self.selectedIndex - 1)
        
        -- Adjust scroll if needed
        if self.selectedIndex < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedIndex - 1
        end
        
        return true
    elseif key == "down" then
        self.selectedIndex = math.min(#self.maps, self.selectedIndex + 1)
        
        -- Adjust scroll if needed
        if self.selectedIndex > self.scrollOffset + self.maxVisibleItems then
            self.scrollOffset = self.selectedIndex - self.maxVisibleItems
        end
        
        return true
    end
    
    return false
end

function MapBrowser:getSelectedMap()
    if self.selectedIndex > 0 and self.selectedIndex <= #self.maps then
        return self.maps[self.selectedIndex].filename
    end
    return nil
end

return MapBrowser
