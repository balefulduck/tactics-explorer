-- Mouse interaction functions for the MapEditor class

-- Check if mouse is over a rectangle
function MapEditor:isMouseOver(x, y, width, height)
    return self.mouseX >= x and self.mouseX <= x + width and
           self.mouseY >= y and self.mouseY <= y + height
end

-- Check if position is valid on the grid
function MapEditor:isValidGridPosition(gridX, gridY)
    return gridX >= 1 and gridX <= self.width and
           gridY >= 1 and gridY <= self.height
end

-- Check if mouse is over the UI panel
function MapEditor:isMouseOverUI()
    -- Check if mouse is over the UI panel
    return self:isMouseOver(self.panelX, self.panelY, self.panelWidth, 650)
end

-- Check if mouse is over the map area
function MapEditor:isMouseOverMap()
    -- Check if mouse is over the map area
    return self.gridX >= 1 and self.gridX <= self.width and
           self.gridY >= 1 and self.gridY <= self.height
end
