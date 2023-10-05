local Timer = {}
Timer.__index = Timer

function Timer.new(duration, isRunning, isLoop)
    local self = setmetatable({}, Timer)
    self.maxDuration = duration
    self.count = duration
    self.isLoop = isLoop or false
    self.running = isRunning or false
    return self
end

function Timer:update(dt)
    if self:isFinished() then
        self.count = self.count + self.maxDuration
        self.running = self.isLoop
    end

    if self.running then
        self.count = self.count - dt
    end
end

function Timer:start()
    self.count = self.maxDuration
    self.running = true
end

function Timer:stop()
    self.running = false
    self.count = self.maxDuration
end

function Timer:isFinished()
    return self.count <= 0
end

function Timer:isRunning() return self.running end

function Timer:getCount() return self.count end

function Timer:setDuration(newDuration)
    self.maxDuration = newDuration
    self.count = newDuration
end

return Timer