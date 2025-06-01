-- Time System Integration
-- Example of how to integrate the time unit system with the existing game

local TimeManager = require("src.systems.time.timeManager")
local ActionSystem = require("src.systems.time.actionSystem")
local EntityTimeExtension = require("src.systems.time.entityTimeExtension")
local TimeUI = require("src.systems.time.timeUI")

local TimeSystemIntegration = {}

-- Initialize the time system
function TimeSystemIntegration.initialize(game)
    -- Create time manager
    game.timeManager = TimeManager:new()
    
    -- Create time UI
    game.timeUI = TimeUI:new(game.timeManager)
    
    -- Register player with time system
    EntityTimeExtension.extend(game.player, {
        timeUnits = 100,
        maxTimeUnits = 100,
        speed = 100,
        isPlayerControlled = true
    })
    
    -- Create default actions for player
    EntityTimeExtension.createDefaultActions(game.player, ActionSystem)
    
    -- Register player with time manager
    game.timeManager:registerEntity(game.player)
    
    -- Register other entities with time system
    if game.currentMap and game.currentMap.entities then
        for _, entity in ipairs(game.currentMap.entities) do
            -- Skip player as we already registered it
            if entity ~= game.player then
                -- Extend entity with time capabilities
                EntityTimeExtension.extend(entity, {
                    timeUnits = 100,
                    maxTimeUnits = 100,
                    speed = 90,  -- Slightly slower than player
                    isPlayerControlled = false
                })
                
                -- Create default actions for entity
                EntityTimeExtension.createDefaultActions(entity, ActionSystem)
                
                -- Register with time manager
                game.timeManager:registerEntity(entity)
            end
        end
    end
    
    -- Start first turn
    game.timeManager:startNewTurn()
    
    -- Add turn-based flag to game
    game.isTurnBased = true
    
    return game.timeManager
end

-- Update function to be called from game's update
function TimeSystemIntegration.update(game, dt)
    if not game.timeManager then return end
    
    -- Update time manager
    game.timeManager:update(dt)
    
    -- Update time UI
    if game.timeUI then
        game.timeUI:update(dt)
    end
    
    -- Check if turn should end automatically
    if game.autoEndTurn and game.timeManager:isReadyForNextTurn() then
        TimeSystemIntegration.endTurn(game)
    end
end

-- Draw function to be called from game's draw
function TimeSystemIntegration.draw(game)
    if not game.timeUI then return end
    
    -- Draw time UI
    game.timeUI:draw()
end

-- End the current turn and start a new one
function TimeSystemIntegration.endTurn(game)
    if not game.timeManager then return end
    
    -- Execute all queued actions
    game.timeManager:executeActions()
    
    -- Start a new turn
    game.timeManager:startNewTurn()
    
    return game.timeManager.currentTurn
end

-- Queue a move action for the player
function TimeSystemIntegration.queuePlayerMove(game, dx, dy)
    if not game.timeManager or not game.player then return false end
    
    -- Create move action
    local moveAction = ActionSystem.MoveAction:new(dx, dy)
    
    -- Queue the action
    return game.timeManager:queueAction(game.player, moveAction)
end

-- Queue a wait action for the player
function TimeSystemIntegration.queuePlayerWait(game, amount)
    if not game.timeManager or not game.player then return false end
    
    -- Create wait action
    local waitAction = ActionSystem.WaitAction:new(amount or ActionSystem.COSTS.WAIT)
    
    -- Queue the action
    return game.timeManager:queueAction(game.player, waitAction)
end

-- Define a custom action with specific TU cost
function TimeSystemIntegration.defineCustomAction(name, cost, priority, executeFunc)
    -- Create a new action class
    local CustomAction = setmetatable({}, {__index = ActionSystem.Action})
    CustomAction.__index = CustomAction
    
    function CustomAction:new(config)
        config = config or {}
        config.name = config.name or name
        config.cost = config.cost or cost
        config.priority = config.priority or priority
        
        local self = ActionSystem.Action.new(self, config)
        
        return self
    end
    
    function CustomAction:execute(entity)
        if executeFunc then
            executeFunc(self, entity)
        else
            print(entity.name .. " executes " .. self.name)
        end
    end
    
    -- Add to ActionSystem
    ActionSystem[name .. "Action"] = CustomAction
    ActionSystem.COSTS[string.upper(name)] = cost
    
    return CustomAction
end

-- Modify the TU cost of an existing action type
function TimeSystemIntegration.setActionCost(actionType, newCost)
    if ActionSystem.COSTS[string.upper(actionType)] then
        ActionSystem.COSTS[string.upper(actionType)] = newCost
        return true
    end
    return false
end

return TimeSystemIntegration
