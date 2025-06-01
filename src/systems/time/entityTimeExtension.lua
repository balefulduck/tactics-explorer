-- Entity Time Extension
-- Utility functions to add time unit capabilities to existing entities

local EntityTimeExtension = {}

-- Add time unit capabilities to an entity
function EntityTimeExtension.extend(entity, config)
    config = config or {}
    
    -- Set default time unit properties
    entity.timeUnits = config.timeUnits or 100
    entity.maxTimeUnits = config.maxTimeUnits or entity.timeUnits
    entity.speed = config.speed or 100  -- Base speed (percentage)
    entity.actionQueue = entity.actionQueue or {}
    entity.isPlayerControlled = config.isPlayerControlled or false
    
    -- Add TU-related methods if they don't exist
    
    -- Check if entity can afford an action
    if not entity.canAffordAction then
        entity.canAffordAction = function(self, actionCost)
            return self.timeUnits >= actionCost
        end
    end
    
    -- Get available actions based on TUs
    if not entity.getAvailableActions then
        entity.getAvailableActions = function(self)
            local availableActions = {}
            
            -- If entity has defined actions
            if self.actions then
                for _, action in pairs(self.actions) do
                    if self:canAffordAction(action.cost) then
                        table.insert(availableActions, action)
                    end
                end
            end
            
            return availableActions
        end
    end
    
    -- Spend TUs manually
    if not entity.spendTimeUnits then
        entity.spendTimeUnits = function(self, amount)
            if self.timeUnits >= amount then
                self.timeUnits = self.timeUnits - amount
                return true
            end
            return false
        end
    end
    
    -- Restore TUs
    if not entity.restoreTimeUnits then
        entity.restoreTimeUnits = function(self, amount)
            self.timeUnits = math.min(self.timeUnits + amount, self.maxTimeUnits)
            return self.timeUnits
        end
    end
    
    -- Reset TUs to max
    if not entity.resetTimeUnits then
        entity.resetTimeUnits = function(self)
            self.timeUnits = self.maxTimeUnits
            return self.timeUnits
        end
    end
    
    -- Get TU percentage
    if not entity.getTimeUnitPercentage then
        entity.getTimeUnitPercentage = function(self)
            return self.timeUnits / self.maxTimeUnits
        end
    end
    
    return entity
end

-- Create a set of default actions for an entity based on its capabilities
function EntityTimeExtension.createDefaultActions(entity, actionSystem)
    local actions = {}
    
    -- If entity can move, add movement actions
    if entity.move then
        -- Cardinal directions
        actions.moveUp = actionSystem.MoveAction:new(0, -1, {cost = actionSystem.COSTS.MOVE})
        actions.moveDown = actionSystem.MoveAction:new(0, 1, {cost = actionSystem.COSTS.MOVE})
        actions.moveLeft = actionSystem.MoveAction:new(-1, 0, {cost = actionSystem.COSTS.MOVE})
        actions.moveRight = actionSystem.MoveAction:new(1, 0, {cost = actionSystem.COSTS.MOVE})
        
        -- Diagonal directions (optional, could cost more)
        actions.moveUpLeft = actionSystem.MoveAction:new(-1, -1, {
            cost = math.floor(actionSystem.COSTS.MOVE * 1.4),  -- ~sqrt(2) times more expensive
            name = "Move Diagonally"
        })
        actions.moveUpRight = actionSystem.MoveAction:new(1, -1, {
            cost = math.floor(actionSystem.COSTS.MOVE * 1.4)
        })
        actions.moveDownLeft = actionSystem.MoveAction:new(-1, 1, {
            cost = math.floor(actionSystem.COSTS.MOVE * 1.4)
        })
        actions.moveDownRight = actionSystem.MoveAction:new(1, 1, {
            cost = math.floor(actionSystem.COSTS.MOVE * 1.4)
        })
    end
    
    -- Add wait action
    actions.wait = actionSystem.WaitAction:new(actionSystem.COSTS.WAIT)
    
    -- If entity has attack capability
    if entity.attack then
        actions.attack = actionSystem.AttackAction:new(nil, nil, {cost = actionSystem.COSTS.ATTACK})
    end
    
    -- If entity has interact capability
    if entity.interact then
        actions.interact = actionSystem.InteractAction:new(nil, {cost = actionSystem.COSTS.INTERACT})
    end
    
    -- Assign actions to entity
    entity.actions = actions
    
    return actions
end

return EntityTimeExtension
