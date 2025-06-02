-- Sight Tweak UI
-- Provides an in-game interface for tweaking sight system variables

local SightTweakUI = {}
SightTweakUI.__index = SightTweakUI

function SightTweakUI:new(sightManager)
    local self = setmetatable({}, SightTweakUI)
    
    -- Store reference to the sight manager
    self.sightManager = sightManager
    
    -- UI state
    self.visible = false
    self.activeTab = "ranges"
    self.sliders = {}
    self.checkboxes = {}
    self.colorPickers = {}
    
    -- Initialize UI components
    self:initializeUI()
    
    -- Position and size
    self.x = 20
    self.y = 20
    self.width = 300
    self.height = 500
    self.headerHeight = 30
    self.tabHeight = 25
    self.padding = 10
    
    -- Dragging state
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    -- Apply button state
    self.applyButtonHovered = false
    self.resetButtonHovered = false
    self.closeButtonHovered = false
    
    -- Store original values for reset functionality
    self.originalValues = {}
    self:storeOriginalValues()
    
    return self
end

function SightTweakUI:toggle()
    -- Toggle visibility of the UI
    self.visible = not self.visible
    print("Sight tweaking UI visibility toggled: " .. tostring(self.visible))
    return true
end

function SightTweakUI:storeOriginalValues()
    -- Store original values for all tweakable parameters
    self.originalValues = {
        BASE_SIGHT_RANGE = self.sightManager.constants.BASE_SIGHT_RANGE,
        MAX_SIGHT_RANGE = self.sightManager.constants.MAX_SIGHT_RANGE,
        DEGRADATION_START = self.sightManager.constants.DEGRADATION_START,
        HEIGHT_THRESHOLD = self.sightManager.constants.HEIGHT_THRESHOLD,
        PARTIAL_OBSTRUCTION_FACTOR = self.sightManager.constants.PARTIAL_OBSTRUCTION_FACTOR,
        PERIPHERAL_ANGLE = self.sightManager.constants.PERIPHERAL_ANGLE,
        PERIPHERAL_PENALTY = self.sightManager.constants.PERIPHERAL_PENALTY,
        DARKNESS_PENALTY = self.sightManager.constants.DARKNESS_PENALTY,
        MOVEMENT_BONUS = self.sightManager.constants.MOVEMENT_BONUS,
        AMBIENT_OCCLUSION_LEVELS = self.sightManager.constants.AMBIENT_OCCLUSION_LEVELS,
        AMBIENT_OCCLUSION_MISS_CHANCE = table.concat(self.sightManager.constants.AMBIENT_OCCLUSION_MISS_CHANCE, ","),
        CORNER_PEEK_ENABLED = self.sightManager.constants.CORNER_PEEK_ENABLED,
        SHADOW_LENGTH = self.sightManager.constants.SHADOW_LENGTH or 10,
        SHADOW_WIDTH_FACTOR = self.sightManager.constants.SHADOW_WIDTH_FACTOR or 0.5
    }
    
    -- Store original colors
    self.originalValues.AMBIENT_OCCLUSION_COLORS = {}
    for i, color in ipairs(self.sightManager.constants.AMBIENT_OCCLUSION_COLORS) do
        self.originalValues.AMBIENT_OCCLUSION_COLORS[i] = {unpack(color)}
    end
end

