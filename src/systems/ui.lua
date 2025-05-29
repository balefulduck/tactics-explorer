-- UI system for handling interface elements
local InfoScreen = require("src.ui.infoScreen")

local UI = {}
UI.__index = UI

function UI:new(game)
    local self = setmetatable({}, UI)
    
    self.game = game
    self.font = love.graphics.getFont()
    self.debugInfo = true
    self.messages = {}
    
    -- Initialize UI components
    self.infoScreen = InfoScreen:new()
    
    return self
end

function UI:update(dt)
    -- Update UI components
    self.infoScreen:update(dt)
    
    -- Update messages
    for i = #self.messages, 1, -1 do
        local message = self.messages[i]
        message.time = message.time - dt
        if message.time <= 0 then
            table.remove(self.messages, i)
        end
    end
end

function UI:draw()
    -- In the newspaper layout, most UI elements are drawn by the Game object
    -- We only need to draw the info screen when it's visible
    if self.infoScreen.visible then
        self.infoScreen:draw()
    end
    
    -- Draw messages
    self:drawMessages()
end

function UI:drawMessages()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local messageHeight = 30
    local padding = 10
    
    for i, message in ipairs(self.messages) do
        local alpha = math.min(1, message.time)
        local y = screenHeight - (messageHeight + padding) * i - 60 -- Leave space for debug info
        
        -- Draw message background
        love.graphics.setColor(0, 0, 0, 0.7 * alpha)
        love.graphics.rectangle("fill", 0, y, screenWidth, messageHeight)
        
        -- Draw message text
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(message.text, padding, y + (messageHeight - font:getHeight()) / 2, screenWidth - padding * 2, "left")
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function UI:toggleDebugInfo()
    self.debugInfo = not self.debugInfo
end

function UI:showMessage(text, duration)
    table.insert(self.messages, {
        text = text,
        time = duration or 3
    })
end

function UI:toggleInfoScreen(entity)
    self.infoScreen:toggle(entity)
end

return UI
