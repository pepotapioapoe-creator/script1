--[[
    ZVOLT HUB V2.43 — FRESH EDITION
    UI moderna + más funciones + mejor rendimiento
    By Zvolt
]]

--// Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

--// Settings
local settings = {
    -- combat
    aimEnabled = false, aimMode = "Camera", teamCheck = false, wallCheck = false,
    stickyTarget = true, smoothing = 25, fovRadius = 140, showFov = true, fovRainbow = false,
    targetPart = "Head", hitboxEnabled = false, hitboxSize = 8, wallbangEnabled = false,
    silentAimEnabled = false, silentHitChance = 100, silentPrediction = 0.12,
    silentBone = "Same as Aimbot", silentFov = 200,
    magicBulletsEnabled = false, magicNotified = false,
    spyEnabled = false,
    silentGame = "Universal",
    triggerbot = false, triggerDelay = 150, triggerWarned = false,
    aimDebug = false,
    aimAuto = false,
    aimClassic = false,
    aimSnap = false,
    aimNpcs = false,
    aimBrute = false,
    aimScriptable = false,
    aimDeadzone = 6,
    -- visuals
    espEnabled = false, espNames = true, espDistance = true, espHealthBar = true,
    espBox = true, espTracer = true, tracerOrigin = "Bottom", espChams = false, espTool = false,
    espRainbow = false, maxDistance = 1500, skeleton = true,
    espXray = true,
    -- movement
    flyEnabled = false, flySpeed = 60, noclipEnabled = false, speedEnabled = false, customSpeed = 32,
    jumpEnabled = false, customJump = 100, bhopEnabled = false, infJumpEnabled = false,
    spinEnabled = false, spinSpeed = 50, ctrlClickTpEnabled = false, gravity = 196.2, antiVoid = false,
    tapTp = false, freecam = false,
    jerkEnabled = false, jerkPower = 5,
    -- troll / tp
    trollTrackEnabled = false, trollOrbitEnabled = false, orbitSpeed = 3, orbitRadius = 6, trackDist = 3,
    flingEnabled = false, headSitEnabled = false, spectateEnabled = false,
    selectedTpPlayer = nil, savedPos = nil, tpFollow = false,
    -- weapon/world
    ammoEnabled = false, rapidFire = false, fullbright = false, fpsBoosted = false, antiAfk = false,
    noShadows = false,
    -- ui
    uiToggleKey = Enum.KeyCode.RightShift, theme = "Cyan", uiTransparency = 0,
    ghostMode = false,
    verbose = false,
}
local DEFAULT_SPEED, DEFAULT_JUMP = 16, 50
local hitboxOriginals, currentAimTarget = {}, nil
local orbitAngle, spectating = 0, false
local lastAimPart = nil -- objetivo del aimbot V1; magic lo sigue (declarado arriba para que magic lo vea)

--// Snapshot original para restaurar todo al salir (anti-ban: no dejar huellas)
local origLighting = {}
pcall(function()
    origLighting = {
        ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
    }
end)
local function restoreLighting()
    pcall(function()
        for k, v in pairs(origLighting) do Lighting[k] = v end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") and origLighting.AtmosDensity ~= nil then v.Density = origLighting.AtmosDensity end
        end
    end)
end

local keybinds = {
    aimbot = Enum.KeyCode.F1, esp = Enum.KeyCode.F2, noclip = Enum.KeyCode.F3,
    fly = Enum.KeyCode.F4, hitbox = Enum.KeyCode.F5, spinbot = Enum.KeyCode.F6,
}

--// Temas
local THEMES = {
    Cyan   = { main = Color3.fromRGB(0, 242, 255),  second = Color3.fromRGB(150, 80, 255) },
    Purple = { main = Color3.fromRGB(170, 90, 255), second = Color3.fromRGB(255, 90, 200) },
    Red    = { main = Color3.fromRGB(255, 70, 90),  second = Color3.fromRGB(255, 160, 60) },
    Green  = { main = Color3.fromRGB(60, 255, 170), second = Color3.fromRGB(0, 220, 255) },
    Sunset = { main = Color3.fromRGB(255, 180, 60), second = Color3.fromRGB(255, 80, 160) },
}
local COLOR_BG      = Color3.fromRGB(10, 10, 16)
local COLOR_SIDE    = Color3.fromRGB(13, 13, 22)
local COLOR_CARD    = Color3.fromRGB(17, 17, 27)
local COLOR_CARD2   = Color3.fromRGB(22, 22, 34)
local COLOR_TEXT    = Color3.fromRGB(245, 245, 250)
local COLOR_SUBTEXT = Color3.fromRGB(150, 150, 170)
local FONT_MAIN  = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_TITLE = Enum.Font.FredokaOne
local function Accent() return THEMES[settings.theme].main end
local function Accent2() return THEMES[settings.theme].second end
local accentTagged = {} -- {obj, prop}
local function TagAccent(obj, prop) table.insert(accentTagged, {o = obj, p = prop or "BackgroundColor3"}) end
local function RefreshTheme()
    for _, e in ipairs(accentTagged) do
        pcall(function() e.o[e.p] = Accent() end)
    end
end

--// Utils
local function tween(obj, info, props) pcall(function() TweenService:Create(obj, info or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end) end
local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = obj return c end
local function stroke(obj, col, t, tr) local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1 s.Transparency = tr or 0 s.Parent = obj return s end
local function isAlive(plr)
    local c = plr and plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c ~= nil and h ~= nil and h.Health > 0
end
local function myRoot() local c = localPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function myHum() local c = localPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function targetRootOf(plr) local c = plr and plr.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function sameTeam(a, b)
    if not settings.teamCheck then return false end
    if a.Team == nil or b.Team == nil then return false end
    return a.Team == b.Team
end
-- (build sin silent: hasWallBetween/rayParams eliminados, nadie los usaba)
local defaultsCaptured = false
local function captureDefaults()
    if defaultsCaptured then return end
    local h = myHum()
    if h then
        DEFAULT_SPEED = h.WalkSpeed
        DEFAULT_JUMP = h.JumpPower
        defaultsCaptured = true
    end
end
local function restoreDefaults()
    local h = myHum()
    if h then
        if not settings.speedEnabled then h.WalkSpeed = DEFAULT_SPEED end
        if not settings.jumpEnabled then h.JumpPower = DEFAULT_JUMP end
    end
    if not settings.hitboxEnabled then
        for part, size in pairs(hitboxOriginals) do
            pcall(function() if part and part.Parent then part.Size = size part.Transparency = 0 end end)
        end
        table.clear(hitboxOriginals)
    end
end

--// Anti-fugas: al re-ejecutar se matan loops e hilos de la instancia anterior.
-- (Si no, cada execute duplica ESP/aim/fly y pelean entre sí.)
if _G.__ZV_STOP then pcall(_G.__ZV_STOP) end
local dead = false
_G.__ZV_STOP = function() dead = true end
if _G.__ZV_CONNS then
    for _, c in ipairs(_G.__ZV_CONNS) do pcall(function() c:Disconnect() end) end
end
_G.__ZV_CONNS = {}
local function ZCONN(c) table.insert(_G.__ZV_CONNS, c) return c end

--// GUI raíz (nombres neutros: los anticheats escanean instancias con "hub", "aim", "esp", "zvolt", etc.)
local function rndName()
    local s = ""
    for i = 1, 10 do s = s .. string.char(math.random(97, 122)) end
    return "ui_" .. s
end
for _, v in ipairs(localPlayer.PlayerGui:GetChildren()) do
    pcall(function()
        if v:GetAttribute("ZV2") or v.Name:find("Zvolt") or v.Name:find("ZVOLT") then v:Destroy() end
    end)
end
local gui = Instance.new("ScreenGui")
gui.Name = rndName()
gui:SetAttribute("ZV2", true)
-- limpia restos de ejecuciones viejas: su GUI y su ESP pegado a personajes
for _, pl in ipairs(Players:GetPlayers()) do
    local ch = pl.Character
    if ch then
        for _, d in ipairs(ch:GetDescendants()) do
            pcall(function() if d:GetAttribute("ZV2") then d:Destroy() end end)
        end
    end
end
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- STEALTH: siempre PlayerGui. gethui/CoreGui es una bandera clásica para los anticheats.
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// Texto discreto: el anticheat escanea PlayerGui (TextLabel/TextButton).
-- Se traduce ANTES de crear el texto (sin flash). discreetOn=true siempre.
-- Definido ANTES de notify() a proposito (scope Lua: notify lo captura como upvalue).
-- DISCREET_ENABLED=false: nombres reales (el usuario confirmo que "ESP" no patea).
-- Si vuelve el kick al ejecutar, poner en true y todo vuelve a neutro solo.
local DISCREET_ENABLED = false
local discreetOn = true
local labelOrig = {}
local DMDICT = {
    {"SILENT AIM", "Sigilo"}, {"Silent Aim", "Sigilo"},
    {"MAGIC BULLETS", "Proyectil"}, {"Magic Bullets", "Proyectil"},
    {"TRIGGERBOT", "Disparo"}, {"Triggerbot", "Disparo"},
    {"Trigger", "Disparo"}, {"TRIGGER", "DISPARO"},
    {"Aimbot", "Asistencia"}, {"AIMBOT", "ASISTENCIA"},
    {"Wallbang", "Muro"}, {"WALLBANG", "MURO"},
    {"Hitbox", "Zona"}, {"HITBOX", "ZONA"},
    {"Spinbot", "Giro"}, {"SPINBOT", "GIRO"},
    {"Bunny Hop", "Rebote"},
    {"Noclip", "Fase"}, {"NOCLIP", "FASE"},
    {"Freecam", "Vista"}, {"FREECAM", "VISTA"},
    {"Jerk anti-aim", "Movimiento"},
    {"Tracker", "Seguir"}, {"tracker", "seguir"}, {"track", "seguir"},
    {"Rapid Fire", "Rafaga"}, {"RAPID FIRE", "RAFAGA"},
    {"Magic", "Proy"}, {"MAGIC", "PROY"},
    {"Munición infinita", "Reserva"}, {"MUNICIÓN INFINITA", "RESERVA"},
    {"Municion infinita", "Reserva"},
    {"Fullbright", "Brillo"}, {"FULLBRIGHT", "BRILLO"},
    {"Anti-AFK", "Presencia"}, {"Anti-Void", "Suelo"},
    {"Super Jump", "Salto"}, {"SUPER JUMP", "SALTO"},
    {"Jump Power", "Salto"}, {"JUMP POWER", "SALTO"},
    {"Custom Speed", "Velocidad"}, {"CUSTOM SPEED", "VELOCIDAD"},
    {"Speed", "Vel"}, {"SPEED", "VEL"},
    {"Salto infinito", "Salto+"},
    {"Ctrl + Click", "Click"},
    {"Fling", "Empuje"}, {"FLING", "EMPUJE"},
    {"Espectando", "Viendo"}, {"Espectar", "Ver"},
    {"Spectate", "Ver"}, {"spectate", "ver"},
    {"Server Hop", "Servidor"},
    {"MODO FANTASMA", "FANTASMA"},
    {"Modo Fantasma", "Fantasma"},
    {"Modo AUTO", "Auto"},
    {"SNAP directo", "Fijar"},
    {"Fuerza bruta", "Amplio"},
    {"Diagnóstico F9", "Info"},
    {"Incluir NPCs/bots", "NPCs"},
    {"Team Check", "Equipos"},
    {"Chams", "Aura"}, {"CHAMS", "AURA"},
    {"Tracers", "Lineas"}, {"Tracer", "Linea"},
    {"Silent", "Sigilo"}, {"SILENT", "SIGILO"},
    {"Troll", "Fun"}, {"TROLL", "FUN"},
    {"Weapon", "Equipo"}, {"WEAPON", "EQUIPO"},
    {"Combat", "Pelea"}, {"COMBAT", "PELEA"},
    {"Visuals", "Vista"}, {"VISUALS", "VISTA"},
    {"Movement", "Mover"}, {"MOVEMENT", "MOVER"},
    {"Teleport", "Viaje"}, {"TELEPORT", "VIAJE"},
    {"World", "Mundo"}, {"WORLD", "MUNDO"},
    {"Config", "Ajustes"}, {"CONFIG", "AJUSTES"},
    {"Keybinds", "Teclas"}, {"KEYBINDS", "TECLAS"},
    {"ESP", "Radar"},
    {"Fly", "Vuelo"}, {"FLY", "VUELO"},
    {"FPS Boost", "Rendimiento"}, {"FPS BOOST", "RENDIMIENTO"},
    {"X-ray", "Ver"},
    {"Aim", "Asis"}, {"AIM", "ASIS"},
    {"spin", "giro"}, {"Jerk", "Mov"},
    {"TP", "Viaje"}, {"chetadas", "mejoradas"}, {"chetada", "mejorada"},
    {"ZVOLT", "ZV"}, {"Zvolt", "ZV"},
    {"HUB", ""},
}
local function repAll(s, find, repl)
    local out, i = {}, 1
    while true do
        local a, b = s:find(find, i, true)
        if not a then out[#out + 1] = s:sub(i) break end
        out[#out + 1] = s:sub(i, a - 1)
        out[#out + 1] = repl
        i = b + 1
    end
    return table.concat(out)
end
local function discreetText(s)
    s = tostring(s)
    if not DISCREET_ENABLED then return s end
    s = s:gsub("%b()", "")
    for _, pr in ipairs(DMDICT) do s = repAll(s, pr[1], pr[2]) end
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("  +", " ")
    return s
end
local function applyDiscreet()
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            if labelOrig[d] == nil then labelOrig[d] = d.Text end
            if discreetOn then
                local ok, nt = pcall(discreetText, labelOrig[d])
                if ok and nt ~= "" then d.Text = nt end
            else
                d.Text = labelOrig[d]
            end
        end
    end
end

--// Notificaciones modernas (stack)
local notifHolder = Instance.new("Frame")
notifHolder.Size = UDim2.new(0, 280, 1, 0)
notifHolder.Position = UDim2.new(1, -290, 0, 10)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = gui
local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 8)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = notifHolder

local function notify(title, text)
    do
        local ok1, nt1 = pcall(discreetText, title)
        if ok1 and nt1 ~= "" then title = nt1 end
        local ok2, nt2 = pcall(discreetText, text)
        if ok2 and nt2 ~= "" then text = nt2 end
    end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 64)
    f.BackgroundColor3 = COLOR_CARD
    f.Parent = notifHolder
    corner(f, 10) stroke(f, Color3.fromRGB(40, 40, 60), 1)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -16) bar.Position = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = Accent() bar.Parent = f corner(bar, 4) TagAccent(bar)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -30, 0, 20) t.Position = UDim2.new(0, 20, 0, 8)
    t.BackgroundTransparency = 1 t.Font = FONT_BOLD t.TextSize = 12 t.TextColor3 = COLOR_TEXT
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title t.Parent = f
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -30, 0, 30) d.Position = UDim2.new(0, 20, 0, 26)
    d.BackgroundTransparency = 1 d.Font = FONT_MAIN d.TextSize = 11 d.TextColor3 = COLOR_SUBTEXT
    d.TextXAlignment = Enum.TextXAlignment.Left d.TextWrapped = true d.Text = text d.Parent = f
    f.BackgroundTransparency = 1 t.TextTransparency = 1 d.TextTransparency = 1 bar.BackgroundTransparency = 1
    tween(f, TweenInfo.new(0.25), {BackgroundTransparency = 0})
    tween(t, TweenInfo.new(0.25), {TextTransparency = 0})
    tween(d, TweenInfo.new(0.25), {TextTransparency = 0})
    tween(bar, TweenInfo.new(0.25), {BackgroundTransparency = 0})
    task.delay(2.2, function()
        tween(f, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        tween(t, TweenInfo.new(0.3), {TextTransparency = 1})
        tween(d, TweenInfo.new(0.3), {TextTransparency = 1})
        task.wait(0.32) pcall(function() f:Destroy() end)
    end)
    -- NOTA: no se usa StarterGui:SetCore a propósito (rompe módulos CoreGui en algunos executors)
end
-- Prints solo con Log F9 activado: el anticheat puede leer la consola y banear por el texto.
local function dprint(...)
    if settings.verbose then
        print(...)
    end
end

--// FOV + mira
local fovFrame = Instance.new("Frame")
fovFrame.Name = "vista" fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1 fovFrame.Visible = false fovFrame.Parent = gui
local fovStroke = stroke(fovFrame, Accent(), 1.6) TagAccent(fovStroke, "Color")
corner(fovFrame, 999)
local fovDot = Instance.new("Frame")
fovDot.Size = UDim2.new(0, 4, 0, 4) fovDot.AnchorPoint = Vector2.new(0.5, 0.5)
fovDot.BackgroundColor3 = Accent() fovDot.Parent = fovFrame corner(fovDot, 999) TagAccent(fovDot)
local snapLine = Instance.new("Frame")
snapLine.AnchorPoint = Vector2.new(0.5, 0.5) snapLine.BorderSizePixel = 0
snapLine.BackgroundColor3 = Accent() snapLine.Visible = false snapLine.Parent = gui TagAccent(snapLine)
-- Estado del aimbot en pantalla (diagnóstico en vivo, sin F9)
local aimStatus = Instance.new("TextLabel")
aimStatus.Size = UDim2.new(0, 340, 0, 18) aimStatus.Position = UDim2.new(0, 10, 0, 10)
aimStatus.BackgroundTransparency = 1 aimStatus.Font = FONT_MAIN aimStatus.TextSize = 12
aimStatus.TextColor3 = COLOR_SUBTEXT aimStatus.TextStrokeTransparency = 0.5
aimStatus.Text = "" aimStatus.Parent = gui
-- (build sin silent: etiqueta silentStatus eliminada; magicStatus la reemplaza)
local magicStatus = Instance.new("TextLabel")
magicStatus.Size = UDim2.new(0, 380, 0, 18) magicStatus.Position = UDim2.new(0, 10, 0, 30)
magicStatus.BackgroundTransparency = 1 magicStatus.Font = FONT_MAIN magicStatus.TextSize = 11
magicStatus.TextColor3 = COLOR_SUBTEXT magicStatus.TextStrokeTransparency = 0.5
magicStatus.Text = "" magicStatus.Parent = gui
-- Estado del ESP en pantalla (diagnóstico en vivo: cuantos ve y por que filtra)
local espStatus = Instance.new("TextLabel")
espStatus.Size = UDim2.new(0, 380, 0, 18) espStatus.Position = UDim2.new(0, 10, 0, 50)
espStatus.BackgroundTransparency = 1 espStatus.Font = FONT_MAIN espStatus.TextSize = 11
espStatus.TextColor3 = COLOR_SUBTEXT espStatus.TextStrokeTransparency = 0.5
espStatus.Text = "" espStatus.Parent = gui

--// Pantalla de carga
local loader = Instance.new("Frame")
loader.Size = UDim2.new(1, 0, 1, 0) loader.BackgroundColor3 = COLOR_BG loader.Parent = gui
local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 50) loadTitle.Position = UDim2.new(0, 0, 0.42, -40)
loadTitle.BackgroundTransparency = 1 loadTitle.Font = FONT_TITLE loadTitle.TextSize = 42
loadTitle.TextColor3 = Color3.fromRGB(255,255,255) loadTitle.Text = "ZVOLT" loadTitle.Parent = loader
local loadGrad = Instance.new("UIGradient") loadGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEMES.Cyan.main), ColorSequenceKeypoint.new(1, THEMES.Cyan.second)} loadGrad.Parent = loadTitle
local loadSub = Instance.new("TextLabel")
loadSub.Size = UDim2.new(1, 0, 0, 20) loadSub.Position = UDim2.new(0, 0, 0.42, 12)
loadSub.BackgroundTransparency = 1 loadSub.Font = FONT_MAIN loadSub.TextSize = 12
loadSub.TextColor3 = COLOR_SUBTEXT loadSub.Text = "FRESH EDITION • v2.43" loadSub.Parent = loader
local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0, 240, 0, 5) loadBarBg.Position = UDim2.new(0.5, -120, 0.42, 42)
loadBarBg.BackgroundColor3 = COLOR_CARD2 loadBarBg.Parent = loader corner(loadBarBg, 99)
local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0) loadBar.BackgroundColor3 = Accent() loadBar.Parent = loadBarBg corner(loadBar, 99)

