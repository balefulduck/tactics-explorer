-- UI system for handling game interface elements
local UI = {}
UI.__index = UI

function UI:new(game)
    local self = setmetatable({}, UI)
    
    self.game = game
    self.font = love.graphics.getFont()
    self.debugInfo = true
    
    return self
end

function UI:draw()
    -- Draw game title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Tactics Explorer", 10, 10)
    
    -- Draw debug information
    if self.debugInfo then
        local debugText = {
            "FPS: " .. love.timer.getFPS(),
            "Player Position: " .. self.game.player.gridX .. ", " .. self.game.player.gridY,
            "Controls: WASD/Arrows to move, F1 for debug grid, ESC to quit"
        }
        
        for i, text in ipairs(debugText) do
            love.graphics.print(text, 10, love.graphics.getHeight() - (20 * (#debugText - i + 1)))
        end
    end
end

function UI:toggleDebugInfo()
    self.debugInfo = not self.debugInfo
end

return UI
