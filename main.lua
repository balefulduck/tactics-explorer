-- Main entry point for the LÖVE2D game
local Game = require("src.core.game")
local IntroScreen = require("src.screens.introScreen")
local SettingsMenu = require("src.ui.settingsMenu")

-- Global variables
local game
local introScreen
local settingsMenu

-- Check if intro screen should be shown
local showIntro = false

-- Parse command line arguments
function parseArguments()
    -- In LÖVE, command line arguments are available in the global 'arg' table
    -- arg[1] is the first argument after the game path
    if arg and #arg > 0 then
        for i=1, #arg do
            if arg[i] == "--intro" or arg[i] == "-i" then
                showIntro = true
                break
            end
        end
    end
end

function love.load()
    -- Parse command line arguments
    parseArguments()
    
    -- Initialize the game
    game = Game:new()
    game:load()
    
    -- Initialize intro screen if needed
    if showIntro then
        introScreen = IntroScreen:new()
    end
    
    -- Initialize settings menu
    settingsMenu = SettingsMenu:init()
end

function love.update(dt)
    -- Update intro screen if active
    if introScreen and introScreen:isActive() then
        introScreen:update(dt)
        return
    end
    
    -- Update settings menu
    settingsMenu:update(dt)
    
    -- Update game state
    game:update(dt)
end

function love.draw()
    -- Render the game
    game:draw()
    
    -- Draw intro screen on top if active
    if introScreen and introScreen:isActive() then
        introScreen:draw()
    end
    
    -- Draw settings menu on top if active
    settingsMenu:draw()
end

function love.keypressed(key)
    -- Handle intro screen key presses first
    if introScreen and introScreen:isActive() then
        if introScreen:keypressed(key) then
            return -- Key was handled by intro screen
        end
    end
    
    -- Handle settings menu key presses
    if settingsMenu:keypressed(key) then
        return -- Key was handled by settings menu
    end
    
    -- Handle key press events
    game:keypressed(key)
end

function love.keyreleased(key)
    -- Handle key release events
    game:keyreleased(key)
end

function love.mousepressed(x, y, button)
    -- Handle intro screen mouse presses first
    if introScreen and introScreen:isActive() then
        if introScreen:mousepressed() then
            return -- Mouse press was handled by intro screen
        end
    end
    
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