--// Panel principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 740, 0, 500)
mainFrame.Position = UDim2.new(0.5, -370, 0.5, -250)
mainFrame.BackgroundColor3 = COLOR_BG
mainFrame.Visible = false
mainFrame.Parent = gui
corner(mainFrame, 12) stroke(mainFrame, Color3.fromRGB(38, 38, 55), 1.2)
-- sombra
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 40, 1, 40) shadow.Position = UDim2.new(0, -20, 0, -20)
shadow.BackgroundTransparency = 1 shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0,0,0) shadow.ImageTransparency = 0.5 shadow.ZIndex = -1
shadow.Parent = mainFrame

-- Sidebar
local side = Instance.new("Frame")
side.Size = UDim2.new(0, 178, 1, 0) side.BackgroundColor3 = COLOR_SIDE side.Parent = mainFrame
corner(side, 12)
local sideFix = Instance.new("Frame") -- tapa esquina derecha del sidebar para que solo redondee a la izquierda
sideFix.Size = UDim2.new(0, 12, 1, 0) sideFix.Position = UDim2.new(1, -12, 0, 0)
sideFix.BackgroundColor3 = COLOR_SIDE sideFix.BorderSizePixel = 0 sideFix.Parent = side

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(1, -24, 0, 40) logo.Position = UDim2.new(0, 12, 0, 12)
logo.BackgroundTransparency = 1 logo.Font = FONT_TITLE logo.TextSize = 24
logo.TextXAlignment = Enum.TextXAlignment.Left logo.TextColor3 = Color3.fromRGB(255,255,255)
logo.Text = "ZVOLT" logo.Parent = side
local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEMES.Cyan.main), ColorSequenceKeypoint.new(1, THEMES.Cyan.second)}
logoGrad.Parent = logo
local logoSub = Instance.new("TextLabel")
logoSub.Size = UDim2.new(1, -24, 0, 16) logoSub.Position = UDim2.new(0, 12, 0, 46)
logoSub.BackgroundTransparency = 1 logoSub.Font = FONT_MAIN logoSub.TextSize = 10
logoSub.TextXAlignment = Enum.TextXAlignment.Left logoSub.TextColor3 = COLOR_SUBTEXT
logoSub.Text = "FRESH • v2.43" logoSub.Parent = side

local userLabel = Instance.new("TextLabel")
userLabel.Size = UDim2.new(1, -24, 0, 18) userLabel.Position = UDim2.new(0, 12, 0, 68)
userLabel.BackgroundTransparency = 1 userLabel.Font = FONT_MAIN userLabel.TextSize = 11
userLabel.TextXAlignment = Enum.TextXAlignment.Left userLabel.TextColor3 = COLOR_SUBTEXT
userLabel.TextTruncate = Enum.TextTruncate.AtEnd
userLabel.Text = "👤 " .. localPlayer.DisplayName userLabel.Parent = side

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -24, 0, 16) statsLabel.Position = UDim2.new(0, 12, 0, 86)
statsLabel.BackgroundTransparency = 1 statsLabel.Font = FONT_MAIN statsLabel.TextSize = 10
statsLabel.TextXAlignment = Enum.TextXAlignment.Left statsLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
statsLabel.Text = "FPS: -- • PING: --" statsLabel.Parent = side

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -16, 1, -170) tabHolder.Position = UDim2.new(0, 8, 0, 108)
tabHolder.BackgroundTransparency = 1 tabHolder.Parent = side
local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5) tabLayout.SortOrder = Enum.SortOrder.LayoutOrder tabLayout.Parent = tabHolder

local sideBottom = Instance.new("TextButton")
sideBottom.Size = UDim2.new(1, -24, 0, 32) sideBottom.Position = UDim2.new(0, 12, 1, -44)
sideBottom.BackgroundColor3 = COLOR_CARD2 sideBottom.Font = FONT_BOLD sideBottom.TextSize = 11
sideBottom.TextColor3 = Color3.fromRGB(255, 110, 120) sideBottom.Text = "✕  CERRAR UI"
sideBottom.Parent = side corner(sideBottom, 8)

-- Contenido derecha
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -178, 0, 56) topBar.Position = UDim2.new(0, 178, 0, 0)
topBar.BackgroundTransparency = 1 topBar.Parent = mainFrame
local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(0, 250, 0, 28) pageTitle.Position = UDim2.new(0, 18, 0, 8)
pageTitle.BackgroundTransparency = 1 pageTitle.Font = FONT_BOLD pageTitle.TextSize = 17
pageTitle.TextXAlignment = Enum.TextXAlignment.Left pageTitle.TextColor3 = COLOR_TEXT
pageTitle.Text = "Combat" pageTitle.Parent = topBar
local pageDesc = Instance.new("TextLabel")
pageDesc.Size = UDim2.new(0, 350, 0, 16) pageDesc.Position = UDim2.new(0, 18, 0, 34)
pageDesc.BackgroundTransparency = 1 pageDesc.Font = FONT_MAIN pageDesc.TextSize = 11
pageDesc.TextXAlignment = Enum.TextXAlignment.Left pageDesc.TextColor3 = COLOR_SUBTEXT
pageDesc.Text = "Apunta, pega y domina." pageDesc.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32) minBtn.Position = UDim2.new(1, -78, 0, 12)
minBtn.BackgroundColor3 = COLOR_CARD2 minBtn.Font = FONT_BOLD minBtn.TextSize = 14
minBtn.TextColor3 = COLOR_TEXT minBtn.Text = "–" minBtn.Parent = topBar corner(minBtn, 8)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32) closeBtn.Position = UDim2.new(1, -40, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 22, 30) closeBtn.Font = FONT_BOLD closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(255, 110, 120) closeBtn.Text = "✕" closeBtn.Parent = topBar corner(closeBtn, 8)

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -178, 1, -56) contentArea.Position = UDim2.new(0, 178, 0, 56)
contentArea.BackgroundTransparency = 1 contentArea.Parent = mainFrame

