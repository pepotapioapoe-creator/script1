--[[
    ZVOLT HUB V2 — FRESH EDITION
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
    -- visuals
    espEnabled = false, espNames = true, espDistance = true, espHealthBar = true,
    espBox = true, espTracer = false, tracerOrigin = "Bottom", espChams = true, espTool = false,
    espRainbow = false, maxDistance = 1500,
    -- movement
    flyEnabled = false, flySpeed = 60, noclipEnabled = false, speedEnabled = false, customSpeed = 32,
    jumpEnabled = false, customJump = 100, bhopEnabled = false, infJumpEnabled = false,
    spinEnabled = false, spinSpeed = 50, ctrlClickTpEnabled = false, gravity = 196.2, antiVoid = false,
    -- troll / tp
    trollTrackEnabled = false, trollOrbitEnabled = false, orbitSpeed = 3, orbitRadius = 6, trackDist = 3,
    flingEnabled = false, headSitEnabled = false, spectateEnabled = false,
    selectedTpPlayer = nil, savedPos = nil,
    -- weapon/world
    ammoEnabled = false, rapidFire = false, fullbright = false, fpsBoosted = false, antiAfk = false,
    -- ui
    uiToggleKey = Enum.KeyCode.RightShift, theme = "Cyan", uiTransparency = 0,
    ghostMode = false,
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
    pcall(function()
        if a.Team ~= nil and b.Team ~= nil and a.Team == b.Team then return true end
    end)
    return a.Team ~= nil and b.Team ~= nil and a.TeamColor == b.TeamColor and a.Team == b.Team
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function hasWallBetween(fromPos, toPos, ignoreChar)
    if not settings.wallCheck then return false end
    rayParams.FilterDescendantsInstances = {localPlayer.Character, ignoreChar and ignoreChar.Parent or nil, camera}
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

--// GUI raíz
for _, v in ipairs(localPlayer.PlayerGui:GetChildren()) do
    if v.Name:find("Zvolt") then pcall(function() v:Destroy() end) end
end
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltV2_" .. math.random(11111, 99999)
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
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 1.2})
    end)
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
loadSub.TextColor3 = COLOR_SUBTEXT loadSub.Text = "FRESH EDITION • v2.4 GHOST" loadSub.Parent = loader
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
logoSub.Text = "FRESH • v2.4 GHOST" logoSub.Parent = side

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
        b.Text = list[idx] pcall(callback, list[idx])
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
createSlider(c4, "Prediccion", 12, 0, 50, function(v) settings.silentPrediction = v / 100 end)
createDropdown(c4, "Hueso silent", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Same as Aimbot"}, "Same as Aimbot", function(v)
    settings.silentBone = v
end)

local c1 = createCard(pages["combat"], "🎯 Aimbot", 250)
createToggle(c1, "Aimbot (click derecho)", function(v) settings.aimEnabled = v currentAimTarget = nil end, "aimbot")
createDropdown(c1, "Modo de apuntado", {"Camera", "Mouse"}, "Camera", function(v) settings.aimMode = v end)
createDropdown(c1, "Hueso objetivo", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v) settings.targetPart = v end)
createToggle(c1, "Team Check (no apuntar aliados)", function(v) settings.teamCheck = v end)
createToggle(c1, "Wall Check (no apuntar tras pared)", function(v) settings.wallCheck = v end)
createToggle(c1, "Sticky Target (fijar objetivo)", function(v) settings.stickyTarget = v end)

local c2 = createCard(pages["combat"], "⭕ FOV & Suavizado", 190)
createSlider(c2, "Radio FOV", settings.fovRadius, 40, 400, function(v) settings.fovRadius = v end)
createSlider(c2, "Suavizado", settings.smoothing, 1, 100, function(v) settings.smoothing = v end)
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
tWallbang = createToggle(c3, "Wallbang ⚠️ detectable", function(v)
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
createToggle(v1, "Caja 2D (Box)", function(v) settings.espBox = v end, nil, true)
createToggle(v1, "Tracers / Líneas", function(v) settings.espTracer = v end)
createToggle(v1, "Chams (resaltado)", function(v) settings.espChams = v end, nil, true)
createToggle(v1, "Ver herramienta en mano 🔫", function(v) settings.espTool = v end)

local v2 = createCard(pages["visuals"], "🎨 Estilo ESP", 160)
createDropdown(v2, "Origen de líneas", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) settings.tracerOrigin = v end)
createToggle(v2, "ESP arcoíris 🌈", function(v) settings.espRainbow = v end)
createSlider(v2, "Distancia máxima", settings.maxDistance, 100, 5000, function(v) settings.maxDistance = v end)

