local Timer = require 'Timer'
local Tile = require 'Tile'

local TileManager = {}
TileManager.__index = TileManager

function TileManager.new(width, height)
    local self = setmetatable({}, TileManager)

    self.tiles = {}
    self.activeTiles = {}
    self.descendTimer = Timer.new(1, true, true)
    self.board = {
        width = width or 10,
        height = height or 20
    }
    
    return self
end

function TileManager:update(dt)
    self.descendTimer:update(dt)

    if self.descendTimer:isFinished() then
        if not self:checkActiveTilesFromY(1, self.board.height) then
            self:moveActiveTiles(0, 1)
        end
    end
end

function TileManager:newTile(x, y, active)
    local newTile = Tile.new(x, y)
    table.insert(self.tiles, newTile)
    if active then table.insert(self.activeTiles, newTile) end
end

local function moveTiles(tiles, relativeX, relativeY)
    for i, tile in ipairs(tiles) do
        tile.x, tile.y = tile.x + relativeX, tile.y + relativeY
    end
end

function TileManager:moveActiveTiles(relativeX, relativeY)
    moveTiles(self.activeTiles, relativeX, relativeY)
end

local function checkTileFromPosition(tile, relativeX, relativeY, targetX, targetY)
    targetX = targetX or tile.x
    targetY = targetY or tile.y
    if tile.x + relativeX == targetX and tile.y + relativeY == targetY then
        return true
    end
    return false
end

function TileManager:checkActiveTilesFromPosition(
    relativeX, relativeY, targetX, targetY
)
    for i, tile in ipairs(self.activeTiles) do
        if checkTileFromPosition(
            tile, relativeX, relativeY, targetX, targetY
        )
        then return true end
    end
    return false
end
 
function TileManager:checkActiveTilesFromX(relativeX, targetX)
    return self:checkActiveTilesFromPosition(relativeX, 0, targetX, nil)
end

function TileManager:checkActiveTilesFromY(relativeY, targetY)
    return self:checkActiveTilesFromPosition(0, relativeY, nil, targetY)
end

return TileManager