-- drag
do
    local dragging, ds, sp
    local function begin(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true ds = input.Position sp = mainFrame.Position
        end
    end
    local function move(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - ds
            mainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end
    local function fin(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end
    topBar.InputBegan:Connect(begin) side.InputBegan:Connect(begin)
    UserInputService.InputChanged:Connect(move) UserInputService.InputEnded:Connect(fin)
    minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
    closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false notify("Zvolt", "UI oculta. Pulsa el botón ZVOLT o RightShift.") end)
    sideBottom.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
end

--// Páginas + tabs
local pages, tabBtns = {}, {}
local TAB_INFO = {
    {id="combat",   icon="⚔️", title="Combat",   desc="Apunta, pega y domina."},
    {id="visuals",  icon="👁️", title="Visuals",    desc="Ve todo antes que ellos."},
    {id="movement", icon="🌀", title="Movement",   desc="Muévete sin límites."},
    {id="teleport", icon="📍", title="Teleport",      desc="Viaja instantáneo."},
    {id="troll",    icon="🤡", title="Troll",     desc="Modo payaso activado."},
    {id="weapon",   icon="🔫", title="Weapon",   desc="Tus armas, chetadas."},
    {id="world",    icon="🌍", title="World",   desc="Controla el mapa."},
    {id="config",   icon="⚙️", title="Config", desc="Teclas, tema y cuenta."},
}
local function createPage(id)
    local p = Instance.new("ScrollingFrame")
    p.Name = "pg" p.Size = UDim2.new(1, -24, 1, -12) p.Position = UDim2.new(0, 12, 0, 0)
    p.BackgroundTransparency = 1 p.Visible = false p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = Accent() p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y p.Parent = contentArea
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 16) pad.Parent = p
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 10) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = p
    pages[id] = p return p
end
for _, t in ipairs(TAB_INFO) do createPage(t.id) end
local function showPage(id, title, desc)
    do
        local ok1, nt1 = pcall(discreetText, title)
        if ok1 and nt1 ~= "" then title = nt1 end
        local ok2, nt2 = pcall(discreetText, desc)
        if ok2 and nt2 ~= "" then desc = nt2 end
    end
    for k, p in pairs(pages) do p.Visible = (k == id) end
    pageTitle.Text = title pageDesc.Text = desc
    for k, b in pairs(tabBtns) do
        local active = (k == id)
        tween(b, TweenInfo.new(0.2), {BackgroundTransparency = active and 0 or 1})
        b.TextLabel.TextColor3 = active and Color3.fromRGB(255,255,255) or COLOR_SUBTEXT
        local old = b:FindFirstChildOfClass("UIStroke")
        if old then old:Destroy() end
        if active then TagAccent(stroke(b, Accent(), 1), "Color") end
    end
end
for i, t in ipairs(TAB_INFO) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32) b.LayoutOrder = i
    b.BackgroundColor3 = (i == 1) and COLOR_CARD2 or COLOR_CARD
    b.BackgroundTransparency = (i == 1) and 0 or 1
    b.Text = "" b.Parent = tabHolder corner(b, 8)
    if i == 1 then stroke(b, Accent(), 1) TagAccent(b:FindFirstChildOfClass("UIStroke"), "Color") end
    local lbl = Instance.new("TextLabel")
    lbl.Name = "TextLabel" lbl.Size = UDim2.new(1, -14, 1, 0) lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1 lbl.Font = FONT_MAIN lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = (i == 1) and COLOR_TEXT or COLOR_SUBTEXT
    lbl.Text = t.icon .. "   " .. discreetText(t.title) lbl.Parent = b
    b.MouseButton1Click:Connect(function() showPage(t.id, t.title, t.desc) end)
    -- hover
    b.MouseEnter:Connect(function() if not pages[t.id].Visible then tween(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}) end end)
    b.MouseLeave:Connect(function() if not pages[t.id].Visible then tween(b, TweenInfo.new(0.15), {BackgroundTransparency = 1}) end end)
    tabBtns[t.id] = b
end
showPage("combat", "Combat", "Apunta, pega y domina.")

--// Componentes modernos
local toggleStates = {}
local cardCount = 0
local function createCard(page, titleText, height)
    cardCount = cardCount + 1
    do local ok, nt = pcall(discreetText, titleText) if ok and nt ~= "" then titleText = nt end end
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -12, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = COLOR_CARD card.Parent = page
    card.LayoutOrder = cardCount
    corner(card, 10) stroke(card, Color3.fromRGB(32, 32, 48), 1)
    local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 14) pad.PaddingRight = UDim.new(0, 14) pad.PaddingTop = UDim.new(0, 12) pad.PaddingBottom = UDim.new(0, 14) pad.Parent = card
    local layCard = Instance.new("UIListLayout") layCard.Padding = UDim.new(0, 6) layCard.SortOrder = Enum.SortOrder.LayoutOrder layCard.Parent = card
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20) title.BackgroundTransparency = 1
    title.Font = FONT_BOLD title.TextSize = 12 title.TextColor3 = COLOR_TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left title.Text = titleText:upper() title.Parent = card
    title.LayoutOrder = 1
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 26, 0, 3)
    accentBar.BackgroundColor3 = Accent() accentBar.Parent = card corner(accentBar, 99) TagAccent(accentBar)
    accentBar.LayoutOrder = 2
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundTransparency = 1 box.Parent = card
    box.LayoutOrder = 3
    local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 8) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = box
    -- altura mínima para que no se vea vacía (el height que se pasaba antes)
    if height and height > 0 then
        local minPad = Instance.new("Frame")
        minPad.Size = UDim2.new(1, 0, 0, 0) minPad.BackgroundTransparency = 1 minPad.LayoutOrder = 999 minPad.Parent = box
    end
    return box
end

local function createToggle(parent, text, callback, key, default)
    default = default or false
    do local ok, nt = pcall(discreetText, text) if ok and nt ~= "" then text = nt end end
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 30) row.BackgroundTransparency = 1 row.Text = "" row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 1, 0) lbl.BackgroundTransparency = 1
    lbl.Font = FONT_MAIN lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = default and COLOR_TEXT or COLOR_SUBTEXT lbl.Text = text lbl.Parent = row
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22) track.Position = UDim2.new(1, -42, 0.5, -11)
    track.BackgroundColor3 = default and Accent() or Color3.fromRGB(30, 30, 44) track.Parent = row corner(track, 99)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16) knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255) knob.Parent = track corner(knob, 99)
    local state = default
    local function set(v, silent)
        state = v
        lbl.TextColor3 = state and COLOR_TEXT or COLOR_SUBTEXT
        tween(track, TweenInfo.new(0.2), {BackgroundColor3 = state and Accent() or Color3.fromRGB(30, 30, 44)})
        tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        if not silent then pcall(callback, state) end
    end
    if key then toggleStates[key] = {Set = function(v) set(v) end, Get = function() return state end} end
    row.MouseButton1Click:Connect(function() set(not state) end)
    if default then pcall(callback, true) end
    return {Set = set}
end

local function createSlider(parent, titlePrefix, defaultVal, minVal, maxVal, callback)
    do local ok, nt = pcall(discreetText, titlePrefix) if ok and nt ~= "" then titlePrefix = nt end end
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 46) box.BackgroundTransparency = 1 box.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18) label.BackgroundTransparency = 1
    label.Font = FONT_MAIN label.TextSize = 12 label.TextColor3 = COLOR_SUBTEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = titlePrefix .. ":  " .. tostring(defaultVal) label.Parent = box
    local valBadge = Instance.new("TextLabel")
    valBadge.Size = UDim2.new(0, 52, 0, 18) valBadge.Position = UDim2.new(1, -52, 0, 0)
    valBadge.BackgroundColor3 = COLOR_CARD2 valBadge.Font = FONT_BOLD valBadge.TextSize = 11
    valBadge.TextColor3 = Accent() valBadge.Text = tostring(defaultVal) valBadge.Parent = box corner(valBadge, 6)
    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 8) bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 42) bar.Text = "" bar.AutoButtonColor = false bar.Parent = box corner(bar, 99)
    local fill = Instance.new("Frame")
    local p0 = (defaultVal - minVal) / math.max(1, (maxVal - minVal))
    fill.Size = UDim2.new(p0, 0, 1, 0) fill.BackgroundColor3 = Accent() fill.Parent = bar corner(fill, 99) TagAccent(fill)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Accent()), ColorSequenceKeypoint.new(1, Accent2())}
    grad.Parent = fill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14) knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(p0, 0, 0.5, 0) knob.BackgroundColor3 = Color3.fromRGB(255,255,255) knob.Parent = bar corner(knob, 99)
    stroke(knob, Accent(), 2) TagAccent(knob:FindFirstChildOfClass("UIStroke"), "Color")
    local dragging = false
    local function apply(xPos)
        local bp, bs = bar.AbsolutePosition.X, math.max(1, bar.AbsoluteSize.X)
        local c = math.clamp((xPos - bp) / bs, 0, 1)
        local val = math.floor(minVal + c * (maxVal - minVal))
        fill.Size = UDim2.new(c, 0, 1, 0) knob.Position = UDim2.new(c, 0, 0.5, 0)
        label.Text = titlePrefix .. ":" valBadge.Text = tostring(val)
        pcall(callback, val)
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true apply(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        -- FIX táctil: usar i.Position (el dedo), no GetMouseLocation (no se actualiza en móvil y el slider saltaba)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then apply(i.Position.X) end
    end)
end

local function createButton(parent, text, callback, accent)
    do local ok, nt = pcall(discreetText, text) if ok and nt ~= "" then text = nt end end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34) b.Font = FONT_BOLD b.TextSize = 12
    b.TextColor3 = accent and Color3.fromRGB(8, 8, 12) or COLOR_TEXT
    b.BackgroundColor3 = accent and Accent() or COLOR_CARD2
    b.Text = text b.Parent = parent corner(b, 8)
    if not accent then stroke(b, Color3.fromRGB(40, 40, 60), 1) else TagAccent(b) end
    b.MouseEnter:Connect(function() tween(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}) end)
    b.MouseLeave:Connect(function() tween(b, TweenInfo.new(0.15), {BackgroundTransparency = 0}) end)
    b.MouseButton1Click:Connect(function()
        tween(b, TweenInfo.new(0.08), {Size = UDim2.new(1, -4, 0, 32)})
        task.wait(0.08) tween(b, TweenInfo.new(0.12), {Size = UDim2.new(1, 0, 0, 34)})
        pcall(callback)
    end)
    return b
end

local function createDropdown(parent, title, list, default, callback)
    do local ok, nt = pcall(discreetText, title) if ok and nt ~= "" then title = nt end end
    local idx = 1
    for i, v in ipairs(list) do if v == default then idx = i break end end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32) row.BackgroundTransparency = 1 row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 170, 1, 0) lbl.BackgroundTransparency = 1
    lbl.Font = FONT_MAIN lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = COLOR_SUBTEXT lbl.Text = title lbl.Parent = row
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 170, 0, 28) b.Position = UDim2.new(1, -170, 0.5, -14)
    b.BackgroundColor3 = COLOR_CARD2 b.Font = FONT_BOLD b.TextSize = 11
    b.TextColor3 = Accent() b.Text = discreetText(list[idx]) b.Parent = row corner(b, 7)
    stroke(b, Color3.fromRGB(45, 45, 65), 1)
    pcall(callback, list[idx])
    b.MouseButton1Click:Connect(function()
        idx = idx + 1 if idx > #list then idx = 1 end
        b.Text = discreetText(list[idx]) pcall(callback, list[idx])
    end)
    return b
end

--// MODO FANTASMA: solo permite lo que el servidor NO puede ver (ESP, aimbot de cámara, luz).
-- Los anticheats detectan: WalkSpeed, tamaño de hitbox, teleports, hooks, fly, noclip.
local riskyToggles = {}
local function ghostBlock()
    if settings.ghostMode then
        notify("Modo Fantasma", "Desactivalo para usar funciones riesgosas.")
        return true
    end
    return false
end

-- (build sin silent: perfiles eliminados)

--// ===== CONSTRUIR PESTAÑAS =====
-- COMBAT
-- (build sin silent: card Sigilo/Silent/SPY eliminada; Magia vive en Armas)

local c1 = createCard(pages["combat"], "🎯 Aimbot", 250)
createToggle(c1, "Aimbot", function(v) settings.aimEnabled = v end, "aimbot")
createDropdown(c1, "Hueso objetivo", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v) settings.targetPart = v end)
createToggle(c1, "Modo AUTO", function(v) settings.aimAuto = v end)
createToggle(c1, "SNAP directo", function(v) settings.aimSnap = v end)
createToggle(c1, "Incluir NPCs/bots", function(v) settings.aimNpcs = v end)
createToggle(c1, "Diagnóstico F9", function(v) settings.aimDebug = v end)
createToggle(c1, "Fuerza bruta", function(v) settings.aimBrute = v end)
local tTrigger
tTrigger = createToggle(c1, "Triggerbot", function(v)
    if v and ghostBlock() then tTrigger.Set(false) return end
    settings.triggerbot = v
end)
table.insert(riskyToggles, tTrigger)
createSlider(c1, "Retraso Trigger", settings.triggerDelay, 0, 500, function(v) settings.triggerDelay = v end)

local c2 = createCard(pages["combat"], "⭕ FOV & Suavizado", 190)
createSlider(c2, "Radio FOV", settings.fovRadius, 40, 400, function(v) settings.fovRadius = v end)
createSlider(c2, "Suavizado", settings.smoothing, 1, 100, function(v) settings.smoothing = v end)
createSlider(c2, "Zona muerta", settings.aimDeadzone, 0, 30, function(v) settings.aimDeadzone = v end)
createToggle(c2, "Mostrar círculo FOV", function(v) settings.showFov = v end, nil, true)
createToggle(c2, "FOV arcoíris 🌈", function(v) settings.fovRainbow = v end)

