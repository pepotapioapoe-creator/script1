

--// Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
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
    espBox = true, espTracer = false, tracerOrigin = "Bottom", espChams = true, espTool = false,
    espRainbow = false, maxDistance = 1500,
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
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function hasWallBetween(fromPos, toPos, ignoreChar)
    if not settings.wallCheck then return false end
    local filter = {camera}
    if localPlayer.Character then table.insert(filter, localPlayer.Character) end
    if ignoreChar and ignoreChar.Parent then table.insert(filter, ignoreChar.Parent) end
    rayParams.FilterDescendantsInstances = filter
    local res = workspace:Raycast(fromPos, (toPos - fromPos), rayParams)
    if res and res.Instance then
        local m = res.Instance:FindFirstAncestorOfClass("Model")
        if m and Players:GetPlayerFromCharacter(m) then return false end
        return true
    end
    return false
end
local function restoreDefaults()
    local h = myHum()
    if h then
        if not settings.speedEnabled then h.WalkSpeed = DEFAULT_SPEED end
        if not settings.jumpEnabled then h.JumpPower = DEFAULT_JUMP h.UseJumpPower = true end
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

--// Nombres discretos: el anticheat puede leer los textos de tu PlayerGui.
-- Cambia palabras sensibles por neutras. Prendido desde la construcción (si patean
-- al ejecutar, un interruptor interno no serviría). "Nombres reales" lo revierte.
local discreetOn = true
local labelOrig = {}
local DMDICT = {
    {"SILENT AIM", "SIL"}, {"Silent Aim", "Silent"},
    {"MAGIC BULLETS", "MAGIC"}, {"Magic Bullets", "Magic"},
    {"TRIGGERBOT", "TRIGGER"}, {"Triggerbot", "Trigger"},
    {"Aimbot", "Aim"}, {"AIMBOT", "AIM"},
    {"Wallbang", "WB"}, {"WALLBANG", "WB"},
    {"Hitbox", "Hit"}, {"HITBOX", "HIT"},
    {"Spinbot", "Spin"}, {"SPINBOT", "SPIN"},
    {"Bunny Hop", "Hop"},
    {"Noclip", "Clip"}, {"NOCLIP", "CLIP"},
    {"Freecam", "Cam"}, {"FREECAM", "CAM"},
    {"Jerk anti-aim", "Jerk"},
    {"Tracker", "Track"}, {"tracker", "track"},
    {"Rapid Fire", "Rapid"}, {"RAPID FIRE", "RAPID"},
    {"Munición infinita", "Municion"}, {"MUNICIÓN INFINITA", "MUNICION"},
    {"Fullbright", "Brillo"}, {"FULLBRIGHT", "BRILLO"},
    {"Anti-AFK", "AntiAFK"}, {"Anti-Void", "AntiVoid"},
    {"Super Jump", "Salto"}, {"SUPER JUMP", "SALTO"},
    {"Custom Speed", "Speed"}, {"CUSTOM SPEED", "SPEED"},
    {"Salto infinito", "SaltoInf"},
    {"Ctrl + Click", "Click"},
    {"Fling", "Push"},
    {"Espectar", "Ver"},
    {"Spectate", "Spec"},
    {"Server Hop", "Servidor"},
    {"Hueso silent", "Hueso"},
    {"MODO FANTASMA", "FANTASMA"},
    {"Modo AUTO", "Auto"},
    {"SNAP directo", "SNAP"},
    {"Fuerza bruta", "Bruta"},
    {"Diagnóstico F9", "Diag"},
    {"Incluir NPCs/bots", "NPCs"},
    {"Forzar cámara", "Forzar"},
    {"Team Check", "Equipos"},
    {"Wall Check", "Paredes"},
    {"Chams", "Aura"}, {"CHAMS", "AURA"},
    {"Tracers", "Linea"},
    {"Silent", "Sigilo"}, {"SILENT", "SIGILO"},
    {"Troll", "Fun"}, {"TROLL", "FUN"},
    {"Weapon", "Armas"}, {"WEAPON", "ARMAS"},
    {"Combat", "Pelea"}, {"COMBAT", "PELEA"},
    {"Visuals", "Ver"}, {"VISUALS", "VER"},
    {"Movement", "Mover"}, {"MOVEMENT", "MOVER"},
    {"Teleport", "TP"}, {"TELEPORT", "TP"},
    {"World", "Mundo"}, {"WORLD", "MUNDO"},
    {"Config", "Ajustes"}, {"CONFIG", "AJUSTES"},
    {"Keybinds", "Teclas"}, {"KEYBINDS", "TECLAS"},
    {"ESP", "Radar"},
    {"Fly", "Vuelo"}, {"FLY", "VUELO"},
    {"FPS BOOST", "FPS"},
    {"hook detectable", "discreto"},
    {"X-ray", "XR"},
    {"ZVOLT", "ZV"},
    {"AIM: ", "● "}, {"SILENT:", "●"}, {"MAGIC:", "●"}, {"HOOKS:", "●"},
    {"LOCK ", ""},
}
local function repAll(s, find, repl)
    local out, i, n = {}, 1, #find
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

