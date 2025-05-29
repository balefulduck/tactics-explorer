-- InfoScreen UI Component
-- Displays detailed information about entities

local InfoScreen = {}
InfoScreen.__index = InfoScreen

function InfoScreen:new()
    local self = setmetatable({}, InfoScreen)
    
    -- State
    self.visible = false
    self.targetEntity = nil
    self.alpha = 0 -- For fade effect
    self.fadeSpeed = 4 -- Fade speed (higher = faster)
    
    -- Appearance
    self.width = 900 -- Increased width to accommodate larger image
    self.height = 600 -- Increased height for larger image
    self.padding = 20
    self.cornerRadius = 8
    self.backgroundColor = {0.98, 0.98, 0.98, 1} -- Bright white
    self.accentColor = {0.2, 0.6, 0.9, 1} -- Blue accent
    self.secondaryAccentColor = {0.9, 0.3, 0.3, 1} -- Red accent for warnings/important info
    self.textColor = {0.2, 0.2, 0.2, 1} -- Dark gray text
    self.sectionSpacing = 25
    
    -- Content layout
    self.contentWidth = 350 -- Width of the text content area
    self.imageWidth = 500 -- Width of the image area (increased 3x from original 200)
    
    -- Load Tomorrow fonts
    self.titleFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 24)
    self.headerFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-SemiBold.ttf", 20)
    self.bodyFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 16)
    self.flavorFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Italic.ttf", 18)
    
    -- Load image
    self.image = love.graphics.newImage("assets/images/bb.jpg")
    
    -- Flavor text
    self.flavorText = "This couch is positively crawling. You feel the ten thousand legs even looking at it."
    
    -- Connection line
    self.connectionPoints = {}
    
    return self
end

function InfoScreen:show(entity, sourceX, sourceY)
    self.targetEntity = entity
    self.visible = true
    self.alpha = 0
    
    -- Calculate connection points
    if entity then
        local tileSize = entity.grid.tileSize
        local entityCenterX = entity.x + (entity.width * tileSize) / 2
        local entityCenterY = entity.y + (entity.height * tileSize) / 2
        
        self.connectionPoints = {
            source = {x = entityCenterX, y = entityCenterY},
            target = {x = 0, y = 0} -- Will be calculated in draw
        }
    end
end

function InfoScreen:hide()
    self.visible = false
    self.targetEntity = nil
end

function InfoScreen:toggle(entity, sourceX, sourceY)
    if self.visible and self.targetEntity == entity then
        self:hide()
    else
        self:show(entity, sourceX, sourceY)
    end
end

function InfoScreen:update(dt)
    if self.visible and self.alpha < 1 then
        self.alpha = math.min(1, self.alpha + dt * self.fadeSpeed)
    elseif not self.visible and self.alpha > 0 then
        self.alpha = math.max(0, self.alpha - dt * self.fadeSpeed)
    end
end

