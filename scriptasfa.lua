local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local localPlayer = game:GetService("Players").LocalPlayer
local mouse = localPlayer and localPlayer:GetMouse()
local ZV = _G.ZV
assert(ZV and ZV.settings, "Falta P1")
local settings = ZV.settings
local gui = ZV.gui
local mainFrame = ZV.mainFrame
local pages = ZV.pages
local createCard = ZV.createCard
local createToggle = ZV.createToggle
local createSlider = ZV.createSlider
local createButton = ZV.createButton
local createDropdown = ZV.createDropdown
local notify = ZV.notify
local tween = ZV.tween
local corner = ZV.corner
local stroke = ZV.stroke
local Accent = ZV.Accent
local Accent2 = ZV.Accent2
local TagAccent = ZV.TagAccent
local RefreshTheme = ZV.RefreshTheme
local ghostBlock = ZV.ghostBlock
local riskyToggles = ZV.riskyToggles
local SILENT_PROFILES = ZV.SILENT_PROFILES
local THEMES = ZV.THEMES
local COLOR_CARD = ZV.COLOR_CARD
local COLOR_CARD2 = ZV.COLOR_CARD2
local COLOR_TEXT = ZV.COLOR_TEXT
local COLOR_SUBTEXT = ZV.COLOR_SUBTEXT
local FONT_MAIN = ZV.FONT_MAIN
local FONT_BOLD = ZV.FONT_BOLD
local FONT_TITLE = ZV.FONT_TITLE
local logoGrad = ZV.logoGrad
local myRoot = ZV.myRoot
local myHum = ZV.myHum
local targetRootOf = ZV.targetRootOf
local restoreDefaults = ZV.restoreDefaults
local restoreLighting = ZV.restoreLighting
local toggleStates = ZV.toggleStates
local sameTeam = ZV.sameTeam
local dprint = ZV.dprint
local keybinds = ZV.keybinds
local origLighting = ZV.origLighting
local applyDiscreet = ZV.applyDiscreet
local m3 = createCard(pages["movement"], "🌀 Extra", 190)
local tSpin
tSpin = createToggle(m3, "Spin ⚠️", function(v)
    if v and ghostBlock() then tSpin.Set(false) return end
    settings.spinEnabled = v
end, "spinbot")
table.insert(riskyToggles, tSpin)
createSlider(m3, "Velocidad spin", settings.spinSpeed, 5, 200, function(v) settings.spinSpeed = v end)
local tJerk
tJerk = createToggle(m3, "Jerk ⚠️", function(v)
    if v and ghostBlock() then tJerk.Set(false) return end
    settings.jerkEnabled = v
end)
table.insert(riskyToggles, tJerk)
createSlider(m3, "Fuerza", settings.jerkPower, 1, 10, function(v) settings.jerkPower = v end)
local tCtrl
tCtrl = createToggle(m3, "Click TP 🖱️", function(v)
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
tTap = createToggle(m3, "Toque TP", function(v)
    if v and ghostBlock() then tTap.Set(false) return end
    settings.tapTp = v
end)
table.insert(riskyToggles, tTap)
UserInputService.TouchTapInWorld:Connect(function(pos, processed)
    if gui.Parent == nil then return end
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
createToggle(m3, "Cam", function(v)
    settings.freecam = v
    if not v then restoreFreecam() end
end)
RunService.RenderStepped:Connect(function(dt)
    if gui.Parent == nil then return end
    if not settings.freecam then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
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
local t1 = createCard(pages["teleport"], "📍 Viajes", 380)
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
Players.PlayerAdded:Connect(function() if gui.Parent ~= nil then refreshPlayers() end end)
Players.PlayerRemoving:Connect(function() if gui.Parent ~= nil then refreshPlayers() end end)
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
        if gui.Parent == nil then break end
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
tTrack = createToggle(tr1, "Track", function(v)
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
tFling = createToggle(tr2, "Push", function(v)
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
    settings.spectateEnabled = v settings.spectating = v
    if not v then pcall(function() workspace.CurrentCamera.CameraSubject = myHum() end) end
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
tAmmo = createToggle(w1, "Munición ♾️", function(v)
    if v and ghostBlock() then tAmmo.Set(false) return end
    settings.ammoEnabled = v
end)
table.insert(riskyToggles, tAmmo)
local tRapid
tRapid = createToggle(w1, "Rapid", function(v)
    if v and ghostBlock() then tRapid.Set(false) return end
    settings.rapidFire = v
end)
table.insert(riskyToggles, tRapid)
createButton(w1, "🧹 Reset cámara", function()
    camera.FieldOfView = 70 notify("Weapon", "Cámara reseteada.")
end, false)
createButton(w1, "🔍 Ver arma · F9", function()
    local tp = settings.selectedTpPlayer
    if tp and tp.Character then
        for _, t in ipairs(tp.Character:GetChildren()) do
            if t:IsA("Tool") then dprint("[ZVOLT] " .. tp.Name .. " tiene: " .. t.Name) end
        end
        notify("Weapon", "Revisa la consola (F9).")
    end
end, false)

-- WORLD
local wo1 = createCard(pages["world"], "🌍 Iluminación & Mapa", 190)
createToggle(wo1, "Brillo 💡", function(v)
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
createToggle(wo2, "AntiAFK ☕", function(v) settings.antiAfk = v end)
createToggle(wo2, "Sin sombras", function(v)
    settings.noShadows = v
    if v then Lighting.GlobalShadows = false
    else Lighting.GlobalShadows = (origLighting.GlobalShadows == nil) and true or origLighting.GlobalShadows end
end)
createButton(wo2, "🚀 FPS", function()
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
    settings.magicBulletsEnabled = false
    settings.triggerbot = false settings.tapTp = false settings.tpFollow = false
    settings.jerkEnabled = false
    restoreDefaults()
    pcall(function() workspace.Gravity = 196.2 end)
end
local cfGhost = createCard(pages["config"], "👻 Fantasma", 90)
local tGhost
tGhost = createToggle(cfGhost, "FANTASMA", function(v)
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
createToggle(cf1, "Radar color", function(v) settings.espRainbow = v end)
createButton(cf1, "🔄 Resetear todo", function()
    settings.ghostMode = false
    pcall(function() tGhost.Set(false) end)
    applyGhostOff()
    for _, s in pairs(toggleStates) do pcall(function() s.Set(false) end) end
    restoreDefaults() workspace.Gravity = 196.2 restoreLighting()
    pcall(restoreCamType) pcall(restoreFreecam)
    pcall(function() workspace.CurrentCamera.CameraSubject = myHum() workspace.CurrentCamera.FieldOfView = 70 end)
    notify("Config", "Todo reseteado y huellas limpiadas.")
end, false)

local cf2 = createCard(pages["config"], "⌨️ Keybinds", 330)
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
keyRow(cf2, "Aim", "aimbot") keyRow(cf2, "Radar", "esp") keyRow(cf2, "Clip", "noclip")
keyRow(cf2, "Vuelo", "fly") keyRow(cf2, "Hit", "hitbox") keyRow(cf2, "Spin", "spinbot")
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
createButton(cf3, "🎲 Servidor", function()
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
createButton(cf3, "🗑️ Cerrar", function()
    restoreDefaults() restoreLighting()
    pcall(function() workspace.Gravity = 196.2 end)
    pcall(function() RunService:UnbindFromRenderStep("ZV_Aimbot") end)
    pcall(restoreCamType) pcall(restoreFreecam)
    pcall(function() workspace.CurrentCamera.CameraSubject = myHum() workspace.CurrentCamera.FieldOfView = 70 end) gui:Destroy()
end, false)

--// Botón flotante fresco
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 96, 0, 44) floatBtn.Position = UDim2.new(0, 30, 0, 120)
floatBtn.BackgroundColor3 = COLOR_CARD floatBtn.Font = FONT_TITLE floatBtn.TextSize = 14
floatBtn.TextColor3 = Color3.fromRGB(255,255,255) floatBtn.Text = "ZV" floatBtn.Parent = gui corner(floatBtn, 12)
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
            if txt == "▲" then settings.flyUp = true else settings.flyDown = true end
            b.BackgroundColor3 = Accent() b.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end)
    b.InputEnded:Connect(function(i)
        settings.flyUp = false settings.flyDown = false
        b.BackgroundColor3 = COLOR_CARD b.TextColor3 = Accent()
    end)
    return b
end
local flyUpBtn = flyTouchBtn("▲", UDim2.new(1, -164, 0.5, -70))
local flyDownBtn = flyTouchBtn("▼", UDim2.new(1, -164, 0.5, 0))
aimBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then settings.aimMobile = true aimBtn.BackgroundColor3 = Accent() aimBtn.TextColor3 = Color3.fromRGB(0,0,0) end end)
aimBtn.InputEnded:Connect(function(i) settings.aimMobile = false aimBtn.BackgroundColor3 = COLOR_CARD aimBtn.TextColor3 = Accent() end)

applyDiscreet()

--// Inputs globales
local aimingPC = false
local isAimingRightClick = false
UserInputService.InputBegan:Connect(function(inp, gp)
    if gui.Parent == nil then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then settings.aimPC = true settings.isAiming = true end
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
            if r and mouse and mouse.Hit then r.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) r.Velocity = Vector3.zero end
        end
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if gui.Parent == nil then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then settings.aimPC = false settings.isAiming = false end
end)
-- anti afk
Players.LocalPlayer.Idled:Connect(function()
    if gui.Parent == nil then return end
    if settings.antiAfk then game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end
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
        hl.FillColor = espColor() hl.OutlineColor = espColor()
        hl.DepthMode = (settings.espXray ~= false) and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        hl:SetAttribute("ZV2", true)
        hl.Parent = char objs.hl = hl
    end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 170, 0, 46) bb.StudsOffset = UDim2.new(0, 2.8, 0) bb.AlwaysOnTop = true
    bb:SetAttribute("ZV2", true)
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
    local camera = workspace.CurrentCamera
    local char = plr.Character local root = char and char:FindFirstChild("HumanoidRootPart")
    if not settings.espEnabled or not char or not root then clearESP(plr) return end
    local objs = espData[plr]
    if not objs or espCharOf[plr] ~= char then buildESP(plr, char) objs = espData[plr] if not objs then return end end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local lr = myRoot()
    if not lr then return end
    if not hum and not settings.aimBrute then return end
    local dist = math.floor((lr.Position - root.Position).Magnitude)
    if dist > settings.maxDistance or (hum and hum.Health <= 0) then
        objs.bb.Enabled = false objs.line.Visible = false objs.box.Visible = false
        if objs.hl then objs.hl.Enabled = false end
        return
    end
    local col = espColor()
    -- con Team Check: aliados en verde, enemigos con el color del tema
    if settings.teamCheck and sameTeam(plr, localPlayer) then
        col = Color3.fromRGB(90, 255, 130)
    end
    objs.bb.Enabled = true
    if objs.hl then
        objs.hl.Enabled = true
        objs.hl.DepthMode = (settings.espXray ~= false) and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
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
Players.PlayerRemoving:Connect(function(plr) if gui.Parent ~= nil then clearESP(plr) espCharOf[plr] = nil end end)

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
_G.ZV.updateESP = updateESP
_G.ZV.clearESP = clearESP
_G.ZV.espData = espData
_G.ZV.espCharOf = espCharOf
_G.ZV.refreshPlayers = refreshPlayers
_G.ZV.getAimPart = getAimPart
_G.ZV.aimRefPoint = aimRefPoint
_G.ZV.aimBtn = aimBtn
_G.ZV.flyUpBtn = flyUpBtn
_G.ZV.flyDownBtn = flyDownBtn
print("P2 OK")
