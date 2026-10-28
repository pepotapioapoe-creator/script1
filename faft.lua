--[[
    SB HUB V1 — desde cero. Silent real por hookfunction al BulletHandler (estilo video).
    Solo para Real (necesita hookfunction/getgc). ESP + target picker + FOV propio.
    Basado en el GunFramework decompilado: el cliente reporta el hit via Position:FireServer
    con la direccion de la bala => reescribir direccion = headshot garantizado.
]]

--// Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// Anti re-ejecución
if _G.__SB_STOP then pcall(_G.__SB_STOP) end
local dead = false
_G.__SB_STOP = function() dead = true end
if _G.__SB_CONNS then
    for _, c in ipairs(_G.__SB_CONNS) do pcall(function() c:Disconnect() end) end
end
_G.__SB_CONNS = {}
local function SCONN(c) table.insert(_G.__SB_CONNS, c) return c end
if _G.__SB_GUI then pcall(function() _G.__SB_GUI:Destroy() end) _G.__SB_GUI = nil end

--// Requerimientos del executor
local HAS_HOOKS = type(hookfunction) == "function" and (type(hookmetamethod) == "function" or type(getgc) == "function")
local HAS_GETUPVALS = type(debug) == "table" and type(debug.getupvalue) == "function" or type(getupvalue) == "function"

--// Settings
local settings = {
    -- silent
    silentEnabled = false, silentFov = 150, silentHitChance = 100,
    targetPart = "Head", silentRange = 800, prediction = 0.12,
    -- esp
    espEnabled = false, espNames = true, espDistance = true,
    espBox = true, espTracer = true, espHealthBar = true,
    tracerOrigin = "Bottom", maxDistance = 2000,
    -- ui
    uiToggleKey = Enum.KeyCode.RightShift,
}
local hookedFire = nil -- funcion original del BulletHandler tras el hook
local hookInstalled = false

--// Estilo
local ACCENT = Color3.fromRGB(0, 242, 255)
local COLOR_BG = Color3.fromRGB(10, 10, 16)
local COLOR_CARD = Color3.fromRGB(17, 17, 27)
local COLOR_CARD2 = Color3.fromRGB(22, 22, 34)
local COLOR_TEXT = Color3.fromRGB(245, 245, 250)
local COLOR_SUBTEXT = Color3.fromRGB(150, 150, 170)
local FONT_MAIN = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_TITLE = Enum.Font.FredokaOne

local function tween(obj, info, props)
    pcall(function()
        TweenService:Create(obj, info or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end
local function corner(obj, r)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = obj return c
end
local function stroke(obj, col, t)
    local s = Instance.new("UIStroke") s.Color = col s.Thickness = t or 1 s.Parent = obj return s
end
local function myRoot()
    local c = localPlayer.Character return c and c:FindFirstChild("HumanoidRootPart")
end

--// GUI raíz
local function rndName()
    local s = ""
    for i = 1, 10 do s = s .. string.char(math.random(97, 122)) end
    return "ui_" .. s
end
for _, v in ipairs(localPlayer.PlayerGui:GetChildren()) do
    pcall(function()
        if v:GetAttribute("SB1") then v:Destroy() end
    end)
end
local gui = Instance.new("ScreenGui")
gui.Name = rndName()
gui:SetAttribute("SB1", true)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = localPlayer:WaitForChild("PlayerGui")
_G.__SB_GUI = gui

--// Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 400)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -200)
mainFrame.BackgroundColor3 = COLOR_BG
mainFrame.Visible = false
mainFrame.Parent = gui
corner(mainFrame, 12) stroke(mainFrame, Color3.fromRGB(38, 38, 55), 1.2)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 48) topBar.BackgroundTransparency = 1 topBar.Parent = mainFrame
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 220, 0, 28) titleLbl.Position = UDim2.new(0, 16, 0, 6)
titleLbl.BackgroundTransparency = 1 titleLbl.Font = FONT_BOLD titleLbl.TextSize = 17
titleLbl.TextXAlignment = Enum.TextXAlignment.Left titleLbl.TextColor3 = COLOR_TEXT
titleLbl.Text = "SB v1.0" titleLbl.Parent = topBar
local descLbl = Instance.new("TextLabel")
descLbl.Size = UDim2.new(0, 300, 0, 16) descLbl.Position = UDim2.new(0, 16, 0, 30)
descLbl.BackgroundTransparency = 1 descLbl.Font = FONT_MAIN descLbl.TextSize = 11
descLbl.TextXAlignment = Enum.TextXAlignment.Left descLbl.TextColor3 = COLOR_SUBTEXT
descLbl.Text = "Silent real + radar." descLbl.Parent = topBar
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 32, 0, 32) hideBtn.Position = UDim2.new(1, -44, 0, 8)
hideBtn.BackgroundColor3 = COLOR_CARD2 hideBtn.Font = FONT_BOLD hideBtn.TextSize = 14
hideBtn.TextColor3 = COLOR_TEXT hideBtn.Text = "-" hideBtn.Parent = topBar corner(hideBtn, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -60) scroll.Position = UDim2.new(0, 12, 0, 54)
scroll.BackgroundTransparency = 1 scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = ACCENT scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0) scroll.Parent = mainFrame
local scrollLay = Instance.new("UIListLayout")
scrollLay.Padding = UDim.new(0, 10) scrollLay.SortOrder = Enum.SortOrder.LayoutOrder scrollLay.Parent = scroll

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
    SCONN(topBar.InputBegan:Connect(begin))
    SCONN(UserInputService.InputChanged:Connect(move))
    SCONN(UserInputService.InputEnded:Connect(fin))
    hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
