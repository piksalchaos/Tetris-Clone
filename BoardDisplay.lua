local keybinds = require 'keybinds'

local BoardDisplay = {}
BoardDisplay.__index = BoardDisplay

function BoardDisplay.new(tileManager, tileScale)
    local self = setmetatable({}, BoardDisplay)

    self.tileManager = tileManager
    self.scaleCenterOffset = {
        x=0,
        y=0
    }
    self.scaleCenterOffsetTarget = {
        x=0,
        y=0
    }
    self.scaleCenterOffsetSpeed = 5
    self.shadowOffset = 0.03

    self.defaultScale = 30
    self.upcomingTetriminoScale = 25
    self.upcomingTetriminoBorderRect = {width = 150, height = 320}
    self.heldTetriminoRect = {width = 150, height = 100}
    self.heldTetriminoScale = 30
    
    return self
end

function BoardDisplay:getBoardWidth()
    return self.tileManager:getBoardWidth() * self.tileScale
end
function BoardDisplay:getBoardHeight()
    return self.tileManager:getBoardHeight() * self.tileScale
end

function BoardDisplay:applyScaleTint(scale, colorChannelTints)
    if scale > self.defaultScale then
        scale = self.defaultScale - (scale - self.defaultScale)
    end
    colorChannelTints[4] = colorChannelTints[4] or 1

    local colorChannels = {}
    colorChannels = {love.graphics:getColor()}
    for i, colorChannel in ipairs(colorChannels) do
        local power = colorChannelTints[i]
        colorChannels[i] = colorChannel * (scale/self.defaultScale)^power
    end
    love.graphics.setColor(unpack(colorChannels))
end

function BoardDisplay:getCenterOffsetFromScale(scale)
    return (scale/self.defaultScale-1+self.shadowOffset/2)*self.scaleCenterOffset.x * self.defaultScale,
           (scale/self.defaultScale-1+self.shadowOffset/2)*self.scaleCenterOffset.y * self.defaultScale
end

function BoardDisplay:drawBoardOutline(scale)
    local xScaleOffset, yScaleOffset = self:getCenterOffsetFromScale(scale)
    local boardWidth, boardHeight = self.tileManager:getBoardDimensions()
    love.graphics.setColor(1, 1, 1)
    self:applyScaleTint(scale, {1, 1, 1, 30})
    love.graphics.rectangle(
        'line',
        -boardWidth/2 * scale + xScaleOffset,
        -boardHeight/2 * scale + yScaleOffset,
        boardWidth * scale,
        boardHeight * scale
    )
end

function BoardDisplay:drawTiles(tiles, scale, alpha, tileXOffset, tileYOffset, tileBorderSize)
    alpha = alpha or 1
    tileBorderSize = tileBorderSize or 0

    tileXOffset, tileYOffset = tileXOffset or 0, tileYOffset or 0
    tileXOffset = tileXOffset - self.tileManager:getBoardWidth()/2
    tileYOffset = tileYOffset - self.tileManager:getBoardHeight()/2
    local xScaleOffset, yScaleOffset = self:getCenterOffsetFromScale(scale)
    for _, tile in ipairs(tiles) do
        local r, g, b = unpack(tile:getColor())
        love.graphics.setColor(r, g, b, alpha)
        self:applyScaleTint(scale, {15, 15, 2})
        love.graphics.rectangle(
            'fill',
            scale * (tile:getX() + tileXOffset) + tileBorderSize + xScaleOffset,
            scale * (tile:getY() + tileYOffset) + tileBorderSize + yScaleOffset,
            scale - tileBorderSize*2,
            scale - tileBorderSize*2
        )
    end
    love.graphics.setColor(1, 1, 1)
end

function BoardDisplay:drawGhostTiles()
    self:drawTiles(
        self.tileManager:getActiveTiles(),
        self.defaultScale,
        0.5,
        0,
        self.tileManager:getGhostYOffset(),
        3
    )
end

function BoardDisplay:drawBoard(scale)
    self:drawBoardOutline(scale)
    if self.tileManager:aboutToSettle() then
        self:drawTiles(self.tileManager:getActiveTiles(), scale, 0.5)
    else
        self:drawTiles(self.tileManager:getActiveTiles(), scale)
    end
    self:drawTiles(self.tileManager:getIdleTiles(), scale)
end

