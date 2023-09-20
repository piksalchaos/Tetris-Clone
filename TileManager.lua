local Timer = require 'Timer'
local Tile = require 'Tile'
local keybinds = require 'keybinds'
local tetriminos= require 'tetriminos'

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
    self.tetriminoRect = {x=0, y=0, width=0, height=0}
    
    return self
end

function TileManager:update(dt)
    for _, timer in pairs(self.timers) do
        timer:update(dt)
    end

    if self.timers.descend:isFinished() then
        
    end
    if self.timers.move:isFinished() then
        
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
        self:shiftActiveTiles(-1)
    elseif key == keybinds.moveRight then
        self:shiftActiveTiles(1)
    end
    if key == keybinds.softDrop then
        self:moveActiveTilesOneDown()
        self.timers.descend:setDuration(self.timerDurations.descend.softDrop)
        self.timers.descend:start()
    end
    if key == keybinds.hardDrop then self:hardDrop() end
    if key == keybinds.rotateClockwise then self:rotateActiveTiles(true) end
    if key == keybinds.rotateCounterClockwise then self:rotateActiveTiles(false) end
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

function TileManager:newTetrimino()
    local function newTetriminoTile(tileValue, x, y)
        if tileValue == 1 then
            self:newTile(x, y, true)
        end
    end
    local tetriminoMatrix = tetriminos[math.random(1, #tetriminos)]

    self.tetriminoRect.width = #tetriminoMatrix[1]
    self.tetriminoRect.height = #tetriminoMatrix

    local xOffset =  self.board.width/2 - math.ceil(#tetriminoMatrix[1]/2)

    self.tetriminoRect.x = xOffset
    self.tetriminoRect.y = 0
    

    for row, tileValues in ipairs(tetriminoMatrix) do
        for column, tileValue in ipairs(tileValues) do
            newTetriminoTile(tileValue, xOffset + column-1, row-1)
        end
    end
end

local function moveTiles(tiles, relativeX, relativeY)
    for _, tile in ipairs(tiles) do
        tile:setPosition(tile:getX() + relativeX, tile:getY() + relativeY)
    end
end

local function tilesOverlapVerticalBorders(tiles, boardWidth)
    for _, tile in ipairs(tiles) do
        if tile.x < 0 or tile.x > boardWidth-1 then
            return true
        end
    end
    return false
end

function TileManager:copyActiveTiles()
    return table.copy(self.activeTiles)
end

function TileManager:shiftActiveTiles(relativeXPosition)
    local shiftedTiles = self:copyActiveTiles()
    moveTiles(shiftedTiles, relativeXPosition, 0)

    if not tilesOverlapVerticalBorders(shiftedTiles, self.board.width) then
        self.activeTiles = shiftedTiles
        self.tetriminoRect.x = self.tetriminoRect.x + relativeXPosition
    end
end

function TileManager:rotateActiveTiles(isClockwise)
    local originOffset = {
        x = self.tetriminoRect.x + self.tetriminoRect.width/2 - 0.5,
        y = self.tetriminoRect.y + self.tetriminoRect.height/2 - 0.5
    }
    local rotatingTiles = self:copyActiveTiles()
    for _, tile in ipairs(rotatingTiles) do
        local sign = {
            x = isClockwise and -1 or 1,
            y = isClockwise and 1 or -1
        }
        tile:setPosition(
            (tile:getY() - originOffset.y)*sign.x + originOffset.x,
            (tile:getX() - originOffset.x)*sign.y + originOffset.y
        )
    end
    if not tilesOverlapVerticalBorders(rotatingTiles, self.board.width) then
        self.activeTiles = rotatingTiles
    end
end

return TileManager