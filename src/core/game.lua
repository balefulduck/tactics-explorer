-- Game class - main game controller
-- Redesigned to use the new entity-based system

local Grid = require("src.core.grid")
local Map = require("src.core.map")
local Player = require("src.entities.player")
local Furniture = require("src.core.furniture")
local Camera = require("src.systems.camera")
local UI = require("src.systems.ui")
local EditorMode = require("src.editor.editorMode")
local PaperEffect = require("src.utils.paperEffect")
local SightTweakIntegration = require("src.systems.sight.sightTweakIntegration")

local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)
    
    -- Game settings
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    self.tileSize = 64  -- Size of each grid tile in pixels
    
    -- Track window size for responsive layout
    self.lastWidth = self.width
    self.lastHeight = self.height
    
    -- Game state
    self.state = "playing"  -- playing, paused, menu, editor, etc.
    self.debug = false
    
    -- Examination mode state
    self.examinationMode = false
    self.examinationCursor = {
        gridX = 0,
        gridY = 0,
        color = {0.1, 0.1, 0.1, 0.4}, -- Dark background for eye
        eyeColor = {0.9, 0.1, 0.1, 1}, -- Bold red for eye
        borderColor = {0, 0, 0, 1}, -- Bold black border
        metallic = true -- Enable metallic effect
    }
    
    return self
end

function Game:load()
    -- Initialize systems
    self.grid = Grid:new(self.tileSize)
    self.camera = Camera:new(self.width, self.height)
    self.ui = UI:new(self)
    
    -- Load the test map instead of creating the default room
    self:loadTestMap()
    
    -- If test map loading fails, fall back to the default room
    if not self.currentMap then
        -- Create a room map (12x14 grid)
        self.currentMap = Map:new(self.grid, 12, 14)
        
        -- Define window positions (centered on east and south walls)
        local windowPositions = {
            {x = 12, y = 7},  -- East wall, centered
            {x = 6, y = 14}   -- South wall, centered
        }
        
        -- Create the room with windows
        self.currentMap:createRoomMap(windowPositions)
        
        -- Create player in the center of the room
        self.player = Player:new(self.grid, 6, 7)
        
        -- Add furniture to the room
        self:setupRoom()
    end
    
    -- Initialize layout dimensions
    self:initializeLayout()
    
    -- Generate paper grain texture (512x512 is enough for tiling)
    self.paperGrainTexture = PaperEffect:createPaperGrainTexture(512, 512)
    self.paperGrainTexture:setWrap("repeat", "repeat")
    
    -- Create paper grain quad for tiling
    local screenWidth, screenHeight = love.graphics.getDimensions()
    self.paperGrainQuad = love.graphics.newQuad(
        0, 0, screenWidth, screenHeight,
        self.paperGrainTexture:getWidth(), self.paperGrainTexture:getHeight()
    )
    
    -- Calculate the appropriate scale for the board to fit in its container
    self:calculateBoardScale()
    
    -- Center camera on player
    self.camera:setTarget(self.player)
    
    -- Initialize editor mode
    self.editorMode = EditorMode:new(self)
    
    -- Initialize sight tweaking UI
    SightTweakIntegration.init(self)
end

function Game:setupRoom()
    -- Create furniture items based on the new 12x14 grid layout
    
    -- Couch in the top right corner
    local couch = Furniture.create("couch", self.grid, 9, 3)
    self.currentMap:addEntity(couch)
    
    -- TV opposite of the couch (across the room)
    local tv = Furniture.create("tv", self.grid, 3, 3)
    self.currentMap:addEntity(tv)
    
    -- Coffee table in front of the sofa
    local coffeeTable = Furniture.create("coffee_table", self.grid, 9, 5, {
        labelText = "coffee table"
    })
    self.currentMap:addEntity(coffeeTable)
    
    -- Cupboard vertically oriented on the left side / west wall
    local cupboard = Furniture.create("cupboard", self.grid, 2, 7, {
        orientation = "vertical" -- Assuming the furniture system supports this
    })
    self.currentMap:addEntity(cupboard)
    
    -- Plants for decoration
    local plant1 = Furniture.create("plant", self.grid, 4, 10)
    self.currentMap:addEntity(plant1)
    
    local plant2 = Furniture.create("plant", self.grid, 8, 10)
    self.currentMap:addEntity(plant2)
end

