-- Timer utility
-- Simple timer class for tracking elapsed time

local Timer = {}
Timer.__index = Timer

function Timer:new()
    local self = setmetatable({}, Timer)
    self.time = 0
    return self
end

function Timer:update(dt)
    self.time = self.time + dt
end

function Timer:getTime()
    return self.time
end

function Timer:reset()
    self.time = 0
end

return Timer
