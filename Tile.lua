Tile = {}
Tile.__index = Tile

function Tile.new(x, y)
    local self = setmetatable({}, Tile)
    self.x, self.y = x, y

    return self
end

function Tile:getX() return self.x end
function Tile:getY() return self.y end
function Tile:setPosition(x, y) self.x, self.y = x, y end

return Tile