function Game:update(dt)
    if self.state == "playing" then
        -- Update player
        self.player:update(dt)
        
        -- Update map (which updates all entities and tiles)
        self.currentMap:update(dt)
        
        -- Update camera
        self.camera:update(dt)
        
        -- Update UI
        self.ui:update(dt)
        
        -- Update sight tweaking UI
        SightTweakIntegration.update(dt)
    elseif self.state == "editor" then
        -- Update editor mode
        self.editorMode:update(dt)
    end
end

function Game:draw()
    -- Draw newspaper background and layout
    self:drawBackground()
    
    if self.state == "playing" then
        -- Draw header section (newspaper headline)
        self:drawHeader()
        
        -- Recalculate board scale if window size changes
        if self.lastWidth ~= love.graphics.getWidth() or self.lastHeight ~= love.graphics.getHeight() then
            self.lastWidth = love.graphics.getWidth()
            self.lastHeight = love.graphics.getHeight()
            self:calculateBoardScale()
        end
        
        -- Draw board section with game map
        self:drawBoardSection()
        
        -- Draw info section (context-sensitive UI)
        self:drawInfoSection()
        
        -- Draw footer section
        self:drawFooterSection()
        
        -- Draw debug info if enabled
        if self.debug then
            self:drawDebugInfo()
        end
        
        -- Draw sight tweaking UI
        SightTweakIntegration.draw()
    elseif self.state == "editor" then
        -- Draw editor mode
        self.editorMode:draw()
    end
end

function Game:initializeLayout()
    -- Calculate layout dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    self.layout = {
        -- Header section (newspaper headline)
        header = {
            x = 20,
            y = 20,
            width = screenWidth - 40,
            height = 60
        },
        -- Game board section (left side, 75% width)
        board = {
            x = 20,
            y = 100,
            width = math.floor((screenWidth - 40) * 0.75),
            height = screenHeight - 180 -- Leave space for header and footer
        },
        -- Info section (right side, 25% width)
        info = {
            x = math.floor(20 + (screenWidth - 40) * 0.75) + 20, -- Board x + board width + margin
            y = 100,
            width = math.floor((screenWidth - 40) * 0.25) - 20, -- 25% width minus margin
            height = screenHeight - 180
        },
        -- Footer section
        footer = {
            x = 20,
            y = screenHeight - 60,
            width = screenWidth - 40,
            height = 40
        }
    }
end

function Game:drawBackground()
    -- Draw newspaper background and layout
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Update layout if window size changes
    if self.lastWidth ~= screenWidth or self.lastHeight ~= screenHeight then
        self.lastWidth = screenWidth
        self.lastHeight = screenHeight
        self:initializeLayout()
        self:calculateBoardScale()
        
        -- Update paper grain quad for new screen dimensions
        self.paperGrainQuad = love.graphics.newQuad(
            0, 0, screenWidth, screenHeight,
            self.paperGrainTexture:getWidth(), self.paperGrainTexture:getHeight()
        )
    end
    
    -- Set paper background color (#edf5ef)
    love.graphics.setColor(0.93, 0.96, 0.94, 1) -- #edf5ef in RGB
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw paper grain texture
    love.graphics.setColor(1, 1, 1, 0.7) -- Slightly transparent to blend with background
    love.graphics.draw(self.paperGrainTexture, self.paperGrainQuad, 0, 0)
    
    -- Draw section borders (newspaper columns)
    love.graphics.setColor(0.7, 0.65, 0.55, 0.8) -- Darker than background
    love.graphics.setLineWidth(1)
    
    -- Header border
    love.graphics.rectangle("line", self.layout.header.x, self.layout.header.y, 
                           self.layout.header.width, self.layout.header.height)
    
    -- Board border
    love.graphics.rectangle("line", self.layout.board.x, self.layout.board.y, 
                           self.layout.board.width, self.layout.board.height)
    
    -- Info border
    love.graphics.rectangle("line", self.layout.info.x, self.layout.info.y, 
                           self.layout.info.width, self.layout.info.height)
    
    -- Footer border
    love.graphics.rectangle("line", self.layout.footer.x, self.layout.footer.y, 
                           self.layout.footer.width, self.layout.footer.height)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Game:drawBoardFrame()
    if not self.currentMap then return end
    
    local mapWidth = self.currentMap.width * self.grid.tileSize
    local mapHeight = self.currentMap.height * self.grid.tileSize
    
    -- Draw a subtle shadow for the board (newspaper print effect)
    love.graphics.setColor(0.6, 0.55, 0.5, 0.3) -- Darker paper color for shadow
    love.graphics.rectangle("fill", -5, -5, mapWidth + 10, mapHeight + 10)
    
    -- Draw board background (slightly off-white for printed paper look)
    love.graphics.setColor(0.95, 0.93, 0.9, 1) -- Slightly off-white
    love.graphics.rectangle("fill", 0, 0, mapWidth, mapHeight)
    
    -- Draw subtle grid lines for the board
    love.graphics.setColor(0.85, 0.83, 0.8, 0.5) -- Light gray for grid lines
    love.graphics.setLineWidth(0.5)
    
    -- Draw vertical grid lines
    for x = 0, mapWidth, self.grid.tileSize do
        love.graphics.line(x, 0, x, mapHeight)
    end
    
    -- Draw horizontal grid lines
    for y = 0, mapHeight, self.grid.tileSize do
        love.graphics.line(0, y, mapWidth, y)
    end
    
    -- Reset color and line width
    love.graphics.setLineWidth(1)
end

-- Draw the board section with the game map
function Game:drawBoardSection()
    -- Apply clipping to ensure the board stays within its container
    love.graphics.setScissor(
        self.layout.board.x, 
        self.layout.board.y, 
        self.layout.board.width, 
        self.layout.board.height
    )
    
    -- Set the camera to the board position
    self.camera:setBoardViewport(
        self.layout.board.x,
        self.layout.board.y,
        self.layout.board.width,
        self.layout.board.height
    )
    
    -- Apply camera transformations
    self.camera:set()
    
    -- Draw the map
    if self.currentMap then
        self.currentMap:draw()
    end
    
    -- Draw grid for debugging if needed
    if self.debug then
        self:drawBoardFrame()
    end
    
    -- Reset camera transformations
    self.camera:unset()
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw board border
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.layout.board.x, self.layout.board.y, 
                           self.layout.board.width, self.layout.board.height)
    
    -- Display zoom level indicator if not at default zoom
    if math.abs(self.camera.scale - 1.0) > 0.01 then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print(string.format("Zoom: %.1fx", self.camera.scale), 
                          self.layout.board.x + 10, 
                          self.layout.board.y + self.layout.board.height - 30)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the header section (newspaper headline)
