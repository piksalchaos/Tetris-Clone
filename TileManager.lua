local Timer = require 'Timer'
local Tile = require 'Tile'
local keybinds = require 'keybinds'

local TileManager = {}
TileManager.__index = TileManager

function TileManager.new(width, height)
    local self = setmetatable({}, TileManager)

    self.tiles = {}
    self.activeTiles = {}
    self.idleTiles = {}
    self.timerDurations = {
        descend = {
            default = 0.85,
            softDrop = 0.12
        },
        move = 0.15,
        settle = 0.3
    }
    self.timers = {
        descend = Timer.new(self.timerDurations.descend.default, true, true),
        move = Timer.new(self.timerDurations.move, false, true),
        settle = Timer.new(self.timerDurations.settle, false, false)
    }
    
    self.board = {
        width = width or 10,
        height = height or 20
    }
    self.horizontalDirection = 0
    
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
        self:moveActiveTilesOneHorizontally()
    end
    if self.timers.settle:isFinished() then
        
        self:settle()
    end

    if love.keyboard.isDown(keybinds.moveLeft) then
        self.horizontalDirection = -1
    elseif love.keyboard.isDown(keybinds.moveRight) then
        self.horizontalDirection = 1
    else
        self.timers.move:stop()
    end
end

function TileManager:keypressed(key)
    if key == keybinds.moveLeft or key == keybinds.moveRight then
        if key == keybinds.moveLeft then self.horizontalDirection = -1
        else self.horizontalDirection = 1 end
        self:moveActiveTilesOneHorizontally()
        self.timers.move:start()
    end
    if key == keybinds.softDrop then
        self:moveActiveTilesOneDown()
        self.timers.descend:setDuration(self.timerDurations.descend.softDrop)
        self.timers.descend:start()
    end
    if key == keybinds.hardDrop then self:hardDrop() end
end

function TileManager:keyreleased(key)
    if key == keybinds.softDrop then
        self.timers.descend:setDuration(self.timerDurations.descend.default)
        self.timers.descend:start()
    end
end

function TileManager:newTile(x, y, active)
    local newTile = Tile.new(x, y)
    table.insert(self.tiles, newTile)
    if active then
        table.insert(self.activeTiles, newTile)
    else
        table.insert(self.idleTiles, newTile)
    end
end

local function moveTiles(tiles, relativeX, relativeY)
    for i, tile in ipairs(tiles) do
        tile:setPosition(tile:getX() + relativeX, tile:getY() + relativeY)
    end
end

function TileManager:moveActiveTiles(relativeX, relativeY)
    moveTiles(self.activeTiles, relativeX, relativeY)
end

function TileManager:checkActiveTilesFromPosition(
    relativeX, relativeY, targetX, targetY
)
    for _, tile in ipairs(self.activeTiles) do
        if tile:getX() + relativeX == (targetX or tile:getX())
        and tile:getY() + relativeY == (targetY or tile:getY()) then
            return true
        end
    end
    return false
end
 
function TileManager:checkActiveTilesFromX(relativeX, targetX)
    return self:checkActiveTilesFromPosition(relativeX, 0, targetX, nil)
end

function TileManager:checkActiveTilesFromY(relativeY, targetY)
    return self:checkActiveTilesFromPosition(0, relativeY, nil, targetY)
end
function TileManager:moveActiveTilesOneHorizontally()
    local canMove = true

    for _, idleTile in ipairs(self.idleTiles) do
        if self:checkActiveTilesFromPosition(
            self.horizontalDirection, 0, idleTile:getX(), idleTile:getY()
        ) then
            canMove = false
        end
    end

    if self:checkActiveTilesFromX(self.horizontalDirection, -1)
    or self:checkActiveTilesFromX(self.horizontalDirection, self.board.width)
    then canMove = false end

    if canMove then
        self:moveActiveTiles(self.horizontalDirection, 0)
    end

    if self.timers.settle:isRunning() then
        if not self:aboutToSettle() then self.timers.settle:stop() end
    end
end

function TileManager:moveActiveTilesOneDown()
    if self:aboutToSettle() then
        self.timers.settle:start()
    else
        self:moveActiveTiles(0, 1)
    end
end

function TileManager:aboutToSettle()
    if self:checkActiveTilesFromY(1, self.board.height) then
        return true
    end
    for _, tile in ipairs(self.idleTiles) do
        if self:checkActiveTilesFromPosition(0, 1, tile:getX(), tile:getY()) then
            return true
        end
    end
    return false
end

function TileManager:settle()
    for _, activeTile in ipairs(self.activeTiles) do
        table.insert(self.idleTiles, activeTile)
    end
    self.activeTiles = {}
end

function TileManager:hardDrop()
    while not self:aboutToSettle() do self:moveActiveTiles(0, 1) end
    self:settle()
end

return TileManager