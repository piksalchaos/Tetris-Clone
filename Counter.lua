local Counter = {}
Counter.__index = Counter

function Counter.new(max)
    local self = setmetatable({}, Counter)
    self.max = max
    self.count = 0
    return self
end

function Counter:increment(amount)
    self.count = self.count + (amount or 1)
end

function Counter:reset() self.count = 0 end

function Counter:setCount(newCount) self.count = newCount end

function Counter:getCount() return self.count end

function Counter:isFinished() return self.count >= self.max end

return Counter