-- settingsMenu.lua
-- A fullscreen settings menu accessible via the escape key
-- Divided into three sections: Settings, Controls, and Help

local SettingsMenu = {}

-- Constants
local BACKGROUND_COLOR = {0.93, 0.93, 0.93, 1} -- #eeeeee
local TEXT_COLOR = {0.1, 0.1, 0.1, 1}
local HEADING_COLOR = {0.2, 0.2, 0.2, 1}
local DIVIDER_COLOR = {0, 0.5, 0.2, 1} -- Deep green

-- State
local isVisible = false
local activeSection = 1
local fonts = {}

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
        ["3"] = function() self:setActiveSection(3) end
    }
    
    -- Initialize settings data
    self.settings = {
        volume = 0.8,
        fullscreen = false,
        showFPS = true,
        -- Add more settings as needed
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
    
    -- Initialize help topics
    self.helpTopics = {
        "Movement: Use WASD to move your character around the map.",
        "Combat: Click on enemies to attack them.",
        "Line of Sight: Your vision is affected by walls and obstacles.",
        "Ambient Occlusion: Shadows form behind walls and obstacles.",
        "Time Units: Each action costs time units.",
        -- Add more help topics as needed
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
    
    -- Highlight active section
    if section == activeSection then
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.rectangle("fill", x, y, width, height)
    end
    
    -- Draw title
    love.graphics.setFont(fonts.headingBold)
    love.graphics.setColor(HEADING_COLOR)
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
    local lineHeight = 30
    local currentY = y
    
    -- Volume
    love.graphics.print("Volume: " .. math.floor(self.settings.volume * 100) .. "%", x, currentY)
    currentY = currentY + lineHeight
    
    -- Draw volume slider
    love.graphics.rectangle("line", x, currentY, width, 10)
    love.graphics.rectangle("fill", x, currentY, width * self.settings.volume, 10)
    currentY = currentY + lineHeight
    
    -- Fullscreen
    local fullscreenText = "Fullscreen: " .. (self.settings.fullscreen and "On" or "Off")
    love.graphics.print(fullscreenText, x, currentY)
    currentY = currentY + lineHeight
    
    -- Show FPS
    local fpsText = "Show FPS: " .. (self.settings.showFPS and "On" or "Off")
    love.graphics.print(fpsText, x, currentY)
    currentY = currentY + lineHeight
    
    -- Instructions
    currentY = currentY + lineHeight
    love.graphics.print("Press 1-3 to switch tabs", x, currentY)
    currentY = currentY + lineHeight
    love.graphics.print("Press ESC to close menu", x, currentY)
end

-- Draw controls content
function SettingsMenu:drawControlsContent(x, y, width)
    local lineHeight = 30
    local currentY = y
    
    -- Draw each control binding
    for action, key in pairs(self.controls) do
        local displayAction = action:gsub("_", " "):gsub("^%l", string.upper)
        love.graphics.print(displayAction .. ": " .. key, x, currentY)
        currentY = currentY + lineHeight
    end
    
    -- Instructions
    currentY = currentY + lineHeight
    love.graphics.print("Click on a control to rebind", x, currentY)
end

-- Draw help content
function SettingsMenu:drawHelpContent(x, y, width)
    local lineHeight = 30
    local currentY = y
    
    -- Draw each help topic
    for _, topic in ipairs(self.helpTopics) do
        -- Word wrap the text to fit within the width
        local wrappedText = love.graphics.newText(fonts.regular, topic)
        local _, wrappedLines = fonts.regular:getWrap(topic, width)
        
        love.graphics.print(topic, x, currentY)
        currentY = currentY + (lineHeight * #wrappedLines)
    end
end

-- Update function for any animations or time-based changes
function SettingsMenu:update(dt)
    if not isVisible then return end
    
    -- Update logic here if needed
end

return SettingsMenu
