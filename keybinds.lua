local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(...)
    local self = setmetatable({}, Keybind)

    self.keys = {...}

    return self
end

function Keybind:isDown()
    for _, key in ipairs(self.keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end

function Keybind:hasKey(pressedKey)
    for _, key in ipairs(self.keys) do
        if pressedKey == key then
            return true
        end
    end
    return false
end

local keybinds = {
    moveLeft = Keybind.new('left'),
    moveRight = Keybind.new('right'),
    rotateClockwise = Keybind.new('up', 'x'),
    rotateCounterClockwise = Keybind.new('z', 'lctrl'),
    softDrop = Keybind.new('down'),
    hardDrop = Keybind.new('space'),
    hold = Keybind.new('c', 'lshift')
}

return keybinds