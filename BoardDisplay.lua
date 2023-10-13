local BoardDisplay = {}
BoardDisplay.__index = BoardDisplay

function BoardDisplay.new(tileManager, tileScale)
    local self = setmetatable({}, BoardDisplay)

    self.tileManager = tileManager
    self.center = {
        x=0,
        y=0
    }
    self.defaultScale = 30

    return self
end

function BoardDisplay:getBoardWidth()
    return self.tileManager:getBoardWidth() * self.tileScale
end
function BoardDisplay:getBoardHeight()
    return self.tileManager:getBoardHeight() * self.tileScale
end

function BoardDisplay:applyScaleTint(scale, colorChannelTints)
    colorChannelTints[4] = colorChannelTints[4] or 1

    local colorChannels = {}
    colorChannels = {love.graphics:getColor()}
    for i, colorChannel in ipairs(colorChannels) do
        local power = colorChannelTints[i]
        colorChannels[i] = colorChannel * (scale^power/self.defaultScale^power)
    end
    love.graphics.setColor(unpack(colorChannels))
end

function BoardDisplay:drawBoardOutline(scale)
    local boardWidth, boardHeight = self.tileManager:getBoardDimensions()
    love.graphics.setColor(1, 1, 1)
    self:applyScaleTint(scale, {1, 1, 1, 30})
    love.graphics.rectangle(
        'line',
        -boardWidth/2 * scale,
        -boardHeight/2 * scale,
        boardWidth * scale,
        boardHeight * scale
    )
end

function BoardDisplay:drawTiles(tiles, scale, alpha)
    alpha = alpha or 1
    for _, tile in ipairs(tiles) do
        local tileX = tile:getX() - self.tileManager:getBoardWidth()/2
        local tileY = tile:getY() - self.tileManager:getBoardHeight()/2
        local r, g, b = unpack(tile:getColor())
        love.graphics.setColor(r, g, b, alpha)
        self:applyScaleTint(scale, {15, 15, 2})
        love.graphics.rectangle(
            'fill',
            self.center.x + scale * (tileX - self.center.x),
            self.center.y + scale * (tileY - self.center.y),
            scale,
            scale
        )
    end
    love.graphics.setColor(1, 1, 1)
end

function BoardDisplay:drawBoard(scale)
    self:drawBoardOutline(scale)
    if self.tileManager:aboutToSettle() then
        self:drawTiles(self.tileManager.activeTiles, scale, 0.5)
    else
        self:drawTiles(self.tileManager.activeTiles, scale)
    end
    self:drawTiles(self.tileManager.idleTiles, scale)
end

function BoardDisplay:draw()
    love.graphics.translate(
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/2
    )

    self:drawBoard(self.defaultScale * 0.965)
    self:drawBoard(self.defaultScale)
end

return BoardDisplay