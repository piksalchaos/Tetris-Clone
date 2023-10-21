local Timer = require 'Timer'
local Counter = require 'Counter'
local Tile = require 'Tile'
local keybinds = require 'keybinds'
local TetriminoManager = require 'TetriminoManager'

local TileManager = {}
TileManager.__index = TileManager

function TileManager.new(width, height)
    local self = setmetatable({}, TileManager)

    self.tiles = {}
    self.activeTiles = {}
    self.idleTiles = {}
    self.timers = {
        descend = Timer.new(0.85, true, true),
        softDrop = Timer.new(0.075, false, true),
        quickShiftDelay = Timer.new(0.1, false, false),
        quickShift = Timer.new(0.05, false, true),
        settle = Timer.new(0.5, false, false)
    }
    
    self.board = {
        width = width or 10,
        height = height or 20
    }
    self.tetriminoManager = TetriminoManager.new()

    self.tetriminoData = {}
    self.tetriminoData.rect = {x=0, y=0, width=0, height=0}
    self.tetriminoData.rotationState = 0
    self.tetriminoData.kickTests = {}
    self.horizontalDirection = 0

    self.aboutToSettleLastDescension = false

    local resetCounterMax = 15
    self.resetCounters = {
        shift = Counter.new(resetCounterMax),
        rotation = Counter.new(resetCounterMax)
    }
    
    return self
end

function TileManager:update(dt)
    for _, timer in pairs(self.timers) do
        timer:update(dt)
    end

    if self.timers.descend:isFinished() or self.timers.softDrop:isFinished() then
        self:descendActiveTiles()
    end

    if not self:aboutToSettle() then
        self.timers.settle:stop()
    end
    
    if self.timers.settle:isFinished()
    or ((self.resetCounters.shift:isFinished() or self.resetCounters.rotation:isFinished())
    and self:aboutToSettle()) then
        self:settleActiveTiles()
    end

    if keybinds.moveLeft:isDown() then
        self.horizontalDirection = -1
    elseif keybinds.moveRight:isDown() then
        self.horizontalDirection = 1
    end

    if self.timers.quickShiftDelay:isFinished() then
        self.timers.quickShift:start()
    end
    if self.timers.quickShift:isFinished() then
        self:shiftActiveTilesHorizontally(self.horizontalDirection)
    end
end

function TileManager:keypressed(key)
    if keybinds.moveLeft:hasKey(key) then
        self:shiftActiveTilesHorizontally(-1)
        self.timers.quickShiftDelay:start()
    elseif keybinds.moveRight:hasKey(key) then
        self:shiftActiveTilesHorizontally(1)
        self.timers.quickShiftDelay:start()
    end

    if keybinds.softDrop:hasKey(key) then
        self:descendActiveTiles()
        self.timers.descend:stop()
        self.timers.softDrop:start()
    end
    if keybinds.hardDrop:hasKey(key) then self:hardDropActiveTiles() end
    if keybinds.rotateClockwise:hasKey(key) then self:rotateActiveTiles(true) end
    if keybinds.rotateCounterClockwise:hasKey(key) then self:rotateActiveTiles(false) end
end

function TileManager:keyreleased(key)
    if keybinds.softDrop:hasKey(key) then
        self.timers.descend:start()
        self.timers.softDrop:stop()
    end
    if keybinds.moveLeft:hasKey(key) or keybinds.moveRight:hasKey(key) then
        if self.timers.quickShift:isRunning() then
            self.timers.quickShift:stop()
        else
            self.timers.quickShiftDelay:stop()
        end
    end
end

function TileManager:newTile(x, y, color, active)
    local newTile = Tile.new(x, y, color)
    table.insert(self.tiles, newTile)
    if active then
        table.insert(self.activeTiles, newTile)
    else
        table.insert(self.idleTiles, newTile)
    end
end

function TileManager:newTetrimino()
    local tetrimino = self.tetriminoManager:getNextTetrimino()

    self.tetriminoData.rect.width, self.tetriminoData.rect.height = tetrimino:getRect()
    self.tetriminoData.rect.x = self.board.width/2 - math.ceil(self.tetriminoData.rect.width/2)
    self.tetriminoData.rect.y = -2

    self.tetriminoData.rotationState = 0
    self.tetriminoData.kickTests = tetrimino:getKickTests()

    for _, coordinate in ipairs(tetrimino:getTileCoordinates()) do
        self:newTile(
            coordinate[1] + self.tetriminoData.rect.x,
            coordinate[2] + self.tetriminoData.rect.y,
            tetrimino:getColor(),
            true
        )
    end

    self.aboutToSettleLastDescension = false
end

function TileManager:moveActiveTiles(relativeX, relativeY)
    for _, tile in ipairs(self.activeTiles) do
        tile:setPosition(tile:getX() + relativeX, tile:getY() + relativeY)
    end
    self.tetriminoData.rect.x = self.tetriminoData.rect.x + relativeX
    self.tetriminoData.rect.y = self.tetriminoData.rect.y + relativeY
end

function TileManager:checkActiveTiles(func)
    for _, tile in ipairs(self.activeTiles) do
        if func(tile) then return true end
    end
    return false
end

function TileManager:isTileOnIdleTiles(tile, offsetX, offsetY)
    offsetX, offsetY = offsetX or 0, offsetY or 0
    for _, idleTile in ipairs(self.idleTiles) do
        if tile:getX()+offsetX == idleTile:getX()
        and tile:getY()+offsetY == idleTile:getY() then
            return true
        end
    end
    return false
