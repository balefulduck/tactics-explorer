-- Intro screen that shows before the main game
local IntroScreen = {}
IntroScreen.__index = IntroScreen

function IntroScreen:new()
    local self = setmetatable({}, IntroScreen)
    
    -- Initialize properties
    self.active = true
    self.font = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 18)
    self.backgroundColor = {0.93, 0.93, 0.93, 1} -- #eeeeee
    self.textColor = {0, 0, 0, 1} -- Black
    
    -- Text content
    self.text = {
        "This game is meant to be played with a keyboard.",
        "",
        "See the in-game help screen (F1) for more information on controls.",
        "",
        "A touchscreen or mouse works too, though."
    }
    
    -- Timer to auto-dismiss after a few seconds
    self.timer = 0
    self.displayTime = 5 -- Display for 5 seconds
    self.fadeOutTime = 1 -- Fade out over 1 second
    self.alpha = 1 -- For fade out effect
    
    return self
end

function IntroScreen:update(dt)
    if not self.active then return end
    
    -- Update timer
    self.timer = self.timer + dt
    
    -- Start fading out after display time
    if self.timer > self.displayTime then
        local fadeProgress = (self.timer - self.displayTime) / self.fadeOutTime
        self.alpha = 1 - fadeProgress
        
        -- Deactivate after fade out
        if self.alpha <= 0 then
            self.active = false
            self.alpha = 0
        end
    end
end

function IntroScreen:draw()
    if not self.active or self.alpha <= 0 then return end
    
    -- Save current state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Draw background
    love.graphics.setColor(
        self.backgroundColor[1], 
        self.backgroundColor[2], 
        self.backgroundColor[3], 
        self.alpha
    )
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw text
    love.graphics.setFont(self.font)
    love.graphics.setColor(
        self.textColor[1], 
        self.textColor[2], 
        self.textColor[3], 
        self.alpha
    )
    
    -- Calculate text position (centered)
    local totalHeight = #self.text * self.font:getHeight() * 1.5
    local startY = (love.graphics.getHeight() - totalHeight) / 2
    
    for i, line in ipairs(self.text) do
        local textWidth = self.font:getWidth(line)
        local x = (love.graphics.getWidth() - textWidth) / 2
        local y = startY + (i - 1) * self.font:getHeight() * 1.5
        love.graphics.print(line, x, y)
    end
    
    -- Restore previous state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

function IntroScreen:keypressed(key)
    -- Any key press dismisses the intro screen
    if self.active then
        self.active = false
        return true -- Signal that we handled the key press
    end
    return false
end

function IntroScreen:mousepressed()
    -- Any mouse press dismisses the intro screen
    if self.active then
        self.active = false
        return true -- Signal that we handled the mouse press
    end
    return false
end

function IntroScreen:isActive()
    return self.active
end

return IntroScreen