function Game:drawHeader()
    -- Draw header background (slightly darker paper for visual separation)
    love.graphics.setColor(0.89, 0.92, 0.90, 1) -- Slightly darker than main background
    love.graphics.rectangle("fill", self.layout.header.x, self.layout.header.y, 
                           self.layout.header.width, self.layout.header.height)
    
    -- Draw newspaper title
    love.graphics.setColor(0.15, 0.15, 0.15, 1) -- Dark text
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Black.ttf", 28))
    love.graphics.print("THE DAILY EXPLORER", self.layout.header.x + 20, self.layout.header.y + 15)
    
    -- Draw date and issue number
    local dateStr = "MAY 29, 2025"
    local issueStr = "ISSUE #42"
    
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12))
    local dateWidth = love.graphics.getFont():getWidth(dateStr)
    love.graphics.print(dateStr, self.layout.header.x + self.layout.header.width - dateWidth - 20, 
                      self.layout.header.y + 15)
    
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 14))
    local issueWidth = love.graphics.getFont():getWidth(issueStr)
    love.graphics.print(issueStr, self.layout.header.x + self.layout.header.width - issueWidth - 20, 
                      self.layout.header.y + 35)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the info section (context-sensitive UI)
function Game:drawInfoSection()
    -- Check if we have an entity to display info for
    local entityToDisplay = self.ui.infoScreen.targetEntity
    
    -- Draw info section title
    love.graphics.setColor(0.2, 0.2, 0.2, 1) -- Dark text
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 16))
    
    if entityToDisplay and self.ui.infoScreen.visible then
        love.graphics.print(entityToDisplay.name, self.layout.info.x + 10, self.layout.info.y + 10)
    else
        love.graphics.print("CURRENT FOCUS", self.layout.info.x + 10, self.layout.info.y + 10)
    end
    
    -- Draw horizontal separator
    love.graphics.setColor(0.6, 0.55, 0.5, 0.8) -- Darker paper color
    love.graphics.setLineWidth(1)
    love.graphics.line(self.layout.info.x + 10, self.layout.info.y + 35, 
                     self.layout.info.x + self.layout.info.width - 10, self.layout.info.y + 35)
    
    -- Draw content based on whether we have an entity to display
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 14))
    love.graphics.setColor(0.2, 0.2, 0.2, 1) -- Dark text
    
    local infoY = self.layout.info.y + 50
    
    if entityToDisplay and self.ui.infoScreen.visible then
        -- Display entity information
        -- Type
        love.graphics.print("Type: " .. entityToDisplay.type, self.layout.info.x + 15, infoY)
        infoY = infoY + 25
        
        -- Dimensions
        if entityToDisplay.properties and entityToDisplay.properties.dimensions then
            love.graphics.print("Dimensions: " .. entityToDisplay.properties.dimensions, self.layout.info.x + 15, infoY)
        else
            love.graphics.print("Dimensions: " .. entityToDisplay.width .. "x" .. entityToDisplay.height, self.layout.info.x + 15, infoY)
        end
        infoY = infoY + 25
        
        -- Special properties section
        love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 14))
        love.graphics.print("Special Properties", self.layout.info.x + 15, infoY)
        infoY = infoY + 25
        
        -- List special properties
        love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 14))
        local specialProps = {}
        if entityToDisplay.properties then
            if entityToDisplay.properties.sittable then table.insert(specialProps, "Sittable") end
            if entityToDisplay.properties.cover then table.insert(specialProps, "Provides Cover") end
            if entityToDisplay.properties.storage then table.insert(specialProps, "Storage") end
            if entityToDisplay.properties.searchable then table.insert(specialProps, "Searchable") end
            if entityToDisplay.properties.breakable then table.insert(specialProps, "Breakable") end
        end
        
        if #specialProps > 0 then
            for _, prop in ipairs(specialProps) do
                love.graphics.print("• " .. prop, self.layout.info.x + 20, infoY)
                infoY = infoY + 20
            end
        else
            love.graphics.print("No special properties", self.layout.info.x + 20, infoY)
            infoY = infoY + 20
        end
        
        -- Draw flavor text
        infoY = infoY + 15
        love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Italic.ttf", 14))
        love.graphics.setColor(0.6, 0.3, 0.3, 0.9) -- Reddish for flavor text
        
        -- Use entity flavor text if available
        local flavorText = self.ui.infoScreen.flavorText
        if entityToDisplay.flavorText then
            flavorText = entityToDisplay.flavorText
        end
        
        love.graphics.printf(flavorText, self.layout.info.x + 15, infoY, self.layout.info.width - 30, "left")
        
        -- Draw associated image if available
        infoY = infoY + 80 -- Space for the flavor text
        
        -- Determine which image to use based on entity type or name
        local imagePath = nil
        if entityToDisplay.name:lower():find("window") then
            imagePath = "assets/images/window.jpg"
        elseif entityToDisplay.name:lower():find("couch") or entityToDisplay.name:lower():find("sofa") then
            imagePath = "assets/images/bb.jpg"
        end
        
        if imagePath then
            -- Use cached image or load it if not already cached
            if not self.cachedImages then self.cachedImages = {} end
            if not self.cachedImages[imagePath] then
                self.cachedImages[imagePath] = {
                    image = love.graphics.newImage(imagePath),
                    captionFont = love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12)
                }
            end
            
            local imageData = self.cachedImages[imagePath]
            local image = imageData.image
            
            -- Calculate image dimensions to fit in the info panel
            local maxWidth = self.layout.info.width - 30
            local maxHeight = 150 -- Maximum height for the image
            
            local scale = math.min(maxWidth / image:getWidth(), maxHeight / image:getHeight())
            local scaledWidth = image:getWidth() * scale
            local scaledHeight = image:getHeight() * scale
            
            -- Center the image horizontally
            local imageX = self.layout.info.x + (self.layout.info.width - scaledWidth) / 2
            
            -- Draw the image
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, imageX, infoY, 0, scale, scale)
            
            -- Add a caption
            infoY = infoY + scaledHeight + 10
            love.graphics.setFont(imageData.captionFont)
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
            
            local caption = "Reference Image"
            local captionWidth = imageData.captionFont:getWidth(caption)
            love.graphics.print(caption, self.layout.info.x + (self.layout.info.width - captionWidth) / 2, infoY)
        end
    else
        -- Show default player info
        love.graphics.print("Player Position: " .. self.player.gridX .. ", " .. self.player.gridY, 
                          self.layout.info.x + 15, infoY)
        infoY = infoY + 25
        
        love.graphics.print("Room Size: " .. self.currentMap.width .. "x" .. self.currentMap.height, 
                          self.layout.info.x + 15, infoY)
        infoY = infoY + 25
        
        love.graphics.print("Entities: " .. #self.currentMap.entities, 
                          self.layout.info.x + 15, infoY)
        
        -- Draw instructions
        local instructionsY = self.layout.info.y + self.layout.info.height - 100
        love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Bold.ttf", 14))
        love.graphics.print("CONTROLS", self.layout.info.x + 10, instructionsY)
        
        instructionsY = instructionsY + 25
        love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12))
        love.graphics.print("WASD/Arrows - Move", self.layout.info.x + 15, instructionsY)
        instructionsY = instructionsY + 20
        love.graphics.print("SHIFT - View Info", self.layout.info.x + 15, instructionsY)
        instructionsY = instructionsY + 20
        love.graphics.print("ESC - Quit", self.layout.info.x + 15, instructionsY)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the footer section