local c3 = createCard(pages["combat"], "💥 Daño & Paredes", 150)
local tHitbox
tHitbox = createToggle(c3, "Hitbox", function(v)
    if v and ghostBlock() then tHitbox.Set(false) return end
    settings.hitboxEnabled = v if not v then restoreDefaults() end
end, "hitbox")
table.insert(riskyToggles, tHitbox)
createSlider(c3, "Tamaño Hitbox", settings.hitboxSize, 2, 25, function(v) settings.hitboxSize = v end)
-- (build sin silent: wallbang real solo existía vía silent, toggle eliminado)

-- VISUALS
local v1 = createCard(pages["visuals"], "👁️ ESP", 280)
createToggle(v1, "ESP", function(v) settings.espEnabled = v end, "esp")
createToggle(v1, "Nombres", function(v) settings.espNames = v end, nil, true)
createToggle(v1, "Distancia [m]", function(v) settings.espDistance = v end, nil, true)
createToggle(v1, "Barra de vida", function(v) settings.espHealthBar = v end, nil, true)
createToggle(v1, "Caja 2D", function(v) settings.espBox = v end, nil, true)
createToggle(v1, "Tracers", function(v) settings.espTracer = v end, nil, true)
createToggle(v1, "Esqueleto", function(v) settings.skeleton = v end, nil, true)
createToggle(v1, "Ver herramienta en mano 🔫", function(v) settings.espTool = v end)
createToggle(v1, "Team Check", function(v) settings.teamCheck = v end)

local v2 = createCard(pages["visuals"], "🎨 Estilo", 160)
createDropdown(v2, "Lineas", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) settings.tracerOrigin = v end)
createToggle(v2, "ESP Arcoíris", function(v) settings.espRainbow = v end)
createSlider(v2, "Distancia máxima", settings.maxDistance, 100, 5000, function(v) settings.maxDistance = v end)

-- MOVEMENT
local m1 = createCard(pages["movement"], "✈️ Vuelo & Noclip", 150)
local tFly
tFly = createToggle(m1, "Fly", function(v)
    if v and ghostBlock() then tFly.Set(false) return end
    settings.flyEnabled = v
end, "fly")
table.insert(riskyToggles, tFly)
createSlider(m1, "Velocidad de vuelo", settings.flySpeed, 10, 200, function(v) settings.flySpeed = v end)
local tNoclip
tNoclip = createToggle(m1, "Noclip", function(v)
    if v and ghostBlock() then tNoclip.Set(false) return end
    settings.noclipEnabled = v
end, "noclip")
table.insert(riskyToggles, tNoclip)

local m2 = createCard(pages["movement"], "🏃 Velocidad & Salto", 240)
local tSpeed
tSpeed = createToggle(m2, "Custom Speed", function(v)
    if v and ghostBlock() then tSpeed.Set(false) return end
    settings.speedEnabled = v if not v then local h = myHum() if h then h.WalkSpeed = DEFAULT_SPEED end end
end, "speed")
table.insert(riskyToggles, tSpeed)
createSlider(m2, "Speed", settings.customSpeed, 16, 150, function(v) settings.customSpeed = v end)
local tJump
tJump = createToggle(m2, "Super Jump", function(v)
    if v and ghostBlock() then tJump.Set(false) return end
    settings.jumpEnabled = v if not v then local h = myHum() if h then h.JumpPower = DEFAULT_JUMP end end
end, "jump")
table.insert(riskyToggles, tJump)
createSlider(m2, "Jump Power", settings.customJump, 50, 350, function(v) settings.customJump = v end)
local tBhop
tBhop = createToggle(m2, "Bunny Hop", function(v)
    if v and ghostBlock() then tBhop.Set(false) return end
    settings.bhopEnabled = v
end)
table.insert(riskyToggles, tBhop)
local tInfJump
tInfJump = createToggle(m2, "Salto infinito ♾️", function(v)
    if v and ghostBlock() then tInfJump.Set(false) return end
    settings.infJumpEnabled = v
end)
table.insert(riskyToggles, tInfJump)

local m3 = createCard(pages["movement"], "🌀 Extra", 190)
local tSpin
tSpin = createToggle(m3, "Spinbot", function(v)
    if v and ghostBlock() then tSpin.Set(false) return end
    settings.spinEnabled = v
end, "spinbot")
table.insert(riskyToggles, tSpin)
createSlider(m3, "Velocidad spin", settings.spinSpeed, 5, 200, function(v) settings.spinSpeed = v end)
local tJerk
tJerk = createToggle(m3, "Jerk anti-aim ⚠️", function(v)
    if v and ghostBlock() then tJerk.Set(false) return end
    settings.jerkEnabled = v
end)
table.insert(riskyToggles, tJerk)
createSlider(m3, "Fuerza Jerk", settings.jerkPower, 1, 10, function(v) settings.jerkPower = v end)
local tCtrl
tCtrl = createToggle(m3, "Ctrl + Click TP 🖱️", function(v)
    if v and ghostBlock() then tCtrl.Set(false) return end
    settings.ctrlClickTpEnabled = v
end)
table.insert(riskyToggles, tCtrl)
createToggle(m3, "Anti-Void", function(v) settings.antiVoid = v end)
createSlider(m3, "Gravedad", 196, 0, 400, function(v)
    if settings.ghostMode then pcall(function() workspace.Gravity = 196.2 end) ghostBlock() return end
    settings.gravity = v pcall(function() workspace.Gravity = v end)
end)
local tTap
tTap = createToggle(m3, "TP Táctil", function(v)
    if v and ghostBlock() then tTap.Set(false) return end
    settings.tapTp = v
end)
table.insert(riskyToggles, tTap)
UserInputService.TouchTapInWorld:Connect(function(pos, processed)
    if dead then return end
    if processed then return end
    if not settings.tapTp or settings.ghostMode then return end
    local r = myRoot()
    if r then r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) r.Velocity = Vector3.zero end
end)
local freecamPrev = nil
local function restoreFreecam()
    if freecamPrev ~= nil then
        pcall(function()
            camera.CameraSubject = freecamPrev[1]
            camera.CameraType = freecamPrev[2]
        end)
        freecamPrev = nil
    end
end
createToggle(m3, "Freecam", function(v)
    settings.freecam = v
    if not v then restoreFreecam() end
end)
RunService.RenderStepped:Connect(function(dt)
    if dead then return end
    if not settings.freecam then return end
    if camera.CameraType ~= Enum.CameraType.Scriptable then
        if freecamPrev == nil then freecamPrev = {camera.CameraSubject, camera.CameraType} end
        camera.CameraType = Enum.CameraType.Scriptable
    end
    local cf = camera.CFrame
    local mv = Vector3.zero
    local h = myHum()
    if h and h.MoveDirection.Magnitude > 0.1 then
        local md = h.MoveDirection
        mv = mv + (cf.LookVector * -md.Z) + (cf.RightVector * md.X)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0, 1, 0) end
    if mv.Magnitude > 1 then mv = mv.Unit end
    camera.CFrame = cf + (mv * 60 * dt)
end)

-- TELEPORT
local t1 = createCard(pages["teleport"], "📍 Teleport", 380)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 30) searchBox.BackgroundColor3 = COLOR_CARD2
searchBox.Font = FONT_MAIN searchBox.TextSize = 12 searchBox.TextColor3 = COLOR_TEXT
searchBox.PlaceholderColor3 = COLOR_SUBTEXT searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.Text = "" searchBox.Parent = t1 corner(searchBox, 7)
local plist = Instance.new("ScrollingFrame")
plist.Size = UDim2.new(1, 0, 0, 170) plist.BackgroundTransparency = 1
plist.ScrollBarThickness = 3 plist.ScrollBarImageColor3 = Accent() plist.Parent = t1
local plLay = Instance.new("UIListLayout") plLay.Padding = UDim.new(0, 5) plLay.SortOrder = Enum.SortOrder.LayoutOrder plLay.Parent = plist
local selLabel = Instance.new("TextLabel")
selLabel.Size = UDim2.new(1, 0, 0, 20) selLabel.BackgroundTransparency = 1
selLabel.Font = FONT_MAIN selLabel.TextSize = 12 selLabel.TextXAlignment = Enum.TextXAlignment.Left
selLabel.TextColor3 = COLOR_SUBTEXT selLabel.Text = "Seleccionado: nadie" selLabel.Parent = t1
local function refreshPlayers()
    for _, ch in ipairs(plist:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
    local q = searchBox.Text:lower() local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and (q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
            n = n + 1
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 28) b.BackgroundColor3 = (settings.selectedTpPlayer == p) and COLOR_CARD2 or Color3.fromRGB(20, 20, 30)
            b.Font = FONT_MAIN b.TextSize = 12 b.TextColor3 = COLOR_TEXT b.TextXAlignment = Enum.TextXAlignment.Left
            b.Text = "   👤 " .. p.DisplayName .. " (@" .. p.Name .. ")" b.Parent = plist corner(b, 6)
            if settings.selectedTpPlayer == p then stroke(b, Accent(), 1.2) end
            b.MouseButton1Click:Connect(function()
                settings.selectedTpPlayer = p selLabel.Text = "Seleccionado: " .. p.DisplayName
                notify("Teleport", "Seleccionado: " .. p.Name) refreshPlayers()
            end)
        end
    end
    plist.CanvasSize = UDim2.new(0, 0, 0, n * 33)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayers)
Players.PlayerAdded:Connect(function() if not dead then refreshPlayers() end end)
Players.PlayerRemoving:Connect(function() if not dead then refreshPlayers() end end)
refreshPlayers()
local btnRow = Instance.new("Frame") btnRow.Size = UDim2.new(1, 0, 0, 34) btnRow.BackgroundTransparency = 1 btnRow.Parent = t1
local tpTweenBtn = Instance.new("TextButton")
tpTweenBtn.Size = UDim2.new(0.48, 0, 1, 0) tpTweenBtn.BackgroundColor3 = Accent() tpTweenBtn.Font = FONT_BOLD tpTweenBtn.TextSize = 11
tpTweenBtn.TextColor3 = Color3.fromRGB(8,8,12) tpTweenBtn.Text = discreetText("✨ TP SUAVE") tpTweenBtn.Parent = btnRow corner(tpTweenBtn, 8) TagAccent(tpTweenBtn)
local tpFastBtn = Instance.new("TextButton")
tpFastBtn.Size = UDim2.new(0.48, 0, 1, 0) tpFastBtn.Position = UDim2.new(0.52, 0, 0, 0)
tpFastBtn.BackgroundColor3 = COLOR_CARD2 tpFastBtn.Font = FONT_BOLD tpFastBtn.TextSize = 11
tpFastBtn.TextColor3 = COLOR_TEXT tpFastBtn.Text = discreetText("⚡ TP INSTANT") tpFastBtn.Parent = btnRow corner(tpFastBtn, 8)
tpTweenBtn.MouseButton1Click:Connect(function()
    if ghostBlock() then return end
    local tp = settings.selectedTpPlayer local mr, tr = myRoot(), targetRootOf(tp)
    if not (tp and mr and tr) then notify("TP", "Selecciona un jugador primero.") return end
    local start = mr.CFrame local fin = tr.CFrame + Vector3.new(0, 3, 0)
    for i = 1, 14 do
        if not myRoot() then break end
        myRoot().CFrame = start:Lerp(fin, i / 14)
        myRoot().Velocity = Vector3.zero myRoot().AssemblyLinearVelocity = Vector3.zero
        task.wait(0.015)
    end
end)
tpFastBtn.MouseButton1Click:Connect(function()
    if ghostBlock() then return end
    local tp = settings.selectedTpPlayer local mr, tr = myRoot(), targetRootOf(tp)
    if not (tp and mr and tr) then notify("TP", "Selecciona un jugador primero.") return end
    mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) mr.Velocity = Vector3.zero
end)
local tFollow
tFollow = createToggle(t1, "Seguir seleccionado", function(v)
    if v and ghostBlock() then tFollow.Set(false) return end
    settings.tpFollow = v
    if v and not settings.selectedTpPlayer then notify("TP", "Selecciona un jugador primero.") end
end)
table.insert(riskyToggles, tFollow)
task.spawn(function()
    while true do
        if dead then break end
        task.wait(0.5)
        if settings.tpFollow and not settings.ghostMode then
            local tp, mr = settings.selectedTpPlayer, myRoot()
            local tr = targetRootOf(tp)
            if tp and mr and tr then
                mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0)
                mr.Velocity = Vector3.zero
            end
        end
    end
end)

local t2 = createCard(pages["teleport"], "📌 Posiciones", 150)
createButton(t2, "💾 Guardar mi posición", function()
    local r = myRoot() if r then settings.savedPos = r.CFrame notify("TP", "Posición guardada.") end
end, false)
createButton(t2, "↩️ Volver a posición guardada", function()
    if ghostBlock() then return end
    local r = myRoot() if r and settings.savedPos then r.CFrame = settings.savedPos r.Velocity = Vector3.zero end
end, false)
createButton(t2, "🏠 Ir al spawn", function()
    if ghostBlock() then return end
    local r = myRoot() if r then r.CFrame = CFrame.new(0, 10, 0) r.Velocity = Vector3.zero end
end, false)