--// FOV + mira
local fovFrame = Instance.new("Frame")
fovFrame.Name = "Fov" fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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
-- Estado silent/magic en pantalla (como el del aimbot)
local silentStatus = Instance.new("TextLabel")
silentStatus.Size = UDim2.new(0, 380, 0, 18) silentStatus.Position = UDim2.new(0, 10, 0, 30)
silentStatus.BackgroundTransparency = 1 silentStatus.Font = FONT_MAIN silentStatus.TextSize = 11
silentStatus.TextColor3 = COLOR_SUBTEXT silentStatus.TextStrokeTransparency = 0.5
silentStatus.Text = "" silentStatus.Parent = gui

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
loadSub.TextColor3 = COLOR_SUBTEXT loadSub.Text = "FRESH EDITION • v2.39 NOCORE" loadSub.Parent = loader
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
logoSub.Text = "FRESH • v2.39 NOCORE" logoSub.Parent = side

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
    {id="visuals",  icon="👁️", title="Visuals",  desc="Ve todo antes que ellos."},
    {id="movement", icon="🌀", title="Movement", desc="Muévete sin límites."},
    {id="teleport", icon="📍", title="Teleport", desc="Viaja instantáneo."},
    {id="troll",    icon="🤡", title="Troll",    desc="Modo payaso activado."},
    {id="weapon",   icon="🔫", title="Weapon",   desc="Tus armas, chetadas."},
    {id="world",    icon="🌍", title="World",    desc="Controla el mapa."},
    {id="config",   icon="⚙️", title="Config",   desc="Teclas, tema y cuenta."},
}
local function createPage(id)
    local p = Instance.new("ScrollingFrame")
    p.Name = id p.Size = UDim2.new(1, -24, 1, -12) p.Position = UDim2.new(0, 12, 0, 0)
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
    lbl.Text = t.icon .. "   " .. t.title lbl.Parent = b
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
        label.Text = discreetText(titlePrefix) .. ":" valBadge.Text = tostring(val)
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
    b.TextColor3 = Accent() b.Text = list[idx] b.Parent = row corner(b, 7)
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

--// PERFILES SILENT POR JUEGO (estilo silent.lua del video: remote + índices exactos).
-- Universal = escaneo automático. Los demás se llenan con la data del F9 que pases.
-- originIdx/dirIdx/hitIdx = posición del argumento (1 = primero). hitIdx es opcional.
local SILENT_PROFILES = {
    ["Universal"] = { auto = true },
    ["BloxStrike"] = { placeIds = {}, remote = nil, originIdx = 1, dirIdx = 2, hitIdx = nil },
    ["FFA"] = { placeIds = {}, remote = nil, originIdx = 1, dirIdx = 2, hitIdx = nil },
    ["Juego 4"] = { placeIds = {}, remote = nil, originIdx = 1, dirIdx = 2, hitIdx = nil },
}

