function Game:loadMap(mapName)
    if not mapName then return end
    
    -- Sanitize map name for filename
    local safeMapName = mapName:gsub("[^%w_%-%.]" , "_")
    if safeMapName == "" then safeMapName = "custom_map" end
    
    -- Load from file
    local filename = "maps/" .. safeMapName .. ".json"
    
    if not love.filesystem.getInfo(filename) then
        print("No saved map found: " .. filename)
        return
    end
    
    local mapJson, size = love.filesystem.read(filename)
    
    if not mapJson then
        print("Failed to read map file: " .. filename)
        return
    end
    
    -- Parse JSON
    local json = require("lib.json")
    local mapData = json.decode(mapJson)
    
    if not mapData then
        print("Failed to parse map data")
        return
    end
    
    -- Create a new map with the loaded dimensions
    local width = mapData.width or 12
    local height = mapData.height or 14
    
    -- Create a new grid and map
    self.grid = Grid:new(self.tileSize)
    self.currentMap = Map:new(self.grid, width, height)
    
    -- Load tiles
    for y = 1, height do
        for x = 1, width do
            if mapData.tiles and mapData.tiles[y] and mapData.tiles[y][x] then
                local tileData = mapData.tiles[y][x]
                if tileData.isWindow then
                    self.currentMap:setTile(x, y, "wall", {isWindow = true})
                else
                    self.currentMap:setTile(x, y, tileData.type)
                end
            else
                -- Default to floor if no tile data
                self.currentMap:setTile(x, y, "floor")
            end
        end
    end
    
    -- Load entities
    if mapData.entities then
        for _, entityData in ipairs(mapData.entities) do
            local entity = Furniture.create(entityData.type, self.grid, entityData.x, entityData.y)
            if entity then
                self.currentMap:addEntity(entity)
            end
        end
    end
    
    -- Recalculate board scale
    self:calculateBoardScale()
    
    print("Map loaded from " .. filename)
end
