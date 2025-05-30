-- Main entry point for the LÖVE2D game
local Game = require("src.core.game")

-- Global variables
local game

function love.load()
    -- Initialize the game
    game = Game:new()
    game:load()
end

function love.update(dt)
    -- Update game state
    game:update(dt)
end

function love.draw()
    -- Render the game
    game:draw()
end

function love.keypressed(key)
    -- Handle key press events
    game:keypressed(key)
    
    -- Quit the game if escape is pressed
    if key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)
    -- Handle key release events
    game:keyreleased(key)
end

function love.mousepressed(x, y, button)
    -- Handle mouse press events
    game:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    -- Handle mouse release events
    game:mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    -- Handle mouse wheel events for zooming
    game:wheelmoved(x, y)
end
