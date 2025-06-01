-- Time UI
-- UI components for displaying time unit information

local TimeUI = {}
TimeUI.__index = TimeUI

function TimeUI:new(timeManager)
    local self = setmetatable({}, TimeUI)
    
    self.timeManager = timeManager
    
    -- UI settings
    self.showTurnInfo = true
    self.showEntityTUs = true
    self.showActionCosts = true
    
    -- Style settings (easily tweakable)
    self.style = {
        -- Turn info
        turnInfoX = 20,
        turnInfoY = 20,
        turnInfoWidth = 200,
        turnInfoHeight = 30,
        turnInfoColor = {0.2, 0.2, 0.2, 0.8},
        turnInfoTextColor = {1, 1, 1, 1},
        
        -- TU bars
        tuBarX = 20,
        tuBarY = 60,
        tuBarWidth = 200,
        tuBarHeight = 20,
        tuBarSpacing = 25,
        tuBarBgColor = {0.2, 0.2, 0.2, 0.6},
        tuBarColor = {0.2, 0.6, 0.9, 0.8},
        tuBarPlayerColor = {0.3, 0.8, 0.3, 0.8},
        tuBarTextColor = {1, 1, 1, 1},
        
        -- Action costs
        actionListX = 230,
        actionListY = 60,
        actionListSpacing = 20,
        actionTextColor = {1, 1, 1, 1},
        actionAvailableColor = {0.3, 0.8, 0.3, 1},
        actionUnavailableColor = {0.8, 0.3, 0.3, 1}
    }
    
    -- Fonts
    self.fonts = {
        turnInfo = love.graphics.getFont(),
        tuBar = love.graphics.getFont(),
        actionList = love.graphics.getFont()
    }
    
    return self
end

function TimeUI:update(dt)
    -- Any animations or updates can go here
end

function TimeUI:draw()
    -- Draw turn information
    if self.showTurnInfo then
        self:drawTurnInfo()
    end
    
    -- Draw entity TU bars
    if self.showEntityTUs then
        self:drawEntityTUBars()
    end
    
    -- Draw action costs for player
    if self.showActionCosts then
        self:drawActionCosts()
    end
end

function TimeUI:drawTurnInfo()
    local s = self.style
    
    -- Draw background
    love.graphics.setColor(s.turnInfoColor)
    love.graphics.rectangle("fill", s.turnInfoX, s.turnInfoY, s.turnInfoWidth, s.turnInfoHeight)
    
    -- Draw text
    love.graphics.setColor(s.turnInfoTextColor)
    love.graphics.setFont(self.fonts.turnInfo)
    love.graphics.print(
        "Turn: " .. self.timeManager.currentTurn .. " (" .. self.timeManager.phase .. ")",
        s.turnInfoX + 10,
        s.turnInfoY + 5
    )
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function TimeUI:drawEntityTUBars()
    local s = self.style
    
    -- Get entities sorted by TUs
    local entities = self.timeManager:getEntityOrderByTimeUnits()
    
    -- Draw TU bars for each entity
    for i, entity in ipairs(entities) do
        local y = s.tuBarY + (i-1) * s.tuBarSpacing
        
        -- Draw background
        love.graphics.setColor(s.tuBarBgColor)
        love.graphics.rectangle("fill", s.tuBarX, y, s.tuBarWidth, s.tuBarHeight)
        
        -- Draw TU bar
        if entity.isPlayerControlled then
            love.graphics.setColor(s.tuBarPlayerColor)
        else
            love.graphics.setColor(s.tuBarColor)
        end
        
        local fillWidth = (entity.timeUnits / entity.maxTimeUnits) * s.tuBarWidth
        love.graphics.rectangle("fill", s.tuBarX, y, fillWidth, s.tuBarHeight)
        
        -- Draw border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", s.tuBarX, y, s.tuBarWidth, s.tuBarHeight)
        
        -- Draw text
        love.graphics.setColor(s.tuBarTextColor)
        love.graphics.setFont(self.fonts.tuBar)
        love.graphics.print(
            entity.name .. ": " .. entity.timeUnits .. "/" .. entity.maxTimeUnits .. " TU",
            s.tuBarX + 5,
            y + 2
        )
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function TimeUI:drawActionCosts()
    local s = self.style
    
    -- Find player entity
    local player = nil
    for _, entity in ipairs(self.timeManager.entities) do
        if entity.isPlayerControlled then
            player = entity
            break
        end
    end
    
    if not player or not player.actions then
        return
    end
    
    -- Draw action costs
    love.graphics.setFont(self.fonts.actionList)
    
    local y = s.actionListY
    love.graphics.setColor(s.actionTextColor)
    love.graphics.print("Available Actions:", s.actionListX, y)
    y = y + s.actionListSpacing
    
    -- Sort actions by cost
    local sortedActions = {}
    for name, action in pairs(player.actions) do
        table.insert(sortedActions, {name = name, action = action})
    end
    
    table.sort(sortedActions, function(a, b)
        return a.action.cost < b.action.cost
    end)
    
    -- Display each action
    for _, item in ipairs(sortedActions) do
        local action = item.action
        local canAfford = player:canAffordAction(action.cost)
        
        -- Set color based on availability
        if canAfford then
            love.graphics.setColor(s.actionAvailableColor)
        else
            love.graphics.setColor(s.actionUnavailableColor)
        end
        
        -- Display action name and cost
        love.graphics.print(
            action.name .. " (" .. action.cost .. " TU)",
            s.actionListX,
            y
        )
        
        y = y + s.actionListSpacing
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Helper function to set custom fonts
function TimeUI:setFonts(turnInfoFont, tuBarFont, actionListFont)
    self.fonts.turnInfo = turnInfoFont or self.fonts.turnInfo
    self.fonts.tuBar = tuBarFont or self.fonts.tuBar
    self.fonts.actionList = actionListFont or self.fonts.actionList
end

return TimeUI
