local soundNames = {
    'shift',
    'descend',
    'drop',
    'clearLine',
    'hold'
}

local sounds = {}

for _, soundName in ipairs(soundNames) do
    sounds[soundName] = love.audio.newSource('sounds/' .. soundName .. '.wav', 'static')
end

love.audio.setVolume(0.5)

return sounds