local Timer = require 'Timer'
local Tile = require 'Tile'
local keybinds = require 'keybinds'
local tetriminos = require 'tetriminos'

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
    self.tetriminoData = {}
    self.tetriminoData.rect = {x=0, y=0, width=0, height=0}
    self.tetriminoData.rotationState = 0
    self.tetriminoData.kickTests = {}
    self.horizontalDirection = 0
    
    return self
end

function TileManager:update(dt)
    for _, timer in pairs(self.timers) do
        timer:update(dt)
    end

    if self.timers.descend:isFinished() then
        self:descendActiveTiles()
    end
    if self.timers.move:isFinished() then
        self:shiftActiveTilesHorizontally(self.horizontalDirection)
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
    if key == keybinds.moveLeft then
        self:shiftActiveTilesHorizontally(-1)
        self.timers.move:start()
    elseif key == keybinds.moveRight then
        self:shiftActiveTilesHorizontally(1)
        self.timers.move:start()
    end

    if key == keybinds.softDrop then
        self:descendActiveTiles()
        self.timers.descend:setDuration(self.timerDurations.descend.softDrop)
    end
    if key == keybinds.hardDrop then self:hardDrop() end
    if key == keybinds.rotateClockwise then self:rotateActiveTiles(true) end
    if key == keybinds.rotateCounterClockwise then self:rotateActiveTiles(false) end
end

function TileManager:keyreleased(key)
    if key == keybinds.softDrop then
        self.timers.descend:setDuration(self.timerDurations.descend.default)
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

function TileManager:newTetrimino()
    local function newTetriminoTile(tileValue, x, y)
        if tileValue == 1 then
            self:newTile(x, y, true)
        end
    end
    local tetrimino = tetriminos[math.random(1, #tetriminos)]
    local tetriminoTileMap = tetrimino:getTileMap()

    self.tetriminoData.rect.width = #tetriminoTileMap[1]
    self.tetriminoData.rect.height = #tetriminoTileMap

    local xOffset =  self.board.width/2 - math.ceil(#tetriminoTileMap[1]/2)

    self.tetriminoData.rect.x = xOffset
    self.tetriminoData.rect.y = 0

    self.tetriminoData.rotationState = 0
    self.tetriminoData.kickTests = tetrimino:getKickTests()

    for row, tileValues in ipairs(tetriminoTileMap) do
        for column, tileValue in ipairs(tileValues) do
            newTetriminoTile(tileValue, xOffset + column-1, row-1)
        end
    end
end

local function moveTiles(tiles, relativeX, relativeY)
    for _, tile in ipairs(tiles) do
        tile.x = tile.x + relativeX
        tile.y = tile.y + relativeY
    end
end

function TileManager:moveActiveTiles(relativeX, relativeY)
    moveTiles(self.activeTiles, relativeX, relativeY)
    self.tetriminoData.rect.x = self.tetriminoData.rect.x + relativeX
    self.tetriminoData.rect.y = self.tetriminoData.rect.y + relativeY
end

function TileManager:setActiveTiles(newTiles)
    self.activeTiles = newTiles
    local lowestX, lowestY = self.board.width, self.board.height
    for _, tile in ipairs(self.activeTiles) do
        lowestX = math.min(lowestX, tile.x)
        lowestY = math.min(lowestY, tile.y)
    end
    self.tetriminoData.rect.x = lowestX
    self.tetriminoData.rect.y = lowestY
end

function TileManager:checkActiveTiles(func)
    for _, tile in ipairs(self.activeTiles) do
        if func(tile) then return true end
    end
    return false
end

function TileManager:shiftActiveTilesHorizontally(xOffset)
    if not self:checkActiveTiles(
        xOffset < 0 and function(tile)
            return tile.x <= 0 or self:isTileOnIdleTiles(tile, 1, 0)
        end
        or function(tile)
            return tile.x >= self.board.width-1 or self:isTileOnIdleTiles(tile, -1, 0)
        end)
    then
        self:moveActiveTiles(xOffset, 0)
    end
end

function TileManager:isTileOnIdleTiles(tile, offsetX, offsetY)
    offsetX, offsetY = offsetX or 0, offsetY or 0
    for _, idleTile in ipairs(self.idleTiles) do
        if tile.x == idleTile.x+offsetX and tile.y == idleTile.y+offsetY then
            return true
        end
    end
    return false
end

function TileManager:areActiveTilesInImpossiblePosition()
    for _, tile in ipairs(self.activeTiles) do
        if tile.x < 0 or tile.x > self.board.width-1 then
            return true
        end
        if self:isTileOnIdleTiles(tile) then
            return true
        end
    end
    return false
end

function TileManager:rotateActiveTiles(isClockwise)
    local originOffset = {
        x = self.tetriminoData.rect.x + self.tetriminoData.rect.width/2 - 0.5,
        y = self.tetriminoData.rect.y + self.tetriminoData.rect.height/2 - 0.5
    }
    local originalTiles = table.copy(self.activeTiles)
    local sign = {
        x = isClockwise and -1 or 1,
        y = isClockwise and 1 or -1
    }

    for _, tile in ipairs(self.activeTiles) do
        tile:setPosition(
            (tile:getY() - originOffset.y)*sign.x + originOffset.x,
            (tile:getX() - originOffset.x)*sign.y + originOffset.y
        )
    end
    local newRotationState = (self.tetriminoData.rotationState + (isClockwise and 1 or -1)) % 4

    local kickTest = self.tetriminoData.kickTests[self.tetriminoData.rotationState+1]
    if not isClockwise then
        kickTest = table.copy(kickTest, function(value) return -value end)
    end

    --print('--------')
    for _, coords in ipairs(kickTest) do
        --print(coords[1] .. '  ' .. coords[2])
        
    end

    if not self:areActiveTilesInImpossiblePosition() then
        self.tetriminoData.rotationState = newRotationState
        print(self.tetriminoData.rotationState)
    else
        self.activeTiles = originalTiles
    end
end

function TileManager:descendActiveTiles()
    if self:aboutToSettle() then
        self.timers.settle:start()
    else
        self:moveActiveTiles(0, 1)
    end
end

function TileManager:aboutToSettle()
    if self:checkActiveTiles(function(tile)
        return tile.y >= self.board.height-1
    end) then
        return true
    end

    if self:checkActiveTiles(function(tile)
        return self:isTileOnIdleTiles(tile, 0, -1)
    end) then
        return true
    end

    return false
end

function TileManager:settle()
    for _, activeTile in ipairs(self.activeTiles) do
        table.insert(self.idleTiles, activeTile)
    end
    self.activeTiles = {}
    self:newTetrimino()

    self.timers.settle:stop()
end

function TileManager:hardDrop()
    while not self:aboutToSettle() do self:moveActiveTiles(0, 1) end
    self:settle()
end

return TileManager