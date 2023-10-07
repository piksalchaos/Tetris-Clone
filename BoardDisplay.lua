local BoardDisplay = {}
BoardDisplay.__index = BoardDisplay

function BoardDisplay.new(tilePixelLength)
    local self = setmetatable({}, BoardDisplay)

    self.tilePixelLength = tilePixelLength or 30

    return self
end

function BoardDisplay:drawTiles(tiles)
    for _, tile in ipairs(tiles) do
        love.graphics.rectangle(
            'fill',
            tile:getX() * self.tilePixelLength,
            tile:getY() * self.tilePixelLength,
            self.tilePixelLength,
            self.tilePixelLength
        )
    end
end

function BoardDisplay:draw(tileManager)
    local boardTileWidth, boardTileHeight = tileManager:getBoardDimensions()

    love.graphics.translate(
        love.graphics.getWidth()/2 - boardTileWidth*self.tilePixelLength/2,
        love.graphics.getHeight()/2 - boardTileHeight*self.tilePixelLength/2
    )
    love.graphics.rectangle('line', 0, 0, 
        boardTileWidth * self.tilePixelLength,
        boardTileHeight * self.tilePixelLength
    )

    --[[uncomment for tetrimino rect 
    local tetriminoRect = {tileManager:getTetriminoRect()} 
    love.graphics.setColor(0.5, 0.5, 1, 0.25)
    love.graphics.rectangle(
        'fill',
        tetriminoRect[1] * self.tilePixelLength,
        tetriminoRect[2] * self.tilePixelLength,
        tetriminoRect[3] * self.tilePixelLength,
        tetriminoRect[4] * self.tilePixelLength
    )
    love.graphics.setColor(1, 1, 1) ]]

    if tileManager:aboutToSettle() then
        love.graphics.setColor(1, 1, 1, 0.5)
    end
    self:drawTiles(tileManager.activeTiles)
    love.graphics.setColor(1, 1, 1)
    self:drawTiles(tileManager.idleTiles)
end

return BoardDisplay