--// ===== CONSTRUIR PESTAÑAS =====
-- COMBAT (Silent primero para que se vea sin hacer scroll)
local c4 = createCard(pages["combat"], "👻 Silent Aim (tiros fantasma)", 200)
local tSilent
tSilent = createToggle(c4, "Silent Aim ⚠️ hook detectable", function(v)
    if v and ghostBlock() then tSilent.Set(false) return end
    settings.silentAimEnabled = v
    if v then tryEnableSilentAim() end
    notify("Silent Aim", v and "Activado (usa el mismo FOV)" or "Desactivado")
end, "silent")
table.insert(riskyToggles, tSilent)
createSlider(c4, "Hit Chance %", settings.silentHitChance, 1, 100, function(v) settings.silentHitChance = v end)
createSlider(c4, "Silent FOV", settings.silentFov, 40, 500, function(v) settings.silentFov = v end)
createSlider(c4, "Prediccion", 12, 0, 50, function(v) settings.silentPrediction = v / 100 end)
createDropdown(c4, "Hueso silent", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Same as Aimbot"}, "Same as Aimbot", function(v)
    settings.silentBone = v
end)
createToggle(c4, "Team Check", function(v) settings.teamCheck = v end)
createToggle(c4, "Wall Check", function(v) settings.wallCheck = v end)
local profileNames = {}
for k in pairs(SILENT_PROFILES) do table.insert(profileNames, k) end
table.sort(profileNames)
local profBtn = createDropdown(c4, "Perfil silent", profileNames, "Universal", function(v)
    settings.silentGame = v
    notify("Silent", "Perfil: " .. v)
end)
local gameInfoLbl = Instance.new("TextLabel")
gameInfoLbl.Size = UDim2.new(1, 0, 0, 18) gameInfoLbl.BackgroundTransparency = 1
gameInfoLbl.Font = FONT_MAIN gameInfoLbl.TextSize = 11 gameInfoLbl.TextColor3 = COLOR_SUBTEXT
gameInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
gameInfoLbl.Text = "Este juego PlaceId: " .. tostring(game.PlaceId)
gameInfoLbl.Parent = c4
createButton(c4, "📋 Copiar datos del juego", function()
    local s = "PlaceId: " .. tostring(game.PlaceId) .. " JobId: " .. tostring(game.JobId)
    if setclipboard then
        setclipboard(s)
        notify("Silent", "Datos copiados. Pásamelos con el log del SPY.")
    else
        dprint("[ZVOLT-SPY] DATOS DEL JUEGO:", s)
        notify("Silent", "Sin portapapeles: mira la consola F9.")
    end
end, false)
-- auto-detecta el juego por PlaceId y elige su perfil solo
for pname, prof in pairs(SILENT_PROFILES) do
    if prof.placeIds then
        for _, pid in ipairs(prof.placeIds) do
            if pid == game.PlaceId then
                settings.silentGame = pname
                profBtn.Text = pname
                notify("Silent", "Juego detectado: perfil " .. pname)
                break
            end
        end
    end
end
local tMagic
tMagic = createToggle(c4, "Magic Bullets ⚠️", function(v)
    if v and ghostBlock() then tMagic.Set(false) return end
    settings.magicBulletsEnabled = v
    settings.magicNotified = false
    if v then
        -- sin silent no hay objetivo: se prende solo
        if not settings.silentAimEnabled and toggleStates["silent"] then
            toggleStates["silent"].Set(true)
        end
        notify("Magic Bullets", "Activadas + Silent auto (usan su FOV y predicción)")
    else
        notify("Magic Bullets", "Desactivadas")
    end
end)
table.insert(riskyToggles, tMagic)
createToggle(c4, "SPY del arma 🔍", function(v)
    settings.spyEnabled = v
    if v then tryEnableSpy() notify("Spy", "Dispara varias veces y abre la consola con F9.") end
end)

