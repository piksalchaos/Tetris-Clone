local Tetrimino = {}
Tetrimino.__index = Tetrimino

local tetriminoData = {
    {
        {
            {0, 0, 0, 0},
            {1, 1, 1, 1},
            {0, 0, 0, 0},
            {0, 0, 0, 0}
        },
        {163, 239, 239}
    },
    {
        {
            {1, 0, 0},
            {1, 1, 1},
            {0, 0, 0},
        },
        {112, 112, 239}
    },
    {
        {
            {0, 0, 1},
            {1, 1, 1},
            {0, 0, 0}
        },
        {255, 210, 96}
    },
    {
        {
            {1, 1},
            {1, 1}
        },
        {255, 247, 135}
    },
    {
        {
            {0, 1, 1},
            {1, 1, 0},
            {0, 0, 0}
        },
        {148, 239, 148}
    },
    {
        {
            {1, 1, 0},
            {0, 1, 1},
            {0, 0, 0}
        },
        {239, 112, 143}
    },
    {
        {
            {0, 1, 0},
            {1, 1, 1},
            {0, 0, 0}
        },
        {179, 122, 239}
    }
}

-- 0 is starting position
-- 1 is 90 clockwise
-- 2 is full 180
-- 3 is 270 clockwise
Tetrimino.kickTests = { -- all clockwise by default
    basic = {
        { -- 0>>1
            {0, 0},
            {-1, 0},
            {-1, 1},
            {0, -2},
            {-1, -2}
        },
        { -- 1>>2
            {0, 0},
            {1, 0},
            {1, -1},
            {0, 2},
            {1, 2}
        },
        { -- 2>>3
            {0, 0},
            {1, 0},
            {1, 1},
            {0, -2},
            {1, -2}
        },
        { -- 3>>0
            {0, 0},
            {-1, 0},
            {-1, -1},
            {0, 2},
            {-1, 2}
        }
    },
    ITetrimino = {
        { -- 0>>1
            {0, 0},
            {-2, 0},
            {1, 0},
            {-2, -1},
            {1, 2}
        },
        { -- 1>>2
            {0, 0},
            {-1, 0},
            {2, 0},
            {-1, 2},
            {2, -1}
        },
        { -- 2>>3
            {0, 0},
            {2, 0},
            {-1, 0},
            {2, 1},
            {-1, -2}
        },
        { -- 3>>0
            {0, 0},
            {1, 0},
            {-2, 0},
            {1, -2},
            {-2, 1}
        }
    }
}

function Tetrimino.new(tileMap, color)
    local self = setmetatable({}, Tetrimino)

    self.tileMap = tileMap
    self.color = color

    return self
end

local tetriminos = {}
for _, params in ipairs(tetriminoData) do
    local tileMap, rgbColors = unpack(params)
    local colors = {}
    for _, channel in ipairs(rgbColors) do table.insert(colors, channel/255) end
    table.insert(tetriminos, Tetrimino.new(tileMap, colors))
end

function Tetrimino.getRandomTetrimino()
    return tetriminos[math.random(1, #tetriminos)]
end

function Tetrimino:getTileMap()
    return self.tileMap
end

function Tetrimino:getColor() return self.color end

function Tetrimino:getKickTests()
    if self.index == 1 then
        return self.kickTests.ITetrimino
    end
    return self.kickTests.basic
end

return Tetrimino