local tileManager
local boardDisplay

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time())

    local TileManager = require 'TileManager'
    tileManager = TileManager.new()
    tileManager:newTetrimino()
    local BoardDisplay = require 'BoardDisplay'
    boardDisplay = BoardDisplay.new(tileManager)
end

function love.update(dt)
    tileManager:update(dt)
    boardDisplay:update(dt)
end

function love.keypressed(key)
    if key == 'q' then
        love.event.quit()
    end
    tileManager:keypressed(key)
    boardDisplay:keypressed(key)
end

function love.keyreleased(key)
    tileManager:keyreleased(key)
end

function love.draw()
    boardDisplay:draw(tileManager)
end

function table.copy(t, modifierFunction)
    modifierFunction = modifierFunction or function(value) return value end
    local copy = {}
    for key, value in pairs(t) do
        if type(value) == "table" then
            copy[key] = table.copy(value)
        else
            copy[key] = modifierFunction(value)
        end
    end
    setmetatable(copy, getmetatable(t))
    return copy
end