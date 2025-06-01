-- Time Manager
-- Manages the turn-based time unit system for the game
-- Controls turn flow, action queuing, and time unit allocation

local TimeManager = {}
TimeManager.__index = TimeManager

function TimeManager:new()
    local self = setmetatable({}, TimeManager)
    
    -- Turn state
    self.currentTurn = 0
    self.phase = "planning" -- planning, execution, update
    
    -- Entity tracking
    self.entities = {}
    self.actionQueue = {}
    
    -- Time settings (easily tweakable)
    self.baseTimeUnits = 100 -- Base TU per turn
    self.speedFactor = 1.0   -- Global speed multiplier
    
    -- Debug
    self.debug = false
    
    return self
end

-- Register an entity with the time system
function TimeManager:registerEntity(entity)
    -- Skip if already registered
    for _, e in ipairs(self.entities) do
        if e == entity then return end
    end
    
    -- Add entity to the time system
    table.insert(self.entities, entity)
    
    -- Initialize time-related properties if they don't exist
    if not entity.timeUnits then
        -- Set default values
        entity.speed = entity.speed or 100 -- Default speed (percentage)
        entity.timeUnits = self:calculateEntityTimeUnits(entity)
        entity.maxTimeUnits = entity.timeUnits
        entity.actionQueue = {}
    end
    
    return entity
end

-- Remove an entity from the time system
function TimeManager:unregisterEntity(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            return true
        end
    end
    return false
end

-- Calculate how many TUs an entity gets based on its speed
function TimeManager:calculateEntityTimeUnits(entity)
    -- Calculate TUs based on entity's speed attribute
    -- Speed is a percentage value (100 = normal speed)
    return math.floor(self.baseTimeUnits * (entity.speed / 100) * self.speedFactor)
end

-- Start a new turn cycle
function TimeManager:startNewTurn()
    self.currentTurn = self.currentTurn + 1
    self.phase = "planning"
    
    -- Reset TUs for all entities
    for _, entity in ipairs(self.entities) do
        entity.timeUnits = self:calculateEntityTimeUnits(entity)
        entity.actionQueue = {}
    end
    
    -- Clear global action queue
    self.actionQueue = {}
    
    if self.debug then
        print("Turn " .. self.currentTurn .. " started")
    end
    
    return self.currentTurn
end

-- Queue an action for an entity
function TimeManager:queueAction(entity, action)
    -- Check if entity has enough TUs
    if not entity.timeUnits or entity.timeUnits < action.cost then
        if self.debug then
            print(entity.name .. " doesn't have enough TUs for " .. action.name)
        end
        return false
    end
    
    -- Deduct TUs
    entity.timeUnits = entity.timeUnits - action.cost
    
    -- Queue the action
    table.insert(self.actionQueue, {
        entity = entity,
        action = action,
        priority = action.priority or 50, -- Default priority
        turn = self.currentTurn
    })
    
    -- Also store in entity's own queue for reference
    table.insert(entity.actionQueue, action)
    
    if self.debug then
        print(entity.name .. " queued " .. action.name .. " (cost: " .. action.cost .. ", remaining TU: " .. entity.timeUnits .. ")")
    end
    
    return true
end

-- Execute all queued actions in priority order
function TimeManager:executeActions()
    self.phase = "execution"
    
    if #self.actionQueue == 0 then
        if self.debug then
            print("No actions to execute")
        end
        self.phase = "update"
        return
    end
    
    -- Sort actions by priority (higher priority executes first)
    table.sort(self.actionQueue, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Execute all queued actions
    for _, item in ipairs(self.actionQueue) do
        if item.action.execute then
            item.action:execute(item.entity)
            
            if self.debug then
                print("Executed: " .. item.entity.name .. "'s " .. item.action.name)
            end
        else
            print("Error: Action has no execute method: " .. (item.action.name or "unnamed action"))
        end
    end
    
    -- Move to update phase
    self.phase = "update"
end

-- Check if all entities have used their TUs or have no more actions to take
function TimeManager:isReadyForNextTurn()
    for _, entity in ipairs(self.entities) do
        -- If entity still has TUs and is controlled by player, not ready
        if entity.isPlayerControlled and entity.timeUnits > 0 then
            return false
        end
    end
    return true
end

-- Update function called from the game loop
function TimeManager:update(dt)
    -- This could handle automatic turn progression
    -- For example, if all entities have used their TUs
    
    -- For now, we'll leave turn advancement to be manually triggered
end

-- Get a list of entities sorted by their current TUs
function TimeManager:getEntityOrderByTimeUnits()
    local sortedEntities = {}
    
    -- Copy entities to avoid modifying the original table
    for _, entity in ipairs(self.entities) do
        table.insert(sortedEntities, entity)
    end
    
    -- Sort by remaining TUs (descending)
    table.sort(sortedEntities, function(a, b)
        return (a.timeUnits or 0) > (b.timeUnits or 0)
    end)
    
    return sortedEntities
end

-- Debug function to print current TU status of all entities
function TimeManager:printStatus()
    print("=== Turn " .. self.currentTurn .. " (" .. self.phase .. " phase) ===")
    for _, entity in ipairs(self.entities) do
        print(entity.name .. ": " .. (entity.timeUnits or 0) .. "/" .. (entity.maxTimeUnits or 0) .. " TU")
    end
    print("===================")
end

return TimeManager