function InfoScreen:draw()
    if self.alpha <= 0 or not self.targetEntity then return end
    
    -- Calculate position (centered on screen)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local x = (screenWidth - self.width) / 2
    local y = (screenHeight - self.height) / 2
    
    -- Update connection target point
    self.connectionPoints.target = {x = x + self.width / 2, y = y + 30}
    
    -- Draw connection line
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        self.connectionPoints.source.x, self.connectionPoints.source.y,
        self.connectionPoints.target.x, self.connectionPoints.target.y
    )
    
    -- Draw shadow
    love.graphics.setColor(0, 0, 0, self.alpha * 0.2)
    love.graphics.rectangle("fill", x + 5, y + 5, self.width, self.height, self.cornerRadius, self.cornerRadius)
    
    -- Draw background
    love.graphics.setColor(
        self.backgroundColor[1], 
        self.backgroundColor[2], 
        self.backgroundColor[3], 
        self.alpha * self.backgroundColor[4]
    )
    love.graphics.rectangle("fill", x, y, self.width, self.height, self.cornerRadius, self.cornerRadius)
    
    -- Draw border
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, self.width, self.height, self.cornerRadius, self.cornerRadius)
    
    -- Draw content
    self:drawContent(x, y)
    
    -- Reset colors and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function InfoScreen:drawContent(x, y)
    if not self.targetEntity then return end
    
    local entity = self.targetEntity
    local contentX = x + self.padding
    local contentY = y + self.padding
    
    -- Load the appropriate image based on entity type
    if entity.isWindow then
        -- Use window.jpg for window tiles
        self.image = love.graphics.newImage("assets/images/window.jpg")
        -- Use the flavor text from the entity if available
        if entity.flavorText then
            self.flavorText = entity.flavorText
        end
    elseif self.image == nil or self.image:getWidth() == 0 then
        -- Fallback to default image if needed
        self.image = love.graphics.newImage("assets/images/bb.jpg")
    end
    
    -- Draw title (spans the entire width) with bold effect
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha)
    
    -- Simulate bold by drawing the text multiple times with slight offsets
    love.graphics.print(entity.name, contentX+1, contentY)
    love.graphics.print(entity.name, contentX, contentY+1)
    love.graphics.print(entity.name, contentX+1, contentY+1)
    love.graphics.print(entity.name, contentX, contentY)
    
    contentY = contentY + self.titleFont:getHeight() + 10
    
    -- Draw horizontal separator below title (spans the entire width)
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(contentX, contentY, contentX + self.width - (self.padding * 2), contentY)
    contentY = contentY + 15
    
    -- Draw vertical separator between text content and image
    local verticalSeparatorX = contentX + self.contentWidth
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        verticalSeparatorX, y + self.padding,
        verticalSeparatorX, y + self.height - self.padding
    )
    
    -- Draw flavor text at the top of the right side
    local flavorX = verticalSeparatorX + 20
    local flavorY = y + self.padding + 50 -- Position below the title
    
    -- Use flavor font with a color that simulates italics
    love.graphics.setFont(self.flavorFont)
    love.graphics.setColor(self.secondaryAccentColor[1], self.secondaryAccentColor[2], self.secondaryAccentColor[3], self.alpha * 0.9)
    
    -- Wrap the flavor text to fit the image width with proper padding
    love.graphics.printf(
        self.flavorText,
        flavorX,
        flavorY,
        self.imageWidth - 40,
        "center"
    )
    
    -- Calculate height of the flavor text
    local _, flavorTextLines = self.flavorFont:getWrap(self.flavorText, self.imageWidth - 40)
    local flavorTextHeight = #flavorTextLines * self.flavorFont:getHeight() + 20 -- Add some padding
    
    -- Draw image below the flavor text
    local imageX = verticalSeparatorX + 20
    local imageY = flavorY + flavorTextHeight + 10 -- Position below the flavor text
    
    -- Calculate image dimensions while maintaining aspect ratio
    local imageWidth = self.imageWidth - 40 -- Account for padding
    local imageHeight = imageWidth * (self.image:getHeight() / self.image:getWidth())
    
    -- Draw image with a subtle border
    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.draw(self.image, imageX, imageY, 0, imageWidth / self.image:getWidth(), imageHeight / self.image:getHeight())
    
    -- Draw image border
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", imageX, imageY, imageWidth, imageHeight)
    
    -- Draw image caption
    local captionY = imageY + imageHeight + 10
    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha * 0.8)
    local caption = "Reference Image"
    local captionWidth = self.bodyFont:getWidth(caption)
    love.graphics.print(caption, imageX + (imageWidth - captionWidth) / 2, captionY)
    
    -- Reset font
    love.graphics.setFont(self.bodyFont)
    
    -- Now draw the text content on the left side
    -- Draw basic properties
    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
    love.graphics.print("Basic Properties", contentX, contentY)
    contentY = contentY + self.headerFont:getHeight() + 5
    
    love.graphics.setFont(self.bodyFont)
    
    -- Type
    love.graphics.print("Type: " .. entity.type, contentX + 10, contentY)
    contentY = contentY + self.bodyFont:getHeight() + 5
    
    -- Dimensions
    if entity.properties.dimensions then
        love.graphics.print("Dimensions: " .. entity.properties.dimensions, contentX + 10, contentY)
    else
        love.graphics.print("Dimensions: " .. entity.width .. "x" .. entity.height, contentX + 10, contentY)
    end
    contentY = contentY + self.bodyFont:getHeight() + 5
    
    -- Height
    if entity.properties.height then
        love.graphics.print("Height: " .. entity.properties.height, contentX + 10, contentY)
        contentY = contentY + self.bodyFont:getHeight() + 5
    end
    
    -- Draw section separator
    contentY = contentY + 10
    love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.3)
    love.graphics.line(contentX, contentY, contentX + self.contentWidth - 20, contentY)
    contentY = contentY + 15
    
    -- Draw special properties section
    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
    love.graphics.print("Special Properties", contentX, contentY)
    contentY = contentY + self.headerFont:getHeight() + 5
    
    love.graphics.setFont(self.bodyFont)
    
    -- List special properties
    local specialProps = {}
    if entity.properties.sittable then table.insert(specialProps, "Sittable") end
    if entity.properties.cover then table.insert(specialProps, "Provides Cover") end
    if entity.properties.storage then table.insert(specialProps, "Storage") end
    if entity.properties.searchable then table.insert(specialProps, "Searchable") end
    if entity.properties.breakable then table.insert(specialProps, "Breakable") end
    
    if #specialProps > 0 then
        for _, prop in ipairs(specialProps) do
            love.graphics.print("• " .. prop, contentX + 10, contentY)
            contentY = contentY + self.bodyFont:getHeight() + 5
        end
    else
        love.graphics.print("No special properties", contentX + 10, contentY)
        contentY = contentY + self.bodyFont:getHeight() + 5
    end
    
    -- Draw penetration data if available
    if entity.properties.penetration then
        contentY = contentY + 10
        love.graphics.setColor(self.accentColor[1], self.accentColor[2], self.accentColor[3], self.alpha * 0.3)
        love.graphics.line(contentX, contentY, contentX + self.contentWidth - 20, contentY)
        contentY = contentY + 15
        
        love.graphics.setFont(self.headerFont)
        love.graphics.setColor(self.secondaryAccentColor[1], self.secondaryAccentColor[2], self.secondaryAccentColor[3], self.alpha)
        love.graphics.print("Penetration Values", contentX, contentY)
        contentY = contentY + self.headerFont:getHeight() + 5
        
        love.graphics.setFont(self.bodyFont)
        love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
        
        -- Create a table for penetration values
        local tableX = contentX + 20
        local tableWidth = self.contentWidth - 60
        local colWidth = tableWidth / 2
        
        -- Table headers
        love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha * 0.8)
        love.graphics.print("Caliber", tableX, contentY)
        love.graphics.print("Value", tableX + colWidth, contentY)
        contentY = contentY + self.bodyFont:getHeight() + 5
        
        -- Table separator
        love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha * 0.3)
        love.graphics.line(tableX, contentY, tableX + tableWidth, contentY)
        contentY = contentY + 5
        
        -- Table rows
        love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
        for caliber, value in pairs(entity.properties.penetration) do
            love.graphics.print(caliber, tableX, contentY)
            love.graphics.print(value, tableX + colWidth, contentY)
            contentY = contentY + self.bodyFont:getHeight() + 5
        end
    end
    
    -- Draw footer with hint
    local footerY = y + self.height - self.padding - self.bodyFont:getHeight()
    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha * 0.6)
    love.graphics.print("Press SHIFT again to close", contentX, footerY)
end

return InfoScreen
