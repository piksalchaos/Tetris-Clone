local boardTileWidth, boardTileHeight = 10, 20
local tilePixelLength = 30
local boardDrawPosition = {
    x = love.graphics.getWidth()/2 - boardTileWidth*tilePixelLength/2,
    y = love.graphics.getHeight()/2 - boardTileHeight*tilePixelLength/2
}

local tileManager

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time())

    local TileManager = require 'TileManager'
    tileManager = TileManager.new()
    tileManager:newTetrimino()
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

    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.rectangle(
        'fill',
        tileManager.tetriminoRect.x * tilePixelLength + boardDrawPosition.x,
        tileManager.tetriminoRect.y * tilePixelLength + boardDrawPosition.y,
        tileManager.tetriminoRect.width * tilePixelLength,
        tileManager.tetriminoRect.height * tilePixelLength
    )
    love.graphics.setColor(1, 1, 1)

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

    local originOffset = {
        x = tileManager.tetriminoRect.x + tileManager.tetriminoRect.width/2,
        y = tileManager.tetriminoRect.y + tileManager.tetriminoRect.height/2
    }

    --[[ for _, tile in ipairs(tileManager.activeTiles) do
        love.graphics.rectangle(
            'fill',
            tile.x * tilePixelLength + boardDrawPosition.x - originOffset.x * tilePixelLength,
            tile.y * tilePixelLength + boardDrawPosition.y - originOffset.y * tilePixelLength,
            tilePixelLength,
            tilePixelLength
        )
    end ]]
end

function table.copy(t)
    local copy = {}
    for key, value in pairs(t) do
        if type(value) == "table" then
            copy[key] = table.copy(value)
        else
            copy[key] = value
        end
    end
    setmetatable(copy, getmetatable(t))
    return copy
end