end

--// Componentes
local cardCount = 0
local function createCard(titleText)
    cardCount = cardCount + 1
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -12, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = COLOR_CARD card.Parent = scroll
    card.LayoutOrder = cardCount
    corner(card, 10) stroke(card, Color3.fromRGB(32, 32, 48), 1)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14) pad.PaddingRight = UDim.new(0, 14)
    pad.PaddingTop = UDim.new(0, 12) pad.PaddingBottom = UDim.new(0, 14) pad.Parent = card
    local layCard = Instance.new("UIListLayout")
    layCard.Padding = UDim.new(0, 6) layCard.SortOrder = Enum.SortOrder.LayoutOrder layCard.Parent = card
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20) title.BackgroundTransparency = 1
    title.Font = FONT_BOLD title.TextSize = 12 title.TextColor3 = COLOR_TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left title.Text = titleText:upper() title.Parent = card
    title.LayoutOrder = 1
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 26, 0, 3)
    bar.BackgroundColor3 = ACCENT bar.Parent = card corner(bar, 99)
    bar.LayoutOrder = 2
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundTransparency = 1 box.Parent = card
    box.LayoutOrder = 3
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = box
    return box
end

local function createToggle(parent, text, callback, default)
    default = default or false
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 30) row.BackgroundTransparency = 1 row.Text = "" row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 1, 0) lbl.BackgroundTransparency = 1
    lbl.Font = FONT_MAIN lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = default and COLOR_TEXT or COLOR_SUBTEXT lbl.Text = text lbl.Parent = row
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22) track.Position = UDim2.new(1, -42, 0.5, -11)
    track.BackgroundColor3 = default and ACCENT or Color3.fromRGB(30, 30, 44) track.Parent = row corner(track, 99)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16) knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) knob.Parent = track corner(knob, 99)
    local state = default
    local function set(v)
        state = v
        lbl.TextColor3 = state and COLOR_TEXT or COLOR_SUBTEXT
        tween(track, TweenInfo.new(0.2), {BackgroundColor3 = state and ACCENT or Color3.fromRGB(30, 30, 44)})
        tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        pcall(callback, state)
    end
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
    valBadge.TextColor3 = ACCENT valBadge.Text = tostring(defaultVal) valBadge.Parent = box corner(valBadge, 6)
    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 8) bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 42) bar.Text = "" bar.AutoButtonColor = false bar.Parent = box corner(bar, 99)
    local fill = Instance.new("Frame")
    local p0 = (defaultVal - minVal) / math.max(1, (maxVal - minVal))
    fill.Size = UDim2.new(p0, 0, 1, 0) fill.BackgroundColor3 = ACCENT fill.Parent = bar corner(fill, 99)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14) knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(p0, 0, 0.5, 0) knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) knob.Parent = bar corner(knob, 99)
    local dragging = false
    local function apply(xPos)
        local bp, bs = bar.AbsolutePosition.X, math.max(1, bar.AbsoluteSize.X)
        local c = math.clamp((xPos - bp) / bs, 0, 1)
        local val = math.floor(minVal + c * (maxVal - minVal))
        fill.Size = UDim2.new(c, 0, 1, 0) knob.Position = UDim2.new(c, 0, 0.5, 0)
        label.Text = titlePrefix .. ":  " .. tostring(val) valBadge.Text = tostring(val)
        pcall(callback, val)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true apply(i.Position.X)
        end
    end)
    SCONN(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    SCONN(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then apply(i.Position.X) end
    end))
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
    b.TextColor3 = ACCENT b.Text = list[idx] b.Parent = row corner(b, 7)
    stroke(b, Color3.fromRGB(45, 45, 65), 1)
    pcall(callback, list[idx])
    b.MouseButton1Click:Connect(function()
        idx = idx + 1 if idx > #list then idx = 1 end
        b.Text = list[idx] pcall(callback, list[idx])
    end)
    return b
