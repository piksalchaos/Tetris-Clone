Timer = {}
Timer.__index = Timer

function Timer.new(duration, isRunning, isLoop)
    local self = setmetatable({}, Timer)
    self.maxDuration = duration
    self.count = duration
    self.isLoop = isLoop or false
    self.isRunning = isRunning or false
    return self
end

function Timer:update(dt)
    if self:isFinished() then
        self.count = self.count + self.maxDuration
        self.isRunning = self.isLoop
    end

    if self.isRunning then
        self.count = self.count - dt
    end
end

function Timer:start()
    self.count = self.maxDuration
    self.isRunning = true
end

function Timer:isFinished()
    return self.count <= 0
end

return Timer