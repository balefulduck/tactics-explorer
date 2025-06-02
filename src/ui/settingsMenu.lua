-- settingsMenu.lua
-- A fullscreen settings menu accessible via the escape key
-- Divided into three sections: Settings, Controls, and Help

local SettingsMenu = {}

-- Constants
local BACKGROUND_COLOR = {0.93, 0.93, 0.93, 1} -- #eeeeee
local TEXT_COLOR = {0.1, 0.1, 0.1, 1}
local HEADING_COLOR = {0.2, 0.2, 0.2, 1}
local DIVIDER_COLOR = {0, 0.5, 0.2, 1} -- Deep green
local ACTIVE_COLOR = {0, 0.7, 0.3, 1} -- Bright green for active items
local INACTIVE_TAB_OPACITY = 0.5 -- Opacity for inactive tabs

-- State
local isVisible = false
local activeSection = 1
local activeItem = 1
local fonts = {}

-- Settings structure for each section
local sectionItems = {
    {}, -- Settings section items
    {}, -- Controls section items
    {}  -- Help section items
}

-- Track which item is currently being adjusted
local isAdjusting = false

-- Initialize the settings menu
function SettingsMenu:init()
    -- Load fonts
    fonts.headingBold = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 24)
    fonts.regular = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 18)
    
    -- Set up key bindings
    self.keyBindings = {
        escape = function() self:toggle() end,
        ["1"] = function() self:setActiveSection(1) end,
        ["2"] = function() self:setActiveSection(2) end,
        ["3"] = function() self:setActiveSection(3) end,
        tab = function() self:nextItem() end,
        space = function() self:toggleCurrentItem() end,
        up = function() self:adjustCurrentItem(1) end,
        down = function() self:adjustCurrentItem(-1) end,
        left = function() self:adjustCurrentItem(-1) end,
        right = function() self:adjustCurrentItem(1) end,
        ["return"] = function() self:toggleAdjusting() end
    }
    
    -- Initialize settings data
    self.settings = {
        volume = 0.8,
        fullscreen = false,
        showFPS = true,
        ambientOcclusion = true,
        -- Add more settings as needed
    }
    
    -- Define settings section items
    sectionItems[1] = {
        {key = "volume", label = "Volume", type = "slider", step = 0.05},
        {key = "fullscreen", label = "Fullscreen", type = "boolean"},
        {key = "showFPS", label = "Show FPS", type = "boolean"},
        {key = "ambientOcclusion", label = "Ambient Occlusion", type = "boolean"}
    }
    
    -- Initialize controls data
    self.controls = {
        move_up = "W",
        move_down = "S",
        move_left = "A",
        move_right = "D",
        interact = "E",
        attack = "Space",
        -- Add more controls as needed
    }
    
    -- Define controls section items
    sectionItems[2] = {
        {key = "move_up", label = "Move Up", type = "key"},
        {key = "move_down", label = "Move Down", type = "key"},
        {key = "move_left", label = "Move Left", type = "key"},
        {key = "move_right", label = "Move Right", type = "key"},
        {key = "interact", label = "Interact", type = "key"},
        {key = "attack", label = "Attack", type = "key"}
    }
    
    -- Initialize help topics
    self.helpTopics = {
        "Movement: Use WASD to move your character around the map.",
        "Combat: Click on enemies to attack them.",
        "Line of Sight: Your vision is affected by walls and obstacles.",
        "Ambient Occlusion: Shadows form behind walls and obstacles.",
        "Time Units: Each action costs time units.",
        -- Add more help topics as needed
    }
    
    -- Define help section items
    sectionItems[3] = {
        {key = 1, label = "Movement", type = "topic"},
        {key = 2, label = "Combat", type = "topic"},
        {key = 3, label = "Line of Sight", type = "topic"},
        {key = 4, label = "Ambient Occlusion", type = "topic"},
        {key = 5, label = "Time Units", type = "topic"}
    }
    
    return self
end

-- Toggle the visibility of the settings menu
function SettingsMenu:toggle()
    isVisible = not isVisible
    
    -- If we're showing the menu, pause the game
    if isVisible then
        -- TODO: Implement game pausing logic
    else
        -- TODO: Implement game resuming logic
    end
