local BoardDisplay = {}
BoardDisplay.__index = BoardDisplay

function BoardDisplay.new(tileManager, tileScale)
    local self = setmetatable({}, BoardDisplay)

    self.tileManager = tileManager
    self.center = {
        x=0,
        y=0
    }
    self.tileScale = tileScale or 30
    self.shadowScaleOffset = 0.95

    return self
end

function BoardDisplay:getBoardWidth()
    return self.tileManager:getBoardWidth() * self.tileScale
end
function BoardDisplay:getBoardHeight()
    return self.tileManager:getBoardHeight() * self.tileScale
end

function BoardDisplay:drawTiles(tiles, alpha)
    alpha = alpha or 1
    for _, tile in ipairs(tiles) do
        local r, g, b = unpack(tile:getColor())
        love.graphics.setColor(r, g, b, alpha)

        local tileX = tile:getX() * self.tileScale - self:getBoardWidth()/2
        local tileY = tile:getY() * self.tileScale - self:getBoardHeight()/2

        love.graphics.rectangle(
            'fill',
            tileX,
            tileY,
            self.tileScale, self.tileScale
        )
        love.graphics.setColor(r, g, b, alpha*0.8)
        love.graphics.rectangle(
            'fill',
            self.center.x + self.shadowScaleOffset * (tileX - self.center.x),
            self.center.y + self.shadowScaleOffset * (tileY - self.center.y),
            self.tileScale * self.shadowScaleOffset,
            self.tileScale * self.shadowScaleOffset
        )
    end
    love.graphics.setColor(1, 1, 1)
end

function BoardDisplay:draw()
    love.graphics.translate(
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/2
    )
    love.graphics.rectangle(
        'line',
        -self:getBoardWidth()/2,
        -self:getBoardHeight()/2,
        self:getBoardWidth(),
        self:getBoardHeight()
    )

    --[[uncomment for tetrimino rect 
    local tetriminoRect = {tileManager:getTetriminoRect()} 
    love.graphics.setColor(0.5, 0.5, 1, 0.25)
    love.graphics.rectangle(
        'fill',
        tetriminoRect[1] * self.tileScale,
        tetriminoRect[2] * self.tileScale,
        tetriminoRect[3] * self.tileScale,
        tetriminoRect[4] * self.tileScale
    )
    love.graphics.setColor(1, 1, 1) ]]

    if self.tileManager:aboutToSettle() then
        self:drawTiles(self.tileManager.activeTiles, 0.5)
    else
        self:drawTiles(self.tileManager.activeTiles)
    end
    self:drawTiles(self.tileManager.idleTiles)
end

return BoardDisplay