end

local function createButton(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34) b.Font = FONT_BOLD b.TextSize = 12
    b.TextColor3 = COLOR_TEXT b.BackgroundColor3 = COLOR_CARD2
    b.Text = text b.Parent = parent corner(b, 8)
    stroke(b, Color3.fromRGB(40, 40, 60), 1)
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return b
end

--// ===== TARGET PICKER (del video: jugador mas cerca del mouse dentro del FOV) =====
local function pickTarget()
    if dead then return nil end
    if math.random(100) > (settings.silentHitChance or 100) then return nil end
    local lr = myRoot()
    if not lr then return nil end
    local ml = UserInputService:GetMouseLocation()
    local best, bestD = nil, settings.silentFov or 150
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local tp = p.Character:FindFirstChild(settings.targetPart)
                    or p.Character:FindFirstChild("Head")
                    or p.Character:FindFirstChild("HumanoidRootPart")
                if tp then
                    local dp = (lr.Position - tp.Position).Magnitude
                    if dp >= 3 and dp <= (settings.silentRange or 800) then
                        local sp, on = camera:WorldToViewportPoint(tp.Position)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                            if d <= (settings.silentFov or 150) and d < bestD then
                                bestD = d best = tp
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

--// ===== SILENT: hook al Position:FireServer (el que REPORTA el daño) =====
-- Flujo real del GunFramework (decompilado):
--   1. Fire:FireServer(token, origen, dir) -> solo informa el disparo
--   2. la bala vuela LOCAL con raycast
--   3. al tocar un Humanoid: Position:FireServer(token, Id, parteGolpeada, u9.Direction, dmg, u100, tiempo)
--   4. el SERVER aplica el daño según ese reporte
-- => hookeamos Position.FireServer y reescribimos la parte golpeada por la
--    cabeza del target (y su dirección). El server aplica el daño.
local positionRemoteCached = nil
local hookLog = "" -- diagnostico de instalacion visible en el HUD
local function getPositionRemote()
    if positionRemoteCached and positionRemoteCached.Parent then return positionRemoteCached end
    local ok, rem = pcall(function()
        return ReplicatedStorage:WaitForChild("Modules", 5)
            :WaitForChild("GunFramework", 5):WaitForChild("Remotes", 5)
    end)
    if not (ok and rem) then hookLog = "sin carpeta Remotes" return nil end
    -- por nombre "Position" (algunos juegos) o por GUID 8-4-4-4-12 (este juego)
    local pos = rem:FindFirstChild("Position")
    if not pos then
        for _, v in ipairs(rem:GetChildren()) do
            if v:IsA("RemoteEvent")
            and v.Name:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x%x$") then
                pos = v break
            end
        end
    end
    if pos then positionRemoteCached = pos return pos end
    hookLog = "remote Position/GUID no encontrado"
    return nil
end

--// ===== SILENT: redirigir la BALA EN VUELO (hook al Projectile) =====
-- Decompile del Projectile (Modules.Projectile):
--   u14.new({Origin, Direction, Speed, RaycastParams}) crea la bala
--   u14:_Update(dt) la mueve con workspace:Raycast(Position, Velocity*dt, params)
--   si el raycast pega => self:OnHit(result) => GunClient manda Position:FireServer
-- Plan: hookear u14._Update para que la Velocity apunte al target => la bala
-- TOCA de verdad al target => el juego reporta el hit legitimo. Nada raro al server.
local projectileTable = nil
local oldUpdate = nil

