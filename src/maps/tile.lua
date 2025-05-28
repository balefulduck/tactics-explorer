-- Tile class for representing a single grid tile
local Tile = {}
Tile.__index = Tile

-- Tile types and their properties
local tileTypes = {
    floor = {
        color = {0.93, 0.93, 0.93, 1},  -- #eeeeee
        walkable = true
    },
    wall = {
        color = {0.44, 0.44, 0.44, 1},  -- #717171
        walkable = false
    },
    water = {
        color = {0.2, 0.4, 0.8, 1},  -- Blue
        walkable = false
    },
    grass = {
        color = {0.2, 0.7, 0.2, 1},  -- Green
        walkable = true
    }
}

function Tile:new(tileType, gridX, gridY, grid)
    local self = setmetatable({}, Tile)
    
    self.type = tileType or "floor"
    self.gridX = gridX
    self.gridY = gridY
    self.grid = grid
    
    -- Get properties from tileTypes table
    local properties = tileTypes[self.type] or tileTypes.floor
    self.color = properties.color
    self.walkable = properties.walkable
    
    -- Calculate world position with 2px padding between tiles
    local padding = 2
    self.padding = padding
    self.tileSize = grid.tileSize - (padding * 2)
    self.x = grid:gridToWorld(gridX, gridY) + padding
    self.y = grid:gridToWorld(0, gridY) + padding
    
    return self
end

function Tile:update(dt)
    -- No animation needed anymore since dust was removed
end

function Tile:draw()
    -- Draw drop shadow first
    love.graphics.setColor(0, 0, 0, 0.3)  -- Semi-transparent black for shadow
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.tileSize, self.tileSize)
    
    -- Draw the tile as a rectangle
    if self.type == "floor" then
        -- Floor tiles are #eeeeee
        love.graphics.setColor(0.93, 0.93, 0.93, 1)  -- #eeeeee
        love.graphics.rectangle("fill", self.x, self.y, self.tileSize, self.tileSize)
        
        -- Subtle border for floor tiles
        love.graphics.setColor(0.85, 0.85, 0.85, 1)  -- Slightly darker than the fill
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", self.x, self.y, self.tileSize, self.tileSize)
    else if self.type == "wall" then
        -- Wall tiles are #717171 with fat black borders on sides facing the board
        love.graphics.setColor(0.44, 0.44, 0.44, 1)  -- #717171
        love.graphics.rectangle("fill", self.x, self.y, self.tileSize, self.tileSize)
        
        -- Determine which sides of the wall are facing the board
        love.graphics.setColor(0, 0, 0, 1)  -- Black
        love.graphics.setLineWidth(3)  -- Fat border
        
        -- Check adjacent tiles to determine which borders to draw
        local map = self.grid.currentMap
        if map then
            -- Check tile below (if it's not a wall, draw bottom border)
            if map:getTile(self.gridX, self.gridY + 1) and 
               map:getTile(self.gridX, self.gridY + 1).type ~= "wall" then
                love.graphics.line(
                    self.x, self.y + self.tileSize,
                    self.x + self.tileSize, self.y + self.tileSize
                )
            end
            
            -- Check tile above (if it's not a wall, draw top border)
            if map:getTile(self.gridX, self.gridY - 1) and 
               map:getTile(self.gridX, self.gridY - 1).type ~= "wall" then
                love.graphics.line(
                    self.x, self.y,
                    self.x + self.tileSize, self.y
                )
            end
            
            -- Check tile to the right (if it's not a wall, draw right border)
            if map:getTile(self.gridX + 1, self.gridY) and 
               map:getTile(self.gridX + 1, self.gridY).type ~= "wall" then
                love.graphics.line(
                    self.x + self.tileSize, self.y,
                    self.x + self.tileSize, self.y + self.tileSize
                )
            end
            
            -- Check tile to the left (if it's not a wall, draw left border)
            if map:getTile(self.gridX - 1, self.gridY) and 
               map:getTile(self.gridX - 1, self.gridY).type ~= "wall" then
                love.graphics.line(
                    self.x, self.y,
                    self.x, self.y + self.tileSize
                )
            end
        else
            -- If no map reference, just draw a full border
            love.graphics.rectangle("line", self.x, self.y, self.tileSize, self.tileSize)
        end
    else
        -- Any other tile types (fallback)
        love.graphics.setColor(0.93, 0.93, 0.93, 1)  -- #eeeeee
        love.graphics.rectangle("fill", self.x, self.y, self.tileSize, self.tileSize)
    end
    end
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Tile