function SightTweakUI:initializeUI()
    -- Create sliders for numeric values
    self.sliders = {
        -- Ranges tab
        {
            tab = "ranges",
            id = "BASE_SIGHT_RANGE",
            label = "Base Sight Range",
            min = 10,
            max = 200,
            value = self.sightManager.constants.BASE_SIGHT_RANGE,
            tooltip = "Perfect visibility range"
        },
        {
            tab = "ranges",
            id = "MAX_SIGHT_RANGE",
            label = "Max Sight Range",
            min = 50,
            max = 300,
            value = self.sightManager.constants.MAX_SIGHT_RANGE,
            tooltip = "Maximum possible sight range"
        },
        {
            tab = "ranges",
            id = "DEGRADATION_START",
            label = "Degradation Start",
            min = 10,
            max = 200,
            value = self.sightManager.constants.DEGRADATION_START,
            tooltip = "Where sight starts to degrade"
        },
        
        -- Obstruction tab
        {
            tab = "obstruction",
            id = "HEIGHT_THRESHOLD",
            label = "Height Threshold",
            min = 1,
            max = 5,
            value = self.sightManager.constants.HEIGHT_THRESHOLD,
            tooltip = "Height at which objects fully block sight"
        },
        {
            tab = "obstruction",
            id = "PARTIAL_OBSTRUCTION_FACTOR",
            label = "Partial Obstruction",
            min = 0,
            max = 1,
            value = self.sightManager.constants.PARTIAL_OBSTRUCTION_FACTOR,
            step = 0.05,
            tooltip = "Chance reduction for partial obstructions"
        },
        
        -- Peripheral tab
        {
            tab = "peripheral",
            id = "PERIPHERAL_ANGLE",
            label = "Peripheral Angle",
            min = 30,
            max = 180,
            value = self.sightManager.constants.PERIPHERAL_ANGLE,
            tooltip = "Angle of peripheral vision (degrees)"
        },
        {
            tab = "peripheral",
            id = "PERIPHERAL_PENALTY",
            label = "Peripheral Penalty",
            min = 0,
            max = 1,
            value = self.sightManager.constants.PERIPHERAL_PENALTY,
            step = 0.05,
            tooltip = "Detection chance multiplier in peripheral vision"
        },
        
        -- Factors tab
        {
            tab = "factors",
            id = "DARKNESS_PENALTY",
            label = "Darkness Penalty",
            min = 0,
            max = 1,
            value = self.sightManager.constants.DARKNESS_PENALTY,
            step = 0.05,
            tooltip = "Detection chance multiplier in darkness"
        },
        {
            tab = "factors",
            id = "MOVEMENT_BONUS",
            label = "Movement Bonus",
            min = 0,
            max = 1,
            value = self.sightManager.constants.MOVEMENT_BONUS,
            step = 0.05,
            tooltip = "Detection chance bonus for moving targets"
        },
        
        -- Occlusion tab
        {
            tab = "occlusion",
            id = "AMBIENT_OCCLUSION_LEVELS",
            label = "Occlusion Levels",
            min = 1,
            max = 5,
            value = self.sightManager.constants.AMBIENT_OCCLUSION_LEVELS,
            step = 1,
            tooltip = "Number of occlusion levels"
        },
        {
            tab = "shadows",
            id = "SHADOW_LENGTH",
            label = "Shadow Length",
            min = 1,
            max = 20,
            value = self.sightManager.constants.SHADOW_LENGTH or 10,
            step = 1,
            tooltip = "Maximum length of shadows cast"
        },
        {
            tab = "shadows",
            id = "SHADOW_WIDTH_FACTOR",
            label = "Shadow Width Factor",
            min = 0.1,
            max = 2,
            value = self.sightManager.constants.SHADOW_WIDTH_FACTOR or 0.5,
            step = 0.1,
            tooltip = "Controls how wide shadows become"
        }
    }
    
    -- Create checkboxes
    self.checkboxes = {
        {
            tab = "obstruction",
            id = "CORNER_PEEK_ENABLED",
            label = "Enable Corner Peeking",
            value = self.sightManager.constants.CORNER_PEEK_ENABLED,
            tooltip = "Allow peeking around corners"
        }
    }
    
    -- Create color pickers for occlusion levels
    self.colorPickers = {}
    for i = 1, self.sightManager.constants.AMBIENT_OCCLUSION_LEVELS do
        local color = self.sightManager.constants.AMBIENT_OCCLUSION_COLORS[i] or {0, 0, 0, 0.5}
        table.insert(self.colorPickers, {
            tab = "occlusion",
            id = "OCCLUSION_COLOR_" .. i,
            label = "Level " .. i .. " Color",
            value = {color[1], color[2], color[3], color[4]},
            tooltip = "Color for occlusion level " .. i
        })
    end
    
    -- Create miss chance inputs for occlusion levels
    self.missChanceInputs = {}
    for i = 1, self.sightManager.constants.AMBIENT_OCCLUSION_LEVELS do
        local missChance = self.sightManager.constants.AMBIENT_OCCLUSION_MISS_CHANCE[i] or 0.1 * i
        table.insert(self.sliders, {
            tab = "occlusion",
            id = "MISS_CHANCE_" .. i,
            label = "Level " .. i .. " Miss Chance",
            min = 0,
            max = 1,
            value = missChance,
            step = 0.05,
            tooltip = "Miss chance for occlusion level " .. i
        })
    end
