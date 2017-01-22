
local constants = require("constants")
local state = require("state")

local function genButton(x, y, label)
    return { x = x, y = y, label = label,
             width = 50, height = 50,
             onRelease = function() end, }
end

local buttons = {}
buttons.pulse_alpha     = genButton(2/8, 14/16, "ξα")
buttons.pulse_beta      = genButton(3/8, 14/16, "ξβ")
buttons.affinity_alpha  = genButton(5/8, 14/16, "+ψα")
buttons.affinity_beta   = genButton(6/8, 14/16, "+ψβ")

local function genGlobals()
    screenWidth, screenHeight = love.graphics.getDimensions()
    centerX = screenWidth / 2
    centerY = screenHeight / 2
    love.graphics.setFont(font)
    print("GEN GLOBALS")
end

function love.load()
    require("lurker").postswap = genGlobals
    require("lurker").preswap = function(name)
        if name == "multiplayer.lua" or name == "multiplayer_thread.lua" then
            return true
        end
    end
    _G.smallFont = love.graphics.newFont("DejaVuSansMono.ttf", 15)
    _G.bigFont = love.graphics.newFont("DejaVuSansMono.ttf", 25)
    font = love.graphics.setNewFont("DejaVuSansMono.ttf", 20)
    genGlobals()
    require("multiplayer"):start()
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

local function spawnScoreEffect(count, x, y, color)
end

local function updateWave(wave, dt)
    wave.velocity = 20
    wave.position = wave.position + wave.velocity * dt
    wave.affinity = wave.affinity - wave.affinity * 0.1 * dt

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

    -- Give points
    local points = getWaveIntensityAt(wave, wave.position) * wave.affinity * dt
    state.playerScore = state.playerScore + points
    if points > dt then
        -- Spawn effect!
        spawnScoreEffect(points, centerX, constants[wave.name].y, constants[wave.name].color)
    end
end

local function sendPulse(waveState, intensity, width)
    table.insert(waveState.pulses, {
        position = waveState.position + 4 * waveState.velocity,
        intensity = intensity,
        width = width,
    })
end

function love.update(dt)
    require("lurker").update()
    updateWave(state.alphaWave, dt)
    updateWave(state.betaWave, dt)

    if state.actionCooldownTimer > 0 then
        state.actionCooldownTimer = math.max(state.actionCooldownTimer - dt, 0)
    end

    local inboundChannel = love.thread.getChannel("inbound")
    local command = inboundChannel:pop()
    if command then
        if command == "pulse_alpha" then
            sendPulse(state.alphaWave, math.random(10, 30), math.random(1, 4))
        elseif command == "pulse_beta" then
            sendPulse(state.betaWave, math.random(10, 30), math.random(1, 4))
        elseif command == "player_connect" then
            state.currentPlayers = state.currentPlayers + 1
        elseif command == "player_disconnect" then
            state.currentPlayers = state.currentPlayers - 1
        else
            local com, arg = command:match("(%w+) (%w+)")
            print(com, arg)
            if com == "players" then
                state.currentPlayers = arg
            end
        end
    end
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
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

local function alignedPrint(msg, x, y, anchorX, anchorY, theFont)
    theFont = theFont or font
    local w = theFont:getWidth(msg)
    local h = theFont:getHeight(msg)
    love.graphics.setFont(theFont)
    love.graphics.print(msg, x - w * anchorX, y - h * anchorY)
end

local function alignedRectangle(x, y, width, height, anchorX, anchorY)
    love.graphics.rectangle("fill",
        x - width * anchorX, y - height * anchorY,
        width, height)
end

function buttons.pulse_alpha.onRelease()
    local outboundChannel = love.thread.getChannel("outbound")
    local inboundChannel = love.thread.getChannel("inbound")
    outboundChannel:push("pulse_alpha")
    inboundChannel:push("pulse_alpha")
end

function buttons.pulse_beta.onRelease()
    local outboundChannel = love.thread.getChannel("outbound")
    local inboundChannel = love.thread.getChannel("inbound")
    outboundChannel:push("pulse_beta")
    inboundChannel:push("pulse_beta")
end

function buttons.affinity_alpha.onRelease()
    state.alphaWave.affinity = state.alphaWave.affinity + 1
end

function buttons.affinity_beta.onRelease()
    state.betaWave.affinity = state.betaWave.affinity + 1
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

    if state.actionCooldownTimer > 0 then
        love.graphics.setColor(0, 0, 0, 150)
        alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)
    end
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
    -- Waves
    renderWave(state.alphaWave, constants.alphaWave)
    alignedPrint("α", 5, constants.alphaWave.y, 0, 1)
    alignedPrint(string.format("%d%% ψ", state.alphaWave.affinity * 100),
                 screenWidth - 5, constants.alphaWave.y, 1, 1)
    renderWave(state.betaWave, constants.betaWave)
    alignedPrint("β", 5, constants.betaWave.y, 0, 0)
    alignedPrint(string.format("%d%% ψ", state.betaWave.affinity * 100),
                 screenWidth - 5, constants.betaWave.y, 1, 0)

    -- Hot area
    love.graphics.setColor(unpack(constants.centerBarColor))
    local centerBarWidth = constants.centerBarWidth
    alignedRectangle(
        centerX, (constants.alphaWave.y + constants.betaWave.y) / 2,
        centerBarWidth, constants.betaWave.y - constants.alphaWave.y + 80,
        0.5, 0.5)

    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(string.format("Score: %d", state.playerScore),
                 centerX, 5, 0.5, 0.0,
                 _G.bigFont)

    -- Action buttons
    for _, button in pairs(buttons) do
        drawButton(button)
    end

    -- Cooldown display
    local cooldownRemaining = state.actionCooldownTimer / constants.actionCooldown
    local middleAngle = (1 - cooldownRemaining) * math.pi * 2 - math.pi/2
    love.graphics.setColor(100, 100, 100,
        state.actionCooldownTimer > 0 and 255
        or 100
    )
    love.graphics.arc("fill", centerX, screenHeight * 14/16, 30, -math.pi/2, middleAngle)
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.arc("fill", centerX, screenHeight * 14/16, 30, middleAngle, math.pi * 3/2)

    -- Player count
    if type(state.currentPlayers) == "boolean" then
        love.graphics.setColor(255, 0, 0, 255)
        alignedPrint("Offline", 5, screenHeight - 5, 0, 1, _G.smallFont)
    else
        love.graphics.setColor(255, 255, 0, 255)
        alignedPrint(string.format("Current Players: %d", state.currentPlayers),
                     5, screenHeight - 5, 0, 1, _G.smallFont)
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
            if state.actionCooldownTimer <= 0 and isInsideButton(button, x, y) then
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
                state.actionCooldownTimer = constants.actionCooldown
                button.onRelease()
            end
            button.pressing = false
        end
    end
end

function love.quit()
    local messageChannel = love.thread.getChannel("outbound")
    messageChannel:push("close")
    require("multiplayer"):wait()
end