function Game:drawFooterSection()
    -- Draw footer content
    love.graphics.setColor(0.2, 0.2, 0.2, 1) -- Dark text
    love.graphics.setFont(love.graphics.newFont("assets/fonts/Tomorrow/Tomorrow-Regular.ttf", 12))
    
    local footerText = "FPS: " .. love.timer.getFPS() .. " | Press F1 for debug grid | F2 for editor mode"
    love.graphics.print(footerText, self.layout.footer.x + 10, self.layout.footer.y + 15)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Calculate the appropriate scale for the board to fit in its container
function Game:calculateBoardScale()
    -- Calculate the total map size in pixels
    local mapWidth = self.currentMap.width * self.grid.tileSize
    local mapHeight = self.currentMap.height * self.grid.tileSize
    
    -- Calculate the available space in the board section (with some padding)
    local availableWidth = self.layout.board.width - 40
    local availableHeight = self.layout.board.height - 40
    
    -- Calculate the scale needed to fit the map in the available space
    local scaleX = availableWidth / mapWidth
    local scaleY = availableHeight / mapHeight
    
    -- Use the smaller scale to ensure the entire map fits
    local scale = math.min(scaleX, scaleY, 1.0) -- Cap at 1.0 to avoid enlarging small maps
    
    -- Update the camera scale
    self.camera.scale = scale
    
    -- Center the map in the available space
    local centeredX = (self.layout.board.width - (mapWidth * scale)) / 2
    local centeredY = (self.layout.board.height - (mapHeight * scale)) / 2
    
    -- Update the camera's board viewport with the centered position
    self.camera:setBoardViewport(
        self.layout.board.x + centeredX,
        self.layout.board.y + centeredY,
        mapWidth * scale,
        mapHeight * scale
    )
    
    -- Adjust the grid tile size based on the scale
    self.grid.scaledTileSize = self.grid.tileSize * scale
