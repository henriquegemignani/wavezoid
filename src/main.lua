
local constants = require("constants")
local state = require("state")
local waves = state.waves

local function getConstant(name)
    local v = constants[name]
    if type(v) == "number" then
        return v
    else
        return v.rangeMin + (v.rangeMax - v.rangeMin) * lovecat.number[v.namespace][name]
    end
end

local function genGlobals()
    screenWidth, screenHeight = love.graphics.getDimensions()
    centerX = screenWidth / 2
    centerY = screenHeight / 2
end

local function createWave(x, y, duration, radius)
    table.insert(waves, {
        life = 0,
        alpha = 255,
        radius = 0,
        x = x,
        y = y,
        duration = duration,
        targetRadius = radius,
    })
end

function love.load()
    lovecat.reload()
    require("lurker").postswap = genGlobals
    genGlobals()
end

local function waveUpdate(dt)
    local index = 1
    while index <= #waves do
        local wave = waves[index]
        wave.life = wave.life + dt
        if wave.life > wave.duration then
            table.remove(waves, index)
        else
            local percentage = wave.life / wave.duration
            wave.radius = percentage * wave.targetRadius
            wave.alpha = 255 * (1 - percentage)
            index = index + 1
        end
    end
end

function love.update(dt)
    require("lurker").update()
    lovecat.update(dt)
    waveUpdate(dt)

    state.timeSinceLastPlayerWave = state.timeSinceLastPlayerWave + dt
    local playerWaveInterval = getConstant("playerWaveInterval")

    if state.timeSinceLastPlayerWave >= playerWaveInterval then
        state.timeSinceLastPlayerWave = state.timeSinceLastPlayerWave - playerWaveInterval
        createWave(centerX, centerY, getConstant("playerWaveDuration"), getConstant("playerWaveRadius"))
    end
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
    end
end

function love.draw()
    for _, wave in ipairs(waves) do
        love.graphics.setColor(255, 255, 255, wave.alpha)
        love.graphics.circle("line", wave.x, wave.y, wave.radius)
    end
end