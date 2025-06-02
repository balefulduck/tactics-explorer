-- Action System
-- Defines the base action class and common action types for the time unit system
-- This is where you define the TU costs for different actions

local ActionSystem = {}

-- Base Action class
local Action = {}
Action.__index = Action

function Action:new(config)
    local self = setmetatable({}, Action)
    
    -- Core action properties
    self.name = config.name or "Unknown Action"
    self.description = config.description or ""
    self.cost = config.cost or 0  -- TU cost to perform this action
    self.priority = config.priority or 50  -- Higher priority actions execute first
    self.icon = config.icon  -- Optional icon for UI
    
    -- Optional properties
    self.range = config.range  -- For ranged actions
    self.areaOfEffect = config.areaOfEffect  -- For area effects
    self.tags = config.tags or {}  -- For categorizing actions
    
    return self
end

function Action:execute(entity)
    -- Base implementation does nothing
    -- This should be overridden by specific action types
    print(entity.name .. " executes " .. self.name)
end

function Action:canPerform(entity, target)
    -- Check if the action can be performed
    -- This is a base implementation that just checks TU cost
    return entity.timeUnits >= self.cost
end

function Action:getDescription()
    return self.description .. " (Cost: " .. self.cost .. " TU)"
end

-- Movement Action
local MoveAction = setmetatable({}, {__index = Action})
MoveAction.__index = MoveAction

function MoveAction:new(dx, dy, config)
    config = config or {}
    config.name = config.name or "Move"
    config.description = config.description or "Move to an adjacent tile"
    config.cost = config.cost or 25  -- Default cost for movement
    config.priority = config.priority or 80  -- Movement happens before most actions
    config.tags = config.tags or {"movement"}
    
    local self = Action.new(self, config)
    
    self.dx = dx
    self.dy = dy
    
    return self
end

function MoveAction:execute(entity)
    -- Perform the actual movement
    if entity.move then
        entity:move(self.dx, self.dy)
    else
        -- Fallback for entities without a move method
        if entity.gridX and entity.gridY then
            entity.gridX = entity.gridX + self.dx
            entity.gridY = entity.gridY + self.dy
            
            -- Update world coordinates if grid-to-world conversion is available
            if entity.grid and entity.grid.gridToWorld then
                entity.x, entity.y = entity.grid:gridToWorld(entity.gridX, entity.gridY)
            end
        end
    end
end

function MoveAction:canPerform(entity, target)
    -- Check if entity has enough TUs
    if not Action.canPerform(self, entity) then
        return false
    end
    
    -- Check if the destination is valid
    local targetX = entity.gridX + self.dx
    local targetY = entity.gridY + self.dy
    
    -- If entity has a grid reference, check walkability
    if entity.grid and entity.grid.isWalkable then
        return entity.grid:isWalkable(targetX, targetY)
    end
    
    -- If no grid reference, assume it's walkable
    return true
end

-- Wait Action (do nothing but spend TUs)
local WaitAction = setmetatable({}, {__index = Action})
WaitAction.__index = WaitAction

function WaitAction:new(amount, config)
    config = config or {}
    config.name = config.name or "Wait"
    config.description = config.description or "Wait and recover"
    config.cost = amount or 10  -- Default small cost
    config.priority = config.priority or 0  -- Lowest priority
    config.tags = config.tags or {"utility"}
    
    local self = Action.new(self, config)
    
    return self
end

function WaitAction:execute(entity)
    -- Do nothing, just spend TUs
    -- Could add recovery effects here
end

-- Attack Action
local AttackAction = setmetatable({}, {__index = Action})
AttackAction.__index = AttackAction

function AttackAction:new(target, weapon, config)
    config = config or {}
    config.name = config.name or "Attack"
    config.description = config.description or "Attack a target"
    config.cost = config.cost or 50  -- Default cost for attacks
    config.priority = config.priority or 60  -- Attacks happen after movement
    config.tags = config.tags or {"combat"}
    
    local self = Action.new(self, config)
    
    self.target = target
    self.weapon = weapon
    
    return self
end