end

function Game:keypressed(key)
    -- Debug output for key presses
    print("Game keypressed: " .. key)
    
    -- Check if sight tweaking UI handles the key press
    if key == "f7" then
        print("F7 key detected in Game:keypressed")
        if SightTweakIntegration.ui then
            print("SightTweakIntegration.ui exists, toggling visibility")
            SightTweakIntegration.ui:toggle()
            return
        else
            print("SightTweakIntegration.ui does not exist")
            -- Try to reinitialize
            print("Attempting to reinitialize SightTweakIntegration")
            SightTweakIntegration.init(self)
            if SightTweakIntegration.ui then
                print("Reinitialization successful, toggling visibility")
                SightTweakIntegration.ui:toggle()
                return
            end
        end
    end
    
    -- Toggle editor mode with F2
    if key == "f2" then
        if self.state == "editor" then
            self.editorMode:closeEditor()
        else
            self.editorMode:launchEditor()
        end
        return
    end
    
    if self.state == "playing" then
        -- Check if shift is being held (for direction change)
        local isShiftHeld = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        
        -- If in examination mode
        if self.examinationMode then
            -- Movement controls for cursor
            local dx, dy = 0, 0
            
            if key == "up" or key == "w" then
                dy = -1
            elseif key == "down" or key == "s" then
                dy = 1
            elseif key == "left" or key == "a" then
                dx = -1
            elseif key == "right" or key == "d" then
                dx = 1
            end
            
            if dx ~= 0 or dy ~= 0 then
                -- Move the examination cursor
                self:moveExaminationCursor(dx, dy)
            end
            
            -- Exit examination mode with X key
            if key == "x" then
                self:toggleExaminationMode()
            end
            
            -- Also exit with escape key
            if key == "escape" then
                self:toggleExaminationMode()
            end
        else
            -- Normal gameplay mode
            -- Movement controls for player
            local dx, dy = 0, 0
            
            if key == "up" or key == "w" then
                dy = -1
            elseif key == "down" or key == "s" then
                dy = 1
            elseif key == "left" or key == "a" then
                dx = -1
            elseif key == "right" or key == "d" then
                dx = 1
            end
            
            if dx ~= 0 or dy ~= 0 then
                if isShiftHeld then
                    -- Change direction without moving (costs 25 TU)
                    local newDirection = nil
                    
                    if dx == 1 and dy == 0 then
                        newDirection = 0     -- East
                    elseif dx == 0 and dy == 1 then
                        newDirection = 1     -- South
                    elseif dx == -1 and dy == 0 then
                        newDirection = 2     -- West
                    elseif dx == 0 and dy == -1 then
                        newDirection = 3     -- North
                    end
                    
                    if newDirection ~= nil and self.player.facingDirection ~= newDirection then
                        print("Changing direction to " .. newDirection)
                        
                        -- Use the time system to queue the direction change action
                        local ActionSystem = require("src.systems.time.actionSystem")
                        local directionAction = ActionSystem.ChangeDirectionAction:new(newDirection)
                        
                        -- Queue the action in the time system if available
                        if self.timeManager then
                            self.timeManager:queueAction(self.player, directionAction)
                        else
                            -- Fallback if time system not available
                            self.player:changeDirection(newDirection)
                        end
                    end
                else
                    -- Normal movement (costs 25 TU)
                    if self.timeManager then
                        -- Use the time system to queue the movement action
                        local ActionSystem = require("src.systems.time.actionSystem")
                        local moveAction = ActionSystem.MoveAction:new(dx, dy)
                        self.timeManager:queueAction(self.player, moveAction)
                    else
                        -- Fallback to direct movement if time system not available
                        self.player:move(dx, dy)
                    end
                end
            end
            
            -- Toggle debug mode
            if key == "f1" then
                self.debug = not self.debug
            end
            
            -- Interaction key
            if key == "e" or key == "space" then
                self:interact()
            end
            
            -- Examination mode (X key)
            if key == "x" then
                self:toggleExaminationMode()
            end
        end
    elseif self.state == "editor" then
        -- Pass keypresses to the editor
        self.editorMode:keypressed(key)
    end