local function findProjectileTable()
    -- via modulo directo (el require cachea la misma tabla)
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules", 5)
            :WaitForChild("GunFramework", 5):WaitForChild("Modules", 5)
            :WaitForChild("Projectile", 5))
    end)
    if ok and type(mod) == "table" and type(mod._Update) == "function" and type(mod.new) == "function" then
        return mod
    end
    -- via GC: tabla con _Update + new + Reflect + Destroy (firma exacta del decompile)
    if type(getgc) == "function" then
        for _, v in ipairs(getgc(false)) do
            if type(v) == "table" and rawget(v, "_Update") and rawget(v, "new") and rawget(v, "Reflect") and rawget(v, "Destroy") then
                return v
            end
        end
    end
    return nil
end

local function installHook()
    if hookInstalled or not HAS_HOOKS then return false end
    -- Plan A: hook al Projectile._Update (bala en vuelo, hit 100% legitimo)
    projectileTable = findProjectileTable()
    if projectileTable and type(hookfunction) == "function" then
        local okH, old = pcall(hookfunction, projectileTable._Update, function(self, dt)
            if not dead and settings.silentEnabled and not self._sbAimed then
                local tgt = pickTarget()
                if tgt and tgt.Parent then
                    local aim = tgt.Position + (tgt.Velocity * (settings.prediction or 0.12))
                    local nd = aim - self.Position
                    local mag = nd.Magnitude
                    local sp = self.Velocity.Magnitude
                    -- giro seguro: distancias y velocidades validas, sin NaN
                    if mag > 1 and mag == mag and sp > 50 and sp == sp then
                        local unit = nd / mag
                        if unit.X == unit.X and unit.Y == unit.Y and unit.Z == unit.Z then
                            self._sbAimed = true
                            self.Velocity = unit * sp
                            self.Direction = unit
                        end
                    end
                end
            end
            return old(self, dt)
        end)
        if okH and old then
            _G.__SB_OLDPROJ = old
            oldUpdate = old
            hookedFire = old
            hookInstalled = true
            hookLog = ""
            return true
        end
    end
    -- Plan B: hook al remote Position (reporte de hit)
    local pos = getPositionRemote()
    if pos and type(hookfunction) == "function" then
        local okH2, old2 = pcall(hookfunction, pos.FireServer, function(self, ...)
            local args = {...}
            if not dead and settings.silentEnabled and typeof(args[3]) == "Instance" then
                local tgt = pickTarget()
                if tgt and tgt.Parent then
                    args[3] = tgt
                    if typeof(args[4]) == "Vector3" then
                        local lr = myRoot()
                        local origin = lr and lr.Position or tgt.Position
                        local aim = tgt.Position + (tgt.Velocity * (settings.prediction or 0.12))
                        local nd = aim - origin
                        if nd.Magnitude > 0.1 then
                            args[4] = nd.Unit
                        end
                    end
                    return old2(self, table.unpack(args, 1, select("#", ...)))
                end
            end
            return old2(self, ...)
        end)
        if okH2 and old2 then
            _G.__SB_OLDPOS = old2
            hookedFire = old2
            hookInstalled = true
            hookLog = ""
            return true
        end
    end
    -- Plan C: hookmetamethod al Position
    if pos and type(hookmetamethod) == "function" then
        local okM, oldM = pcall(hookmetamethod, game, "__namecall", function(self, ...)
            if not dead and settings.silentEnabled and self == pos and getnamecallmethod() == "FireServer" then
                local args = {...}
                if typeof(args[3]) == "Instance" then
                    local tgt = pickTarget()
                    if tgt and tgt.Parent then
                        args[3] = tgt
                        if typeof(args[4]) == "Vector3" then
                            local lr = myRoot()
                            local origin = lr and lr.Position or tgt.Position
                            local aim = tgt.Position + (tgt.Velocity * (settings.prediction or 0.12))
                            local nd = aim - origin
                            if nd.Magnitude > 0.1 then
                                args[4] = nd.Unit
                            end
                        end
                        return _G.__SB_OLDNC(self, table.unpack(args, 1, select("#", ...)))
                    end
                end
            end
            return _G.__SB_OLDNC(self, ...)
        end)
        if okM and oldM then
            _G.__SB_OLDNC = oldM
            hookedFire = oldM
            hookInstalled = true
            hookLog = ""
            return true
        end
    end
    if hookLog == "" then hookLog = "ni Projectile ni remote encontrados" end
    return false
end