-- TROLL
local tr1 = createCard(pages["troll"], "🤡 Seguir & Orbitar", 230)
local tTrack
tTrack = createToggle(tr1, "Tracker", function(v)
    if v and ghostBlock() then tTrack.Set(false) return end
    settings.trollTrackEnabled = v
    if v then settings.trollOrbitEnabled = false settings.flingEnabled = false settings.headSitEnabled = false end
end)
table.insert(riskyToggles, tTrack)
createSlider(tr1, "Distancia track", settings.trackDist, 1, 10, function(v) settings.trackDist = v end)
local tOrbit
tOrbit = createToggle(tr1, "Orbita", function(v)
    if v and ghostBlock() then tOrbit.Set(false) return end
    settings.trollOrbitEnabled = v
    if v then settings.trollTrackEnabled = false settings.flingEnabled = false settings.headSitEnabled = false end
end)
table.insert(riskyToggles, tOrbit)
createSlider(tr1, "Velocidad órbita", settings.orbitSpeed, 1, 15, function(v) settings.orbitSpeed = v end)
createSlider(tr1, "Radio órbita", settings.orbitRadius, 3, 20, function(v) settings.orbitRadius = v end)

local tr2 = createCard(pages["troll"], "😈 Molestar", 190)
local tFling
tFling = createToggle(tr2, "Fling", function(v)
    if v and ghostBlock() then tFling.Set(false) return end
    settings.flingEnabled = v
    if v then settings.trollTrackEnabled = false settings.trollOrbitEnabled = false end
end)
table.insert(riskyToggles, tFling)
local tHeadSit
tHeadSit = createToggle(tr2, "Sentarse 🪑", function(v)
    if v and ghostBlock() then tHeadSit.Set(false) return end
    settings.headSitEnabled = v
    if v then settings.trollTrackEnabled = false settings.trollOrbitEnabled = false end
end)
table.insert(riskyToggles, tHeadSit)
createToggle(tr2, "Mirar", function(v)
    settings.spectateEnabled = v spectating = v
    if not v then pcall(function() camera.CameraSubject = myHum() end) end
end)
createButton(tr2, "👁️ Ver", function()
    local tp = settings.selectedTpPlayer
    if tp and tp.Character then
        local h = tp.Character:FindFirstChildOfClass("Humanoid")
        if h then camera.CameraSubject = h notify("Troll", "Espectando a " .. tp.Name .. ". Toca el toggle para salir.") end
    end
end, false)

-- WEAPON
local w1 = createCard(pages["weapon"], "🔫 Armas", 190)
local tAmmo
tAmmo = createToggle(w1, "Munición infinita ♾️", function(v)
    if v and ghostBlock() then tAmmo.Set(false) return end
    settings.ammoEnabled = v
end)
table.insert(riskyToggles, tAmmo)
local tRapid
tRapid = createToggle(w1, "Rapid Fire", function(v)
    if v and ghostBlock() then tRapid.Set(false) return end
    settings.rapidFire = v
end)
table.insert(riskyToggles, tRapid)
local tMagic
tMagic = createToggle(w1, "Magic Bullets ⚠️", function(v)
    if v and ghostBlock() then tMagic.Set(false) return end
    settings.magicBulletsEnabled = v
    settings.magicNotified = false
    if v then
        notify("Magic Bullets", "Activadas: siguen al objetivo del aimbot")
    else
        notify("Magic Bullets", "Desactivadas")
    end
end)
table.insert(riskyToggles, tMagic)
createSlider(w1, "Prediccion", 12, 0, 50, function(v) settings.silentPrediction = v / 100 end)
createButton(w1, "🧹 Reset cámara", function()
    camera.FieldOfView = 70 notify("Weapon", "Cámara reseteada.")
end, false)
createButton(w1, "🔍 Ver arma · F9", function()
    local tp = settings.selectedTpPlayer
    if tp and tp.Character then
        for _, t in ipairs(tp.Character:GetChildren()) do
            if t:IsA("Tool") then dprint("[sys] " .. tp.Name .. " tiene: " .. t.Name) end
        end
        notify("Weapon", "Revisa la consola (F9).")
    end
end, false)

-- WORLD
local wo1 = createCard(pages["world"], "🌍 Iluminación & Mapa", 190)
createToggle(wo1, "Fullbright 💡", function(v)
    settings.fullbright = v
    if v then
        Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        restoreLighting()
    end
end)
createButton(wo1, "☀️ Poner de día", function()
    Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.Brightness = 2 Lighting.Ambient = Color3.fromRGB(255,255,255)
end, false)
createButton(wo1, "🌙 Poner de noche", function()
    Lighting.ClockTime = 0 Lighting.Brightness = 1
end, false)
createButton(wo1, "🌫️ Quitar niebla", function()
    Lighting.FogEnd = 100000 for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") then v.Density = 0 end end
end, false)
createSlider(wo1, "Hora del día", 14, 0, 24, function(v) Lighting.ClockTime = v end)

local wo2 = createCard(pages["world"], "⚡ Rendimiento", 150)
createToggle(wo2, "Anti-AFK ☕", function(v) settings.antiAfk = v end)
createToggle(wo2, "Sin sombras", function(v)
    settings.noShadows = v
    if v then Lighting.GlobalShadows = false
    else Lighting.GlobalShadows = (origLighting.GlobalShadows == nil) and true or origLighting.GlobalShadows end
end)
createButton(wo2, "🚀 FPS Boost", function()
    if settings.fpsBoosted then notify("World", "Ya está aplicado.") return end
    settings.fpsBoosted = true
    Lighting.GlobalShadows = false Lighting.FogEnd = 9e9
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = false
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("MeshPart") then v.RenderFidelity = Enum.RenderFidelity.Performance end
        end)
    end
    notify("World", "FPS Boost aplicado ✅")
end, true)

-- CONFIG
local function applyGhostOff()
    for _, t in ipairs(riskyToggles) do pcall(function() t.Set(false) end) end
    settings.hitboxEnabled = false settings.speedEnabled = false settings.jumpEnabled = false
    settings.flyEnabled = false settings.noclipEnabled = false settings.spinEnabled = false
    settings.bhopEnabled = false
    settings.infJumpEnabled = false settings.ctrlClickTpEnabled = false settings.trollTrackEnabled = false
    settings.trollOrbitEnabled = false settings.flingEnabled = false settings.headSitEnabled = false
    settings.ammoEnabled = false settings.rapidFire = false
    settings.magicBulletsEnabled = false
    settings.triggerbot = false settings.tapTp = false settings.tpFollow = false
    settings.jerkEnabled = false
    restoreDefaults()
    pcall(function() workspace.Gravity = 196.2 end)
end
local cfGhost = createCard(pages["config"], "👻 Fantasma", 90)
local tGhost
tGhost = createToggle(cfGhost, "MODO FANTASMA", function(v)
    settings.ghostMode = v
    if v then applyGhostOff() notify("Fantasma", "Solo queda lo invisible al servidor: ESP + aimbot camara + luz.") end
end)
createToggle(cfGhost, "Log F9 (solo diagnóstico)", function(v)
    settings.verbose = v
    if v then
        notify("Consola", "Log activado: úsalo y apágalo, el anticheat lee la consola.")
        print("[sys] verbose ON")
    end
end)
local cf1 = createCard(pages["config"], "🎨 Tema", 150)
local themeRow = Instance.new("Frame") themeRow.Size = UDim2.new(1, 0, 0, 32) themeRow.BackgroundTransparency = 1 themeRow.Parent = cf1
local themeLay = Instance.new("UIListLayout") themeLay.FillDirection = Enum.FillDirection.Horizontal themeLay.Padding = UDim.new(0, 8) themeLay.Parent = themeRow
for name, th in pairs(THEMES) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 60, 0, 30) b.Font = FONT_BOLD b.TextSize = 10 b.TextColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundColor3 = th.main b.Text = name:upper():sub(1, 4) b.Parent = themeRow corner(b, 8)
    b.MouseButton1Click:Connect(function()
        settings.theme = name RefreshTheme()
        logoGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, th.main), ColorSequenceKeypoint.new(1, th.second)}
        notify("Tema", "Tema " .. name .. " activado ✨")
    end)
end
createToggle(cf1, "Color ESP", function(v) settings.espRainbow = v end)
createButton(cf1, "🔄 Resetear todo", function()
    settings.ghostMode = false
    pcall(function() tGhost.Set(false) end)
    applyGhostOff()
    for _, s in pairs(toggleStates) do pcall(function() s.Set(false) end) end
    restoreDefaults() workspace.Gravity = 196.2 restoreLighting()
    pcall(restoreCamType) pcall(restoreFreecam)
    pcall(function() camera.CameraSubject = myHum() camera.FieldOfView = 70 end)
    notify("Config", "Todo reseteado y huellas limpiadas.")
end, false)

local cf2 = createCard(pages["config"], "⌨️ Keybinds", 330)
local function keyRow(parent, labelName, bindKey)
    do local ok, nt = pcall(discreetText, labelName) if ok and nt ~= "" then labelName = nt end end
    local row = Instance.new("Frame") row.Size = UDim2.new(1, 0, 0, 30) row.BackgroundTransparency = 1 row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 1, 0) lbl.BackgroundTransparency = 1
    lbl.Font = FONT_MAIN lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = COLOR_SUBTEXT lbl.Text = labelName lbl.Parent = row
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 110, 0, 26) b.Position = UDim2.new(1, -110, 0.5, -13)
    b.BackgroundColor3 = COLOR_CARD2 b.Font = FONT_BOLD b.TextSize = 11 b.TextColor3 = Accent()
    b.Text = keybinds[bindKey] and keybinds[bindKey].Name or "None" b.Parent = row corner(b, 6)
    local listening = false
    b.MouseButton1Click:Connect(function() listening = true b.Text = "..." end)
    UserInputService.InputBegan:Connect(function(inp)
        if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode == Enum.KeyCode.Backspace or inp.KeyCode == Enum.KeyCode.Delete then keybinds[bindKey] = nil b.Text = "None"
            else keybinds[bindKey] = inp.KeyCode b.Text = inp.KeyCode.Name end
            listening = false
        end
    end)
end
keyRow(cf2, "Aimbot", "aimbot") keyRow(cf2, "ESP", "esp") keyRow(cf2, "Noclip", "noclip")
keyRow(cf2, "Fly", "fly") keyRow(cf2, "Hitbox", "hitbox") keyRow(cf2, "Spinbot", "spinbot")
createDropdown(cf2, "Tecla abrir/cerrar UI", {"RightShift", "Insert", "P", "L"}, "RightShift", function(v)
    settings.uiToggleKey = Enum.KeyCode[v]
end)

local cf3 = createCard(pages["config"], "👤 Cuenta & Salir", 150)
createButton(cf3, "🔁 Rejoin", function()
    local ok = pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
    end)
    if not ok then
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer) end)
        notify("Rejoin", "Reintentando con teleport normal...")
    end
end, false)
createButton(cf3, "🎲 Server Hop", function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer) end)
    notify("Cuenta", "Buscando otro servidor...")
end, false)
createButton(cf3, "📋 Copiar JobId", function()
    local j = tostring(game.JobId)
    if setclipboard then
        setclipboard(j)
        notify("Cuenta", "JobId copiado al portapapeles.")
    else
        notify("Cuenta", "JobId: " .. j)
    end
    dprint("JOBID:", j)
end, false)
createButton(cf3, "🗑️ Destruir GUI", function()
    restoreDefaults() restoreLighting()
    pcall(function() workspace.Gravity = 196.2 end)
    pcall(function() RunService:UnbindFromRenderStep("ZV_Cam") end)
    pcall(restoreCamType) pcall(restoreFreecam)
    pcall(function() camera.CameraSubject = myHum() camera.FieldOfView = 70 end) gui:Destroy()
end, false)

--// Botón flotante fresco
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 96, 0, 44) floatBtn.Position = UDim2.new(0, 30, 0, 120)
floatBtn.BackgroundColor3 = COLOR_CARD floatBtn.Font = FONT_TITLE floatBtn.TextSize = 14
floatBtn.TextColor3 = Color3.fromRGB(255,255,255) floatBtn.Text = "ZVOLT" floatBtn.Parent = gui corner(floatBtn, 12)
local floatGrad = Instance.new("UIGradient")
floatGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEMES.Cyan.main), ColorSequenceKeypoint.new(1, THEMES.Cyan.second)}
floatGrad.Parent = floatBtn
stroke(floatBtn, Color3.fromRGB(255,255,255), 1).Transparency = 0.7
do
    local d, ds, sp
    floatBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true ds = i.Position sp = floatBtn.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local dd = i.Position - ds
            floatBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dd.X, sp.Y.Scale, sp.Y.Offset + dd.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end
    end)
end
floatBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)
-- pulso
task.spawn(function()
    while floatBtn.Parent do
        tween(floatGrad, TweenInfo.new(1.5), {Rotation = 180}) task.wait(1.6)
        tween(floatGrad, TweenInfo.new(1.5), {Rotation = 0}) task.wait(1.6)
    end
end)

--// Botón Aim móvil
local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 64, 0, 64) aimBtn.Position = UDim2.new(1, -90, 0.5, -32)
aimBtn.BackgroundColor3 = COLOR_CARD aimBtn.Font = FONT_BOLD aimBtn.TextSize = 13
aimBtn.TextColor3 = Accent() aimBtn.Text = "AIM" aimBtn.Visible = false aimBtn.Parent = gui
corner(aimBtn, 999) stroke(aimBtn, Accent(), 2) TagAccent(aimBtn:FindFirstChildOfClass("UIStroke"), "Color")
local aimingMobile = false
-- Botones táctiles para subir/bajar volando
local flyUpHeld, flyDownHeld = false, false
local function flyTouchBtn(txt, pos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 56, 0, 56) b.Position = pos
    b.BackgroundColor3 = COLOR_CARD b.Font = FONT_BOLD b.TextSize = 18
    b.TextColor3 = Accent() b.Text = txt b.Visible = false b.Parent = gui
    corner(b, 999) stroke(b, Accent(), 2)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if txt == "▲" then flyUpHeld = true else flyDownHeld = true end
            b.BackgroundColor3 = Accent() b.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end)
    b.InputEnded:Connect(function(i)
        flyUpHeld = false flyDownHeld = false
        b.BackgroundColor3 = COLOR_CARD b.TextColor3 = Accent()
    end)
    return b
