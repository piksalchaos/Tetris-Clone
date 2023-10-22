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
local kickTests = { -- all clockwise by default
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

local Tetrimino = {}
Tetrimino.__index = Tetrimino

function Tetrimino.new(tileMap, color, isIPiece)
    local self = setmetatable({}, Tetrimino)

    self.tileCoordinates = {}
    for row, tileValues in ipairs(tileMap) do
        for column, tileValue in ipairs(tileValues) do
            if tileValue == 1 then
                table.insert(self.tileCoordinates, {column-1, row-1})
            end
        end
    end
    self.rect = {
        width = #tileMap[1],
        height = #tileMap
    }
    self.color = color
    self.isIPiece = isIPiece

    return self
end

function Tetrimino:getColor() return self.color end

function Tetrimino:getKickTests()
    if self.isIPiece then
        return kickTests.ITetrimino
    end
    return kickTests.basic
end

function Tetrimino:getTileCoordinates()
    return self.tileCoordinates
end

function Tetrimino:getRect()
    return self.rect.width, self.rect.height
end

local TetriminoManager = {}
TetriminoManager.__index = TetriminoManager

function TetriminoManager.new()
    local self = setmetatable({}, TetriminoManager)

    self.tetriminos = {}
    for i, params in ipairs(tetriminoData) do
        local tileMap, rgbColors = unpack(params)
        local colors = {}
        for _, channel in ipairs(rgbColors) do table.insert(colors, channel/255) end
        table.insert(self.tetriminos, Tetrimino.new(tileMap, colors, i==1))
    end

    self.tetriminoSequence = {}
    self.tetriminoBag = {}

    return self
end

function TetriminoManager:getNextTetrimino()
    if #self.tetriminoBag <= 0 then 
        for i=1, #self.tetriminos do
            table.insert(self.tetriminoBag, i)
            --io.write(i .. ' ')
        end
        --print()
    end
    while #self.tetriminoSequence <= 3 do
        local tetriminoBagIndex = math.random(1, #self.tetriminoBag)
        local tetriminoIndex = table.remove(self.tetriminoBag, tetriminoBagIndex)
        --print(tetriminoIndex)

        table.insert(self.tetriminoSequence, tetriminoIndex)
    end
    return self.tetriminos[table.remove(self.tetriminoSequence, 1)]
end

function TetriminoManager:getUpcomingTetriminos()
    local upcomingTetriminos = {}
    for _, tetriminoIndex in ipairs(self.tetriminoSequence) do
        table.insert(upcomingTetriminos, self.tetriminos[tetriminoIndex])
    end
    return upcomingTetriminos
end


return TetriminoManager