local function uninstallHook()
    if _G.__SB_OLDPROJ and projectileTable then
        pcall(hookfunction, projectileTable._Update, _G.__SB_OLDPROJ)
        _G.__SB_OLDPROJ = nil
    end
    if _G.__SB_OLDPOS and getPositionRemote() then
        pcall(hookfunction, getPositionRemote().FireServer, _G.__SB_OLDPOS)
        _G.__SB_OLDPOS = nil
    end
    if _G.__SB_OLDNC then
        pcall(hookmetamethod, game, "__namecall", _G.__SB_OLDNC)
        _G.__SB_OLDNC = nil
    end
    oldUpdate = nil
    hookedFire = nil
    hookInstalled = false
end

--// Contenido
local c1 = createCard("Silent")
local silentToggleRef = nil
local silentReverting = false
local function onSilentToggle(v)
    if silentReverting then return end
    settings.silentEnabled = v
    if v then
        local ok = installHook()
        if not ok then
            -- apagar el toggle sin re-entrar al callback
            silentReverting = true
            settings.silentEnabled = false
            if silentToggleRef then pcall(function() silentToggleRef.Set(false) end) end
            silentReverting = false
        end
    else
        uninstallHook()
    end
end
silentToggleRef = createToggle(c1, "Silent aim", onSilentToggle)
createDropdown(c1, "Punto", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v) settings.targetPart = v end)
createSlider(c1, "FOV", settings.silentFov, 40, 500, function(v) settings.silentFov = v end)
createSlider(c1, "Alcance", settings.silentRange, 50, 2000, function(v) settings.silentRange = v end)
createSlider(c1, "Chance", settings.silentHitChance, 0, 100, function(v) settings.silentHitChance = v end)
createSlider(c1, "Predicción", 12, 0, 50, function(v) settings.prediction = v / 100 end)

local c2 = createCard("Radar")
createToggle(c2, "Radar", function(v) settings.espEnabled = v end)
createToggle(c2, "Nombres", function(v) settings.espNames = v end, nil, true)
createToggle(c2, "Distancia", function(v) settings.espDistance = v end, nil, true)
createToggle(c2, "Vida", function(v) settings.espHealthBar = v end, nil, true)
createToggle(c2, "Caja", function(v) settings.espBox = v end, nil, true)
createToggle(c2, "Líneas", function(v) settings.espTracer = v end, nil, true)
createDropdown(c2, "Origen", {"Bottom", "Center"}, "Bottom", function(v) settings.tracerOrigin = v end)
createSlider(c2, "Lejos", settings.maxDistance, 100, 5000, function(v) settings.maxDistance = v end)

local c3 = createCard("Ajustes")
createDropdown(c3, "Tecla menú", {"RightShift", "Insert", "P", "L"}, "RightShift", function(v)
    settings.uiToggleKey = Enum.KeyCode[v]
end)
createButton(c3, "Quitar menú", function()
    uninstallHook()
    if _G.__SB_STOP then pcall(_G.__SB_STOP) end
    pcall(function() gui:Destroy() end)
end)

--// FOV círculo + estados
local fovFrame = Instance.new("Frame")
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1 fovFrame.Visible = false fovFrame.Parent = gui
local fovStroke = stroke(fovFrame, Color3.fromRGB(255, 255, 255), 1)
fovStroke.Transparency = 0.4
corner(fovFrame, 999)
local silentStatus = Instance.new("TextLabel")
silentStatus.Size = UDim2.new(0, 380, 0, 18) silentStatus.Position = UDim2.new(0, 10, 0, 10)
silentStatus.BackgroundTransparency = 1 silentStatus.Font = FONT_MAIN silentStatus.TextSize = 12
silentStatus.TextColor3 = COLOR_SUBTEXT silentStatus.TextStrokeTransparency = 0.5
silentStatus.Text = "" silentStatus.Parent = gui

--// Botón flotante
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 70, 0, 40) floatBtn.Position = UDim2.new(0, 30, 0, 120)
floatBtn.BackgroundColor3 = COLOR_CARD floatBtn.Font = FONT_TITLE floatBtn.TextSize = 14
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255) floatBtn.Text = "SB" floatBtn.Parent = gui corner(floatBtn, 12)
floatBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)

SCONN(UserInputService.InputBegan:Connect(function(inp, gp)
    if dead then return end
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == settings.uiToggleKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end))

--// ESP
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
local function clearESP(key)
    local o = espData[key]
    if o then
        safeDestroy(o.bb) safeDestroy(o.line) safeDestroy(o.box)
        espData[key] = nil
    end
