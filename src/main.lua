
local constants = require("constants")
local state = require("state")

local function genGlobals()
    screenWidth, screenHeight = love.graphics.getDimensions()
    centerX = screenWidth / 2
    centerY = screenHeight / 2
    love.graphics.setFont(font)
end

function love.load()
    require("lurker").postswap = genGlobals
    font = love.graphics.setNewFont("DejaVuSansMono.ttf", 20)
    genGlobals()
end

local function updateWave(wave, dt)
    wave.position = wave.position + wave.velocity * dt

    local waveRightCorner = wave.position - screenWidth * constants.pixelSize
    local index = 1
    while index <= #wave.pulses do
        if wave.pulses[index].position < waveRightCorner then
            table.remove(wave.pulses, index)
        else
            index = index + 1
        end
    end


    if wave.position > 4096 then
        wave.position = wave.position - 4096
        for _, pulse in ipairs(wave.pulses) do
            pulse.position = pulse.position - 4096
        end
    end
end

local function getWaveIntensityAt(waveState, position)
    local intensity = 0
    for _, pulse in ipairs(waveState.pulses) do
        local distance = math.abs(pulse.position - position)
        if distance < pulse.width then
            intensity = intensity + pulse.intensity * math.cos( (math.pi / 2) * (distance / pulse.width) )
        end
    end
    return intensity
end

function love.update(dt)
    require("lurker").update()
    updateWave(state.alphaWave, dt)
    updateWave(state.betaWave, dt)

    state.playerScore = state.playerScore +
        (getWaveIntensityAt(state.alphaWave, state.alphaWave.position) * state.alphaAffinity
        +
        getWaveIntensityAt(state.betaWave, state.betaWave.position) * state.betaAffinity)
        * dt
end

local function sendPulse(waveState, intensity, width)
    table.insert(waveState.pulses, {
        position = waveState.position + 4 * waveState.velocity,
        intensity = intensity,
        width = width,
    })
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
    elseif key == "p" then
        sendPulse(state.alphaWave, math.random(10, 30), math.random(1, 4))
    elseif key == "o" then
        sendPulse(state.betaWave, math.random(10, 30), math.random(1, 4))
    end
end

local function renderWave(waveState, waveConfig)
    love.graphics.setColor(unpack(waveConfig.color))

    local pixelPosition = waveState.position + centerX * constants.pixelSize

    for col = 0, screenWidth - 1 do
        local intensity = getWaveIntensityAt(waveState, pixelPosition)
        intensity = math.max(intensity, 0.5)

        love.graphics.rectangle("fill",
            col,
            waveConfig.y - intensity,
            1,
            intensity * 2)

        pixelPosition = pixelPosition - constants.pixelSize
    end
end

local function alignedPrint(msg, x, y, anchorX, anchorY)
    local w = font:getWidth(msg)
    local h = font:getHeight(msg)
    love.graphics.print(msg, x - w * anchorX, y - h * anchorY)
end

local function alignedRectangle(x, y, width, height, anchorX, anchorY)
    love.graphics.rectangle("fill",
        x - width * anchorX, y - height * anchorY,
        width, height)
end

local function drawButton(x, y, label)
    local width = 50
    local height = 50
    local border = 4

    love.graphics.setColor(120, 120, 120, 255)
    alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)
    love.graphics.setColor(80, 80, 80, 255)
    alignedRectangle(x, y, width, height, 0.5, 0.5)

    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(label, x, y, 0.5, 0.5)
end

function love.draw()
    renderWave(state.alphaWave, constants.alphaWave)
    alignedPrint("α", 5, constants.alphaWave.y, 0, 1)
    alignedPrint(string.format("%d%% ψ", state.alphaAffinity * 100), screenWidth - 5, constants.alphaWave.y, 1, 1)
    renderWave(state.betaWave, constants.betaWave)
    alignedPrint("β", 5, constants.betaWave.y, 0, 0)
    alignedPrint(string.format("%d%% ψ", state.betaAffinity * 100), screenWidth - 5, constants.betaWave.y, 1, 0)

    love.graphics.setColor(unpack(constants.centerBarColor))
    local centerBarWidth = constants.centerBarWidth
    love.graphics.rectangle("fill", centerX - centerBarWidth / 2, 0, centerBarWidth, screenHeight)

    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(string.format("Score: %d", state.playerScore), centerX, screenHeight - 5, 0.5, 1.0)

    drawButton(screenWidth / 4, screenHeight * 3/4 - 50, "ξα")
    drawButton(screenWidth / 4, screenHeight * 3/4 + 50, "ξβ")

    drawButton(screenWidth * 3/4, screenHeight * 3/4 - 50, "+ αψ")
    drawButton(screenWidth * 3/4, screenHeight * 3/4 + 50, "+ βψ")
end