function BoardDisplay:drawTetrimino(tetrimino, scale, xOffset, yOffset)
    xOffset, yOffset = xOffset or 0, yOffset or 0
    local tileWidth, tileHeight = tetrimino:getDisplayDimensions()
    local tileXOffset, tileYOffset = tetrimino:getDisplayRectOffset()
    for _, coordinate in ipairs(tetrimino:getTileCoordinates()) do
        love.graphics.rectangle(
            'fill',
            (coordinate[1] - tileWidth/2 - tileXOffset)*scale + xOffset,
            (coordinate[2] - tileHeight/2 - tileYOffset)*scale + yOffset,
            scale,
            scale
        )
    end
end

function BoardDisplay:drawShadedTetrimino(tetrimino, scale, xOffset, yOffset)
    love.graphics.translate(-2.5, -2.5)
    self:drawTetrimino(tetrimino, scale, xOffset, yOffset)

    love.graphics.translate(5, 5)
    love.graphics.setColor(1, 1, 1, 0.5)
    self:drawTetrimino(tetrimino, scale, xOffset, yOffset)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(-2.5, -2.5)
end

function BoardDisplay:drawUpcomingTetriminos()
    for i, tetrimino in ipairs(self.tileManager:getUpcomingTetriminos()) do
        self:drawShadedTetrimino(
            tetrimino, self.upcomingTetriminoScale, 0, (i-2)*100
        )
    end
end

function BoardDisplay:drawUpcomingTetriminosPanel()
    local rect = self.upcomingTetriminoBorderRect
    love.graphics.rectangle(
        'line',
        -rect.width/2,
        -rect.height/2,
        rect.width,
        rect.height
    )

    self:drawUpcomingTetriminos()
end

function BoardDisplay:drawHeldTetriminoPanel()
    love.graphics.rectangle(
        'line',
        -self.heldTetriminoRect.width/2,
        -self.heldTetriminoRect.height/2, 
        self.heldTetriminoRect.width,
        self.heldTetriminoRect.height)
    local heldTetrimino = self.tileManager:getHeldTetrimino()
    if heldTetrimino then 
        self:drawShadedTetrimino(heldTetrimino, self.heldTetriminoScale)
    end
end

function BoardDisplay:update(dt)
    local x, y, w, h = self.tileManager:getTetriminoRect()
    self.scaleCenterOffsetTarget.x = (x + w/2) - self.tileManager:getBoardWidth()/2
    self.scaleCenterOffsetTarget.y = (y + h/2) - self.tileManager:getBoardHeight()/2

    if self.scaleCenterOffset.x ~= self.scaleCenterOffsetTarget.x then
        local xDistance = self.scaleCenterOffsetTarget.x - self.scaleCenterOffset.x
        local speed = xDistance * self.scaleCenterOffsetSpeed*dt
        self.scaleCenterOffset.x = self.scaleCenterOffset.x + speed
    end

    if self.scaleCenterOffset.y ~= self.scaleCenterOffsetTarget.y then
        local yDistance = self.scaleCenterOffsetTarget.y - self.scaleCenterOffset.y
        local speed = yDistance * self.scaleCenterOffsetSpeed*dt
        self.scaleCenterOffset.y = self.scaleCenterOffset.y + speed
    end
end

function BoardDisplay:keypressed(key)
    if keybinds.hardDrop:hasKey(key) then
        self.scaleCenterOffset.y = self.scaleCenterOffset.y + 10
    end
    if keybinds.rotateCounterClockwise:hasKey(key) or keybinds.rotateClockwise:hasKey(key) then
        self.scaleCenterOffset.y = self.scaleCenterOffset.y - 5
    end
end

function BoardDisplay:translateOriginByScale(x, y)
    love.graphics.origin()
    love.graphics.translate(
        love.graphics.getWidth() * x,
        love.graphics.getHeight() * y
    )
end

function BoardDisplay:draw()
    self:translateOriginByScale(0.5, 0.5)
    --[[ for i=0, 2, 0.04 do
        self:drawBoard(self.defaultScale * i)
    end ]]
    self:drawBoard(self.defaultScale * (1-self.shadowOffset))
    self:drawBoard(self.defaultScale)
    self:drawGhostTiles()

    self:translateOriginByScale(0.83, 0.5)
    self:drawUpcomingTetriminosPanel()

    self:translateOriginByScale(0.15, 0.3)
    self:drawHeldTetriminoPanel()
end

return BoardDisplay