end
local flyUpBtn = flyTouchBtn("▲", UDim2.new(1, -164, 0.5, -70))
local flyDownBtn = flyTouchBtn("▼", UDim2.new(1, -164, 0.5, 0))
aimBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then aimingMobile = true aimBtn.BackgroundColor3 = Accent() aimBtn.TextColor3 = Color3.fromRGB(0,0,0) end end)
aimBtn.InputEnded:Connect(function(i) aimingMobile = false aimBtn.BackgroundColor3 = COLOR_CARD aimBtn.TextColor3 = Accent() end)

--// Inputs globales
local aimingPC = false
local isAimingRightClick = false
UserInputService.InputBegan:Connect(function(inp, gp)
    if dead then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then aimingPC = true isAimingRightClick = true end
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        if inp.KeyCode == settings.uiToggleKey then mainFrame.Visible = not mainFrame.Visible end
        if inp.KeyCode == Enum.KeyCode.Space and settings.infJumpEnabled and not settings.ghostMode and myHum() then
            myHum():ChangeState(Enum.HumanoidStateType.Jumping)
        end
        for feat, kc in pairs(keybinds) do
            if inp.KeyCode == kc and toggleStates[feat] then
                local ns = not toggleStates[feat].Get()
                toggleStates[feat].Set(ns)
                notify("Keybind", feat:upper() .. (ns and " ✅" or " ❌"))
            end
        end
    end
    if inp.UserInputType == Enum.UserInputType.MouseButton1 and settings.ctrlClickTpEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local r = myRoot()
            if r and mouse.Hit then r.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) r.Velocity = Vector3.zero end
        end
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if dead then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then aimingPC = false isAimingRightClick = false end
end)
-- anti afk
Players.LocalPlayer.Idled:Connect(function()
    if dead then return end
    if settings.antiAfk then pcall(function() game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end) end
end)

--// ESP moderno (Barra de vida + Box + Tracer + Nombre)
-- NOTA ANTI-BUG: el Character NUNCA se guarda en espData (solo Instances ESP).
-- El character se trackea aparte en espCharOf, que clearESP jamás destruye.
local espData = {}
local espCharOf = {}
local function safeDestroy(inst)
    pcall(function()
        if inst and typeof(inst) == "Instance" then
            local cn = inst.ClassName
            if cn == "Model" or cn == "Humanoid" or cn == "HumanoidRootPart" then return end
            if Players:GetPlayerFromCharacter(inst) then return end
            inst:Destroy()
        end
    end)
end
local function clearESP(plr)
    local o = espData[plr]
    if o then
        safeDestroy(o.hl) safeDestroy(o.bb) safeDestroy(o.line) safeDestroy(o.box)
        if o.sk then for _, f in ipairs(o.sk) do safeDestroy(f) end end
        if o.skj then for _, f in ipairs(o.skj) do safeDestroy(f) end end
        espData[plr] = nil
    end
    -- no tocamos espCharOf aquí a propósito en el loop por frame;
    -- se actualiza solo en buildESP / respawn
end
local function espColor()
    if settings.espRainbow then return Color3.fromHSV(tick() % 5 / 5, 1, 1) end
    return Accent()
end
--// ESP esqueleto sutil (R15 + fallback R6). Sin Highlight (muy fogoso).
local SK_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","UpperArmLeft"},{"UpperArmLeft","LowerArmLeft"},{"LowerArmLeft","HandLeft"},
    {"UpperTorso","UpperArmRight"},{"UpperArmRight","LowerArmRight"},{"LowerArmRight","HandRight"},
    {"LowerTorso","UpperLegLeft"},{"UpperLegLeft","LowerLegLeft"},{"LowerLegLeft","FootLeft"},
    {"LowerTorso","UpperLegRight"},{"UpperLegRight","LowerLegRight"},{"LowerLegRight","FootRight"},
}
local SK_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function skSeg(objs, i)
    local f = objs.sk[i]
    if not f then
        f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5) f.BorderSizePixel = 0
        f.BackgroundColor3 = Accent() f.Visible = false f.Parent = gui
        objs.sk[i] = f
    end
    return f
end
local function drawSeg(f, ax, ay, bx, by, col)
    local dx, dy = bx - ax, by - ay
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then f.Visible = false return end
    f.Size = UDim2.new(0, 1, 0, len)
    f.Position = UDim2.new(0, (ax + bx) / 2, 0, (ay + by) / 2)
    f.Rotation = math.deg(math.atan2(dy, dx)) - 90
    f.BackgroundColor3 = col f.BackgroundTransparency = 0.1 f.Visible = true
end
local function skDot(objs, i)
    objs.skj = objs.skj or {}
    local f = objs.skj[i]
    if not f then
        f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5) f.BorderSizePixel = 0
        f.Size = UDim2.new(0, 3, 0, 3)
        f.BackgroundColor3 = Accent() f.Visible = false f.Parent = gui
        corner(f, 999)
        objs.skj[i] = f
    end
    return f
end
local function hideSk(objs)
    if objs.sk then for _, f in ipairs(objs.sk) do f.Visible = false end end
    if objs.skj then for _, f in ipairs(objs.skj) do f.Visible = false end end
end
local function buildESP(plr, char)
    clearESP(plr)
    local objs = {}
    objs.sk = {} objs.skj = {}
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 170, 0, 46) bb.StudsOffset = Vector3.new(0, 2.8, 0) bb.AlwaysOnTop = true
    bb:SetAttribute("ZV2", true)
    bb.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    bb.Parent = char
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0, 16) name.BackgroundTransparency = 1
    name.Font = FONT_BOLD name.TextSize = 12 name.TextColor3 = Color3.fromRGB(255,255,255)
    name.TextStrokeTransparency = 0.4 name.Parent = bb objs.name = name
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -40, 0, 5) hpBg.Position = UDim2.new(0, 20, 0, 20)
    hpBg.BackgroundColor3 = Color3.fromRGB(25, 25, 35) hpBg.Parent = bb corner(hpBg, 99) objs.hpBg = hpBg
    local hpFill = Instance.new("Frame") hpFill.Size = UDim2.new(1, 0, 1, 0) hpFill.Parent = hpBg corner(hpFill, 99) objs.hpFill = hpFill
    local tool = Instance.new("TextLabel")
    tool.Size = UDim2.new(1, 0, 0, 14) tool.Position = UDim2.new(0, 0, 0, 28) tool.BackgroundTransparency = 1
    tool.Font = FONT_MAIN tool.TextSize = 10 tool.TextColor3 = Color3.fromRGB(255, 220, 120)
    tool.TextStrokeTransparency = 0.4 tool.Parent = bb objs.tool = tool
    objs.bb = bb
    espCharOf[plr] = char
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5) line.BorderSizePixel = 0 line.Visible = false line.Parent = gui objs.line = line
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1 box.Visible = false box.Parent = gui objs.box = box
    local bs = stroke(box, espColor(), 1.6) objs.boxStroke = bs
    espData[plr] = objs