end

-- Set the active section
function SettingsMenu:setActiveSection(section)
    if section >= 1 and section <= 3 then
        activeSection = section
        activeItem = 1 -- Reset active item when changing sections
        isAdjusting = false
    end
end

-- Move to the next selectable item in the current section
function SettingsMenu:nextItem()
    local itemCount = #sectionItems[activeSection]
    if itemCount > 0 then
        activeItem = (activeItem % itemCount) + 1
        isAdjusting = false
    end
end

-- Toggle the current boolean item
function SettingsMenu:toggleCurrentItem()
    local item = sectionItems[activeSection][activeItem]
    if item and item.type == "boolean" then
        self.settings[item.key] = not self.settings[item.key]
    elseif item and item.type == "slider" then
        self:toggleAdjusting()
    end
end

-- Toggle adjustment mode for sliders
function SettingsMenu:toggleAdjusting()
    local item = sectionItems[activeSection][activeItem]
    if item and item.type == "slider" then
        isAdjusting = not isAdjusting
    end
end

-- Adjust the current item's value
function SettingsMenu:adjustCurrentItem(direction)
    local item = sectionItems[activeSection][activeItem]
    if item and item.type == "slider" and isAdjusting then
        local value = self.settings[item.key]
        local step = item.step or 0.05
        value = value + (direction * step)
        
        -- Clamp the value
        if value < 0 then value = 0 end
        if value > 1 then value = 1 end
        
        self.settings[item.key] = value
    end
end

-- Handle key presses
function SettingsMenu:keypressed(key)
    if not isVisible and key == "escape" then
        self:toggle()
        return true
    end
    
    if isVisible then
        local action = self.keyBindings[key]
        if action then
            action()
            return true
        end
    end
    
    return false
end

-- Draw the settings menu
function SettingsMenu:draw()
    if not isVisible then return end
    
    local w, h = love.graphics.getDimensions()
    local sectionWidth = w / 3
    
    -- Draw background
    love.graphics.setColor(BACKGROUND_COLOR)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Draw dividers
    love.graphics.setColor(DIVIDER_COLOR)
    
    -- First divider (between sections 1 and 2)
    local x = sectionWidth
    for i = 0, 0.5 do
        local width = (i % 2 == 0) and 3 or 7
        love.graphics.rectangle("fill", x + i * 25, 0, width, h)
    end
    
    -- Second divider (between sections 2 and 3)
    x = sectionWidth * 2
    for i = 0, 0.5 do
        local width = (i % 2 == 0) and 3 or 7
        love.graphics.rectangle("fill", x + i * 25, 0, width, h)
    end
    
    -- Draw section content
    self:drawSection(1, 0, 0, sectionWidth, h)
    self:drawSection(2, sectionWidth, 0, sectionWidth, h)
    self:drawSection(3, sectionWidth * 2, 0, sectionWidth, h)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a specific section
function SettingsMenu:drawSection(section, x, y, width, height)
    -- Set up title based on section
    local title
    if section == 1 then
        title = "[1] Settings"
    elseif section == 2 then
        title = "[2] Controls"
    else
        title = "[3] Help"
    end
    
    -- Apply opacity for inactive sections
    local opacity = 1.0
    if section ~= activeSection then
        opacity = INACTIVE_TAB_OPACITY
    end
    
    -- Highlight active section
    if section == activeSection then
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.rectangle("fill", x, y, width, height)
    else
        love.graphics.setColor(0.9, 0.9, 0.9, opacity)
        love.graphics.rectangle("fill", x, y, width, height)
    end
    
    -- Draw title
    love.graphics.setFont(fonts.headingBold)
    love.graphics.setColor(HEADING_COLOR[1], HEADING_COLOR[2], HEADING_COLOR[3], opacity)
    love.graphics.print(title, x + 20, y + 30)
    
    -- Draw section content
    love.graphics.setFont(fonts.regular)
    love.graphics.setColor(TEXT_COLOR)
    
    local contentY = y + 80
    local padding = 20
    
    if section == 1 then
        -- Settings section
        self:drawSettingsContent(x + padding, contentY, width - padding * 2)
    elseif section == 2 then
        -- Controls section
        self:drawControlsContent(x + padding, contentY, width - padding * 2)
    else
        -- Help section
        self:drawHelpContent(x + padding, contentY, width - padding * 2)
    end
