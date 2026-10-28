--[[
    ESTRUCTURA TÉCNica DE SILENT AIM — GunFramework
    Paso 3: Lógica de Targeting + Paso 4: Hook de Redirección
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuración de parámetros tácticos
local Settings = {
    Enabled = true,
    FOV = 180,               -- Rango visual del FOV en píxeles
    HitPart = "Head",        -- Parte del cuerpo objetivo (Head por defecto para headshot)
    MaxRange = 2000,         -- Distancia máxima de alcance
    Prediction = 0.12        -- Factor de compensación de movimiento (Velocity prediction)
}

--// PASO 3: Lógica de Targeting
-- Función para buscar el jugador enemigo más cercano al centro del cursor dentro del FOV
local function GetBestTarget()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar.FindFirstChild(myChar, "HumanoidRootPart")
    if not myRoot then return nil end

    local mousePos = UserInputService.GetMouseLocation(UserInputService)
    local closestTarget = nil
    local shortestDist = Settings.FOV

    for _, player in ipairs(Players.GetPlayers(Players)) do
        if player ~= localPlayer and player.Character then
            local enemyChar = player.Character
            local humanoid = enemyChar.FindFirstChildOfClass(enemyChar, "Humanoid")
            
            -- Verificar que el enemigo esté vivo
            if humanoid and humanoid.Health > 0 then
                local targetPart = enemyChar.FindFirstChild(enemyChar, Settings.HitPart) or enemyChar.FindFirstChild(enemyChar, "HumanoidRootPart")
                
                if targetPart then
                    local distance3D = (myRoot.Position - targetPart.Position).Magnitude
                    if distance3D <= Settings.MaxRange then
                        -- Proyectar la posición 3D al espacio de pantalla (Viewport)
                        local screenPos, onScreen = camera.WorldToViewportPoint(camera, targetPart.Position)
                        
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
    return closestTarget
end

--// PASO 4: Implementación del Hook de Disparo
-- Localizamos el módulo de armas en el Garbage Collector (GC) basándonos en la estructura del GunClient
local function InstallSilentHook()
    if type(getgc) ~= "function" or type(hookfunction) ~= "function" then
        warn("El executor actual no soporta getgc o hookfunction.")
        return false
    end

    for _, v in ipairs(getgc(false)) do
        if type(v) == "table" then
            -- Identificamos la tabla de la clase de armas que contiene FireBullet (visto en GunClient)
            if rawget(v, "FireBullet") and type(v.FireBullet) == "function" then
                local oldFireBullet
                oldFireBullet = hookfunction(v.FireBullet, function(self, origin, direction, ...)
                    if Settings.Enabled then
                        local target = GetBestTarget()
                        if target and target.Parent then
                            -- Obtenemos la velocidad del enemigo para aplicar predicción matemática
                            local rootPart = target.Parent.FindFirstChild(target.Parent, "HumanoidRootPart")
                            local velocity = rootPart and rootPart.Velocity or Vector3.new(0, 0, 0)
                            
                            -- Calculamos la posición futura del objetivo
                            local predictedPosition = target.Position + (velocity * Settings.Prediction)
                            
                            -- Redirigimos el vector de dirección (Direction) desde el origen de la bala hacia el blanco
                            if typeof(origin) == "Vector3" then
                                local newDirection = (predictedPosition - origin).Unit
                                if newDirection.Magnitude == newDirection.Magnitude then -- Validación anti-NaN
                                    direction = newDirection
                                end
                            end
                        end
                    end
                    return oldFireBullet(self, origin, direction, ...)
                end)
                print("¡Hook de Silent Aim aplicado con éxito sobre FireBullet!")
                return true
            end
        end
    end
    return false
end

-- Inicializar el hook de manera segura
task.spawn(function()
    local success = false
    while not success do
        success = InstallSilentHook()
        task.wait(1)
    end
end)
