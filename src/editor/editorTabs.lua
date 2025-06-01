-- Editor Tabs
-- A tabbed interface for the different editor modes

local EditorTabs = {}
EditorTabs.__index = EditorTabs

function EditorTabs:new()
    local self = setmetatable({}, EditorTabs)
    
    -- Tab configuration
    self.tabs = {
        {id = "map", name = "Map Editor", active = true},
        {id = "tile", name = "Tile Creator", active = false},
        {id = "entity", name = "Entity Composer", active = false}
    }
    
    -- UI properties
    self.tabHeight = 40
    self.tabPadding = 10
    self.backgroundColor = {0.93, 0.93, 0.93, 1} -- #eeeeee
    self.activeTabColor = {0.85, 0.85, 0.85, 1}
    self.inactiveTabColor = {0.7, 0.7, 0.7, 1}
    self.borderColor = {0, 0, 0, 1}
    
    -- Font
    self.font = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    
    return self
end

function EditorTabs:draw()
    -- Draw tab bar background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.tabHeight)
    
    -- Draw bottom border
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, self.tabHeight, love.graphics.getWidth(), self.tabHeight)
    love.graphics.setLineWidth(1)
    
    -- Draw tabs
    local x = self.tabPadding
    for _, tab in ipairs(self.tabs) do
        local tabWidth = self.font:getWidth(tab.name) + 40
        
        -- Draw tab background
        if tab.active then
            love.graphics.setColor(self.activeTabColor)
        else
            love.graphics.setColor(self.inactiveTabColor)
        end
        
        -- Draw tab with rugged border
        self:drawRuggedRectangle(x, 5, tabWidth, self.tabHeight - 5, tab.active)
        
        -- Draw tab text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(self.font)
        love.graphics.print(tab.name, x + 20, 12)
        
        x = x + tabWidth + self.tabPadding
    end
end

function EditorTabs:drawRuggedRectangle(x, y, width, height, isActive)
    -- Draw clean rectangle for stable appearance
    love.graphics.setLineWidth(2)
    
    -- Fill
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    
    -- Draw border with clean lines for stable appearance
    -- Top line
    love.graphics.line(x, y, x + width, y)
    
    -- Right line
    love.graphics.line(x + width, y, x + width, y + height)
    
    -- Bottom line (not drawn if active tab)
    if not isActive then
        love.graphics.line(x + width, y + height, x, y + height)
    end
    
    -- Left line
    love.graphics.line(x, y + height, x, y)
    
    love.graphics.setLineWidth(1)
end

function EditorTabs:mousepressed(x, y, button)
    if button == 1 and y <= self.tabHeight then -- Left click in tab area
        local tabX = self.tabPadding
        for i, tab in ipairs(self.tabs) do
            local tabWidth = self.font:getWidth(tab.name) + 40
            
            if x >= tabX and x <= tabX + tabWidth then
                -- Activate this tab and deactivate others
                for j, otherTab in ipairs(self.tabs) do
                    otherTab.active = (i == j)
                end
                return tab.id
            end
            
            tabX = tabX + tabWidth + self.tabPadding
        end
    end
    
    return nil
end

function EditorTabs:getActiveTab()
    for _, tab in ipairs(self.tabs) do
        if tab.active then
            return tab.id
        end
    end
    return "map" -- Default to map editor
end

function EditorTabs:setActiveTab(tabId)
    for _, tab in ipairs(self.tabs) do
        tab.active = (tab.id == tabId)
    end
end

return EditorTabs
