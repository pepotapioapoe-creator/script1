local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local localPlayer = game:GetService("Players").LocalPlayer
local mouse = localPlayer and localPlayer:GetMouse()
local camera = workspace.CurrentCamera
local orbitAngle = 0
local ZV = _G.ZV
assert(ZV and ZV.settings and ZV.updateESP, "Falta P1/P2")
local settings = ZV.settings
local gui = ZV.gui
local notify = ZV.notify
local tween = ZV.tween
local myRoot = ZV.myRoot
local myHum = ZV.myHum
local targetRootOf = ZV.targetRootOf
local isAlive = ZV.isAlive
local sameTeam = ZV.sameTeam
local hasWallBetween = ZV.hasWallBetween
local rayParams = ZV.rayParams
local Accent = ZV.Accent
local hitboxOriginals = ZV.hitboxOriginals
local DEFAULT_SPEED = ZV.DEFAULT_SPEED
local DEFAULT_JUMP = ZV.DEFAULT_JUMP
local updateESP = ZV.updateESP
local clearESP = ZV.clearESP
local espData = ZV.espData
local espCharOf = ZV.espCharOf
local refreshPlayers = ZV.refreshPlayers
local getAimPart = ZV.getAimPart
local aimRefPoint = ZV.aimRefPoint
local fovFrame = ZV.fovFrame
local fovDot = ZV.fovDot
local fovStroke = ZV.fovStroke
local aimStatus = ZV.aimStatus
local silentStatus = ZV.silentStatus
local statsLabel = ZV.statsLabel
local aimBtn = ZV.aimBtn
local flyUpBtn = ZV.flyUpBtn
local flyDownBtn = ZV.flyDownBtn
local loadBar = ZV.loadBar
local loader = ZV.loader
local mainFrame = ZV.mainFrame
local dprint = ZV.dprint
local SILENT_PROFILES = ZV.SILENT_PROFILES
local COLOR_SUBTEXT = ZV.COLOR_SUBTEXT
local discreetText = ZV.discreetText
--// SILENT AIM 👻 (redirige tiros sin mover la cámara)
settings.silentBone = settings.silentBone or "Same as Aimbot"
local silentHooked = false
local silentBypass = false -- en true = son nuestros propios raycasts (wallcheck), no redirigir
local silentFlash = 0 -- feedback visual: el FOV parpadea cuando el silent redirige un tiro
local silentRedirects = 0 -- telemetría: tiros redirigidos en total
local silentLastTarget = nil -- último objetivo adquirido
local diagLast, diagF9Last = 0, 0 -- throttles del panel y del F9
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
    local ml = aimRefPoint()
    local lr = myRoot()
    local bestPart, bestD = nil, settings.silentFov
    for _, p in ipairs(Players:GetPlayers()) do
        -- en bruto (juegos sin Humanoid como BloxStrike) basta con tener personaje
        local sAlive = (settings.aimBrute and p.Character ~= nil) or isAlive(p)
        if p ~= localPlayer and sAlive and not sameTeam(p, localPlayer) then
            local part = getAimPart(p.Character, bone)
            if part and lr and (lr.Position - part.Position).Magnitude <= settings.maxDistance then
                -- wallbang ON = el silent ignora paredes (pega tras pared si el server no valida LOS)
                local blocked = false
                if not settings.wallbangEnabled then
                    silentBypass = true
                    blocked = hasWallBetween(camera.CFrame.Position, part.Position, part)
                    silentBypass = false
                end
                if not blocked then
                    local sp, on = camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                        if d <= settings.silentFov and d < bestD then
                            bestD = d bestPart = part
                        end
                    end
                end
            end
        end
    end
    if not bestPart and settings.aimNpcs then
        -- bots: también para el silent (si tus enemigos no son Players, aquí los encuentra)
        local function scanS(c)
            for _, m in ipairs(c:GetChildren()) do
                if bestPart then break end
                if m:IsA("Model") and m ~= localPlayer.Character
                and not Players:GetPlayerFromCharacter(m) then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if settings.aimBrute or (hum and hum.Health > 0) then
                        local part = getAimPart(m, bone)
                        if part and lr and (lr.Position - part.Position).Magnitude <= settings.maxDistance then
                            local blocked = false
                            if not settings.wallbangEnabled then
                                silentBypass = true
                                blocked = hasWallBetween(camera.CFrame.Position, part.Position, part)
                                silentBypass = false
                            end
                            if not blocked then
                                local sp, on = camera:WorldToViewportPoint(part.Position)
                                if on then
                                    local d = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                                    if d <= settings.silentFov and d < bestD then
                                        bestD = d
                                        bestPart = part
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        scanS(workspace)
        for _, c in ipairs(workspace:GetChildren()) do
            if not bestPart and c:IsA("Folder") then scanS(c) end
        end
    end
    if bestPart then
        local pred = settings.silentPrediction or 0.12
        local vel = bestPart.Velocity
        if vel.Magnitude > 60 then vel = vel.Unit * 60 end -- anti-fling loco
        pcall(function()
            local m = bestPart:FindFirstAncestorOfClass("Model")
            local pl = m and Players:GetPlayerFromCharacter(m)
            silentLastTarget = pl and pl.DisplayName or (m and m.Name) or "?"
        end)
        return bestPart.Position + (vel * pred), bestPart
    end
    return nil
