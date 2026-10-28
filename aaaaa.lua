--[[
    SILENT AIM DEFINITIVO — GunFramework (Hook de Remote Position:FireServer)
    Fuerza el impacto real en el servidor sin que este lo rechace.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Settings = {
    Enabled = true,
    FOV = 200,               -- Rango del FOV en píxeles
    HitPart = "Head",        -- Parte objetivo ("Head" para matar rápido)
    MaxRange = 3000,
    Prediction = 0.12
}

-- 1. Lógica de Targeting (Encontrar al enemigo más cercano en pantalla)
local function GetBestTarget()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local closestTarget = nil
    local shortestDist = Settings.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local enemyChar = player.Character
            local humanoid = enemyChar:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                -- Evitar compañeros de equipo si el juego tiene equipos
                if player.Team ~= localPlayer.Team or not player.Team then
                    local targetPart = enemyChar:FindFirstChild(Settings.HitPart) or enemyChar:FindFirstChild("Head") or enemyChar:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart then
                        local distance3D = (myRoot.Position - targetPart.Position).Magnitude
                        if distance3D <= Settings.MaxRange then
                            local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                            
                            if onScreen then
                                local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if dist2D <= shortestDist then
                                    shortestDist = dist2D
                                    closestTarget = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- 2. Localizar el RemoteEvent "Position" (visto en el código fuente de GunClient)
local function GetPositionRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Modules") 
        and ReplicatedStorage.Modules:FindFirstChild("GunFramework") 
        and ReplicatedStorage.Modules.GunFramework:FindFirstChild("Remotes")
    
    if remotes then
        local pos = remotes:FindFirstChild("Position")
        if pos then return pos end
        -- Búsqueda por patrón UUID si el nombre cambió
        for _, v in ipairs(remotes:GetChildren()) do
            if v:IsA("RemoteEvent") and v.Name:match("^%x+-%x+-%x+-%x+-%x+$") then
                return v
            end
        end
    end
    
    -- Búsqueda global de respaldo
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == "Position" or v.Name:match("^%x+-%x+-%x+-%x+-%x+$")) then
            return v
        end
    end
    return nil
end

-- 3. Implementación del Hook sobre FireServer
local function InstallHitHook()
    if type(hookfunction) ~= "function" then return false end
    
    local remote = GetPositionRemote()
    if not remote then return false end

    local oldFireServer
    oldFireServer = hookfunction(remote.FireServer, function(self, ...)
        local args = {...}
        if Settings.Enabled and self == remote then
            local target = GetBestTarget()
            if target and target.Parent then
                -- Recorremos los argumentos del remote para reemplazar la parte golpeada y la dirección
                for i, arg in ipairs(args) do
                    -- Si el argumento es una Part (la parte del cuerpo que golpeó la bala)
                    if typeof(arg) == "Instance" and (arg:IsA("BasePart") or arg.Name == "Head") then
                        args[i] = target -- Reemplazamos por la cabeza del enemigo detectado
                    elseif typeof(arg) == "Vector3" then
                        -- Ajustamos el vector de dirección con predicción hacia el blanco
                        local rootPart = target.Parent:FindFirstChild("HumanoidRootPart")
                        local vel = rootPart and rootPart.Velocity or Vector3.new(0,0,0)
                        local predictedPos = target.Position + (vel * Settings.Prediction)
                        args[i] = (predictedPos - camera.CFrame.Position).Unit
                    end
                end
            end
        end
        return oldFireServer(self, table.unpack(args))
    end)

    print("¡Hook de impacto (Position:FireServer) instalado con éxito!")
    return true
end

-- Inicialización automática
task.spawn(function()
    local success = false
    while not success do
        success = InstallHitHook()
        task.wait(1)
    end
end)