-- MOVEMENT
local m1 = createCard(pages["movement"], "✈️ Vuelo & Noclip", 150)
local tFly
tFly = createToggle(m1, "Fly ⚠️ detectable (WASD + Espacio/Shift, joystick en móvil)", function(v)
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
tBhop = createToggle(m2, "Bunny Hop (auto-salto)", function(v)
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
local tCtrl
tCtrl = createToggle(m3, "Ctrl + Click TP 🖱️", function(v)
    if v and ghostBlock() then tCtrl.Set(false) return end
    settings.ctrlClickTpEnabled = v
end)
table.insert(riskyToggles, tCtrl)
createToggle(m3, "Anti-Void (no caer al vacío)", function(v) settings.antiVoid = v end)
createSlider(m3, "Gravedad", 196, 0, 400, function(v)
    if settings.ghostMode then pcall(function() workspace.Gravity = 196.2 end) ghostBlock() return end
    settings.gravity = v pcall(function() workspace.Gravity = v end)
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
        if p ~= localPlayer and (q == "" or p.Name:lower():find(q) or p.DisplayName:lower():find(q)) then
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
Players.PlayerAdded:Connect(refreshPlayers) Players.PlayerRemoving:Connect(refreshPlayers)
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
tTrack = createToggle(tr1, "Tracker (pegado a su cara)", function(v)
    if v and ghostBlock() then tTrack.Set(false) return end
    settings.trollTrackEnabled = v
    if v then settings.trollOrbitEnabled = false settings.flingEnabled = false settings.headSitEnabled = false end
end)
table.insert(riskyToggles, tTrack)
createSlider(tr1, "Distancia tracker", settings.trackDist, 1, 10, function(v) settings.trackDist = v end)
local tOrbit
tOrbit = createToggle(tr1, "Órbita (girar alrededor)", function(v)
    if v and ghostBlock() then tOrbit.Set(false) return end
    settings.trollOrbitEnabled = v
    if v then settings.trollTrackEnabled = false settings.flingEnabled = false settings.headSitEnabled = false end
end)
table.insert(riskyToggles, tOrbit)
createSlider(tr1, "Velocidad órbita", settings.orbitSpeed, 1, 15, function(v) settings.orbitSpeed = v end)
createSlider(tr1, "Radio órbita", settings.orbitRadius, 3, 20, function(v) settings.orbitRadius = v end)

local tr2 = createCard(pages["troll"], "😈 Molestar", 190)
local tFling
tFling = createToggle(tr2, "Fling (lanzar al seleccionado)", function(v)
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
createToggle(tr2, "Espectar seleccionado 📺", function(v)
    settings.spectateEnabled = v spectating = v
    if not v then pcall(function() camera.CameraSubject = myHum() end) end
end)
createButton(tr2, "👁️ Ver (spectate rápido)", function()
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
tRapid = createToggle(w1, "Rapid Fire (recarga rápida)", function(v)
    if v and ghostBlock() then tRapid.Set(false) return end
    settings.rapidFire = v
end)
table.insert(riskyToggles, tRapid)
createButton(w1, "🧹 Limpiar retroceso visual (reset cámara)", function()
    camera.FieldOfView = 70 notify("Weapon", "Cámara reseteada.")
end, false)
createButton(w1, "🔍 Ver arma del seleccionado (consola F9)", function()
    local tp = settings.selectedTpPlayer
    if tp and tp.Character then
        for _, t in ipairs(tp.Character:GetChildren()) do
            if t:IsA("Tool") then print("[ZVOLT] " .. tp.Name .. " tiene: " .. t.Name) end
        end
        notify("Weapon", "Revisa la consola (F9).")
    end
end, false)

-- WORLD
local wo1 = createCard(pages["world"], "🌍 Iluminación & Mapa", 190)
createToggle(wo1, "Fullbright (ver en la oscuridad) 💡", function(v) settings.fullbright = v end)
createButton(wo1, "☀️ Poner de día", function()
    Lighting.ClockTime = 14 Lighting.FogEnd = 100000 Lighting.Brightness = 2 Lighting.Ambient = Color3.fromRGB(255,255,255)
end, false)
createButton(wo1, "🌙 Poner de noche", function()
    Lighting.ClockTime = 0 Lighting.Brightness = 1
end, false)
createButton(wo1, "🌫️ Quitar niebla", function()
    Lighting.FogEnd = 100000 for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") then v.Density = 0 end end
end, false)

local wo2 = createCard(pages["world"], "⚡ Rendimiento", 150)
createToggle(wo2, "Anti-AFK (no te expulsa) ☕", function(v) settings.antiAfk = v end)
createButton(wo2, "🚀 FPS BOOST (quitar lag)", function()
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
    settings.wallbangEnabled = false settings.silentAimEnabled = false settings.bhopEnabled = false
    settings.infJumpEnabled = false settings.ctrlClickTpEnabled = false settings.trollTrackEnabled = false
    settings.trollOrbitEnabled = false settings.flingEnabled = false settings.headSitEnabled = false
    settings.ammoEnabled = false settings.rapidFire = false
    restoreDefaults()
    pcall(function() workspace.Gravity = 196.2 end)
end
local cfGhost = createCard(pages["config"], "👻 Modo Fantasma (anti-ban)", 90)
createToggle(cfGhost, "MODO FANTASMA (solo ESP + aim camara)", function(v)
    settings.ghostMode = v
    if v then applyGhostOff() notify("Fantasma", "Solo queda lo invisible al servidor: ESP + aimbot camara + luz.") end
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
createToggle(cf1, "ESP arcoíris directo", function(v) settings.espRainbow = v end)
createButton(cf1, "🔄 Resetear todo", function()
    for _, s in pairs(toggleStates) do pcall(function() s.Set(false) end) end
    restoreDefaults() workspace.Gravity = 196.2 restoreLighting()
    pcall(function() camera.CameraSubject = myHum() camera.FieldOfView = 70 end)
    notify("Config", "Todo reseteado y huellas limpiadas.")
end, false)

local cf2 = createCard(pages["config"], "⌨️ Keybinds (F1-F6 + UI)", 330)
local function keyRow(parent, labelName, bindKey)
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
createButton(cf3, "🔁 Rejoin (reentrar)", function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer) end, false)
createButton(cf3, "🗑️ Destruir Zvolt (pánico: restaura todo)", function()
    restoreDefaults() restoreLighting()
    pcall(function() workspace.Gravity = 196.2 end)
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
aimBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then aimingMobile = true aimBtn.BackgroundColor3 = Accent() aimBtn.TextColor3 = Color3.fromRGB(0,0,0) end end)
aimBtn.InputEnded:Connect(function(i) aimingMobile = false aimBtn.BackgroundColor3 = COLOR_CARD aimBtn.TextColor3 = Accent() end)

--// Inputs globales
local aimingPC = false
UserInputService.InputBegan:Connect(function(inp, gp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then aimingPC = true end
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
        -- Ctrl + Click TP
        if settings.ctrlClickTpEnabled and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
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
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then aimingPC = false end
end)
-- anti afk
Players.LocalPlayer.Idled:Connect(function()
    if settings.antiAfk then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end
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
        espData[plr] = nil
    end
    -- no tocamos espCharOf aquí a propósito en el loop por frame;
    -- se actualiza solo en buildESP / respawn
end
local function espColor()
    if settings.espRainbow then return Color3.fromHSV(tick() % 5 / 5, 1, 1) end
    return Accent()
end
local function buildESP(plr, char)
    clearESP(plr)
    local objs = {}
    if settings.espChams then
        local hl = Instance.new("Highlight")
        hl.Adornee = char hl.FillTransparency = 0.7 hl.OutlineTransparency = 0
        hl.FillColor = espColor() hl.Parent = char objs.hl = hl
    end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 170, 0, 46) bb.StudsOffset = Vector3.new(0, 2.8, 0) bb.AlwaysOnTop = true bb.Parent = char
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
    if not hum or not lr then return end
    local dist = math.floor((lr.Position - root.Position).Magnitude)
    if dist > settings.maxDistance or hum.Health <= 0 then
        objs.bb.Enabled = false objs.line.Visible = false objs.box.Visible = false
        if objs.hl then objs.hl.Enabled = false end
        return
    end
    local col = espColor()
    objs.bb.Enabled = true
    if objs.hl then objs.hl.Enabled = true end
    -- nombre + dist
    local txt = ""
    if settings.espNames then txt = plr.DisplayName .. " " end
    if settings.espDistance then txt = txt .. "[" .. dist .. "m]" end
    objs.name.Text = txt ~= "" and txt or plr.Name
    objs.name.Visible = (settings.espNames or settings.espDistance)
    objs.name.TextColor3 = col
    -- vida
    objs.hpBg.Visible = settings.espHealthBar
    if settings.espHealthBar then
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
    if objs.hl then objs.hl.FillColor = col end
    -- tracer
    if settings.espTracer then
        local sp, on = camera:WorldToViewportPoint(root.Position)
        if on then
            local vs = camera.ViewportSize local startV
            if settings.tracerOrigin == "Bottom" then startV = Vector2.new(vs.X / 2, vs.Y)
            elseif settings.tracerOrigin == "Center" then startV = Vector2.new(vs.X / 2, vs.Y / 2)
            else startV = UserInputService:GetMouseLocation() end
            local endV = Vector2.new(sp.X, sp.Y)
            local d = (endV - startV).Magnitude
            objs.line.Size = UDim2.new(0, 1.5, 0, d)
            objs.line.Position = UDim2.new(0, (startV.X + endV.X) / 2, 0, (startV.Y + endV.Y) / 2)
            objs.line.Rotation = math.deg(math.atan2(endV.Y - startV.Y, endV.X - startV.X)) - 90
            objs.line.BackgroundColor3 = col objs.line.Visible = true
        else objs.line.Visible = false end
    else objs.line.Visible = false end
    -- box
    if settings.espBox then
        local head = char:FindFirstChild("Head")
        local _, on = camera:WorldToViewportPoint(root.Position)
        if on and head then
            local hp = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
            local lp = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local h = math.abs(hp.Y - lp.Y) local w = h * 0.62
            objs.box.Size = UDim2.new(0, w, 0, h)
            objs.box.Position = UDim2.new(0, hp.X - w / 2, 0, hp.Y)
            objs.box.Visible = true objs.boxStroke.Color = col
        else objs.box.Visible = false end
    else objs.box.Visible = false end
end
Players.PlayerRemoving:Connect(function(plr) clearESP(plr) espCharOf[plr] = nil end)

--// Aimbot con wall/team check
local function closestTarget()
    if settings.stickyTarget and currentAimTarget and isAlive(currentAimTarget) then
        local tp = currentAimTarget.Character and (currentAimTarget.Character:FindFirstChild(settings.targetPart) or currentAimTarget.Character:FindFirstChild("Head"))
        if tp then
            local sp, on = camera:WorldToViewportPoint(tp.Position)
            if on and (Vector2.new(sp.X, sp.Y) - UserInputService:GetMouseLocation()).Magnitude <= settings.fovRadius then
                return currentAimTarget
            end
        end
        currentAimTarget = nil
    end
    local best, bestD = nil, settings.fovRadius
    local ml = UserInputService:GetMouseLocation()
    local lr = myRoot()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and isAlive(p) and not sameTeam(p, localPlayer) then
            local tp = p.Character:FindFirstChild(settings.targetPart) or p.Character:FindFirstChild("Head")
            if tp and lr and (lr.Position - tp.Position).Magnitude <= settings.maxDistance then
                if not hasWallBetween(camera.CFrame.Position, tp.Position, tp) then
                    local sp, on = camera:WorldToViewportPoint(tp.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                        if d <= settings.fovRadius and d < bestD then bestD = d best = p end
                    end
                end
            end
        end
    end
    currentAimTarget = best
    return best
end

--// SILENT AIM 👻 (redirige tiros sin mover la cámara)
settings.silentBone = settings.silentBone or "Same as Aimbot"
local silentHooked = false
local silentBypass = false -- en true = son nuestros propios raycasts (wallcheck), no redirigir
local function silentBoneName()
    if not settings.silentBone or settings.silentBone == "Same as Aimbot" then
        return settings.targetPart
    end
    return settings.silentBone
end
local function getSilentHitPos()
    if not settings.silentAimEnabled then return nil end
    if math.random(1, 100) > (settings.silentHitChance or 100) then return nil end
    local bone = silentBoneName()
    local ml = UserInputService:GetMouseLocation()
    local lr = myRoot()
    local bestPart, bestD = nil, settings.fovRadius
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and isAlive(p) and not sameTeam(p, localPlayer) then
            local part = p.Character and (p.Character:FindFirstChild(bone) or p.Character:FindFirstChild("Head"))
            if part and lr and (lr.Position - part.Position).Magnitude <= settings.maxDistance then
                silentBypass = true
                local blocked = hasWallBetween(camera.CFrame.Position, part.Position, part)
                silentBypass = false
                if not blocked then
                    local sp, on = camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                        if d <= settings.fovRadius and d < bestD then
                            bestD = d bestPart = part
                        end
                    end
                end
            end
        end
    end
    if bestPart then
        local pred = settings.silentPrediction or 0.12
        local vel = bestPart.Velocity
        if vel.Magnitude > 60 then vel = vel.Unit * 60 end -- anti-fling loco
        return bestPart.Position + (vel * pred), bestPart
    end
    return nil
end
function tryEnableSilentAim()
    if silentHooked then return end
    local ok, msg = pcall(function()
        local hm = hookmetamethod
        local gncm = getnamecallmethod
        local chk = checkcaller
        local nc = (newcclosure and newcclosure) or function(f) return f end
        if not (hm and gncm) then error("executor sin hookmetamethod") end
        -- 1) Hook Raycast / FindPartOnRay (juegos con balas físicas)
        local oldNC
        oldNC = hm(game, "__namecall", nc(function(self, ...)
            local method = gncm()
            local args = {...}
            local function isExploitCall()
                if chk then local s, r = pcall(chk) if s and r then return true end end
                return false
            end
            if settings.silentAimEnabled and not silentBypass and not isExploitCall() then
                if method == "Raycast" then
                    local origin, dir = args[1], args[2]
                    if origin and dir and typeof(origin) == "Vector3" and typeof(dir) == "Vector3" then
                        local hitPos = getSilentHitPos()
                        if hitPos then
                            local mag = dir.Magnitude
                            local newDir = (hitPos - origin).Unit * mag
                            return oldNC(self, origin, newDir, args[3])
                        end
                    end
                elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
                    local ray = args[1]
                    if ray and typeof(ray) == "Ray" then
                        local hitPos = getSilentHitPos()
                        if hitPos then
                            local newRay = Ray.new(ray.Origin, (hitPos - ray.Origin).Unit * ray.Direction.Magnitude)
                            local nargs = {newRay}
                            for i = 2, #args do nargs[i] = args[i] end
                            return oldNC(self, table.unpack(nargs))
                        end
                    end
                end
            end
            return oldNC(self, ...)
        end))
        -- 2) Hook Mouse.Hit / Mouse.Target (juegos que disparan con mouse.Hit)
        local oldIdx
        oldIdx = hm(game, "__index", nc(function(self, k)
            if settings.silentAimEnabled and not silentBypass and (self == mouse) and (k == "Hit" or k == "Target") then
                local s, r = pcall(checkcaller)
                local exploitCall = (s and r)
                if not exploitCall then
                    local hitPos, part = getSilentHitPos()
                    if hitPos then
                        if k == "Hit" then return CFrame.new(hitPos) end
                        if k == "Target" then return part end
                    end
                end
            end
            return oldIdx(self, k)
        end))
        silentHooked = true
    end)
    if silentHooked then
        notify("Silent Aim 👻", "Hook instalado. Dispara cerca y pega solo.")
    else
        notify("Silent Aim ⚠️", "Tu executor no soporta hooks (" .. tostring(msg) .. "). Usa Aimbot normal.")
    end
end

--// Loops principales
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
RunService.RenderStepped:Connect(function(dt)
    if not camera then return end
    -- FOV UI
    local ml = UserInputService:GetMouseLocation()
    local wantFov = (settings.aimEnabled or settings.silentAimEnabled) and settings.showFov
    fovFrame.Visible = wantFov
    aimBtn.Visible = settings.aimEnabled and isTouch
    if wantFov then
        fovFrame.Position = UDim2.new(0, ml.X, 0, ml.Y)
        fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
        fovDot.Position = UDim2.new(0.5, 0, 0.5, 0)
        if settings.fovRainbow then fovStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else fovStroke.Color = Accent() end
        fovDot.BackgroundColor3 = fovStroke.Color
    end
    -- ESP
    if settings.espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then updateESP(p) end end
    else
        for p, _ in pairs(espData) do clearESP(p) end
    end
    -- Aimbot
    local aiming = settings.aimEnabled and (aimingPC or aimingMobile)
    snapLine.Visible = false
    if aiming then
        local tgt = closestTarget()
        if tgt and tgt.Character then
            local part = tgt.Character:FindFirstChild(settings.targetPart) or tgt.Character:FindFirstChild("Head")
            if part then
                local sp, on = camera:WorldToViewportPoint(part.Position)
                if on then
                    -- snapline al objetivo
                    local startV = Vector2.new(ml.X, ml.Y) local endV = Vector2.new(sp.X, sp.Y)
                    local d = (endV - startV).Magnitude
                    if d > 2 then
                        snapLine.Size = UDim2.new(0, 1.5, 0, d)
                        snapLine.Position = UDim2.new(0, (startV.X + endV.X) / 2, 0, (startV.Y + endV.Y) / 2)
                        snapLine.Rotation = math.deg(math.atan2(endV.Y - startV.Y, endV.X - startV.X)) - 90
                        snapLine.Visible = true
                    end
                    local alpha = math.clamp(settings.smoothing / 100, 0.05, 1)
                    if settings.aimMode == "Camera" then
                        pcall(function()
                            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, part.Position), alpha)
                        end)
                    else
                        pcall(function()
                            mousemoverel((sp.X - ml.X) * alpha, (sp.Y - ml.Y) * alpha)
                        end)
                    end
                end
            end
        end
    else
        if not settings.stickyTarget then currentAimTarget = nil end
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
    -- noclip (solo escribe si hace falta: menos escrituras = menos huellas)
    if settings.noclipEnabled and localPlayer.Character then
        for _, part in ipairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
    -- NOTA: hitbox y wallbang se aplican en el loop lento (0.5s), no cada frame.
    -- speed / jump / bhop (solo escribir si cambió el valor)
    local ch = myHum()
    if ch and not settings.ghostMode and not settings.trollTrackEnabled and not settings.trollOrbitEnabled then
        local wantSpeed = settings.speedEnabled and settings.customSpeed or DEFAULT_SPEED
        if ch.WalkSpeed ~= wantSpeed then ch.WalkSpeed = wantSpeed end
        if settings.jumpEnabled and ch.JumpPower ~= settings.customJump then ch.JumpPower = settings.customJump ch.UseJumpPower = true end
        if settings.bhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            if ch.FloorMaterial ~= Enum.Material.Air then ch:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
    -- fullbright
    if settings.fullbright then
        Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end
    -- anti-void
    if settings.antiVoid and r and r.Position.Y < -60 then
        r.CFrame = CFrame.new(0, 20, 0) r.Velocity = Vector3.zero
    end
end)

-- Fly (Heartbeat, compatible móvil con joystick)
RunService.Heartbeat:Connect(function(dt)
    local r = myRoot() local h = myHum()
    if not r or not h then return end
    local trollActive = settings.trollTrackEnabled or settings.trollOrbitEnabled or settings.flingEnabled
    if settings.flyEnabled and not settings.ghostMode and not trollActive then
        h.PlatformStand = true
        local cf = camera.CFrame
        local mv = Vector3.zero
        local md = h.MoveDirection -- funciona con joystick móvil ✅
        if md.Magnitude > 0.1 then
            local fwd = cf.LookVector * Vector3.new(1, 0, 1)
            local rgt = cf.RightVector * Vector3.new(1, 0, 1)
            if fwd.Magnitude > 0 then fwd = fwd.Unit else fwd = Vector3.zero end
            if rgt.Magnitude > 0 then rgt = rgt.Unit else rgt = Vector3.zero end
            mv = mv + (fwd * -md.Z) + (rgt * md.X)
            -- joystick arriba = avanzar; si mira arriba/abajo también vuela vertical un poco
            mv = mv + Vector3.new(0, (-md.Z) * cf.LookVector.Y * 0.8, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0, 1, 0) end
        if mv.Magnitude > 1 then mv = mv.Unit end
        r.CFrame = r.CFrame + (mv * settings.flySpeed * dt)
        r.Velocity = Vector3.zero r.AssemblyLinearVelocity = Vector3.zero r.RotVelocity = Vector3.zero
    elseif not trollActive then
        if h.PlatformStand and not settings.spectateEnabled then h.PlatformStand = false end
    end
end)

-- Loops lentos (ammo / rapid / fps-ping)
task.spawn(function()
    local frames, last, fps = 0, tick(), 60
    while true do
        frames = frames + 1
        local now = tick()
        if now - last >= 1 then
            fps = math.floor(frames / (now - last)) frames = 0 last = now
            local ping = "--"
            pcall(function()
                local s = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
                ping = s
            end)
            statsLabel.Text = "FPS: " .. fps .. " • PING: " .. tostring(ping)
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
        if settings.wallbangEnabled and not settings.ghostMode then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer and p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- respawn: limpiar estados
localPlayer.CharacterAdded:Connect(function()
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
notify("ZVOLT V2.4 GHOST", "Cargado. Usa cuenta alt. RightShift = ocultar.")
print("[ZVOLT V2.4 GHOST] cargado OK - modo fantasma en Config")
