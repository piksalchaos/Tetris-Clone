local Tetrimino = {}
Tetrimino.__index = Tetrimino

Tetrimino.tileMaps = {
    {
        {0, 0, 0, 0},
        {1, 1, 1, 1},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    {
        {1, 0, 0},
        {1, 1, 1},
        {0, 0, 0}
    },
    {
        {0, 0, 1},
        {1, 1, 1},
        {0, 0, 0}
    },
    {
        {1, 1},
        {1, 1}
    },
    {
        {0, 1, 1},
        {1, 1, 0},
        {0, 0, 0}
    },
    {
        {1, 1, 0},
        {0, 1, 1},
        {0, 0, 0}
    },
    {
        {0, 1, 0},
        {1, 1, 1},
        {0, 0, 0}
    }
}

Tetrimino.kickTests = {
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



function Tetrimino.new(tetriminoIndex)
    local self = setmetatable({}, Tetrimino)

    self.index = tetriminoIndex

    return self
end

function Tetrimino:getTileMap()
    return self.tileMaps[self.index]
end

function Tetrimino:getKickTests()
    if self.index == 1 then
        return self.kickTests.ITetrimino
    end
    return self.kickTests.basic
end

local tetriminos = {}
for i=1, #Tetrimino.tileMaps do
    table.insert(tetriminos, Tetrimino.new(i))
end

return tetriminos