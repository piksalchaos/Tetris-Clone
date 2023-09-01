local Timer = require 'Timer'
local Tile = require 'Tile'
local keybinds = require 'keybinds'

local TileManager = {}
TileManager.__index = TileManager

function TileManager.new(width, height)
    local self = setmetatable({}, TileManager)

    self.tiles = {}
    self.activeTiles = {}
    self.timerDurations = {
        descend = {
            default = 0.85,
            softDrop = 0.2
        },
        move = 0.15
    }
    self.timers = {
        descend = Timer.new(self.timerDurations.descend.default, true, true),
        move = Timer.new(self.timerDurations.move, false, true)
    }
    
    self.board = {
        width = width or 10,
        height = height or 20
    }
    self.currentDirection = nil
    
    return self
end

function TileManager:update(dt)
    for _, timer in pairs(self.timers) do
        timer:update(dt)
    end

    if self.timers.descend:isFinished() then
        self:moveActiveTilesOneDown()
    end
    if self.timers.move:isFinished() then
        self:moveActiveTilesOneHorizontally(self.currentDirection)
    end
end

function TileManager:keypressed(key)
    if key == keybinds.moveLeft or key == keybinds.moveRight then
        self:moveActiveTilesOneHorizontally(key)
        self.timers.move:start()
    end
    if key == keybinds.softDrop then
        self:moveActiveTilesOneDown()
        self.timers.descend:setDuration(self.timerDurations.descend.softDrop)
        self.timers.descend:start()
    end
end

function TileManager:keyreleased(key)
    if key == keybinds.moveLeft or key == keybinds.moveRight then
        self.timers.move:stop()
    end
    if key == keybinds.softDrop then
        self.timers.descend:setDuration(self.timerDurations.descend.default)
        self.timers.descend:start()
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

function TileManager:checkActiveTilesFromPosition(
    relativeX, relativeY, targetX, targetY
)
    for i, tile in ipairs(self.activeTiles) do
        targetX = targetX or tile.x
        targetY = targetY or tile.y
        if tile.x + relativeX ~= targetX or tile.y + relativeY ~= targetY then
            return false
        end
    end
    return true
end
 
function TileManager:checkActiveTilesFromX(relativeX, targetX)
    return self:checkActiveTilesFromPosition(relativeX, 0, targetX, nil)
end

function TileManager:checkActiveTilesFromY(relativeY, targetY)
    return self:checkActiveTilesFromPosition(0, relativeY, nil, targetY)
end

function TileManager:moveActiveTilesOneHorizontally(horizontalDirection)
    if horizontalDirection == 'left' then
        if not self:checkActiveTilesFromX(-1, -1) then
            self:moveActiveTiles(-1, 0)
        end
    elseif horizontalDirection == 'right' then
        if not self:checkActiveTilesFromX(1, self.board.width) then
            self:moveActiveTiles(1, 0)
        end
    end
    self.currentDirection = horizontalDirection
end

function TileManager:moveActiveTilesOneDown()
    if not self:checkActiveTilesFromY(1, self.board.height) then
        self:moveActiveTiles(0, 1)
    end
end

return TileManager