end

function Game:interact()
    -- Get the tile in front of the player (based on facing direction)
    -- For now, just check all adjacent tiles
    local adjacentPositions = {
        {x = self.player.gridX + 1, y = self.player.gridY},
        {x = self.player.gridX - 1, y = self.player.gridY},
        {x = self.player.gridX, y = self.player.gridY + 1},
        {x = self.player.gridX, y = self.player.gridY - 1}
    }
    
    for _, pos in ipairs(adjacentPositions) do
        local entities = self.currentMap:getEntitiesAt(pos.x, pos.y)
        
        for _, entity in ipairs(entities) do
            if entity.interactable then
                local result = entity:interact()
                
                if result.success then
                    -- Show interaction result
                    self.ui:showMessage(result.message, 2)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Toggle examination mode on/off
function Game:toggleExaminationMode()
    -- If we're entering examination mode
    if not self.examinationMode then
        -- Check if there's a single entity adjacent to the player
        local adjacentEntities = self:getAdjacentEntities()
        
        if #adjacentEntities == 1 then
            -- If there's exactly one entity, show its info directly without cursor mode
            self:showEntityInfoDirect(adjacentEntities[1])
            return
        else
            -- Otherwise, activate cursor mode
            self.examinationMode = true
            -- Initialize cursor at player position
            self.examinationCursor.gridX = self.player.gridX
            self.examinationCursor.gridY = self.player.gridY
            -- Show info for whatever is at the cursor position
            self:showEntityInfoAtCursor()
            -- Show a helpful message
            self.ui:showMessage("Examination mode active. Use WASD to move cursor, X to exit.", 3)
        end
    else
        -- Exit examination mode
        self.examinationMode = false
        -- Hide the info screen
        self.ui.infoScreen.visible = false
        self.ui.infoScreen.targetEntity = nil
        -- Show exit message
        self.ui:showMessage("Exited examination mode.", 1)
    end
end

-- Move the examination cursor
function Game:moveExaminationCursor(dx, dy)
    if not self.examinationMode then return end
    
    -- Update cursor position
    local newX = self.examinationCursor.gridX + dx
    local newY = self.examinationCursor.gridY + dy
    
    -- Ensure cursor stays within map bounds
    if newX >= 1 and newX <= self.currentMap.width and
       newY >= 1 and newY <= self.currentMap.height then
        self.examinationCursor.gridX = newX
        self.examinationCursor.gridY = newY
        
        -- Update info display for the new position
        self:showEntityInfoAtCursor()
    end
