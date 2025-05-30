function MapEditor:drawButton(x, y, width, height, text, enabled, isSelected)
    local isHovered = self:isMouseOver(x, y, width, height)
    local isClicked = isHovered and love.mouse.isDown(1) and enabled
    
    -- Set button colors based on state
    if not enabled then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    elseif isSelected then
        love.graphics.setColor(0.3, 0.7, 1, 1)
    elseif isClicked then
        love.graphics.setColor(0.6, 0.6, 0.8, 1)
    elseif isHovered then
        love.graphics.setColor(0.5, 0.5, 0.7, 1)
    else
        love.graphics.setColor(0.4, 0.4, 0.6, 1)
    end
    
    -- Draw button background
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)
    
    -- Draw button border
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)
    
    -- Draw button text
    love.graphics.setFont(self.buttonFont)
    love.graphics.setColor(1, 1, 1, 1)
    
    local textWidth = self.buttonFont:getWidth(text)
    local textHeight = self.buttonFont:getHeight()
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - textHeight) / 2
    
    love.graphics.print(text, textX, textY)
    
    -- Return true if the button was clicked
    return isHovered and love.mouse.isDown(1) and not self.isDragging and enabled
end
