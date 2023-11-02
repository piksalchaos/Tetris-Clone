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
    or ((self.resetCounters.shift:isFinished() or self.resetCounters.rotation:isFinished()) and self:aboutToSettle()) then
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

    if keybinds.hold:hasKey(key) then
        self:newTetrimino(true)
    end
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

function TileManager:newActiveTile(x, y, color)
    local newTile = Tile.new(x, y, color)
    table.insert(self.tiles, newTile)
    table.insert(self.activeTiles, newTile)
end

function TileManager:newTetrimino(getHeld)
    self.activeTiles = {}
    local tetrimino
    if getHeld then
        tetrimino = self.tetriminoManager:switchHeldTetrimino()
    else
        tetrimino = self.tetriminoManager:nextTetrimino()
    end

    self.tetriminoData.rect.width, self.tetriminoData.rect.height = tetrimino:getRect()
    self.tetriminoData.rect.x = self.board.width/2 - math.ceil(self.tetriminoData.rect.width/2)
    self.tetriminoData.rect.y = -2

    self.tetriminoData.rotationState = 0
    self.tetriminoData.kickTests = tetrimino:getKickTests()

    for _, coordinate in ipairs(tetrimino:getTileCoordinates()) do
        self:newActiveTile(
            coordinate[1] + self.tetriminoData.rect.x,
            coordinate[2] + self.tetriminoData.rect.y,
            tetrimino:getColor()
        )
    end

    self.aboutToSettleLastDescension = false

    if self:aboutToSettle() or self:areActiveTilesInImpossiblePosition() then
        self:restartGame()
    end
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

function TileManager:aboutToSettle(offsetX, offsetY)
    offsetX, offsetY = offsetX or 0, offsetY or 0
    return self:checkActiveTiles(function(tile)
        if tile:getY() + offsetY >= self.board.height-1 then return true end
        if self:isTileOnIdleTiles(tile, offsetX, offsetY + 1) then return true end
        return false
    end)
end

function TileManager:kickActiveTiles(isClockwise)
    local kickTest = self.tetriminoData.kickTests[self.tetriminoData.rotationState+1]
    for _, coords in ipairs(kickTest) do
        local xKick, yKick = coords[1], -coords[2]
        if not isClockwise then xKick, yKick = -xKick, -yKick end

        if not self:areActiveTilesInImpossiblePosition(xKick, yKick) then
            self:moveActiveTiles(xKick, yKick)
            return true
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

    local successfulKick = self:kickActiveTiles(isClockwise)

    local newRotationState = (self.tetriminoData.rotationState + (isClockwise and 1 or -1)) % 4
    if successfulKick then
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
    self:newTetrimino(false)

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
        if tile:getY() <= 0 then break end
        local rowIndex = tile:getY()+1
        rowCounts[rowIndex] = rowCounts[rowIndex] + 1
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

function TileManager:restartGame()
    self.activeTiles = {}
    self.idleTiles = {}
    self.tiles = {}
    self:newTetrimino()
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

function TileManager:getHeldTetrimino()
    return self.tetriminoManager:getHeldTetrimino()
end

function TileManager:getActiveTiles()
    return self.activeTiles
end

function TileManager:getIdleTiles()
    return self.idleTiles
end

function TileManager:getGhostYOffset()
    local yOffset = 0
    while not self:aboutToSettle(0, yOffset) do
        yOffset = yOffset + 1
    end
    return yOffset
end

return TileManager