end
local function buildESP(plr, char)
    clearESP(plr)
    local objs = {}
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 170, 0, 40) bb.StudsOffset = Vector3.new(0, 2.8, 0) bb.AlwaysOnTop = true
    bb:SetAttribute("SB1", true)
    bb.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    bb.Parent = char
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0, 16) name.BackgroundTransparency = 1
    name.Font = FONT_BOLD name.TextSize = 12 name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextStrokeTransparency = 0.4 name.Parent = bb objs.name = name
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -40, 0, 5) hpBg.Position = UDim2.new(0, 20, 0, 20)
    hpBg.BackgroundColor3 = Color3.fromRGB(25, 25, 35) hpBg.Parent = bb corner(hpBg, 99) objs.hpBg = hpBg
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0) hpFill.Parent = hpBg corner(hpFill, 99) objs.hpFill = hpFill
    objs.bb = bb
    espCharOf[plr] = char
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5) line.BorderSizePixel = 0 line.Visible = false line.Parent = gui objs.line = line
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1 box.Visible = false box.Parent = gui objs.box = box
    local bs = stroke(box, ACCENT, 1.2) objs.boxStroke = bs
    espData[plr] = objs
end
local espErr = nil
local function updateESP(plr)
    local char = plr.Character
    if not char or not char.Parent then clearESP(plr) return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not settings.espEnabled or not root then clearESP(plr) return end
    local objs = espData[plr]
    if not objs or espCharOf[plr] ~= char then buildESP(plr, char) objs = espData[plr] if not objs then return end end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local lr = myRoot()
    if not lr then return end
    local dist = math.floor((lr.Position - root.Position).Magnitude)
    local alive = hum ~= nil and hum.Health > 0
    if dist < 3 or dist > settings.maxDistance or not alive then
        objs.bb.Enabled = false objs.line.Visible = false objs.box.Visible = false
        return
    end
    local col = ACCENT
    objs.bb.Enabled = true
    local txt = ""
    if settings.espNames then txt = plr.DisplayName .. " " end
    if settings.espDistance then txt = txt .. "[" .. dist .. "m]" end
    objs.name.Text = txt ~= "" and txt or plr.Name
    objs.name.Visible = (settings.espNames or settings.espDistance)
    objs.name.TextColor3 = col
    objs.hpBg.Visible = settings.espHealthBar and hum ~= nil
    if hum and settings.espHealthBar then
        local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
        objs.hpFill.Size = UDim2.new(pct, 0, 1, 0)
        objs.hpFill.BackgroundColor3 = Color3.fromHSV(pct * 0.33, 1, 1)
    end
    if settings.espTracer then
        local sp, on = camera:WorldToViewportPoint(root.Position)
        if on then
            local vs = camera.ViewportSize local startV
            if settings.tracerOrigin == "Center" then startV = Vector2.new(vs.X / 2, vs.Y / 2)
            else startV = Vector2.new(vs.X / 2, vs.Y) end
            local endV = Vector2.new(sp.X, sp.Y)
            local d = (endV - startV).Magnitude
            objs.line.Size = UDim2.new(0, 1.25, 0, d)
            objs.line.Position = UDim2.new(0, (startV.X + endV.X) / 2, 0, (startV.Y + endV.Y) / 2)
            objs.line.Rotation = math.deg(math.atan2(endV.Y - startV.Y, endV.X - startV.X)) - 90
            objs.line.BackgroundColor3 = col objs.line.Visible = true
        else objs.line.Visible = false end
    else objs.line.Visible = false end
    if settings.espBox then
        local head = char:FindFirstChild("Head")
        local _, on = camera:WorldToViewportPoint(root.Position)
        if on then
            local top3d = head and (head.Position + Vector3.new(0, 0.6, 0)) or (root.Position + Vector3.new(0, 2.5, 0))
            local hp = camera:WorldToViewportPoint(top3d)
            local lp = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local h = math.abs(hp.Y - lp.Y) local w = h * 0.62
            if h > 4 then
                objs.box.Size = UDim2.new(0, w, 0, h)
                objs.box.Position = UDim2.new(0, hp.X - w / 2, 0, hp.Y)
                objs.box.Visible = true objs.boxStroke.Color = col
            else objs.box.Visible = false end
        else objs.box.Visible = false end
    else objs.box.Visible = false end
end
SCONN(Players.PlayerRemoving:Connect(function(plr)
    if not dead then clearESP(plr) espCharOf[plr] = nil end
end))