end

-- Show entity info for whatever is at the cursor position
function Game:showEntityInfoAtCursor()
    if not self.examinationMode then return end
    
    local x = self.examinationCursor.gridX
    local y = self.examinationCursor.gridY
    
    -- Use the new unified examination system to get the most relevant object
    local examinable = self.currentMap:getExaminableAt(x, y)
    
    if examinable then
        -- Get standardized examination info from the object
        local info = examinable:getExaminationInfo()
        
        -- Show the entity info using the existing method
        self:showEntityInfoDirect(examinable)
    else
        -- If nothing examinable found, show generic floor info
        self:showFloorTileInfo(x, y)
    end
end

-- Show floor tile info
function Game:showFloorTileInfo(x, y)
    -- Create a virtual entity for the floor tile
    local floorTile = {
        name = "Floor Tile",
        type = "floor",
        properties = {
            dimensions = "1x1",
            height = 0
        },
        flavorText = "Where would you be without the floor beneath your feet?",
        x = x,
        y = y,
        gridX = x,
        gridY = y,
        width = 1,
        height = 1
    }
    
    -- Show info for this virtual entity
    self:showEntityInfoDirect(floorTile)
end

-- Show entity info directly without checking adjacency
function Game:showEntityInfoDirect(entity)
    -- Make sure the entity has a name
    if not entity.name then entity.name = "Unknown Object" end
    -- Make sure the entity has a type
    if not entity.type then entity.type = "furniture" end
    -- Make sure the entity has properties
    if not entity.properties then entity.properties = {} end
    
    -- Set info screen visibility
    self.ui.infoScreen.visible = true
    self.ui.infoScreen.targetEntity = entity
    self.ui.infoScreen.alpha = 0 -- Start fade in
end

-- Get all entities adjacent to the player
function Game:getAdjacentEntities()
    local adjacentPositions = {
        {x = self.player.gridX + 1, y = self.player.gridY},
        {x = self.player.gridX - 1, y = self.player.gridY},
        {x = self.player.gridX, y = self.player.gridY + 1},
        {x = self.player.gridX, y = self.player.gridY - 1}
    }
    
    local adjacentEntities = {}
    
    for _, pos in ipairs(adjacentPositions) do
        local entities = self.currentMap:getEntitiesAt(pos.x, pos.y)
        for _, entity in ipairs(entities) do
            -- Make sure entity has the necessary properties for display
            if entity.name then
                table.insert(adjacentEntities, entity)
            end
        end
    end
    
    return adjacentEntities
end

-- Legacy function for shift key compatibility
function Game:showEntityInfo()
    local adjacentEntities = self:getAdjacentEntities()
    
    -- If there's exactly one entity, show its info screen
    if #adjacentEntities == 1 then
        self:showEntityInfoDirect(adjacentEntities[1])
        return true
    elseif #adjacentEntities > 1 then
        -- If there are multiple entities, show a message
        self.ui:showMessage("Multiple objects nearby. Move closer to a specific object.", 2)
        return false
    else
        -- If there are no entities, show a message
        self.ui:showMessage("No objects nearby to inspect.", 2)
        return false
    end
end

function Game:keyreleased(key)
    -- Handle key releases if needed
end