end
local function updateESP(plr)
    if plr == localPlayer then return end
    local char = plr.Character local root = char and char:FindFirstChild("HumanoidRootPart")
    if not settings.espEnabled or not char or not root then clearESP(plr) return end
    local objs = espData[plr]
    if not objs or espCharOf[plr] ~= char then buildESP(plr, char) objs = espData[plr] if not objs then return end end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local lr = myRoot()
    if not lr then return end
    local dist = math.floor((lr.Position - root.Position).Magnitude)
    if dist > settings.maxDistance or (hum and hum.Health <= 0) then
        objs.bb.Enabled = false objs.line.Visible = false objs.box.Visible = false
        hideSk(objs)
        return
    end
    local col = espColor()
    -- con Team Check: aliados en verde, enemigos con el color del tema
    if settings.teamCheck and sameTeam(plr, localPlayer) then
        col = Color3.fromRGB(90, 255, 130)
    end
    objs.bb.Enabled = true
    -- nombre + dist
    local txt = ""
    if settings.espNames then txt = plr.DisplayName .. " " end
    if settings.espDistance then txt = txt .. "[" .. dist .. "m]" end
    objs.name.Text = txt ~= "" and txt or plr.Name
    objs.name.Visible = (settings.espNames or settings.espDistance)
    objs.name.TextColor3 = col
    -- vida (solo si hay humanoide real; en bruto se oculta la barra)
    objs.hpBg.Visible = settings.espHealthBar and hum ~= nil
    if hum and settings.espHealthBar then
        local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
        objs.hpFill.Size = UDim2.new(pct, 0, 1, 0)
        objs.hpFill.BackgroundColor3 = Color3.fromHSV(pct * 0.33, 1, 1)
    end
    -- herramienta
    if settings.espTool then
        local t = char:FindFirstChildOfClass("Tool")
        objs.tool.Visible = t ~= nil
        if t then objs.tool.Text = "🔫 " .. t.Name end
    else objs.tool.Visible = false end
    -- tracer sutil
    if settings.espTracer then
        local sp, on = camera:WorldToViewportPoint(root.Position)
        if on then
            local vs = camera.ViewportSize local startV
            if settings.tracerOrigin == "Bottom" then startV = Vector2.new(vs.X / 2, vs.Y)
            elseif settings.tracerOrigin == "Center" then startV = Vector2.new(vs.X / 2, vs.Y / 2)
            else startV = UserInputService:GetMouseLocation() end
            local endV = Vector2.new(sp.X, sp.Y)
            local d = (endV - startV).Magnitude
            objs.line.Size = UDim2.new(0, 1.25, 0, d)
            objs.line.Position = UDim2.new(0, (startV.X + endV.X) / 2, 0, (startV.Y + endV.Y) / 2)
            objs.line.Rotation = math.deg(math.atan2(endV.Y - startV.Y, endV.X - startV.X)) - 90
            objs.line.BackgroundColor3 = col objs.line.Visible = true
        else objs.line.Visible = false end
    else objs.line.Visible = false end
    -- box 2D (con fallback si no hay Head)
    if settings.espBox then
        local head = char:FindFirstChild("Head")
        local _, on = camera:WorldToViewportPoint(root.Position)
        if on then
            local top3d = head and (head.Position + Vector3.new(0, 0.6, 0)) or (root.Position + Vector3.new(0, 2.5, 0))
            local bot3d = root.Position - Vector3.new(0, 3, 0)
            local hp = camera:WorldToViewportPoint(top3d)
            local lp = camera:WorldToViewportPoint(bot3d)
            local h = math.abs(hp.Y - lp.Y) local w = h * 0.62
            if h > 4 then
                objs.box.Size = UDim2.new(0, w, 0, h)
                objs.box.Position = UDim2.new(0, hp.X - w / 2, 0, hp.Y)
                objs.box.Visible = true objs.boxStroke.Color = col
            else objs.box.Visible = false end
        else objs.box.Visible = false end
    else objs.box.Visible = false end
    -- esqueleto sutil (huesos finos + puntos en articulaciones)
    if settings.skeleton then
        local pm = {}
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("BasePart") then pm[c.Name] = c end
        end
        local segs, dots = {}, {}
        local function dotP(p)
            for _, q in ipairs(dots) do
                if (q - p).Magnitude < 0.05 then return end
            end
            if #dots < 16 then dots[#dots + 1] = p end
        end
        if pm["UpperTorso"] then
            for _, s in ipairs(SK_R15) do
                local a, b = pm[s[1]], pm[s[2]]
                if a and b then
                    segs[#segs + 1] = {a.Position, b.Position}
                    dotP(a.Position) dotP(b.Position)
                end
            end
        else
            -- R6: monigote desde el torso (hombros/cadera/nuca calculados)
            local torso, head = pm["Torso"], pm["Head"]
            if torso then
                local cf = torso.CFrame
                local up, rt = cf.UpVector, cf.RightVector
                local sx, sy = torso.Size.X / 2, torso.Size.Y / 2
                local neck = torso.Position + up * sy
                local hipC = torso.Position - up * sy
                local shL = torso.Position - rt * sx + up * (sy * 0.6)
                local shR = torso.Position + rt * sx + up * (sy * 0.6)
                if head then segs[#segs + 1] = {head.Position, neck} dotP(head.Position) end
                dotP(neck) dotP(hipC) dotP(shL) dotP(shR)
                local limbs = {{"Left Arm", shL}, {"Right Arm", shR}, {"Left Leg", hipC}, {"Right Leg", hipC}}
                for _, L in ipairs(limbs) do
                    local p = pm[L[1]]
                    if p then segs[#segs + 1] = {L[2], p.Position} dotP(p.Position) end
                end
            elseif head then
                dotP(head.Position)
            end
        end
        local si = 0
        for _, s in ipairs(segs) do
            local sa, ona = camera:WorldToViewportPoint(s[1])
            local sb, onb = camera:WorldToViewportPoint(s[2])
            si = si + 1
            local f = skSeg(objs, si)
            if ona and onb then
                drawSeg(f, sa.X, sa.Y, sb.X, sb.Y, col)
            else f.Visible = false end
        end
        for i = si + 1, #objs.sk do objs.sk[i].Visible = false end
        local di = 0
        for _, p in ipairs(dots) do
            local sp, on = camera:WorldToViewportPoint(p)
            di = di + 1
            local d = skDot(objs, di)
            if on then
                d.Position = UDim2.new(0, sp.X, 0, sp.Y)
                d.BackgroundColor3 = col d.Visible = true
            else d.Visible = false end
        end
        for i = di + 1, #(objs.skj or {}) do objs.skj[i].Visible = false end
    else hideSk(objs) end
end
Players.PlayerRemoving:Connect(function(plr) if not dead then clearESP(plr) espCharOf[plr] = nil end end)

-- Punto de referencia del aim: cursor en PC, centro de pantalla en táctil (no hay cursor)
local function aimRefPoint()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        local vs = camera.ViewportSize
        return Vector2.new(vs.X / 2, vs.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end
-- Parte a apuntar con fallbacks para juegos con rigs raros (sin Head, etc.)
local function getAimPart(char, bone)
    if not char then return nil end
    return char:FindFirstChild(bone) or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

-- (build sin silent: getSilentHitPos y hooks eliminados; magic sigue al aimbot)
--// MAGIC BULLETS: tus proyectiles doblan su vuelo hacia el objetivo (respeta FOV, equipo, hitchance).
-- Detecta piezas que NACEN cerca tuyo, en movimiento y alejándose (tus balas), e ignora el resto.
local trackedBullets = {}
local magicAcquired = 0 -- telemetría: balas con objetivo asignado
local triggerShots = 0 -- telemetría: disparos del triggerbot
local diagLast, diagF9Last = 0, 0 -- throttles del panel magic/trigger y del F9
workspace.DescendantAdded:Connect(function(inst)
    if dead then return end
    if not settings.magicBulletsEnabled or settings.ghostMode then return end
    if not inst or not inst:IsA("BasePart") then return end
    if inst.Anchored then return end
    local mr = myRoot()
    if not mr then return end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and (Players:GetPlayerFromCharacter(model) or model == localPlayer.Character) then return end
    local off = inst.Position - mr.Position
    if off.Magnitude < 1 or off.Magnitude > 25 then return end -- nació pegado o lejos: no es tu bala
    local vel = inst.AssemblyLinearVelocity
    if vel.Magnitude < 20 then return end -- quieto: decoración del mapa, no bala
    if vel.Unit:Dot(off.Unit) < 0.2 then return end -- viene HACIA ti: es bala enemiga, no tocar
    local count = 0
    for _ in pairs(trackedBullets) do count = count + 1 end
    if count >= 40 then return end
    -- el objetivo es el del aimbot V1 (sin silent no hay getSilentHitPos)
    local tgt = lastAimPart
    local realTgt = (tgt and tgt.Parent) and tgt or nil
    trackedBullets[inst] = {t0 = tick(), target = realTgt}
    if realTgt then magicAcquired = magicAcquired + 1 end
    if realTgt and not settings.magicNotified then
        settings.magicNotified = true
        notify("Magic Bullets", "Objetivo adquirido: curvando balas.")
    end
end)
RunService.Heartbeat:Connect(function()
    if dead then return end
    if not settings.magicBulletsEnabled or settings.ghostMode then return end
    local now = tick()
    for part, info in pairs(trackedBullets) do
        local tgt = info.target
        if (not part) or (not part.Parent) or (now - info.t0) > 3 then
            trackedBullets[part] = nil
        elseif tgt and tgt.Parent then
            local pred = settings.silentPrediction or 0.12
            local aim = tgt.Position + (tgt.Velocity * pred)
            if (aim - part.Position).Magnitude > 4 then
                local sp = part.AssemblyLinearVelocity.Magnitude
                if sp > 5 then
                    -- conserva la velocidad original: SOLO dobla la dirección (natural y menos detectable)
                    part.AssemblyLinearVelocity = (aim - part.Position).Unit * sp
                    pcall(function() part.CFrame = CFrame.new(part.Position, aim) end)
                end
            end
        end
    end
end)
-- (build sin silent: SPY por hooks eliminado)
-- (build sin silent: hook tryEnableSilentAim eliminado)

-- El aimbot V1 corre en el loop principal abajo (RenderStepped plano, como el original).

-- Re-aplicación post-cámara: el juego reescribe su cámara cada frame; con esto
-- la última escritura siempre es la nuestra (Render + post-cámara + Heartbeat).
prevCamType = nil
function restoreCamType()
    if prevCamType ~= nil then
        pcall(function() camera.CameraType = prevCamType end)
        prevCamType = nil
    end
end
local function forceCamType()
    if settings.aimScriptable and camera.CameraType ~= Enum.CameraType.Scriptable then
        if prevCamType == nil then prevCamType = camera.CameraType end
        pcall(function() camera.CameraType = Enum.CameraType.Scriptable end)
    end
end
local function reapplyAim()
    if not settings.aimEnabled then restoreCamType() return end
    if not (isAimingRightClick or aimingMobile or settings.aimAuto) then restoreCamType() return end
    forceCamType()
    local p = lastAimPart
    if not (p and p.Parent) then return end
    do
        local sp, on = camera:WorldToViewportPoint(p.Position)
        if on then
            local ref = aimRefPoint()
            if (Vector2.new(sp.X, sp.Y) - ref).Magnitude <= (settings.aimDeadzone or 0) then return end
        end
    end
    local alphaV1 = settings.aimSnap and 1 or math.clamp(settings.smoothing / 100, 0.05, 1)
    pcall(function()
        camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, p.Position), alphaV1)
    end)
end
pcall(function() RunService:UnbindFromRenderStep("ZV_Aimbot") end)
pcall(function()
    -- prioridad Last (2000): corre DESPUÉS de cualquier cámara del juego, justo antes del render
    RunService:BindToRenderStep("ZV_Cam", Enum.RenderPriority.Last.Value, function() reapplyAim() end)
end)

--// Loops principales
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local aimDeepLast = 0
-- (lastAimPart vive arriba junto a orbitAngle; magic, V1 y reapply usan la misma variable)
local espFrame, noclipLast, fbLastRefresh = 0, 0, 0 -- acumuladores de rendimiento
local espDiagLast = 0 -- throttle del diagnóstico ESP en pantalla
local espErr = nil -- último error de updateESP (el pcall lo tragaba en silencio)
RunService.RenderStepped:Connect(function(dt)
    if dead then return end
    -- La cámara puede ser REEMPLAZADA por el juego (rondas/respawns). Si usamos la vieja,
    -- todo da mal (pant:0) y escribimos en una cámara invisible. Re-leer cada frame lo arregla.
    local freshCam = workspace.CurrentCamera
    if freshCam then camera = freshCam end
    if not camera then return end
    -- red de seguridad: cualquier error aquí saldría a consola con "loadstring" (baneable)
    local okLoop, errLoop = pcall(function()
    -- FOV UI
    local ml = aimRefPoint()
    local wantFov = settings.aimEnabled and settings.showFov
    fovFrame.Visible = wantFov
    aimBtn.Visible = settings.aimEnabled and isTouch
    flyUpBtn.Visible = settings.flyEnabled and isTouch
    flyDownBtn.Visible = settings.flyEnabled and isTouch
    if wantFov then
        fovFrame.Position = UDim2.new(0, ml.X, 0, ml.Y)
        fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
        fovDot.Position = UDim2.new(0.5, 0, 0.5, 0)
        if settings.fovRainbow then fovStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else fovStroke.Color = Accent() end
        fovDot.BackgroundColor3 = fovStroke.Color
        fovStroke.Thickness = 1.6
    end
    -- ESP intercalado: mitad de jugadores por frame (se ve igual, cuesta la mitad)
    espFrame = espFrame + 1
    if settings.espEnabled then
        for i, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and (i + espFrame) % 2 == 0 then
                local okE, errE = pcall(updateESP, p)
                if not okE and not espErr then espErr = errE end
            end
        end
        -- diagnóstico en vivo: embudo del ESP (jugadores -> con root -> cerca)
        local nowE = tick()
        if nowE - espDiagLast > 0.5 then
            espDiagLast = nowE
            if espErr then
                espStatus.Text = "ESP err: " .. tostring(espErr):sub(1, 90)
                espStatus.TextColor3 = Color3.fromRGB(255, 110, 120)
                espErr = nil
            else
            local eTot, eRoot, eNear = 0, 0, 0
            local lrE = myRoot()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer then
                    eTot = eTot + 1
                    local ch = p.Character
                    local rt = ch and ch:FindFirstChild("HumanoidRootPart")
                    if rt then
                        eRoot = eRoot + 1
                        if lrE and (lrE.Position - rt.Position).Magnitude <= settings.maxDistance then
                            eNear = eNear + 1
                        end
                    end
                end
            end
            espStatus.Text = string.format("ESP: %d cerca (%d con root de %d juga)", eNear, eRoot, eTot)
            espStatus.TextColor3 = (eNear > 0) and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(255, 200, 80)
            end
        end
    else
        espStatus.Text = ""
        for p, _ in pairs(espData) do clearESP(p) end
    end
    -- Aimbot estilo V1: RenderStepped plano, sin filtros extra. Fórmula del original que sí funciona.
    -- El estado muestra el embudo (vivos -> con parte -> en pantalla) para ver qué filtra a todos.
    do
        local trigV1 = isAimingRightClick or aimingMobile or settings.aimAuto
        if not settings.aimEnabled then
            aimStatus.Text = ""
        elseif not trigV1 then
            aimStatus.Text = discreetText("AIM: ON - mantén click derecho")
            aimStatus.TextColor3 = COLOR_SUBTEXT
        else
            local ml2 = UserInputService:GetMouseLocation()
            local lr2 = myRoot()
            local bestPartV1, bestDV1, bestNameV1 = nil, settings.fovRadius, ""
            local cAlive, cPart, cScreen, cBots = 0, 0, 0, 0
            local function consider(model, label)
                if not model then return end
                -- BloxStrike y otros no usan Humanoid (vida custom): en bruto se apunta igual
                if not settings.aimBrute then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if not (humanoid and humanoid.Health > 0) then return end
                end
                cAlive = cAlive + 1
                local tp = getAimPart(model, settings.targetPart)
                if not (tp and lr2) then return end
                cPart = cPart + 1
                if (lr2.Position - tp.Position).Magnitude > settings.maxDistance then return end
                local sp, on = camera:WorldToViewportPoint(tp.Position)
                if not on then return end
                cScreen = cScreen + 1
                local d = (Vector2.new(sp.X, sp.Y) - ml2).Magnitude
                if d <= settings.fovRadius and d < bestDV1 then
                    bestDV1 = d
                    bestPartV1 = tp
                    bestNameV1 = label
                end
            end
            if lr2 and localPlayer.Character then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        consider(player.Character, player.DisplayName)
                    end
                end
                if settings.aimBrute or (not bestPartV1 and settings.aimNpcs) then
                    -- bots: modelos con humanoide que no son jugadores (top-level y dentro de carpetas)
                    local function scanBots(c)
                        for _, m in ipairs(c:GetChildren()) do
                            if m:IsA("Model") and m ~= localPlayer.Character
                            and not Players:GetPlayerFromCharacter(m) then
                                local b0 = cAlive
                                consider(m, m.Name)
                                if cAlive > b0 then cBots = cBots + 1 end
                            end
                        end
                    end
                    scanBots(workspace)
                    for _, c in ipairs(workspace:GetChildren()) do
                        if c:IsA("Folder") then scanBots(c) end
                    end
                end
            end
            if bestPartV1 then
                aimStatus.Text = discreetText("AIM: LOCK ") .. tostring(bestNameV1)
                aimStatus.TextColor3 = Color3.fromRGB(80, 255, 130)
                lastAimPart = bestPartV1
                -- zona muerta: si ya estás encima del objetivo no toca la cámara (tu mouse manda)
                if bestDV1 > (settings.aimDeadzone or 0) then
                    local alphaV1 = settings.aimSnap and 1 or math.clamp(settings.smoothing / 100, 0.05, 1)
                    pcall(function()
                        camera.CFrame = camera.CFrame:Lerp(
                            CFrame.new(camera.CFrame.Position, bestPartV1.Position), alphaV1)
                    end)
                end
            else
                aimStatus.Text = discreetText(string.format("AIM: 0 FOV (vivos:%d bots:%d partes:%d pant:%d)",
                    cAlive, cBots, cPart, cScreen))
                aimStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
                lastAimPart = nil
                if settings.aimDebug then
                    local nowDbg = tick()
                    if nowDbg - aimDeepLast > 2 then
                        aimDeepLast = nowDbg
                        local shown = 0
                        local function dump(model, label)
                            if shown >= 6 or not model then return end
                            local hum = model:FindFirstChildOfClass("Humanoid")
                            local hd = model:FindFirstChild("Head")
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            local anchor = hd or hrp
                            local scr, on, dist = "?", false, -1
                            if anchor then
                                local sp2, on2 = camera:WorldToViewportPoint(anchor.Position)
                                scr, on = string.format("%d,%d", sp2.X, sp2.Y), on2
                                if lr2 then dist = math.floor((lr2.Position - anchor.Position).Magnitude) end
                            end
                            shown = shown + 1
                            dprint(string.format("[sys-deep] %s | hum=%s hp=%s head=%s hrp=%s | pant=%s(%s) dist=%s",
                                tostring(label), hum and "SI" or "NO", hum and tostring(math.floor(hum.Health)) or "-",
                                hd and "SI" or "NO", hrp and "SI" or "NO",
                                tostring(scr), tostring(on), tostring(dist)))
                        end
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= localPlayer and player.Character then
                                dump(player.Character, "JUG:" .. player.Name)
                            end
                        end
                        if settings.aimNpcs then
                            for _, m in ipairs(workspace:GetChildren()) do
                                if m:IsA("Model") and m ~= localPlayer.Character
                                and not Players:GetPlayerFromCharacter(m) then
                                    dump(m, "NPC:" .. m.Name)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Telemetría magic/trigger en pantalla + F9
    do
        local showS = settings.magicBulletsEnabled or settings.triggerbot
        if not showS then
            magicStatus.Text = ""
        else
            local nowD = tick()
            if nowD - diagLast > 0.25 then
                diagLast = nowD
                local tracked = 0
                for _ in pairs(trackedBullets) do tracked = tracked + 1 end
                local t = "MAGIC: rastreadas:" .. tracked .. " dirigidas:" .. magicAcquired
                    .. " | TRIGGER tiros:" .. triggerShots
                magicStatus.Text = discreetText(t)
                if nowD - diagF9Last > 4 then
                    diagF9Last = nowD
                    dprint(string.format(
                        "[sys-diag] magic=%s tracked=%d acquired=%d trigger=%s shots=%d fov=%d",
                        tostring(settings.magicBulletsEnabled),
                        tracked, magicAcquired,
                        tostring(settings.triggerbot), triggerShots,
                        settings.fovRadius))
                end
            end
        end
    end
    -- Troll track / orbit / head sit / fling
    local tp = settings.selectedTpPlayer
    local r = myRoot() local h = myHum()
    if tp and tp.Character and r and not settings.ghostMode and (settings.trollTrackEnabled or settings.trollOrbitEnabled or settings.headSitEnabled or settings.flingEnabled) then
        local tr = targetRootOf(tp)
        if tr then
            if settings.trollTrackEnabled then
                if h then h.PlatformStand = true end
                local front = tr.Position + (tr.CFrame.LookVector * settings.trackDist) + Vector3.new(0, 0.5, 0)
                r.CFrame = CFrame.new(front, tr.Position + Vector3.new(0, 1.5, 0))
                r.Velocity = Vector3.zero r.AssemblyLinearVelocity = Vector3.zero
            elseif settings.trollOrbitEnabled then
                if h then h.PlatformStand = true end
                orbitAngle = orbitAngle + dt * settings.orbitSpeed
                local x = tr.Position.X + math.cos(orbitAngle) * settings.orbitRadius
                local z = tr.Position.Z + math.sin(orbitAngle) * settings.orbitRadius
                r.CFrame = CFrame.new(Vector3.new(x, tr.Position.Y + 2, z), tr.Position)
                r.Velocity = Vector3.zero r.AssemblyLinearVelocity = Vector3.zero
            elseif settings.headSitEnabled then
                if h then h.PlatformStand = false h.Sit = true end
                r.CFrame = tr.CFrame + Vector3.new(0, 2.2, 0)
                r.Velocity = Vector3.zero
            elseif settings.flingEnabled then
                if h then h.PlatformStand = true end
                orbitAngle = orbitAngle + dt * 25
                r.CFrame = CFrame.new(tr.Position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, orbitAngle, 0)
                r.Velocity = Vector3.new(0, 60, 0) r.RotVelocity = Vector3.new(9999, 9999, 9999)
            end
        end
    else
        if h and not settings.flyEnabled and spectating == false then
            -- no forzar PlatformStand si no hay troll activo
            if not (settings.trollTrackEnabled or settings.trollOrbitEnabled or settings.flingEnabled) then
                -- lo maneja el loop de fly
            end
        end
    end
    -- spectate
    if settings.spectateEnabled and tp and tp.Character then
        local th = tp.Character:FindFirstChildOfClass("Humanoid")
        if th then camera.CameraSubject = th end
    end
    -- spinbot
    if settings.spinEnabled and not settings.ghostMode and r and not settings.trollTrackEnabled and not settings.trollOrbitEnabled and not settings.flingEnabled then
        r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(settings.spinSpeed), 0)
    end
    -- jerk anti-aim: yaw aleatorio + micro-jitter cada frame (rompe locks enemigos)
    if settings.jerkEnabled and not settings.ghostMode and r
    and not settings.flyEnabled and not settings.trollTrackEnabled
    and not settings.trollOrbitEnabled and not settings.flingEnabled then
        local pw = settings.jerkPower or 5
        r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(math.random(-pw * 18, pw * 18)), 0)
        r.CFrame = r.CFrame + Vector3.new((math.random() - 0.5) * pw * 0.5, 0, (math.random() - 0.5) * pw * 0.5)
        r.Velocity = Vector3.zero
        r.RotVelocity = Vector3.zero
    end
    -- noclip a 10Hz (listar piezas cada frame es caro) + solo escribe si hace falta
    if settings.noclipEnabled and localPlayer.Character and tick() - noclipLast > 0.1 then
        noclipLast = tick()
        for _, part in ipairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
    -- NOTA: hitbox y wallbang se aplican en el loop lento (0.5s), no cada frame.
    -- speed / jump / bhop (solo escribir si cambió el valor)
    local ch = myHum()
    if ch and not settings.ghostMode and not settings.trollTrackEnabled and not settings.trollOrbitEnabled then
        if settings.speedEnabled then
            if ch.WalkSpeed ~= settings.customSpeed then ch.WalkSpeed = settings.customSpeed end
        else
            -- manos fuera: no se toca WalkSpeed; se adopta la del juego
            -- (sprint/agacharse/rondas) para restaurar bien al salir
            DEFAULT_SPEED = ch.WalkSpeed
        end
        if settings.jumpEnabled and ch.JumpPower ~= settings.customJump then ch.JumpPower = settings.customJump ch.UseJumpPower = true end
        if settings.bhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            if ch.FloorMaterial ~= Enum.Material.Air then ch:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    -- fullbright: se aplica al activar + refresco cada 2s (reescribirlo cada frame recalcula la luz y baja FPS)
    -- anti-void
    if settings.antiVoid and r and r.Position.Y < -60 then
        r.CFrame = CFrame.new(0, 20, 0) r.Velocity = Vector3.zero
    end
    end)
    if not okLoop then dprint("[sys] loop:", tostring(errLoop):sub(1, 90)) end
end)

