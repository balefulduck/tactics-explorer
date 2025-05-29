-- Paper Effect Utility
-- Provides functions for creating realistic paper textures and organic text rendering

local PaperEffect = {}

-- Generate a noise texture for paper grain effect
function PaperEffect:createPaperGrainTexture(width, height)
    -- Create a new ImageData object to hold our grain texture
    local imageData = love.image.newImageData(width, height)
    
    -- Generate noise for paper grain
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            -- Create subtle noise variations
            local noise = love.math.noise(x / 20, y / 20) * 0.05
            local noise2 = love.math.noise(x / 5, y / 5) * 0.02
            
            -- Combine noise patterns for more natural look
            local value = 1 - (noise + noise2)
            
            -- Add slight color variation to simulate recycled paper
            local r = value * 0.93 + love.math.random() * 0.07
            local g = value * 0.96 + love.math.random() * 0.04
            local b = value * 0.94 + love.math.random() * 0.06
            
            -- Set the pixel color
            imageData:setPixel(x, y, r, g, b, 1)
        end
    end
    
    -- Convert the ImageData to an Image
    return love.graphics.newImage(imageData)
end

-- Draw text with a slight organic/imperfect look
function PaperEffect:drawOrganicText(text, x, y, font, color, scale)
    scale = scale or 1
    
    -- Save current font
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(font)
    
    -- Draw the text multiple times with slight variations for an imperfect ink look
    for i = 1, 3 do
        -- Slightly vary the alpha for each layer
        local alpha = color[4] * (0.7 + (i * 0.1))
        
        -- Vary the position slightly for each layer
        local offsetX = love.math.random(-1, 1) * 0.3 * scale
        local offsetY = love.math.random(-1, 1) * 0.3 * scale
        
        -- Draw with slightly varied color
        love.graphics.setColor(
            color[1] * (0.95 + love.math.random() * 0.05),
            color[2] * (0.95 + love.math.random() * 0.05),
            color[3] * (0.95 + love.math.random() * 0.05),
            alpha
        )
        
        -- Draw the text at the slightly offset position
        love.graphics.print(text, x + offsetX, y + offsetY)
    end
    
    -- Restore previous font
    love.graphics.setFont(prevFont)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw text with a slight organic/imperfect look and word wrapping
function PaperEffect:drawOrganicTextWrapped(text, x, y, width, align, font, color, scale)
    scale = scale or 1
    align = align or "left"
    
    -- Save current font
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(font)
    
    -- Draw the text multiple times with slight variations for an imperfect ink look
    for i = 1, 3 do
        -- Slightly vary the alpha for each layer
        local alpha = color[4] * (0.7 + (i * 0.1))
        
        -- Vary the position slightly for each layer
        local offsetX = love.math.random(-1, 1) * 0.3 * scale
        local offsetY = love.math.random(-1, 1) * 0.3 * scale
        
        -- Draw with slightly varied color
        love.graphics.setColor(
            color[1] * (0.95 + love.math.random() * 0.05),
            color[2] * (0.95 + love.math.random() * 0.05),
            color[3] * (0.95 + love.math.random() * 0.05),
            alpha
        )
        
        -- Draw the text at the slightly offset position with wrapping
        love.graphics.printf(text, x + offsetX, y + offsetY, width, align)
    end
    
    -- Restore previous font
    love.graphics.setFont(prevFont)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return PaperEffect