end

function TileManager:areActiveTilesInImpossiblePosition(offsetX, offsetY)
    offsetX, offsetY = offsetX or 0, offsetY or 0
    return self:checkActiveTiles(function(tile)
        if tile:getX() + offsetX < 0
        or tile:getX() + offsetX >= self.board.width then
            return true
        end
        if tile:getY() + offsetY >= self.board.height then
            return true
        end
        if self:isTileOnIdleTiles(tile, offsetX, offsetY) then
            return true
        end
        return false
    end)
end

function TileManager:aboutToSettle()
    return self:checkActiveTiles(function(tile)
        if tile.y >= self.board.height-1 then return true end
        if self:isTileOnIdleTiles(tile, 0, 1) then return true end
        return false
    end)
end

function TileManager:testKickActiveTiles(isClockwise)
    local kickTest = self.tetriminoData.kickTests[self.tetriminoData.rotationState+1]
    for _, coords in ipairs(kickTest) do
        local xKick, yKick = coords[1], -coords[2]
        if not isClockwise then xKick, yKick = -xKick, -yKick end

        if not self:areActiveTilesInImpossiblePosition(xKick, yKick) then
            return true, xKick, yKick
        end
    end
    return false
end

function TileManager:rotateActiveTiles(isClockwise)
    local originalTiles = table.copy(self.activeTiles)
    local originalRect = table.copy(self.tetriminoData.rect)

    local originOffset = {
        x = self.tetriminoData.rect.x + self.tetriminoData.rect.width/2 - 0.5,
        y = self.tetriminoData.rect.y + self.tetriminoData.rect.height/2 - 0.5
    }
    local sign = {x = isClockwise and -1 or 1, y = isClockwise and 1 or -1}
    for _, tile in ipairs(self.activeTiles) do
        tile:setPosition(
            (tile:getY() - originOffset.y)*sign.x + originOffset.x,
            (tile:getX() - originOffset.x)*sign.y + originOffset.y
        )
    end

    local successfulRotation, xKick, yKick = self:testKickActiveTiles(isClockwise)

    local newRotationState = (self.tetriminoData.rotationState + (isClockwise and 1 or -1)) % 4
    if successfulRotation then
        self:moveActiveTiles(xKick, yKick)
        self.tetriminoData.rotationState = newRotationState
        if self.aboutToSettleLastDescension then
            self.timers.settle:start()
            self.resetCounters.rotation:increment()
        end
    else
        self.activeTiles = originalTiles
        self.tetriminoData.rect = originalRect
    end
end

function TileManager:shiftActiveTilesHorizontally(xOffset)
    if not self:areActiveTilesInImpossiblePosition(xOffset, 0) then
        self:moveActiveTiles(xOffset, 0)
        if self:aboutToSettle() then
            self.timers.settle:start()
            self.resetCounters.shift:increment()
            self.resetCounters.rotation:increment()
        else
            self.resetCounters.rotation:increment(-self.resetCounters.shift:getCount())
            self.resetCounters.shift:reset()
        end
    end
end

function TileManager:descendActiveTiles()
    if not self:aboutToSettle() then self:moveActiveTiles(0, 1) end
    if self:aboutToSettle() then
        if not self.timers.settle:isRunning() then
            self.timers.settle:start()
        end
    end
    self.aboutToSettleLastDescension = self:aboutToSettle()
end

function TileManager:settleActiveTiles()
    for _, activeTile in ipairs(self.activeTiles) do
        table.insert(self.idleTiles, activeTile)
    end
    self.activeTiles = {}
    self:newTetrimino()

    self.timers.settle:stop()
    self.resetCounters.shift:reset()
    self.resetCounters.rotation:reset()

    self:removeTilesInFullRows()
end

function TileManager:hardDropActiveTiles()
    while not self:aboutToSettle() do self:moveActiveTiles(0, 1) end
    self:settleActiveTiles()
end

function TileManager:getFullRows()
    local rowCounts = {}
    for _=1, self.board.height do
        table.insert(rowCounts, 0)
    end
    for _, tile in ipairs(self.idleTiles) do
        rowCounts[tile:getY()+1] = rowCounts[tile:getY()+1] + 1
    end
    local fullRows = {}
    for row, rowCount in ipairs(rowCounts) do
        if rowCount >= 10 then
            table.insert(fullRows, row)
        end
    end
    return fullRows
end

function TileManager:removeTilesInRow(row)
    local index = 1
    while index <= #self.idleTiles do
        if self.idleTiles[index]:getY() == row-1 then
            table.remove(self.idleTiles, index)
        elseif self.idleTiles[index]:getY() < row then
            self.idleTiles[index]:setPosition(
                self.idleTiles[index]:getX(),
                self.idleTiles[index]:getY() + 1
            )
            index = index + 1
        else
            index = index + 1
        end
    end
end

function TileManager:removeTilesInFullRows()
    for _, row in ipairs(self:getFullRows()) do
        self:removeTilesInRow(row)
    end
end

function TileManager:getBoardDimensions()
    return self.board.width, self.board.height
end
function TileManager:getBoardWidth()
    return self.board.width
end
function TileManager:getBoardHeight()
    return self.board.height
end

function TileManager:getTetriminoRect()
    local rect = self.tetriminoData.rect
    return rect.x, rect.y, rect.width, rect.height
end

function TileManager:getUpcomingTetriminos()
    return self.tetriminoManager:getUpcomingTetriminos()
end

return TileManager