-- Fly (Heartbeat, compatible móvil con joystick)
RunService.Heartbeat:Connect(function(dt)
    if dead then return end
    local r = myRoot() local h = myHum()
    if not r or not h then return end
    local trollActive = settings.trollTrackEnabled or settings.trollOrbitEnabled or settings.flingEnabled
    if settings.flyEnabled and not settings.ghostMode and not trollActive then
        h.PlatformStand = true
        local cf = camera.CFrame
        local mv = Vector3.zero
        if isTouch then
            -- móvil: joystick (MoveDirection) + botones táctiles
            local md = h.MoveDirection
            if md.Magnitude > 0.1 then
                local fwd = cf.LookVector * Vector3.new(1, 0, 1)
                local rgt = cf.RightVector * Vector3.new(1, 0, 1)
                if fwd.Magnitude > 0 then fwd = fwd.Unit else fwd = Vector3.zero end
                if rgt.Magnitude > 0 then rgt = rgt.Unit else rgt = Vector3.zero end
                mv = mv + (fwd * -md.Z) + (rgt * md.X)
                -- joystick arriba = avanzar; si mira arriba/abajo también vuela vertical un poco
                mv = mv + Vector3.new(0, (-md.Z) * cf.LookVector.Y * 0.8, 0)
            end
        else
            -- PC: teclas (una sola vez; MoveDirection ya las incluye y duplicaba = diagonal)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0, 1, 0) end
        end
        if flyUpHeld then mv = mv + Vector3.new(0, 1, 0) end
        if flyDownHeld then mv = mv - Vector3.new(0, 1, 0) end
        if mv.Magnitude > 1 then mv = mv.Unit end
        r.CFrame = r.CFrame + (mv * settings.flySpeed * dt)
        r.Velocity = Vector3.zero r.AssemblyLinearVelocity = Vector3.zero r.RotVelocity = Vector3.zero
    elseif not trollActive then
        if h.PlatformStand and not settings.spectateEnabled then h.PlatformStand = false end
    end
end)

-- Loops lentos (ammo / rapid / fps-ping)
task.spawn(function()
    local frames, last, fps, lastPing, pingCache = 0, tick(), 60, 0, "--"
    while true do
        if dead then break end
        frames = frames + 1
        local now = tick()
        if now - last >= 1 then
            fps = math.floor(frames / (now - last)) frames = 0 last = now
            if now - lastPing >= 5 then
                lastPing = now
                pcall(function()
                    pingCache = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
                end)
            end
            statsLabel.Text = "FPS: " .. fps .. " • PING: " .. tostring(pingCache)
        end
        -- infinite ammo + rapid fire (cada 0.25s para no laggear)
        if (settings.ammoEnabled or settings.rapidFire) and not settings.ghostMode then
            local char = localPlayer.Character local bp = localPlayer:FindFirstChild("Backpack")
            for _, cont in ipairs({char, bp}) do
                if cont then
                    for _, tool in ipairs(cont:GetChildren()) do
                        if tool:IsA("Tool") then
                            for _, v in ipairs(tool:GetDescendants()) do
                                if v:IsA("NumberValue") or v:IsA("IntValue") then
                                    local n = v.Name:lower()
                                    if settings.ammoEnabled and (n:find("ammo") or n:find("clip") or n:find("bullet") or n:find("mag") or n:find("reserve")) then
                                        v.Value = 999
                                    end
                                    if settings.rapidFire and (n:find("cooldown") or n:find("firerate") or n:find("rate") or n:find("delay") or n:find("reload")) then
                                        v.Value = 0
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- hitbox + wallbang en loop LENTO (0.5s) y solo si cambió: mucho menos detectable
        if settings.hitboxEnabled and not settings.ghostMode then
            local want = Vector3.new(settings.hitboxSize, settings.hitboxSize, settings.hitboxSize)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer and p.Character then
                    local part = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                    if part and part:IsA("BasePart") then
                        if not hitboxOriginals[part] then hitboxOriginals[part] = part.Size end
                        if part.Size ~= want then part.Size = want end
                        if part.Transparency ~= 0.6 then part.Transparency = 0.6 end
                        if part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end
        -- (build sin silent: wallbang real eliminado con el silent)
        -- (El viejo loop de CanCollide no afectaba a las balas y se eliminó.)
        -- refresco fullbright cada 2s por si el juego resetea la luz
        if settings.fullbright and tick() - fbLastRefresh > 2 then
            fbLastRefresh = tick()
            Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        end
        task.wait(0.5)
    end
end)

-- Triggerbot: dispara solo cuando un enemigo está bajo la mira (usa el FOV del aimbot).
task.spawn(function()
    local lastShot = 0
    while true do
        if dead then break end
        task.wait(0.05)
        if settings.triggerbot and not settings.ghostMode then
            local now = tick()
            if now - lastShot > 0.3 then
                local ref = aimRefPoint()
                local found = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if found then break end
                    local tAlive = (settings.aimBrute and p.Character ~= nil) or isAlive(p)
                    if p ~= localPlayer and tAlive and not sameTeam(p, localPlayer) then
                        local part = p.Character and getAimPart(p.Character, settings.targetPart)
                        if part then
                            local sp, on = camera:WorldToViewportPoint(part.Position)
                            if on and (Vector2.new(sp.X, sp.Y) - ref).Magnitude <= math.max(14, settings.fovRadius * 0.3) then
                                found = true
                            end
                        end
                    end
                end
                if found then
                    lastShot = now
                    task.wait((settings.triggerDelay or 150) / 1000)
                    local ok = pcall(function()
                        if mouse1click then
                            mouse1click()
                        elseif mouse1press then
                            mouse1press()
                            task.wait(0.05)
                            if mouse1release then mouse1release() end
                        else
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                            task.wait(0.05)
                            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        end
                    end)
                    if ok then triggerShots = triggerShots + 1 end
                    if not ok and not settings.triggerWarned then
                        settings.triggerWarned = true
                        notify("Triggerbot", "Tu executor no soporta clicks.")
                    end
                end
            end
        end
    end
end)

-- respawn: limpiar estados
captureDefaults()
localPlayer.CharacterAdded:Connect(function()
    if dead then return end
    captureDefaults()
    task.wait(0.5)
    table.clear(hitboxOriginals) currentAimTarget = nil orbitAngle = 0
    for p, _ in pairs(espData) do clearESP(p) end
    refreshPlayers()
    pcall(function() camera.CameraSubject = myHum() end)
end)

--// Intro animada
tween(loadBar, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
task.wait(1.35)
tween(loader, TweenInfo.new(0.4), {BackgroundTransparency = 1})
for _, v in ipairs(loader:GetDescendants()) do
    if v:IsA("TextLabel") then tween(v, TweenInfo.new(0.4), {TextTransparency = 1}) end
    if v:IsA("Frame") then tween(v, TweenInfo.new(0.4), {BackgroundTransparency = 1}) end
end
task.wait(0.4)
loader:Destroy()
mainFrame.Visible = true
-- entrada elástica
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
tween(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 740, 0, 500), Position = UDim2.new(0.5, -370, 0.5, -250)
})
notify("ZVOLT V2.43", "Cargado. Usa cuenta alt. RightShift = ocultar.")
dprint("[sys] cargado OK")
