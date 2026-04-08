-- DISASTER SURVIVAL - Base
-- Solar2D / Lua

local W = display.contentWidth
local H = display.contentHeight
local CX = display.contentCenterX
local CY = display.contentCenterY

-- ── PHYSICS ──
local physics = require("physics")
physics.start()
physics.setGravity(0, 0)  -- top-down, sin gravedad

-- ── COLORES ──
local COLOR = {
    bg       = {0.13, 0.18, 0.13},
    grass    = {0.25, 0.40, 0.20},
    dark     = {0.10, 0.15, 0.10},
    player   = {0.20, 0.60, 1.00},
    bot1     = {1.00, 0.30, 0.30},
    bot2     = {1.00, 0.70, 0.10},
    bot3     = {0.70, 0.30, 1.00},
    bot4     = {0.20, 0.90, 0.50},
    wall     = {0.40, 0.35, 0.30},
    ui_bg    = {0, 0, 0, 0.5},
    white    = {1, 1, 1},
    joy_bg   = {1, 1, 1, 0.08},
    joy_knob = {1, 1, 1, 0.25},
}

-- ── MAPA ──
local MAP_W = 1200
local MAP_H = 1200
local TILE  = 60

local worldGroup = display.newGroup()
local uiGroup    = display.newGroup()

-- Fondo del mapa
local bg = display.newRect(worldGroup, 0, 0, MAP_W, MAP_H)
bg:setFillColor(unpack(COLOR.bg))

-- Grilla de tiles
for x = 0, MAP_W/TILE do
    for y = 0, MAP_H/TILE do
        if (x + y) % 2 == 0 then
            local tile = display.newRect(worldGroup,
                x*TILE + TILE/2, y*TILE + TILE/2, TILE-1, TILE-1)
            tile:setFillColor(unpack(COLOR.grass))
        end
    end
end

-- Bordes del mapa (paredes físicas)
local walls = {
    {MAP_W/2, -10,    MAP_W, 20},
    {MAP_W/2, MAP_H+10, MAP_W, 20},
    {-10,    MAP_H/2, 20,  MAP_H},
    {MAP_W+10, MAP_H/2, 20, MAP_H},
}
for _, w in ipairs(walls) do
    local wall = display.newRect(worldGroup, w[1], w[2], w[3], w[4])
    wall:setFillColor(unpack(COLOR.wall))
    physics.addBody(wall, "static", {friction=0.5, bounce=0.3})
end

-- Obstáculos en el mapa
local obstacles = {
    {200, 200, 80, 80}, {600, 150, 100, 60}, {900, 300, 70, 120},
    {150, 600, 60, 90}, {500, 500, 120, 80}, {800, 700, 80, 80},
    {300, 900, 100, 60},{700, 900, 70, 100}, {1000, 800, 90, 60},
    {400, 350, 60, 60}, {250, 750, 80, 80},  {950, 500, 60, 100},
}
for _, ob in ipairs(obstacles) do
    local r = display.newRect(worldGroup, ob[1], ob[2], ob[3], ob[4])
    r:setFillColor(unpack(COLOR.wall))
    r:setStrokeColor(0.6, 0.55, 0.45)
    r.strokeWidth = 2
    physics.addBody(r, "static", {friction=0.5, bounce=0.2})
end

-- ── PERSONAJE ──
local PLAYER_R  = 18
local PLAYER_SPD = 200

local function makeCharacter(group, x, y, color, label)
    local g = display.newGroup()
    group:insert(g)
    g.x, g.y = x, y

    -- Cuerpo
    local body = display.newCircle(g, 0, 0, PLAYER_R)
    body:setFillColor(unpack(color))
    body:setStrokeColor(1, 1, 1, 0.4)
    body.strokeWidth = 2

    -- Indicador de dirección
    local dir = display.newRect(g, PLAYER_R * 0.5, 0, PLAYER_R * 0.8, 5)
    dir:setFillColor(1, 1, 1, 0.7)

    -- Etiqueta
    if label then
        local txt = display.newText({
            parent = g,
            text = label,
            x = 0, y = -PLAYER_R - 12,
            fontSize = 14,
            font = native.systemFontBold,
        })
        txt:setFillColor(1, 1, 1)
    end

    -- Sombra
    local shadow = display.newCircle(group, x+3, y+3, PLAYER_R)
    shadow:setFillColor(0, 0, 0, 0.3)
    shadow:toBack()
    g.shadow = shadow

    physics.addBody(g, "dynamic", {
        radius = PLAYER_R,
        friction = 0.3,
        bounce = 0.2,
        linearDamping = 8,
    })
    g.isFixedRotation = true

    return g
