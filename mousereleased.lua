function MapEditor:mousereleased(x, y, button)
    if not self.active then return end
    
    -- Handle map browser if it's visible
    if self.mapBrowser.visible then
        return
    end
    
    if button == 1 then  -- Left click
        self.isDragging = false
    end
end