--// Loop principal
local espFrame = 0
local espDiagLast = 0
local silentDiagLast = 0
SCONN(RunService.RenderStepped:Connect(function(dt)
    if dead then return end
    local freshCam = workspace.CurrentCamera
    if freshCam then camera = freshCam end
    if not camera then return end
    local okLoop = pcall(function()
        local ml = UserInputService:GetMouseLocation()
        -- círculo FOV del silent
        local wantFov = settings.silentEnabled
        fovFrame.Visible = wantFov
        if wantFov then
            fovFrame.Position = UDim2.new(0, ml.X, 0, ml.Y)
            fovFrame.Size = UDim2.new(0, settings.silentFov * 2, 0, settings.silentFov * 2)
        end
        -- ESP
        espFrame = espFrame + 1
        if settings.espEnabled then
            for i, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer and (i + espFrame) % 2 == 0 then
                    local okE, errE = pcall(updateESP, p)
                    if not okE and not espErr then espErr = errE end
                end
            end
            local nowE = tick()
            if nowE - espDiagLast > 0.5 then
                espDiagLast = nowE
                if espErr then
                    silentStatus.Text = "Radar err: " .. tostring(espErr):sub(1, 80)
                    silentStatus.TextColor3 = Color3.fromRGB(255, 110, 120)
                    espErr = nil
                else
                    local nNear, nTot = 0, 0
                    local lrE = myRoot()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= localPlayer and p.Character then
                            nTot = nTot + 1
                            local rt = p.Character:FindFirstChild("HumanoidRootPart")
                            if rt and lrE and (lrE.Position - rt.Position).Magnitude <= settings.maxDistance then
                                nNear = nNear + 1
                            end
                        end
                    end
                    silentStatus.Text = string.format("Radar: %d/%d", nNear, nTot)
                    silentStatus.TextColor3 = (nNear > 0) and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(255, 200, 80)
                end
            end
        else
            for k, _ in pairs(espData) do clearESP(k) end
            if not settings.silentEnabled then
                silentStatus.Text = ""
            end
        end
        -- estado del silent: diagnsitico detallado
        if settings.silentEnabled then
            local nowS = tick()
            if nowS - silentDiagLast > 0.25 then
                silentDiagLast = nowS
                if not hookInstalled then
                    silentStatus.Text = "Silent: " .. (hookLog ~= "" and hookLog or "no hay hooks (usar Real)")
                    silentStatus.TextColor3 = Color3.fromRGB(255, 110, 120)
                else
                    -- contar candidatos y ver que encuentra el picker
                    local lr = myRoot()
                    if not lr then
                        silentStatus.Text = "Silent: sin personaje (respawnea)"
                        silentStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
                    else
                        local ml = UserInputService:GetMouseLocation()
                        local cAlive, cRange, cScreen, cFov = 0, 0, 0, 0
                        local nearestName, nearestD = "?", math.huge
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= localPlayer and p.Character then
                                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 then
                                    cAlive = cAlive + 1
                                    local tp = p.Character:FindFirstChild(settings.targetPart)
                                        or p.Character:FindFirstChild("Head")
                                        or p.Character:FindFirstChild("HumanoidRootPart")
                                    if tp then
                                        local dp = (lr.Position - tp.Position).Magnitude
                                        if dp <= (settings.silentRange or 800) then
                                            cRange = cRange + 1
                                            local sp, on = camera:WorldToViewportPoint(tp.Position)
                                            if on then
                                                cScreen = cScreen + 1
                                                local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                                                if d < nearestD then nearestD = d nearestName = p.DisplayName end
                                                if d <= (settings.silentFov or 150) then
                                                    cFov = cFov + 1
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        local tgt = pickTarget()
                        local modo = _G.__SB_OLDPROJ and "BALA" or "REPORTE"
                        if tgt then
                            silentStatus.Text = string.format("[%s] OBJETIVO: %s | disparale a cualquier cosa", modo, tostring(tgt.Parent and tgt.Parent.Name or "?"))
                            silentStatus.TextColor3 = Color3.fromRGB(80, 255, 130)
                        else
                            silentStatus.Text = string.format("SIN OBJETIVO | vivos:%d cerca:%d pant:%d fov:%d", cAlive, cRange, cScreen, cFov)
                            silentStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
                        end
                    end
                end
            end
        end
    end)
    if not okLoop then
        -- silencioso a propósito
    end
end))

--// Mostrar
mainFrame.Visible = true