end

function SightTweakUI:toggle()
    self.visible = not self.visible
    
    -- If becoming visible, store original values
    if self.visible then
        self:storeOriginalValues()
    end
end

function SightTweakUI:update(dt)
    if not self.visible then return end
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    
    -- Apply button
    local applyX = self.x + self.width - 180
    local applyY = self.y + self.height - 40
    local applyWidth = 80
    local applyHeight = 30
    self.applyButtonHovered = mx >= applyX and mx <= applyX + applyWidth and
                             my >= applyY and my <= applyY + applyHeight
    
    -- Reset button
    local resetX = self.x + self.width - 90
    local resetY = self.y + self.height - 40
    local resetWidth = 80
    local resetHeight = 30
    self.resetButtonHovered = mx >= resetX and mx <= resetX + resetWidth and
                             my >= resetY and my <= resetY + resetHeight
    
    -- Close button
    local closeX = self.x + self.width - 30
    local closeY = self.y + 10
    local closeSize = 20
    self.closeButtonHovered = mx >= closeX and mx <= closeX + closeSize and
                             my >= closeY and my <= closeY + closeSize
end

function SightTweakUI:draw()
    if not self.visible then return end
    
    -- Save current state
    love.graphics.push()
    
    -- Draw panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    
    -- Draw header
    love.graphics.setColor(0.2, 0.2, 0.3, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.headerHeight, 5, 5)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Sight System Tweaker", self.x + 10, self.y + 8)
    
    -- Draw close button
    if self.closeButtonHovered then
        love.graphics.setColor(1, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", self.x + self.width - 30, self.y + 10, 20, 20, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("X", self.x + self.width - 23, self.y + 11)
    
    -- Draw tabs
    self:drawTabs()
    
    -- Draw content based on active tab
    self:drawTabContent()
    
    -- Draw apply and reset buttons
    self:drawButtons()
    
    -- Restore state
    love.graphics.pop()
end

function SightTweakUI:drawTabs()
    local tabs = {"ranges", "obstruction", "peripheral", "factors", "occlusion", "shadows"}
    local tabWidth = self.width / #tabs
    
    for i, tab in ipairs(tabs) do
        local tabX = self.x + (i-1) * tabWidth
        local isActive = self.activeTab == tab
        
        -- Tab background
        if isActive then
            love.graphics.setColor(0.3, 0.3, 0.4, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.3, 1)
        end
        love.graphics.rectangle("fill", tabX, self.y + self.headerHeight, tabWidth, self.tabHeight)
        
        -- Tab text
        love.graphics.setColor(1, 1, 1, 1)
        local tabName = tab:sub(1,1):upper() .. tab:sub(2)
        local textWidth = love.graphics.getFont():getWidth(tabName)
        love.graphics.print(tabName, tabX + (tabWidth - textWidth) / 2, self.y + self.headerHeight + 5)
    end
end

function SightTweakUI:drawTabContent()
    local contentY = self.y + self.headerHeight + self.tabHeight + self.padding
    local contentHeight = self.height - self.headerHeight - self.tabHeight - self.padding * 2 - 50 -- Leave space for buttons
    
    -- Draw sliders for current tab
    local yOffset = 0
    for _, slider in ipairs(self.sliders) do
        if slider.tab == self.activeTab then
            self:drawSlider(slider, contentY + yOffset)
            yOffset = yOffset + 50
        end
    end
    
    -- Draw checkboxes for current tab
    for _, checkbox in ipairs(self.checkboxes) do
        if checkbox.tab == self.activeTab then
            self:drawCheckbox(checkbox, contentY + yOffset)
            yOffset = yOffset + 30
        end
    end
    
    -- Draw color pickers for current tab
    for _, colorPicker in ipairs(self.colorPickers) do
        if colorPicker.tab == self.activeTab then
            self:drawColorPicker(colorPicker, contentY + yOffset)
            yOffset = yOffset + 60
        end
    end
end

function SightTweakUI:drawSlider(slider, y)
    -- Draw label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(slider.label .. ": " .. slider.value, self.x + 10, y)
    
    -- Draw slider track
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", self.x + 10, y + 25, self.width - 20, 10, 3, 3)
    
    -- Draw slider handle
    local handlePos = self.x + 10 + (self.width - 20) * ((slider.value - slider.min) / (slider.max - slider.min))
    love.graphics.setColor(0.7, 0.7, 0.9, 1)
    love.graphics.rectangle("fill", handlePos - 5, y + 20, 10, 20, 3, 3)
    
    -- Draw tooltip if available
    if slider.tooltip then
        local mx, my = love.mouse.getPosition()
        if mx >= self.x + 10 and mx <= self.x + 10 + self.width - 20 and
           my >= y and my <= y + 35 then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
            love.graphics.rectangle("fill", mx + 10, my + 10, 200, 30, 3, 3)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(slider.tooltip, mx + 15, my + 15)
        end
    end
end

function SightTweakUI:drawCheckbox(checkbox, y)
    -- Draw label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(checkbox.label, self.x + 40, y + 5)
    
    -- Draw checkbox
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", self.x + 10, y + 5, 20, 20, 3, 3)
    
    -- Draw check if enabled
    if checkbox.value then
        love.graphics.setColor(0.7, 0.7, 0.9, 1)
        love.graphics.rectangle("fill", self.x + 13, y + 8, 14, 14, 2, 2)
    end
    
    -- Draw tooltip if available
    if checkbox.tooltip then
        local mx, my = love.mouse.getPosition()
        if mx >= self.x + 10 and mx <= self.x + self.width - 10 and
           my >= y and my <= y + 25 then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
            love.graphics.rectangle("fill", mx + 10, my + 10, 200, 30, 3, 3)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(checkbox.tooltip, mx + 15, my + 15)
        end
    end
end

function SightTweakUI:drawColorPicker(colorPicker, y)
    -- Draw label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(colorPicker.label, self.x + 10, y)
    
    -- Draw color preview
    love.graphics.setColor(unpack(colorPicker.value))
    love.graphics.rectangle("fill", self.x + 10, y + 25, 30, 30, 3, 3)
    
    -- Draw RGBA sliders
    local sliderWidth = (self.width - 60) / 4
    local components = {"R", "G", "B", "A"}
    
    for i, comp in ipairs(components) do
        -- Draw component label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(comp, self.x + 50 + (i-1) * sliderWidth, y + 25)
        
        -- Draw slider track
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", self.x + 50 + (i-1) * sliderWidth, y + 40, sliderWidth - 10, 10, 3, 3)
        
        -- Draw slider handle
        local value = colorPicker.value[i]
        local max = i < 4 and 1 or 1  -- RGB: 0-1, A: 0-1
        local handlePos = self.x + 50 + (i-1) * sliderWidth + (sliderWidth - 10) * (value / max)
        love.graphics.setColor(0.7, 0.7, 0.9, 1)
        love.graphics.rectangle("fill", handlePos - 5, y + 35, 10, 20, 3, 3)
        
        -- Draw value
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("%.2f", value), self.x + 50 + (i-1) * sliderWidth, y + 50)
    end
