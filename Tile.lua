Tile = {}
Tile.__index = Tile

function Tile.new(x, y)
    local self = setmetatable({}, Tile)
    self.x, self.y = x, y

    return self
end

return Tile