end

local player = makeCharacter(worldGroup, MAP_W/2, MAP_H/2, COLOR.player, "TÚ")

-- Bots
local botColors = {COLOR.bot1, COLOR.bot2, COLOR.bot3, COLOR.bot4}
local botNames  = {"Bot1", "Bot2", "Bot3", "Bot4"}
local bots = {}
local botSpawns = {
    {200, 200}, {1000, 200}, {200, 1000}, {1000, 1000}
}
for i = 1, 4 do
    local b = makeCharacter(worldGroup,
        botSpawns[i][1], botSpawns[i][2],
        botColors[i], botNames[i])
    b.vx, b.vy = 0, 0
    b.timer = math.random(60, 180)
    b.angle = math.random() * math.pi * 2
    table.insert(bots, b)
end

-- ── CÁMARA ──
local camX, camY = MAP_W/2, MAP_H/2

local function updateCamera()
    local tx = -player.x + W/2
    local ty = -player.y + H/2
    -- Limitar cámara a bordes del mapa
    tx = math.min(0, math.max(tx, -(MAP_W - W)))
    ty = math.min(0, math.max(ty, -(MAP_H - H)))
    -- Suavizar movimiento
    worldGroup.x = worldGroup.x + (tx - worldGroup.x) * 0.12
    worldGroup.y = worldGroup.y + (ty - worldGroup.y) * 0.12
    -- Actualizar sombras
    player.shadow.x = player.x + 3
    player.shadow.y = player.y + 3
    for _, b in ipairs(bots) do
        b.shadow.x = b.x + 3
        b.shadow.y = b.y + 3
    end
end

-- ── JOYSTICK ──
local JOY_R   = 55
local KNOB_R  = 28
local JOY_X   = 90
local JOY_Y   = H - 90

local joyBase = display.newCircle(uiGroup, JOY_X, JOY_Y, JOY_R)
joyBase:setFillColor(unpack(COLOR.joy_bg))
joyBase:setStrokeColor(1, 1, 1, 0.15)
joyBase.strokeWidth = 2

local joyKnob = display.newCircle(uiGroup, JOY_X, JOY_Y, KNOB_R)
joyKnob:setFillColor(unpack(COLOR.joy_knob))
joyKnob:setStrokeColor(1, 1, 1, 0.3)
joyKnob.strokeWidth = 2

local joyActive = false
local joyTouchID = nil
local joyDX, joyDY = 0, 0

local function onJoyTouch(event)
    if event.phase == "began" then
        if event.x < W * 0.45 then
            joyActive = true
            joyTouchID = event.id
        end
    elseif event.phase == "moved" and joyActive and event.id == joyTouchID then
        local dx = event.x - JOY_X
        local dy = event.y - JOY_Y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > JOY_R then
            dx = dx / dist * JOY_R
            dy = dy / dist * JOY_R
        end
        joyKnob.x = JOY_X + dx
        joyKnob.y = JOY_Y + dy
        joyDX = dx / JOY_R
        joyDY = dy / JOY_R
    elseif (event.phase == "ended" or event.phase == "cancelled")
        and event.id == joyTouchID then
        joyActive = false
        joyTouchID = nil
        joyDX, joyDY = 0, 0
        joyKnob.x = JOY_X
        joyKnob.y = JOY_Y
    end
    return true
end
Runtime:addEventListener("touch", onJoyTouch)