end
--// MAGIC BULLETS: tus proyectiles doblan su vuelo hacia el objetivo (respeta FOV, equipo, hitchance).
-- Detecta piezas que NACEN cerca tuyo, en movimiento y alejándose (tus balas), e ignora el resto.
local trackedBullets = {}
local magicAcquired = 0 -- telemetría: balas con objetivo asignado
workspace.DescendantAdded:Connect(function(inst)
    if gui.Parent == nil then return end
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
    -- hitchance una sola vez por bala: o vuela teledirigida o recta (parece legit)
    local _, tgt = getSilentHitPos()
    local realTgt = (tgt and tgt.Parent) and tgt or nil
    trackedBullets[inst] = {t0 = tick(), target = realTgt}
    if realTgt then magicAcquired = magicAcquired + 1 end
    if realTgt and not settings.magicNotified then
        settings.magicNotified = true
        notify("Magic Bullets", "Objetivo adquirido: curvando balas.")
    end
end)
RunService.Heartbeat:Connect(function()
    if gui.Parent == nil then return end
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
--// SPY: registra qué manda tu arma (remotes/raycasts) en la consola F9. Solo LEE, indetectable.
-- Úsalo una vez por juego: dispara varias veces, abre F9 y pasa el log para adaptar el silent exacto.
local spyHooked = false
local spyLast, spyTotal = {}, 0
function tryEnableSpy()
    if spyHooked then notify("Spy", "Ya instalado. Dispara y abre la consola (F9).") return end
    local ok, msg = pcall(function()
        local hm = hookmetamethod
        local gncm = getnamecallmethod
        local chk = checkcaller
        local nc = (newcclosure and newcclosure) or function(f) return f end
        if not (hm and gncm) then error("executor sin hookmetamethod") end
        local oldSpy
        oldSpy = hm(game, "__namecall", nc(function(self, ...)
            local method = gncm()
            if settings.spyEnabled then
                local s, r = pcall(chk)
                if not (s and r) then
                    if method == "FireServer" or method == "InvokeServer" or method == "Raycast"
                    or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList"
                    or method == "FindPartOnRayWithWhitelist" or method == "Fire" then
                        local nm = "?"
                        pcall(function() nm = self:GetFullName() end)
                        local key = method .. "|" .. nm
                        local now = tick()
                        if (spyLast[key] or 0) + 2 < now and spyTotal < 60 then
                            spyLast[key] = now
                            spyTotal = spyTotal + 1
                            local n = select("#", ...)
                            local parts = {}
                            for i = 1, n do
                                local a = select(i, ...)
                                local t = typeof(a)
                                if t == "Vector3" then parts[#parts + 1] = "V3" .. tostring(a)
                                elseif t == "CFrame" then parts[#parts + 1] = "CF" .. tostring(a.Position)
                                elseif t == "Ray" then parts[#parts + 1] = "Ray" .. tostring(a.Origin)
                                elseif t == "Instance" then
                                    local an = "?"
                                    pcall(function() an = a:GetFullName() end)
                                    parts[#parts + 1] = "Inst:" .. an
                                else parts[#parts + 1] = t end
                            end
                            dprint("[ZVOLT-SPY]", method, nm, "n=" .. n, table.concat(parts, " | "))
                        end
                    end
                end
            end
            return oldSpy(self, ...)
        end))
        spyHooked = true
    end)
    if spyHooked then notify("Spy", "Instalado. Dispara varias veces y abre F9.")
    else notify("Spy", "Sin soporte de hooks: " .. tostring(msg)) end
end
local spyProjLast = 0
workspace.DescendantAdded:Connect(function(inst)
    if gui.Parent == nil then return end
    if not settings.spyEnabled then return end
    if not inst or not inst:IsA("BasePart") or inst.Anchored then return end
    local mr = myRoot()
    if not mr then return end
    if (inst.Position - mr.Position).Magnitude > 30 then return end
    if inst.AssemblyLinearVelocity.Magnitude < 30 then return end
    local now = tick()
    if now - spyProjLast < 1 then return end
    spyProjLast = now
    local pn = "?"
    pcall(function() pn = inst:GetFullName() end)
    dprint("[ZVOLT-SPY] parte rápida cerca:", pn, "vel:", math.floor(inst.AssemblyLinearVelocity.Magnitude))
end)
function tryEnableSilentAim()
    if silentHooked then return end
    local ok, msg = pcall(function()
        local hm = hookmetamethod
        local gncm = getnamecallmethod
        local chk = checkcaller
        local nc = (newcclosure and newcclosure) or function(f) return f end
        if not (hm and gncm) then error("executor sin hookmetamethod") end
        -- Hook único __namecall: 1) raycasts del cliente 2) remotes con hitreg en servidor
        -- Muchos juegos NUNCA hacen Raycast en el cliente: mandan FireServer(pos) y el server registra.
        -- Por eso se escanea cualquier Vector3 cercano a tu punto de mira y se cambia por el enemigo.
        local oldNC
        oldNC = hm(game, "__namecall", nc(function(self, ...)
            local method = gncm()
            local n = select("#", ...)
            local args = table.pack(...)
            local function isExploitCall()
                if chk then local s, r = pcall(chk) if s and r then return true end end
                return false
            end
            if settings.silentAimEnabled and not silentBypass and not isExploitCall() then
                if method == "Raycast" then
                    local origin, dir = args[1], args[2]
                    if origin and dir and typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude > 0 then
                        local hitPos = getSilentHitPos()
                        if hitPos then
                            local ndir = (hitPos - origin)
                            if ndir.Magnitude > 0 then
                                local nargs = {origin, ndir.Unit * dir.Magnitude}
                                for i = 3, n do nargs[i] = args[i] end
                                silentFlash = 0.2
                                silentRedirects = silentRedirects + 1
                                return oldNC(self, table.unpack(nargs, 1, math.max(n, 2)))
                            end
                        end
                    end
                elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
                    local ray = args[1]
                    if ray and typeof(ray) == "Ray" then
                        local hitPos = getSilentHitPos()
                        if hitPos then
                            local ndir = (hitPos - ray.Origin)
                            if ndir.Magnitude > 0 then
                                local newRay = Ray.new(ray.Origin, ndir.Unit * ray.Direction.Magnitude)
                                local nargs = {newRay}
                                for i = 2, n do nargs[i] = args[i] end
                                silentFlash = 0.2
                                silentRedirects = silentRedirects + 1
                                return oldNC(self, table.unpack(nargs, 1, math.max(n, 1)))
                            end
                        end
                    end
                elseif method == "FireServer" or method == "InvokeServer" then
                    local hitPos = getSilentHitPos()
                    if hitPos then
                        -- 0) perfil del juego: reemplazo quirúrgico si conocemos su remote (video style)
                        do
                            local prof = SILENT_PROFILES[settings.silentGame]
                            local rname = nil
                            pcall(function() rname = self:GetFullName() end)
                            if prof and prof.remote and rname == prof.remote then
                                local o = args[prof.originIdx or 1]
                                if o and typeof(o) == "Vector3" then
                                    local nargs = {}
                                    for i = 1, n do nargs[i] = args[i] end
                                    local ch = false
                                    if prof.dirIdx and nargs[prof.dirIdx] and typeof(nargs[prof.dirIdx]) == "Vector3" then
                                        local nd = hitPos - o
                                        if nd.Magnitude > 0.5 then
                                            nargs[prof.dirIdx] = nd.Unit * nargs[prof.dirIdx].Magnitude
                                            ch = true
                                        end
                                    end
                                    if prof.hitIdx and nargs[prof.hitIdx] and typeof(nargs[prof.hitIdx]) == "Vector3" then
                                        nargs[prof.hitIdx] = hitPos
                                        ch = true
                                    end
                                    if ch then
                                        silentFlash = 0.2
                                        silentRedirects = silentRedirects + 1
                                        return oldNC(self, table.unpack(nargs, 1, n))
                                    end
                                end
                            end
                        end
                        silentBypass = true
                        local aimRef = nil
                        pcall(function() aimRef = mouse.Hit.Position end)
                        silentBypass = false
                        local lr = myRoot()
                        if aimRef and lr then
                            local nargs = {}
                            for i = 1, n do nargs[i] = args[i] end
                            local changed = false
                            -- 1) pares (origen, dirección): el formato más común (el server hace el raycast).
                            -- Antes solo se tocaban posiciones y a veces se cambiaba el ORIGEN por error.
                            for i = 1, n - 1 do
                                local a, b = nargs[i], nargs[i + 1]
                                if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
                                    local bm = b.Magnitude
                                    local isDir = (bm > 0.85 and bm < 1.15)
                                        or (bm > 1 and (b - aimRef).Magnitude > 30)
                                    if isDir and (a - lr.Position).Magnitude < 25 then
                                        local nd = hitPos - a
                                        if nd.Magnitude > 0.5 then
                                            nargs[i + 1] = nd.Unit * bm
                                            changed = true
                                        end
                                    end
                                end
                            end
                            -- 2) Vector3 de POSICIÓN cerca de tu mira pero LEJOS de ti (nunca el origen).
                            for i = 1, n do
                                local a = nargs[i]
                                if typeof(a) == "Vector3" then
                                    local dAim = (a - aimRef).Magnitude
                                    local dMe = (a - lr.Position).Magnitude
                                    if dAim > 3 and dAim <= 30 and dMe > 20 then
                                        nargs[i] = hitPos
                                        changed = true
                                    end
                                end
                            end
                            if changed then
                                silentFlash = 0.2
                                silentRedirects = silentRedirects + 1
                                return oldNC(self, table.unpack(nargs, 1, n))
                            end
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
                        silentFlash = 0.2
                        silentRedirects = silentRedirects + 1
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
    if not (settings.isAiming or settings.aimMobile or settings.aimAuto) then restoreCamType() return end
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
    RunService:BindToRenderStep("ZV_Aimbot", Enum.RenderPriority.Last.Value, function() reapplyAim() end)
end)

--// Loops principales
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local aimDeepLast = 0
local lastAimPart = nil -- último objetivo: se re-aplica post-cámara aunque el juego la pise
local espFrame, noclipLast, fbLastRefresh = 0, 0, 0 -- acumuladores de rendimiento
RunService.RenderStepped:Connect(function(dt)
    if gui.Parent == nil then return end
    -- La cámara puede ser REEMPLAZADA por el juego (rondas/respawns). Si usamos la vieja,
    -- todo da mal (pant:0) y escribimos en una cámara invisible. Re-leer cada frame lo arregla.
    local freshCam = workspace.CurrentCamera
    if freshCam then camera = freshCam end
    if not camera then return end
    -- red de seguridad: cualquier error aquí saldría a consola con "loadstring" (baneable)
    local okLoop, errLoop = pcall(function()
    -- FOV UI
    local ml = aimRefPoint()
    local wantFov = (settings.aimEnabled or settings.silentAimEnabled) and settings.showFov
    fovFrame.Visible = wantFov
    aimBtn.Visible = settings.aimEnabled and isTouch
    flyUpBtn.Visible = settings.flyEnabled and isTouch
    flyDownBtn.Visible = settings.flyEnabled and isTouch
    if silentFlash > 0 then silentFlash = math.max(0, silentFlash - dt) end
    if wantFov then
        -- cada aim usa su propio radio: el círculo muestra el del aimbot, o el del silent si solo ese está activo
        local fr = (settings.aimEnabled and settings.fovRadius) or settings.silentFov
        fovFrame.Position = UDim2.new(0, ml.X, 0, ml.Y)
        fovFrame.Size = UDim2.new(0, fr * 2, 0, fr * 2)
        fovDot.Position = UDim2.new(0.5, 0, 0.5, 0)
        if settings.fovRainbow then fovStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else fovStroke.Color = Accent() end
        fovDot.BackgroundColor3 = fovStroke.Color
        -- el círculo se engrosa un instante cuando el silent redirige un tiro (confirmación visual)
        fovStroke.Thickness = (silentFlash > 0) and 3.5 or 1.6
    end
    -- ESP intercalado: mitad de jugadores por frame (se ve igual, cuesta la mitad)
    espFrame = espFrame + 1
    if settings.espEnabled then
        for i, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and (i + espFrame) % 2 == 0 then pcall(updateESP, p) end
        end
    else
        for p, _ in pairs(espData) do clearESP(p) end
    end
    -- Aimbot estilo V1: RenderStepped plano, sin filtros extra. Fórmula del original que sí funciona.
    -- El estado muestra el embudo (vivos -> con parte -> en pantalla) para ver qué filtra a todos.
    do
        local trigV1 = settings.isAiming or settings.aimMobile or settings.aimAuto
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
                aimStatus.Text = discreetText("AIM: LOCK " .. tostring(bestNameV1))
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
                            dprint(string.format("[ZVOLT-DEEP] %s | hum=%s hp=%s head=%s hrp=%s | pant=%s(%s) dist=%s",
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
    -- Telemetría silent/magic en pantalla + F9 (para diagnosticar qué no redirige)
    do
        local showS = settings.silentAimEnabled or settings.magicBulletsEnabled
        if not showS then
            silentStatus.Text = ""
        else
            local nowD = tick()
            if nowD - diagLast > 0.25 then
                diagLast = nowD
                local tracked = 0
                for _ in pairs(trackedBullets) do tracked = tracked + 1 end
                local t = "HOOKS:" .. ((hookmetamethod ~= nil) and "OK" or "FALTA")
                if settings.silentAimEnabled then
                    t = t .. " | SILENT:" .. (silentLastTarget or "sin objetivo")
                        .. " hits:" .. tostring(silentRedirects)
                end
                if settings.magicBulletsEnabled then
                    t = t .. " | MAGIC: rastreadas:" .. tracked .. " dirigidas:" .. magicAcquired
                end
                silentStatus.Text = discreetText(t)
                if nowD - diagF9Last > 4 then
                    diagF9Last = nowD
                    dprint(string.format(
                        "[ZVOLT-DIAG] hooks=%s silent=%s magic=%s target=%s redirects=%d magic_tracked=%d magic_acquired=%d fov=%d/%d hitchance=%d perfil=%s",
                        (hookmetamethod ~= nil) and "OK" or "FALTA",
                        tostring(settings.silentAimEnabled),
                        tostring(settings.magicBulletsEnabled),
                        tostring(silentLastTarget or "-"),
                        silentRedirects, tracked, magicAcquired,
                        settings.fovRadius, settings.silentFov,
                        settings.silentHitChance, tostring(settings.silentGame)))
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
        if h and not settings.flyEnabled and settings.spectating == false then
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
        local wantSpeed = settings.speedEnabled and settings.customSpeed or DEFAULT_SPEED
        if ch.WalkSpeed ~= wantSpeed then ch.WalkSpeed = wantSpeed end
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
    if gui.Parent == nil then return end
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
        if settings.flyUp then mv = mv + Vector3.new(0, 1, 0) end
        if settings.flyDown then mv = mv - Vector3.new(0, 1, 0) end
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
        if gui.Parent == nil then break end
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
        -- wallbang REAL = el silent ignora paredes (ver getSilentHitPos) + X-ray para verlos.
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
        if gui.Parent == nil then break end
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
localPlayer.CharacterAdded:Connect(function()
    if gui.Parent == nil then return end
    task.wait(0.5)
    table.clear(hitboxOriginals) orbitAngle = 0
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
notify("ZVOLT V2.40 SRC", "Cargado. Usa cuenta alt. RightShift = ocultar.")
dprint("[ZVOLT V2.40 SRC] cargado OK - etiquetas discretas de fabrica")
if hookmetamethod == nil then
    notify("Executor limitado", "Sin hookmetamethod: Silent y SPY no funcionan aquí. Aimbot, ESP, Trigger, Hitbox y Magic sí.")
    dprint("[ZVOLT] executor sin hookmetamethod: silent/SPY desactivados por hardware")
end

print("P3 OK")