end

-- Draw settings content
function SettingsMenu:drawSettingsContent(x, y, width)
    local lineHeight = 40
    local currentY = y
    local items = sectionItems[1]
    
    for i, item in ipairs(items) do
        local isSelected = (activeSection == 1 and activeItem == i)
        
        -- Set color based on selection
        if isSelected then
            if isAdjusting and item.type == "slider" then
                love.graphics.setColor(ACTIVE_COLOR)
            else
                love.graphics.setColor(HEADING_COLOR)
            end
            
            -- Draw selection cursor
            love.graphics.print(">", x - 20, currentY)
        else
            love.graphics.setColor(TEXT_COLOR)
        end
        
        -- Draw the item based on its type
        if item.type == "slider" then
            -- Volume slider
            local value = self.settings[item.key]
            love.graphics.print(item.label .. ": " .. math.floor(value * 100) .. "%", x, currentY)
            currentY = currentY + 25
            
            -- Draw slider background
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.rectangle("line", x, currentY, width - 40, 10)
            
            -- Draw slider fill
            if isSelected and isAdjusting then
                love.graphics.setColor(ACTIVE_COLOR)
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
            end
            love.graphics.rectangle("fill", x, currentY, (width - 40) * value, 10)
            
        elseif item.type == "boolean" then
            -- Boolean toggle
            local value = self.settings[item.key]
            local displayText = item.label .. ": " .. (value and "On" or "Off")
            love.graphics.print(displayText, x, currentY)
        end
        
        currentY = currentY + lineHeight
    end
    
    -- Instructions
    currentY = currentY + 20
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print("Tab: Next item | Space: Toggle", x, currentY)
    currentY = currentY + lineHeight - 10
    love.graphics.print("Enter: Adjust | Arrow keys: Change value", x, currentY)
end

-- Draw controls content
function SettingsMenu:drawControlsContent(x, y, width)
    local lineHeight = 40
    local currentY = y
    local items = sectionItems[2]
    
    for i, item in ipairs(items) do
        local isSelected = (activeSection == 2 and activeItem == i)
        
        -- Set color based on selection
        if isSelected then
            love.graphics.setColor(HEADING_COLOR)
            -- Draw selection cursor
            love.graphics.print(">", x - 20, currentY)
        else
            love.graphics.setColor(TEXT_COLOR)
        end
        
        -- Draw the control binding
        local displayAction = item.label
        local key = self.controls[item.key]
        love.graphics.print(displayAction .. ": " .. key, x, currentY)
        currentY = currentY + lineHeight
    end
    
    -- Instructions
    currentY = currentY + 20
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print("Tab: Next control | Enter: Rebind", x, currentY)
end

-- Draw help content
function SettingsMenu:drawHelpContent(x, y, width)
    local lineHeight = 40
    local currentY = y
    local items = sectionItems[3]
    
    for i, item in ipairs(items) do
        local isSelected = (activeSection == 3 and activeItem == i)
        
        -- Set color based on selection
        if isSelected then
            love.graphics.setColor(HEADING_COLOR)
            -- Draw selection cursor
            love.graphics.print(">", x - 20, currentY)
        else
            love.graphics.setColor(TEXT_COLOR)
        end
        
        -- Draw the help topic title
        love.graphics.print(item.label, x, currentY)
        currentY = currentY + lineHeight
        
        -- If selected, show the full help text
        if isSelected then
            love.graphics.setColor(TEXT_COLOR)
            local topic = self.helpTopics[item.key]
            
            -- Word wrap the text to fit within the width
            local _, wrappedLines = fonts.regular:getWrap(topic, width - 20)
            
            -- Draw the wrapped text with proper indentation
            for j, line in ipairs(wrappedLines) do
                love.graphics.print(line, x + 20, currentY)
                currentY = currentY + 25
            end
            
            currentY = currentY + 10 -- Add some extra space after the description
        end
    end
end

-- Update function for any animations or time-based changes
function SettingsMenu:update(dt)
    if not isVisible then return end
    
    -- Update logic here if needed
end

return SettingsMenu
