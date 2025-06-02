-- Sight Tweak Integration
-- Integrates the sight tweaking UI with the game

local SightTweakUI = require("src.systems.sight.sightTweakUI")

local SightTweakIntegration = {}

-- Initialize the tweaking system
function SightTweakIntegration.init(game)
    -- Store reference to the game
    SightTweakIntegration.game = game
    
    -- Find the sight manager
    local sightManager = nil
    if game.currentMap and game.currentMap.sightManager then
        sightManager = game.currentMap.sightManager
    end
    
    if not sightManager then
        print("⚠️ Could not find sight manager for tweaking UI")
        return false
    end
    
    -- Create the tweaking UI
    SightTweakIntegration.ui = SightTweakUI:new(sightManager)
    
    -- Register key binding for toggling the UI
    SightTweakIntegration.keyBinding = "f7"
    
    print("✅ Sight tweaking UI initialized (press " .. SightTweakIntegration.keyBinding .. " to toggle)")
    return true
end

-- Update function to be called from the game's update loop
function SightTweakIntegration.update(dt)
    if SightTweakIntegration.ui then
        SightTweakIntegration.ui:update(dt)
    end
end

-- Draw function to be called from the game's draw loop
function SightTweakIntegration.draw()
    if SightTweakIntegration.ui then
        SightTweakIntegration.ui:draw()
    end
end

-- Handle keypressed events
function SightTweakIntegration.keypressed(key)
    -- Toggle UI visibility with the configured key
    if key == SightTweakIntegration.keyBinding then
        if SightTweakIntegration.ui then
            SightTweakIntegration.ui:toggle()
            return true
        end
    end
    
    -- Pass keypressed events to the UI if visible
    if SightTweakIntegration.ui and SightTweakIntegration.ui.visible then
        return SightTweakIntegration.ui:keypressed(key)
    end
    
    return false
end

-- Handle mousepressed events
function SightTweakIntegration.mousepressed(x, y, button)
    if SightTweakIntegration.ui and SightTweakIntegration.ui.visible then
        return SightTweakIntegration.ui:mousepressed(x, y, button)
    end
    return false
end

-- Handle mousereleased events
function SightTweakIntegration.mousereleased(x, y, button)
    if SightTweakIntegration.ui and SightTweakIntegration.ui.visible then
        return SightTweakIntegration.ui:mousereleased(x, y, button)
    end
    return false
end

-- Handle mousemoved events
function SightTweakIntegration.mousemoved(x, y, dx, dy)
    if SightTweakIntegration.ui and SightTweakIntegration.ui.visible then
        return SightTweakIntegration.ui:mousemoved(x, y, dx, dy)
    end
    return false
end

return SightTweakIntegration
