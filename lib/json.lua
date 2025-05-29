--
-- json.lua
--
-- A simple JSON encoding/decoding library for Lua
-- 
-- Usage:
--   local json = require("lib.json")
--   local encoded = json.encode({key = "value"})
--   local decoded = json.decode(encoded)
--

local json = {}

-- Encode Lua table to JSON string
function json.encode(data)
    local t = type(data)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return data and "true" or "false"
    elseif t == "number" then
        return tostring(data)
    elseif t == "string" then
        return '"' .. json.escapeString(data) .. '"'
    elseif t == "table" then
        return json.encodeTable(data)
    else
        error("Cannot encode value of type " .. t)
    end
end

-- Escape special characters in string
function json.escapeString(s)
    local escapes = {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['/'] = '\\/',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }
    
    return s:gsub('["\\/\b\f\n\r\t]', escapes)
end

-- Encode table to JSON
function json.encodeTable(t)
    -- Check if table is an array
    local isArray = true
    local maxIndex = 0
    
    for k, v in pairs(t) do
        if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
            isArray = false
            break
        end
        maxIndex = math.max(maxIndex, k)
    end
    
    -- Check if array is sparse
    if isArray and maxIndex > #t * 2 then
        isArray = false
    end
    
    -- Encode as array or object
    if isArray then
        return json.encodeArray(t)
    else
        return json.encodeObject(t)
    end
end

-- Encode array to JSON
function json.encodeArray(t)
    local result = {}
    
    for i, v in ipairs(t) do
        table.insert(result, json.encode(v))
    end
    
    return "[" .. table.concat(result, ",") .. "]"
end

-- Encode object to JSON
function json.encodeObject(t)
    local result = {}
    
    for k, v in pairs(t) do
        if type(k) == "string" or type(k) == "number" then
            table.insert(result, '"' .. tostring(k) .. '":' .. json.encode(v))
        end
    end
    
    return "{" .. table.concat(result, ",") .. "}"
end

-- Decode JSON string to Lua table
function json.decode(s)
    -- Initialize position
    local pos = 1
    
    -- Skip whitespace
    local function skipWhitespace()
        pos = s:find("[^ \t\r\n]", pos) or pos
    end
    
    -- Parse value
    local function parseValue()
        skipWhitespace()
        
        local c = s:sub(pos, pos)
        
        if c == "{" then
            return parseObject()
        elseif c == "[" then
            return parseArray()
        elseif c == '"' then
            return parseString()
        elseif c:match("[0-9%-]") then
            return parseNumber()
        elseif s:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif s:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif s:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            error("Invalid JSON at position " .. pos .. ": " .. s:sub(pos, pos + 10))
        end
    end
    
    -- Parse object
    local function parseObject()
        local obj = {}
        pos = pos + 1 -- Skip '{'
        
        skipWhitespace()
        if s:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        
        while true do
            skipWhitespace()
            
            -- Parse key
            if s:sub(pos, pos) ~= '"' then
                error("Expected string key at position " .. pos)
            end
            
            local key = parseString()
            
            -- Parse colon
            skipWhitespace()
            if s:sub(pos, pos) ~= ":" then
                error("Expected ':' at position " .. pos)
            end
            pos = pos + 1
            
            -- Parse value
            obj[key] = parseValue()
            
            -- Parse comma or end
            skipWhitespace()
            local c = s:sub(pos, pos)
            
            if c == "}" then
                pos = pos + 1
                return obj
            elseif c == "," then
                pos = pos + 1
            else
                error("Expected ',' or '}' at position " .. pos)
            end
        end
    end
    
    -- Parse array
    local function parseArray()
        local arr = {}
        pos = pos + 1 -- Skip '['
        
        skipWhitespace()
        if s:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        
        local index = 1
        
        while true do
            -- Parse value
            arr[index] = parseValue()
            index = index + 1
            
            -- Parse comma or end
            skipWhitespace()
            local c = s:sub(pos, pos)
            
            if c == "]" then
                pos = pos + 1
                return arr
            elseif c == "," then
                pos = pos + 1
            else
                error("Expected ',' or ']' at position " .. pos)
            end
        end
    end
    
    -- Parse string
    local function parseString()
        local startPos = pos + 1 -- Skip opening quote
        local endPos = startPos
        
        while true do
            endPos = s:find('"', endPos)
            
            if not endPos then
                error("Unterminated string starting at position " .. startPos)
            end
            
            -- Check if quote is escaped
            local escapeCount = 0
            local escapePos = endPos - 1
            
            while s:sub(escapePos, escapePos) == "\\" do
                escapeCount = escapeCount + 1
                escapePos = escapePos - 1
            end
            
            if escapeCount % 2 == 0 then
                break
            end
            
            endPos = endPos + 1
        end
        
        local str = s:sub(startPos, endPos - 1)
        pos = endPos + 1 -- Skip closing quote
        
        -- Unescape string
        str = str:gsub("\\.", {
            ['\\"'] = '"',
            ['\\\\'] = '\\',
            ['\\/'] = '/',
            ['\\b'] = '\b',
            ['\\f'] = '\f',
            ['\\n'] = '\n',
            ['\\r'] = '\r',
            ['\\t'] = '\t'
        })
        
        return str
    end
    
    -- Parse number
    local function parseNumber()
        local numStr = s:match("[0-9%.%-eE%+]+", pos)
        pos = pos + #numStr
        return tonumber(numStr)
    end
    
    -- Start parsing
    local result = parseValue()
    
    -- Check for trailing content
    skipWhitespace()
    if pos <= #s then
        error("Trailing content at position " .. pos)
    end
    
    return result
end

return json
