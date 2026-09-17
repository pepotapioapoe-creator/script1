--[[
    ZVOLT - ESP & FOV PURPLES (Cámara 100% Libre, Sin Aimbot)
    Script optimizado y con más utilidad
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ESP = {
    Enabled = true,
    Box = true,
    Name = true,
    Distance = false,
    TeamCheck = false,
    Color = Color3.fromRGB(0, 255, 200),
    BoxColor = Color3.fromRGB(0, 255, 200),
    NameColor = Color3.fromRGB(255, 255, 255),
}

local FOV = {
    Enabled = true,
    Radius = 160,
    Color = Color3.fromRGB(255, 0, 128),
    Thickness = 1.5,
    Filled = false,
    Transparency = 0.8,
    MouseFollow = true,
}

--// Validación de personaje
local function validarPersonaje(char)
    return char and char:FindFirstChild("HumanoidRootPart") 
        and char:FindFirstChild("Head") 
        and char:FindFirstChildOfClass("Humanoid") 
        and char.Humanoid.Health > 0
end

--// Crear ESP para un jugador
local function crearESP(player)
    if ESP.Cache[player] then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false
    box.Color = ESP.BoxColor

    local name = Drawing.new("Text")
    name.Visible = false
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = ESP.NameColor

    ESP.Cache[player] = {Box = box, Name = name}
end

--// Limpiar ESP de un jugador
local function limpiarESP(player)
    if ESP.Cache[player] then
        if ESP.Cache[player].Box then ESP.Cache[player].Box:Remove() end
        if ESP.Cache[player].Name then ESP.Cache[player].Name:Remove() end
        ESP.Cache[player] = nil
    end
end

--// Conexiones
ESP.Cache = {}

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.1)
        if ESP.Enabled then
            crearESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    limpiarESP(player)
    ESP.Cache[player] = nil
end)

--// Círculo de FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = FOV.Enabled
fovCircle.Radius = FOV.Radius
fovCircle.Color = FOV.Color
fovCircle.Thickness = FOV.Thickness
fovCircle.Filled = FOV.Filled
fovCircle.Transparency = FOV.Transparency

--// Configuración de distancia máxima
local distanciaMaxima = 1000

--// Loop Principal
RunService.RenderStepped:Connect(function()
    -- Actualizar FOV
    if FOV.Enabled then
        local mousePos = FOV.MouseFollow and UserInputService:GetMouseLocation() or Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
        fovCircle.Position = mousePos
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            -- Check de equipo (si está activado)
            if not ESP.TeamCheck or player.Team ~= localPlayer.Team then
                local char = player.Character
                
                if not char or not validarPersonaje(char) then
                    limpiarESP(player)
                    continue
                end

                -- Check de distancia (si está activado)
                if ESP.Distance then
                    local root = char.HumanoidRootPart
                    local dist = (root.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if dist > distanciaMaxima then
                        limpiarESP(player)
                        continue
                    end
                end

                -- Crear ESP si no existe
                if not ESP.Cache[player] then
                    crearESP(player)
                end

                local data = ESP.Cache[player]
                local root = char.HumanoidRootPart
                local head = char.Head
                local humanoid = char.Humanoid

                local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.5

                    -- Actualizar Box
                    if ESP.Box then
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Position = Vector2.new(headPos.X - (width / 2), headPos.Y)
                        data.Box.Visible = true
                        data.Box.Color = ESP.BoxColor
                    else
                        data.Box.Visible = false
                    end

                    -- Actualizar Nombre
                    if ESP.Name then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(headPos.X, headPos.Y - 18)
                        data.Name.Visible = true
                        data.Name.Color = ESP.NameColor
                    else
                        data.Name.Visible = false
                    end
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                end
            else
                limpiarESP(player)
            end
        end
    end
end)