local c1 = createCard(pages["combat"], "🎯 Aimbot", 250)
createToggle(c1, "Aimbot · click derecho", function(v) settings.aimEnabled = v end, "aimbot")
createDropdown(c1, "Hueso objetivo", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v) settings.targetPart = v end)
createToggle(c1, "Modo AUTO", function(v) settings.aimAuto = v end)
createToggle(c1, "SNAP directo", function(v) settings.aimSnap = v end)
createToggle(c1, "Incluir NPCs/bots", function(v) settings.aimNpcs = v end)
createToggle(c1, "Diagnóstico F9", function(v) settings.aimDebug = v end)
createToggle(c1, "Fuerza bruta", function(v) settings.aimBrute = v end)
local tTrigger
tTrigger = createToggle(c1, "Triggerbot · auto-disparo", function(v)
    if v and ghostBlock() then tTrigger.Set(false) return end
    settings.triggerbot = v
end)
table.insert(riskyToggles, tTrigger)
createSlider(c1, "Retraso disparo", settings.triggerDelay, 0, 500, function(v) settings.triggerDelay = v end)

local c2 = createCard(pages["combat"], "⭕ FOV & Suavizado", 190)
createSlider(c2, "Radio FOV", settings.fovRadius, 40, 400, function(v) settings.fovRadius = v end)
createSlider(c2, "Suavizado", settings.smoothing, 1, 100, function(v) settings.smoothing = v end)
createSlider(c2, "Zona muerta", settings.aimDeadzone, 0, 30, function(v) settings.aimDeadzone = v end)
createToggle(c2, "Mostrar círculo FOV", function(v) settings.showFov = v end, nil, true)
createToggle(c2, "FOV arcoíris 🌈", function(v) settings.fovRainbow = v end)

local c3 = createCard(pages["combat"], "💥 Daño & Paredes", 150)
local tHitbox
tHitbox = createToggle(c3, "Hitbox Extender ⚠️ MUY detectable", function(v)
    if v and ghostBlock() then tHitbox.Set(false) return end
    settings.hitboxEnabled = v if not v then restoreDefaults() end
end, "hitbox")
table.insert(riskyToggles, tHitbox)
createSlider(c3, "Tamaño Hitbox", settings.hitboxSize, 2, 25, function(v) settings.hitboxSize = v end)
local tWallbang
tWallbang = createToggle(c3, "Wallbang + X-ray ⚠️", function(v)
    if v and ghostBlock() then tWallbang.Set(false) return end
    settings.wallbangEnabled = v
end)
table.insert(riskyToggles, tWallbang)

-- VISUALS
local v1 = createCard(pages["visuals"], "👁️ ESP Principal", 280)
createToggle(v1, "ESP Players", function(v) settings.espEnabled = v end, "esp")
createToggle(v1, "Nombres", function(v) settings.espNames = v end, nil, true)
createToggle(v1, "Distancia [m]", function(v) settings.espDistance = v end, nil, true)
createToggle(v1, "Barra de vida", function(v) settings.espHealthBar = v end, nil, true)
createToggle(v1, "Caja 2D", function(v) settings.espBox = v end, nil, true)
createToggle(v1, "Tracers / Líneas", function(v) settings.espTracer = v end)
createToggle(v1, "Chams (resaltado)", function(v) settings.espChams = v end, nil, true)
createToggle(v1, "Ver herramienta en mano 🔫", function(v) settings.espTool = v end)
createToggle(v1, "Chams X-ray", function(v) settings.espXray = v end, nil, true)

local v2 = createCard(pages["visuals"], "🎨 Estilo ESP", 160)
createDropdown(v2, "Origen de líneas", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) settings.tracerOrigin = v end)
createToggle(v2, "ESP arcoíris 🌈", function(v) settings.espRainbow = v end)
createSlider(v2, "Distancia máxima", settings.maxDistance, 100, 5000, function(v) settings.maxDistance = v end)