function AttackAction:execute(entity)
    -- Perform the attack
    if not self.target then
        print("Attack failed: No target")
        return
    end
    
    -- This would involve damage calculations, etc.
    print(entity.name .. " attacks " .. self.target.name)
    
    -- Example damage calculation
    local damage = 10  -- Base damage
    
    -- Apply damage to target if it has health
    if self.target.health then
        self.target.health = self.target.health - damage
        print(self.target.name .. " takes " .. damage .. " damage. Health: " .. self.target.health)
    end
end

function AttackAction:canPerform(entity, target)
    -- Check if entity has enough TUs
    if not Action.canPerform(self, entity) then
        return false
    end
    
    -- Check if target is valid
    if not self.target then
        return false
    end
    
    -- Check if target is in range
    -- This is a simple adjacent check, but could be more complex
    local dx = math.abs(entity.gridX - self.target.gridX)
    local dy = math.abs(entity.gridY - self.target.gridY)
    
    -- For now, only allow attacks on adjacent tiles
    return dx <= 1 and dy <= 1 and (dx + dy > 0)
end

-- Interact Action (for interacting with objects)
local InteractAction = setmetatable({}, {__index = Action})
InteractAction.__index = InteractAction

function InteractAction:new(target, config)
    config = config or {}
    config.name = config.name or "Interact"
    config.description = config.description or "Interact with an object"
    config.cost = config.cost or 30  -- Default cost for interaction
    config.priority = config.priority or 40  -- Lower priority than movement and attacks
    config.tags = config.tags or {"utility"}
    
    local self = Action.new(self, config)
    
    self.target = target
    
    return self
end

function InteractAction:execute(entity)
    -- Perform the interaction
    if not self.target then
        print("Interaction failed: No target")
        return
    end
    
    -- If target has an interact method, call it
    if self.target.interact then
        self.target:interact(entity)
    else
        print(entity.name .. " interacts with " .. self.target.name)
    end
end

function InteractAction:canPerform(entity, target)
    -- Check if entity has enough TUs
    if not Action.canPerform(self, entity) then
        return false
    end
    
    -- Check if target is valid
    if not self.target then
        return false
    end
    
    -- Check if target is in range
    -- This is a simple adjacent check, but could be more complex
    local dx = math.abs(entity.gridX - self.target.gridX)
    local dy = math.abs(entity.gridY - self.target.gridY)
    
    -- For now, only allow interactions on adjacent tiles or the same tile
    return dx <= 1 and dy <= 1
end

-- Export all action types
ActionSystem.Action = Action
-- Change Direction Action
local ChangeDirectionAction = setmetatable({}, {__index = Action})
ChangeDirectionAction.__index = ChangeDirectionAction

ActionSystem.MoveAction = MoveAction
ActionSystem.WaitAction = WaitAction
ActionSystem.AttackAction = AttackAction
ActionSystem.InteractAction = InteractAction
ActionSystem.ChangeDirectionAction = ChangeDirectionAction

function ChangeDirectionAction:new(direction, config)
    config = config or {}
    config.name = config.name or "Change Direction"
    config.description = config.description or "Change facing direction without moving"
    config.cost = config.cost or 25  -- Default cost for changing direction
    config.priority = config.priority or 70  -- Just below movement priority
    config.tags = config.tags or {"movement"}
    
    local self = Action.new(self, config)
    
    self.direction = direction -- 0=East, 1=South, 2=West, 3=North
    
    return self
end

function ChangeDirectionAction:execute(entity)
    -- Change the entity's facing direction
    if entity.changeDirection then
        entity:changeDirection(self.direction)
    else
        -- Fallback for entities without a changeDirection method
        if entity.facingDirection ~= nil then
            entity.facingDirection = self.direction
        end
    end
end

function ChangeDirectionAction:canPerform(entity)
    -- Check if entity has enough TUs
    if not Action.canPerform(self, entity) then
        return false
    end
    
    -- Check if entity can change direction
    return entity.facingDirection ~= nil
end

-- Action cost constants (for easy tweaking)
ActionSystem.COSTS = {
    MOVE = 25,
    ATTACK = 50,
    INTERACT = 30,
    WAIT = 10,
    CHANGE_DIRECTION = 25,
    
    -- Add more action costs here as needed
    DASH = 40,
    DODGE = 35,
    USE_ITEM = 20,
    RELOAD = 30,
    SKILL_BASIC = 40,
    SKILL_ADVANCED = 60,
    SKILL_ULTIMATE = 100
}

return ActionSystem
