Tile = {}
Tile.__index = Tile

function Tile.new(x, y)
    local self = setmetatable({}, Tile)
    self.x, self.y = x, y

    return self
end

--[[ function Tile:checkFromPosition(relativeX, relativeY, targetX, targetY)
    if self.x + relativeX == targetX and self.y + relativeY == targetY then
        return true
    end
    return false
end

function Tile:checkFromX(relativeX, targetX)
    return Tile:checkFromPosition(relativeX, 0, targetX, self.y)
end

function Tile:checkFromY(relativeY, targetY)
    return Tile:checkFromPosition(0, relativeY, self.x, targetY)
end ]]

return Tile