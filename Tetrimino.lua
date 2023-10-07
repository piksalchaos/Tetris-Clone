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
        {141, 192, 255}
    },
    {
        {
            {1, 0, 0},
            {1, 1, 1},
            {0, 0, 0},
        },
        {45, 17, 255}
    },
    {
        {
            {0, 0, 1},
            {1, 1, 1},
            {0, 0, 0}
        },
        {255, 162, 68}
    },
    {
        {
            {1, 1},
            {1, 1}
        },
        {255, 249, 141}
    },
    {
        {
            {0, 1, 1},
            {1, 1, 0},
            {0, 0, 0}
        },
        {82, 255, 131}
    },
    {
        {
            {1, 1, 0},
            {0, 1, 1},
            {0, 0, 0}
        },
        {255, 18, 105}
    },
    {
        {
            {0, 1, 0},
            {1, 1, 1},
            {0, 0, 0}
        },
        {101, 30, 255}
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
    table.insert(tetriminos, Tetrimino.new(unpack(params)))
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