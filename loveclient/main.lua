
local constants = require("constants")
local state = require("state")

local function genButton(x, y, label)
    return { x = x, y = y, label = label,
             width = 50, height = 50,
             onRelease = function() end, }
end

local buttons = {}
buttons.pulse_alpha = genButton(1 / 4, 3/4 - 0.1, "ξα")
buttons.pulse_beta = genButton(1 / 4, 3/4 + 0.1, "ξβ")
buttons.affinity_alpha = genButton(3/4, 3/4 - 0.1, "ψ->α")
buttons.affinity_beta = genButton(3/4, 3/4 + 0.1, "ψ->β")

local function genGlobals()
    screenWidth, screenHeight = love.graphics.getDimensions()
    centerX = screenWidth / 2
    centerY = screenHeight / 2
    love.graphics.setFont(font)
    print("GEN GLOBALS")
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

local function calculateAffinities()
    if state.affinitySlider == 0 then
        return 0.1, 0.1
    else
        local affinity = math.pow(1.2, math.abs(state.affinitySlider))
        if state.affinitySlider > 0 then
            return affinity, -0.8 * affinity
        else
            return -0.8 * affinity, affinity
        end
    end
end

function love.update(dt)
    require("lurker").update()
    updateWave(state.alphaWave, dt)
    updateWave(state.betaWave, dt)

    local alphaAffinity, betaAffinity = calculateAffinities()

    state.playerScore = state.playerScore +
        (getWaveIntensityAt(state.alphaWave, state.alphaWave.position) * alphaAffinity
        +
        getWaveIntensityAt(state.betaWave, state.betaWave.position) * betaAffinity)
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

function buttons.pulse_alpha.onRelease()
    sendPulse(state.alphaWave, math.random(10, 30), math.random(1, 4))
end

function buttons.pulse_beta.onRelease()
    sendPulse(state.betaWave, math.random(10, 30), math.random(1, 4))
end

function buttons.affinity_alpha.onRelease()
    state.affinitySlider = state.affinitySlider + 1
end

function buttons.affinity_beta.onRelease()
    state.affinitySlider = state.affinitySlider - 1
end

local function buttonX(button)
    return button.x * screenWidth
end

local function buttonY(button)
    return button.y * screenHeight
end

local function drawButton(button)
    local x = buttonX(button)
    local y = buttonY(button)
    local label = button.label
    local width = button.width
    local height = button.height
    local border = 4

    if button.pressing then
        love.graphics.setColor(180, 180, 180, 255)
    else
        love.graphics.setColor(120, 120, 120, 255)
    end
    alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)

    if button.hover then
        love.graphics.setColor(100, 100, 100, 255)
    else
        love.graphics.setColor(80, 80, 80, 255)
    end
    alignedRectangle(x, y, width, height, 0.5, 0.5)

    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(label, x, y, 0.5, 0.5)
end

local function isInsideButton(button, x, y)
    local bx = buttonX(button)
    local by = buttonY(button)
    local hWidth = button.width / 2
    local hHeight = button.height / 2
    return bx - hWidth <= x and x <= bx + hWidth
       and by - hHeight <= y and y <= by + hHeight
end

function love.draw()
    local alphaAffinity, betaAffinity = calculateAffinities()

    renderWave(state.alphaWave, constants.alphaWave)
    alignedPrint("α", 5, constants.alphaWave.y, 0, 1)
    alignedPrint(string.format("%d%% ψ", alphaAffinity * 100), screenWidth - 5, constants.alphaWave.y, 1, 1)
    renderWave(state.betaWave, constants.betaWave)
    alignedPrint("β", 5, constants.betaWave.y, 0, 0)
    alignedPrint(string.format("%d%% ψ", betaAffinity * 100), screenWidth - 5, constants.betaWave.y, 1, 0)

    love.graphics.setColor(unpack(constants.centerBarColor))
    local centerBarWidth = constants.centerBarWidth
    love.graphics.rectangle("fill", centerX - centerBarWidth / 2, 0, centerBarWidth, screenHeight)

    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(string.format("Score: %d", state.playerScore), centerX, screenHeight - 5, 0.5, 1.0)

    for _, button in pairs(buttons) do
        drawButton(button)
    end
end

function love.mousemoved(x, y)
    for _, button in pairs(buttons) do
        local isInside = isInsideButton(button, x, y)
        if state.mouseDown then
            button.hover = button.hover and isInside
            button.pressing = button.pressing and isInside
        else
            button.hover = isInside
        end
    end
end

function love.mousepressed(x, y, mouseButton)
    if mouseButton == 1 then
        state.mouseDown = true
        for _, button in pairs(buttons) do
            if isInsideButton(button, x, y) then
                button.pressing = true
            end
        end
    end
end

function love.mousereleased(x, y, mouseButton)
    if mouseButton == 1 then
        state.mouseDown = false
        for _, button in pairs(buttons) do
            if button.pressing and isInsideButton(button, x, y) then
                button.onRelease()
            end
            button.pressing = false
        end
    end
end