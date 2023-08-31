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
    tileManager:newTile(0, 0, true)
end

function love.update(dt)
    tileManager:update(dt)
end

function love.keypressed(key)
    if key == 'a' then
        --moveActiveTiles(-1, 0)
    end
    if key == 'd' then
        --moveActiveTiles(1, 0)
    end
end

function love.draw()
    love.graphics.rectangle(
        'line',
        boardDrawPosition.x,
        boardDrawPosition.y,
        boardTileWidth * tilePixelLength,
        boardTileHeight * tilePixelLength
    )

    for i, tile in ipairs(tileManager.tiles) do
        love.graphics.rectangle(
            'fill',
            tile.x * tilePixelLength + boardDrawPosition.x,
            tile.y * tilePixelLength + boardDrawPosition.y,
            tilePixelLength,
            tilePixelLength
        )
    end
end