-- ── HUD ──
-- Fondo HUD arriba
local hudBar = display.newRect(uiGroup, W/2, 22, W, 44)
hudBar:setFillColor(unpack(COLOR.ui_bg))

-- Contador de vivos
local aliveText = display.newText({
    parent = uiGroup,
    text = "Vivos: 5",
    x = W/2, y = 22,
    fontSize = 18,
    font = native.systemFontBold,
})
aliveText:setFillColor(1, 1, 1)

-- HP Bar
local HP_W = 160
local hpBg = display.newRect(uiGroup, W - HP_W/2 - 20, H - 30, HP_W, 14)
hpBg:setFillColor(0.2, 0.2, 0.2, 0.8)
hpBg.strokeWidth = 1
hpBg:setStrokeColor(1,1,1,0.2)

local hpBar = display.newRect(uiGroup, W - HP_W/2 - 20, H - 30, HP_W, 14)
hpBar:setFillColor(0.2, 0.85, 0.3)
hpBar.anchorX = 0
hpBar.x = W - HP_W - 20

local hpText = display.newText({
    parent = uiGroup,
    text = "100 HP",
    x = W - HP_W/2 - 20, y = H - 30,
    fontSize = 11,
})
hpText:setFillColor(1, 1, 1)

local playerHP = 100

-- Minimap
local MM_S = 90
local MM_X = W - MM_S/2 - 10
local MM_Y = 60
local mmBg = display.newRect(uiGroup, MM_X, MM_Y, MM_S, MM_S)
mmBg:setFillColor(0, 0.1, 0, 0.75)
mmBg:setStrokeColor(1, 1, 1, 0.2)
mmBg.strokeWidth = 1

-- Punto del jugador en minimap
local mmPlayer = display.newCircle(uiGroup, MM_X, MM_Y, 4)
mmPlayer:setFillColor(unpack(COLOR.player))

-- Puntos de bots en minimap
local mmBots = {}
for i = 1, 4 do
    local dot = display.newCircle(uiGroup, MM_X, MM_Y, 3)
    dot:setFillColor(unpack(botColors[i]))
    table.insert(mmBots, dot)
end

local function updateMinimap()
    local scaleX = MM_S / MAP_W
    local scaleY = MM_S / MAP_H
    mmPlayer.x = MM_X - MM_S/2 + player.x * scaleX
    mmPlayer.y = MM_Y - MM_S/2 + player.y * scaleY
    for i, b in ipairs(bots) do
        if b.isAlive ~= false then
            mmBots[i].x = MM_X - MM_S/2 + b.x * scaleX
            mmBots[i].y = MM_Y - MM_S/2 + b.y * scaleY
            mmBots[i].isVisible = true
        else
            mmBots[i].isVisible = false
        end
    end
end

-- ── IA BOTS ──
local function updateBots(dt)
    for _, b in ipairs(bots) do
        if b.isAlive == false then break end
        b.timer = b.timer - 1
        if b.timer <= 0 then
            b.timer = math.random(60, 200)
            b.angle = math.random() * math.pi * 2
            if math.random() < 0.3 then
                -- Ocasionalmente moverse hacia el centro
                local dx = MAP_W/2 - b.x
                local dy = MAP_H/2 - b.y
                b.angle = math.atan2(dy, dx)
            end
        end
        local spd = PLAYER_SPD * 0.65
        b:setLinearVelocity(
            math.cos(b.angle) * spd,
            math.sin(b.angle) * spd
        )
        -- Rotar sprite hacia dirección
        b.rotation = math.deg(b.angle) + 90
    end
end

-- ── GAME LOOP ──
local function onFrame(event)
    -- Mover jugador
    if joyActive and (math.abs(joyDX) > 0.05 or math.abs(joyDY) > 0.05) then
        player:setLinearVelocity(
            joyDX * PLAYER_SPD,
            joyDY * PLAYER_SPD
        )
        player.rotation = math.deg(math.atan2(joyDY, joyDX)) + 90
    else
        player:setLinearVelocity(0, 0)
    end

    updateBots()
    updateCamera()
    updateMinimap()
end

Runtime:addEventListener("enterFrame", onFrame)