end

function SightTweakUI:drawButtons()
    -- Apply button
    if self.applyButtonHovered then
        love.graphics.setColor(0.3, 0.7, 0.3, 1)
    else
        love.graphics.setColor(0.2, 0.6, 0.2, 1)
    end
    love.graphics.rectangle("fill", self.x + self.width - 180, self.y + self.height - 40, 80, 30, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Apply", self.x + self.width - 165, self.y + self.height - 35)
    
    -- Reset button
    if self.resetButtonHovered then
        love.graphics.setColor(0.7, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.6, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", self.x + self.width - 90, self.y + self.height - 40, 80, 30, 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Reset", self.x + self.width - 75, self.y + self.height - 35)
end

function SightTweakUI:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if clicking on header for dragging
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.headerHeight then
        self.dragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end
    
    -- Check if clicking on close button
    if self.closeButtonHovered then
        self.visible = false
        return true
    end
    
    -- Check if clicking on tabs
    local tabs = {"ranges", "obstruction", "peripheral", "factors", "occlusion", "shadows"}
    local tabWidth = self.width / #tabs
    
    if y >= self.y + self.headerHeight and y <= self.y + self.headerHeight + self.tabHeight then
        for i, tab in ipairs(tabs) do
            local tabX = self.x + (i-1) * tabWidth
            if x >= tabX and x <= tabX + tabWidth then
                self.activeTab = tab
                return true
            end
        end
    end
    
    -- Check if clicking on apply button
    if self.applyButtonHovered then
        self:applyChanges()
        return true
    end
    
    -- Check if clicking on reset button
    if self.resetButtonHovered then
        self:resetToOriginal()
        return true
    end
    
    -- Check if clicking on a slider
    local contentY = self.y + self.headerHeight + self.tabHeight + self.padding
    local yOffset = 0
    
    for _, slider in ipairs(self.sliders) do
        if slider.tab == self.activeTab then
            if x >= self.x + 10 and x <= self.x + self.width - 10 and
               y >= contentY + yOffset + 20 and y <= contentY + yOffset + 40 then
                -- Calculate new value based on click position
                local ratio = (x - (self.x + 10)) / (self.width - 20)
                slider.value = slider.min + ratio * (slider.max - slider.min)
                
                -- Apply step if specified
                if slider.step then
                    slider.value = math.floor(slider.value / slider.step + 0.5) * slider.step
                end
                
                -- Clamp to min/max
                slider.value = math.max(slider.min, math.min(slider.max, slider.value))
                
                -- For integer sliders, round to nearest integer
                if not slider.step or slider.step >= 1 then
                    slider.value = math.floor(slider.value + 0.5)
                end
                
                return true
            end
            yOffset = yOffset + 50
        end
    end
    
    -- Check if clicking on a checkbox
    for _, checkbox in ipairs(self.checkboxes) do
        if checkbox.tab == self.activeTab then
            if x >= self.x + 10 and x <= self.x + 30 and
               y >= contentY + yOffset + 5 and y <= contentY + yOffset + 25 then
                checkbox.value = not checkbox.value
                return true
            end
            yOffset = yOffset + 30
        end
    end
    
    -- Check if clicking on a color picker
    for _, colorPicker in ipairs(self.colorPickers) do
        if colorPicker.tab == self.activeTab then
            -- Check if clicking on color components
            local sliderWidth = (self.width - 60) / 4
            
            for i = 1, 4 do
                if x >= self.x + 50 + (i-1) * sliderWidth and x <= self.x + 50 + i * sliderWidth - 10 and
                   y >= contentY + yOffset + 35 and y <= contentY + yOffset + 55 then
                    -- Calculate new value based on click position
                    local ratio = (x - (self.x + 50 + (i-1) * sliderWidth)) / (sliderWidth - 10)
                    local max = i < 4 and 1 or 1  -- RGB: 0-1, A: 0-1
                    colorPicker.value[i] = ratio * max
                    
                    -- Clamp to 0-max
                    colorPicker.value[i] = math.max(0, math.min(max, colorPicker.value[i]))
                    
                    return true
                end
            end
            
            yOffset = yOffset + 60
        end
    end
    
    return false
end

function SightTweakUI:mousereleased(x, y, button)
    self.dragging = false
    return self.visible
end

function SightTweakUI:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    if self.dragging then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
        return true
    end
    
    return false
end

function SightTweakUI:applyChanges()
    -- Apply all changes to the sight manager
    for _, slider in ipairs(self.sliders) do
        if slider.id:find("MISS_CHANCE_") then
            -- Handle miss chance values
            local level = tonumber(slider.id:match("MISS_CHANCE_(%d+)"))
            self.sightManager.constants.AMBIENT_OCCLUSION_MISS_CHANCE[level] = slider.value
        elseif slider.id == "SHADOW_LENGTH" then
            -- Add shadow length if it doesn't exist
            self.sightManager.constants.SHADOW_LENGTH = slider.value
        elseif slider.id == "SHADOW_WIDTH_FACTOR" then
            -- Add shadow width factor if it doesn't exist
            self.sightManager.constants.SHADOW_WIDTH_FACTOR = slider.value
        else
            -- Handle regular constants
            self.sightManager.constants[slider.id] = slider.value
        end
    end
    
    -- Apply checkbox values
    for _, checkbox in ipairs(self.checkboxes) do
        self.sightManager.constants[checkbox.id] = checkbox.value
    end
    
    -- Apply color picker values
    for _, colorPicker in ipairs(self.colorPickers) do
        if colorPicker.id:find("OCCLUSION_COLOR_") then
            local level = tonumber(colorPicker.id:match("OCCLUSION_COLOR_(%d+)"))
            self.sightManager.constants.AMBIENT_OCCLUSION_COLORS[level] = {unpack(colorPicker.value)}
        end
    end
    
    -- Update the sight system
    if self.sightManager.updateAllSight then
        self.sightManager:updateAllSight()
    end
    
    -- Force wall cache update
    self.sightManager.wallCacheNeedsUpdate = true
end

function SightTweakUI:resetToOriginal()
    -- Reset all sliders to original values
    for _, slider in ipairs(self.sliders) do
        if slider.id:find("MISS_CHANCE_") then
            -- Handle miss chance values
            local level = tonumber(slider.id:match("MISS_CHANCE_(%d+)"))
            local missChances = {}
            for num in string.gmatch(self.originalValues.AMBIENT_OCCLUSION_MISS_CHANCE, "([^,]+)") do
                table.insert(missChances, tonumber(num))
            end
            slider.value = missChances[level] or 0.1 * level
        else
            -- Handle regular constants
            slider.value = self.originalValues[slider.id] or slider.value
        end
    end
    
    -- Reset checkbox values
    for _, checkbox in ipairs(self.checkboxes) do
        checkbox.value = self.originalValues[checkbox.id]
    end
    
    -- Reset color picker values
    for _, colorPicker in ipairs(self.colorPickers) do
        if colorPicker.id:find("OCCLUSION_COLOR_") then
            local level = tonumber(colorPicker.id:match("OCCLUSION_COLOR_(%d+)"))
            if self.originalValues.AMBIENT_OCCLUSION_COLORS[level] then
                colorPicker.value = {unpack(self.originalValues.AMBIENT_OCCLUSION_COLORS[level])}
            end
        end
    end
    
    -- Apply the reset values
    self:applyChanges()
end

function SightTweakUI:keypressed(key)
    if key == "escape" and self.visible then
        self.visible = false
        return true
    end
    return false
end

return SightTweakUI
