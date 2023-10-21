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
    self.upcomingTetriminoScale = 25
    self.upcomingTetriminoBorderRect = {width = 150, height = 320}

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

function BoardDisplay:drawUpcomingTiles()
    local scale = self.upcomingTetriminoScale
    for i, tetrimino in ipairs(self.tileManager:getUpcomingTetriminos()) do
        local tileWidth, tileHeight = tetrimino:getRect()
        for _, coordinate in ipairs(tetrimino:getTileCoordinates()) do
            love.graphics.rectangle(
                'fill',
                (coordinate[1] - tileWidth/2)*scale,
                ((coordinate[2] - tileHeight/2)*scale) + (i-2)*100,
                scale,
                scale
            )
        end
    end
end

function BoardDisplay:drawUpcomingTilesPanel()
    local rect = self.upcomingTetriminoBorderRect
    love.graphics.rectangle(
        'line',
        -rect.width/2,
        -rect.height/2,
        rect.width,
        rect.height
    )

    self:drawUpcomingTiles()
    love.graphics.translate(5, 5)
    love.graphics.setColor(1, 1, 1, 0.5)
    self:drawUpcomingTiles()
end

function BoardDisplay:draw()
    love.graphics.translate(
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/2
    )

    self:drawBoard(self.defaultScale * 0.965)
    

    --[[ for i=0, 1, 0.1 do
        self:drawBoard(self.defaultScale * i)
    end ]]

    self:drawBoard(self.defaultScale)

    love.graphics.origin()
    love.graphics.translate(
        love.graphics.getWidth()*0.83,
        love.graphics.getHeight()*0.5
    )
    
    self:drawUpcomingTilesPanel()
end

return BoardDisplay