-- MOVEMENT
local m1 = createCard(pages["movement"], "✈️ Vuelo & Noclip", 150)
local tFly
tFly = createToggle(m1, "Fly ⚠️", function(v)
    if v and ghostBlock() then tFly.Set(false) return end
    settings.flyEnabled = v
end, "fly")
table.insert(riskyToggles, tFly)
createSlider(m1, "Velocidad de vuelo", settings.flySpeed, 10, 200, function(v) settings.flySpeed = v end)
local tNoclip
tNoclip = createToggle(m1, "Noclip (atravesar todo)", function(v)
    if v and ghostBlock() then tNoclip.Set(false) return end
    settings.noclipEnabled = v
end, "noclip")
table.insert(riskyToggles, tNoclip)

local m2 = createCard(pages["movement"], "🏃 Velocidad & Salto", 240)
local tSpeed
tSpeed = createToggle(m2, "Custom Speed ⚠️ detectable", function(v)
    if v and ghostBlock() then tSpeed.Set(false) return end
    settings.speedEnabled = v if not v then local h = myHum() if h then h.WalkSpeed = DEFAULT_SPEED end end
end, "speed")
table.insert(riskyToggles, tSpeed)
createSlider(m2, "WalkSpeed", settings.customSpeed, 16, 150, function(v) settings.customSpeed = v end)
local tJump
tJump = createToggle(m2, "Super Jump", function(v)
    if v and ghostBlock() then tJump.Set(false) return end
    settings.jumpEnabled = v if not v then local h = myHum() if h then h.JumpPower = DEFAULT_JUMP end end
end, "jump")
table.insert(riskyToggles, tJump)
createSlider(m2, "JumpPower", settings.customJump, 50, 350, function(v) settings.customJump = v end)
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
tSpin = createToggle(m3, "Spinbot ⚠️ detectable", function(v)
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
createSlider(m3, "Jerk power", settings.jerkPower, 1, 10, function(v) settings.jerkPower = v end)
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
tTap = createToggle(m3, "Tap TP táctil", function(v)
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
local t1 = createCard(pages["teleport"], "📍 Teleport a jugadores", 380)
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
tpTweenBtn.TextColor3 = Color3.fromRGB(8,8,12) tpTweenBtn.Text = "✨ TP SUAVE" tpTweenBtn.Parent = btnRow corner(tpTweenBtn, 8) TagAccent(tpTweenBtn)
local tpFastBtn = Instance.new("TextButton")
tpFastBtn.Size = UDim2.new(0.48, 0, 1, 0) tpFastBtn.Position = UDim2.new(0.52, 0, 0, 0)
tpFastBtn.BackgroundColor3 = COLOR_CARD2 tpFastBtn.Font = FONT_BOLD tpFastBtn.TextSize = 11
tpFastBtn.TextColor3 = COLOR_TEXT tpFastBtn.Text = "⚡ TP INSTANT" tpFastBtn.Parent = btnRow corner(tpFastBtn, 8)
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
createSlider(tr1, "Distancia tracker", settings.trackDist, 1, 10, function(v) settings.trackDist = v end)
local tOrbit
tOrbit = createToggle(tr1, "Órbita", function(v)
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
tHeadSit = createToggle(tr2, "Sentarse en su cabeza 🪑", function(v)
    if v and ghostBlock() then tHeadSit.Set(false) return end
    settings.headSitEnabled = v
    if v then settings.trollTrackEnabled = false settings.trollOrbitEnabled = false end
end)
table.insert(riskyToggles, tHeadSit)
createToggle(tr2, "Espectar", function(v)
    settings.spectateEnabled = v spectating = v
    if not v then pcall(function() camera.CameraSubject = myHum() end) end
end)
print("CUT1 OK")
