local boardTileWidth, boardTileHeight = 10, 20
local tilePixelLength = 30
local boardDrawPosition = {
    x = love.graphics.getWidth()/2 - boardTileWidth*tilePixelLength/2,
    y = love.graphics.getHeight()/2 - boardTileHeight*tilePixelLength/2
}

local tileManager

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    local TileManager = require 'TileManager'
    tileManager = TileManager.new()
    tileManager:newTile(1, 0, true)
    tileManager:newTile(0, 1, true)
    tileManager:newTile(1, 1, true)
    tileManager:newTile(2, 1, true)
    tileManager:newTile(3, 1, true)
    tileManager:newTile(5, 10, false)
    tileManager:newTile(6, 10, false)
    tileManager:newTile(7, 10, false)
end

function love.update(dt)
    tileManager:update(dt)
end

function love.keypressed(key)
    if key == 'q' then
        love.event.quit()
    end
    tileManager:keypressed(key)
end

function love.keyreleased(key)
    tileManager:keyreleased(key)
end

function love.draw()
    love.graphics.rectangle(
        'line',
        boardDrawPosition.x,
        boardDrawPosition.y,
        boardTileWidth * tilePixelLength,
        boardTileHeight * tilePixelLength
    )

    if tileManager:aboutToSettle() then
        love.graphics.setColor(1, 1, 1, 0.5)
    end
    for _, tile in ipairs(tileManager.activeTiles) do
        love.graphics.rectangle(
            'fill',
            tile.x * tilePixelLength + boardDrawPosition.x,
            tile.y * tilePixelLength + boardDrawPosition.y,
            tilePixelLength,
            tilePixelLength
        )
    end
    love.graphics.setColor(1, 1, 1)
    for _, tile in ipairs(tileManager.idleTiles) do
        love.graphics.rectangle(
            'fill',
            tile.x * tilePixelLength + boardDrawPosition.x,
            tile.y * tilePixelLength + boardDrawPosition.y,
            tilePixelLength,
            tilePixelLength
        )
    end
end