-- Draw the examination cursor
function Game:drawExaminationCursor()
    if not self.examinationMode then return end
    
    -- Get world position of cursor
    local x, y = self.grid:gridToWorld(self.examinationCursor.gridX, self.examinationCursor.gridY)
    local tileSize = self.grid.tileSize
    
    -- Calculate center position and sizes
    local centerX = x + tileSize / 2
    local centerY = y + tileSize / 2
    local eyeSize = tileSize * 0.7 -- Size of the eye
    
    -- Draw cursor background
    love.graphics.setColor(self.examinationCursor.color)
    love.graphics.rectangle("fill", x, y, tileSize, tileSize)
    
    -- Create eye icon with metallic effect
    
    -- Draw bold black border around the tile
    love.graphics.setColor(self.examinationCursor.borderColor)
    love.graphics.setLineWidth(4) -- Bold border
    love.graphics.rectangle("line", x, y, tileSize, tileSize)
    
    -- Draw a custom eye symbol with metallic effect
    -- For metallic effect, draw multiple layers with gradient
    if self.examinationCursor.metallic then
        -- Metallic gradient effect (darker to brighter red)
        local gradientSteps = 5
        for i = 1, gradientSteps do
            local factor = i / gradientSteps
            -- Create a metallic gradient from darker to brighter
            local r = self.examinationCursor.eyeColor[1] * (0.7 + 0.5 * factor)
            local g = self.examinationCursor.eyeColor[2] * (0.7 + 0.3 * factor)
            local b = self.examinationCursor.eyeColor[3] * (0.7 + 0.3 * factor)
            
            -- Adjust position slightly for each layer to create depth
            local offsetX = (gradientSteps - i) * 0.5
            local offsetY = (gradientSteps - i) * 0.5
            
            love.graphics.setColor(r, g, b, self.examinationCursor.eyeColor[4])
            
            -- Draw a custom eye shape
            local eyeWidth = tileSize * 0.6
            local eyeHeight = tileSize * 0.3
            
            -- Draw the eye outline (oval)
            love.graphics.ellipse(
                "fill",
                centerX - offsetX,
                centerY - offsetY,
                eyeWidth / 2,
                eyeHeight / 2
            )
            
            -- Draw the pupil (darker circle in the center)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.circle(
                "fill",
                centerX - offsetX,
                centerY - offsetY,
                eyeHeight / 3
            )
        end
    else
        -- Simple version without metallic effect
        love.graphics.setColor(self.examinationCursor.eyeColor)
        
        -- Draw a custom eye shape
        local eyeWidth = tileSize * 0.6
        local eyeHeight = tileSize * 0.3
        
        -- Draw the eye outline (oval)
        love.graphics.ellipse(
            "fill",
            centerX,
            centerY,
            eyeWidth / 2,
            eyeHeight / 2
        )
        
        -- Draw the pupil (darker circle in the center)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle(
            "fill",
            centerX,
            centerY,
            eyeHeight / 3
        )
    end
    
    -- Reset color, line width, and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(love.graphics.getFont())
end

function Game:mousepressed(x, y, button)
    -- Check if sight tweaking UI handles the mouse press
    if SightTweakIntegration.mousepressed(x, y, button) then
        return
    end
    
    if self.state == "playing" then
        -- Handle middle mouse button for panning
        if button == 3 then  -- Middle mouse button
            self.camera:startPan(x, y)
            return
        end
        
        -- Convert screen coordinates to world coordinates
        local worldX, worldY = self.camera:screenToWorld(x, y)
        
        -- Convert world coordinates to grid coordinates
        local gridX, gridY = self.grid:worldToGrid(worldX, worldY)
        
        -- Handle grid-based interactions
        if button == 1 then  -- Left click
            -- Example: Select a tile or move to it
            print("Grid clicked: " .. gridX .. ", " .. gridY)
        end
    elseif self.state == "editor" then
        -- Pass mouse events to the editor
        self.editorMode:mousepressed(x, y, button)
    end
end

function Game:mousereleased(x, y, button)
    -- Check if sight tweaking UI handles the mouse release
    if SightTweakIntegration.mousereleased(x, y, button) then
        return
    end
    
    if self.state == "playing" then
        -- Stop panning when middle mouse button is released
        if button == 3 then  -- Middle mouse button
            self.camera:stopPan()
            return
        end
    elseif self.state == "editor" then
        -- Pass mouse events to the editor
        self.editorMode:mousereleased(x, y, button)
    end
end

function Game:wheelmoved(x, y)
    if self.state == "editor" then
        -- Pass wheel events to the editor for zooming
        self.editorMode:wheelmoved(x, y)
    elseif self.state == "playing" then
        -- Handle zooming in normal gameplay
        local mouseX, mouseY = love.mouse.getPosition()
        self.camera:zoomAt(mouseX, mouseY, y)
    end
end

function Game:mousemoved(x, y, dx, dy)
    -- Check if sight tweaking UI handles the mouse movement
    if SightTweakIntegration.mousemoved(x, y, dx, dy) then
        return
    end
    
    if self.state == "playing" then
        -- Update camera panning if active
        self.camera:updatePan(x, y)
    elseif self.state == "editor" then
        -- Pass mouse movement to editor if needed
        -- self.editorMode:mousemoved(x, y, dx, dy)
    end
end

function Game:textinput(text)
    if self.state == "editor" then
        -- Pass text input to the editor
        self.editorMode:textinput(text)
    end
end

function Game:loadTestMap()
    -- Load the test map module
    local TestMap = require("src.maps.testMap")
    
    -- Create the test map
    self.currentMap = TestMap.create(self)
    
    -- The player is already created and added to the map in the TestMap.create function
    -- and assigned to the game.player property
    
    print("Test map loaded successfully")
    return true
end

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
return Game
