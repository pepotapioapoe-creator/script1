--[[
    ZVOLT - ESP & FOV PURPLES (Cámara 100% Libre, Sin Aimbot)
    Con menú interactivo GUI
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// Configuración Default
local Config = {
    ESP = {
        Enabled = true,
        Box = true,
        Name = true,
        Distance = true,
        Health = false,
        TeamCheck = false,
        DistanceMax = 1000,
        BoxColor = Color3.fromRGB(0, 255, 200),
        NameColor = Color3.fromRGB(255, 255, 255),
        HealthColor = Color3.fromRGB(0, 255, 0),
        BoxFilled = false,
    },
    FOV = {
        Enabled = true,
        Radius = 160,
        Visible = true,
        MouseFollow = true,
        LockCenter = false,
        Color = Color3.fromRGB(255, 0, 128),
        Filled = false,
        Transparency = 0.8,
        Thickness = 1.5,
    },
}

--// Crear ScreenGUI
local gui = Instance.new("ScreenGui")
gui.Name = "ZVOLT_GUI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

--// Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 350)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true

--// Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.BackgroundTransparency = 0.2
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "ZVOLT - ESP & FOV"
title.Parent = mainFrame

--// Botón Close
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundTransparency = 0
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

// Sección ESP
local espSection = Instance.new("TextLabel")
espSection.Name = "ESPSection"
espSection.Size = UDim2.new(1, -10, 0, 20)
espSection.Position = UDim2.new(0, 5, 0, 50)
espSection.BackgroundTransparency = 1
espSection.Font = Enum.Font.Gotham
espSection.TextSize = 13
espSection.TextColor3 = Color3.fromRGB(200, 200, 200)
espSection.Text = "ESP"
espSection.Parent = mainFrame

// Toggle ESP Box
local espBoxToggle = Instance.new("TextButton")
espBoxToggle.Name = "ESPBoxToggle"
espBoxToggle.Size = UDim2.new(1, -10, 0, 25)
espBoxToggle.Position = UDim2.new(0, 5, 0, 75)
espBoxToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espBoxToggle.BackgroundTransparency = 0.2
espBoxToggle.Font = Enum.Font.Gotham
espBoxToggle.TextSize = 12
espBoxToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espBoxToggle.Text = "Box: " .. tostring(Config.ESP.Box)
espBoxToggle.Parent = mainFrame

espBoxToggle.MouseButton1Click:Connect(function()
    Config.ESP.Box = not Config.ESP.Box
    espBoxToggle.Text = "Box: " .. tostring(Config.ESP.Box)
end)

// Toggle ESP Name
local espNameToggle = Instance.new("TextButton")
espNameToggle.Name = "ESPNameToggle"
espNameToggle.Size = UDim2.new(1, -10, 0, 25)
espNameToggle.Position = UDim2.new(0, 5, 0, 105)
espNameToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espNameToggle.BackgroundTransparency = 0.2
espNameToggle.Font = Enum.Font.Gotham
espNameToggle.TextSize = 12
espNameToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espNameToggle.Text = "Name: " .. tostring(Config.ESP.Name)
espNameToggle.Parent = mainFrame

espNameToggle.MouseButton1Click:Connect(function()
    Config.ESP.Name = not Config.ESP.Name
    espNameToggle.Text = "Name: " .. tostring(Config.ESP.Name)
end)

// Toggle ESP Distance
local espDistToggle = Instance.new("TextButton")
espDistToggle.Name = "ESPDistanceToggle"
espDistToggle.Size = UDim2.new(1, -10, 0, 25)
espDistToggle.Position = UDim2.new(0, 5, 0, 135)
espDistToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espDistToggle.BackgroundTransparency = 0.2
espDistToggle.Font = Enum.Font.Gotham
espDistToggle.TextSize = 12
espDistToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espDistToggle.Text = "Distance: " .. tostring(Config.ESP.Distance)
espDistToggle.Parent = mainFrame

espDistToggle.MouseButton1Click:Connect(function()
    Config.ESP.Distance = not Config.ESP.Distance
    espDistToggle.Text = "Distance: " .. tostring(Config.ESP.Distance)
end)

// Toggle ESP Team Check
local espTeamToggle = Instance.new("TextButton")
espTeamToggle.Name = "ESPTeamToggle"
espTeamToggle.Size = UDim2.new(1, -10, 0, 25)
espTeamToggle.Position = UDim2.new(0, 5, 0, 165)
espTeamToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espTeamToggle.BackgroundTransparency = 0.2
espTeamToggle.Font = Enum.Font.Gotham
espTeamToggle.TextSize = 12
espTeamToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espTeamToggle.Text = "Team Check: " .. tostring(Config.ESP.TeamCheck)
espTeamToggle.Parent = mainFrame

espTeamToggle.MouseButton1Click:Connect(function()
    Config.ESP.TeamCheck = not Config.ESP.TeamCheck
    espTeamToggle.Text = "Team Check: " .. tostring(Config.ESP.TeamCheck)
end)

// Sliders/Colors (simplificado)
local colorLabel = Instance.new("TextLabel")
colorLabel.Name = "ColorLabel"
colorLabel.Size = UDim2.new(1, -10, 0, 20)
colorLabel.Position = UDim2.new(0, 5, 0, 195)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 13
colorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
colorLabel.Text = "Color Box"
colorLabel.Parent = mainFrame

local colorBox = Instance.new("TextBox")
colorBox.Name = "ColorBox"
colorBox.Size = UDim2.new(0, 80, 0, 25)
colorBox.Position = UDim2.new(0, 5, 0, 220)
colorBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
colorBox.BackgroundTransparency = 0.2
colorBox.Font = Enum.Font.Gotham
colorBox.TextSize = 11
colorBox.TextColor3 = Color3.fromRGB(255, 255, 255)
colorBox.Text = "0,255,200"
colorBox.Parent = mainFrame

colorBox.FocusLost:Connect(function()
    local r, g, b = string.match(colorBox.Text, "(%d+),(%d+),(%d+)")
    if r and g and b then
        Config.ESP.BoxColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    end
end)

// Sección FOV
local fovSection = Instance.new("TextLabel")
fovSection.Name = "FOVSection"
fovSection.Size = UDim2.new(1, -10, 0, 20)
fovSection.Position = UDim2.new(0, 5, 0, 250)
fovSection.BackgroundTransparency = 1
fovSection.Font = Enum.Font.Gotham
fovSection.TextSize = 13
fovSection.TextColor3 = Color3.fromRGB(200, 200, 200)
fovSection.Text = "FOV"
fovSection.Parent = mainFrame

// Toggle FOV
local fovToggle = Instance.new("TextButton")
fovToggle.Name = "FOVToggle"
fovToggle.Size = UDim2.new(1, -10, 0, 25)
fovToggle.Position = UDim2.new(0, 5, 0, 275)
fovToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fovToggle.BackgroundTransparency = 0.2
fovToggle.Font = Enum.Font.Gotham
fovToggle.TextSize = 12
fovToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
fovToggle.Text = "FOV: " .. tostring(Config.FOV.Enabled)
fovToggle.Parent = mainFrame

fovToggle.MouseButton1Click:Connect(function()
    Config.FOV.Enabled = not Config.FOV.Enabled
    fovToggle.Text = "FOV: " .. tostring(Config.FOV.Enabled)
    fovCircle.Visible = Config.FOV.Enabled
end)

// Radio FOV
local radiusBox = Instance.new("TextBox")
radiusBox.Name = "RadiusBox"
radiusBox.Size = UDim2.new(0, 80, 0, 25)
radiusBox.Position = UDim2.new(0, 5, 0, 305)
radiusBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
radiusBox.BackgroundTransparency = 0.2
radiusBox.Font = Enum.Font.Gotham
radiusBox.TextSize = 11
radiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusBox.Text = tostring(Config.FOV.Radius)
radiusBox.Parent = mainFrame

radiusBox.FocusLost:Connect(function()
    local num = tonumber(radiusBox.Text)
    if num then
        Config.FOV.Radius = num
        fovCircle.Radius = num
    end
end)

// Color FOV
local fovColorBox = Instance.new("TextBox")
fovColorBox.Name = "FOVColorBox"
fovColorBox.Size = UDim2.new(0, 80, 0, 25)
fovColorBox.Position = UDim2.new(0, 95, 0, 305)
fovColorBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
fovColorBox.BackgroundTransparency = 0.2
fovColorBox.Font = Enum.Font.Gotham
fovColorBox.TextSize = 11
fovColorBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovColorBox.Text = "255,0,128"
fovColorBox.Parent = mainFrame

fovColorBox.FocusLost:Connect(function()
    local r, g, b = string.match(fovColorBox.Text, "(%d+),(%d+),(%d+)")
    if r and g and b then
        Config.FOV.Color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        fovCircle.Color = Config.FOV.Color
    end
end)

//// Configuración actual en el bucle
Esp.Cache = {}

--// Conexiones jugadores
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then
        task.spawn(createESP, p)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        createESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    clearESP(player)
end)

// Validar personaje
local function validChar(char)
    return char and char:FindFirstChild("HumanoidRootPart") 
        and char:FindFirstChild("Head") 
        and char:FindFirstChildOfClass("Humanoid") 
        and char.Humanoid.Health > 0
end

// Círculo FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = Config.FOV.Visible
fovCircle.Radius = Config.FOV.Radius
fovCircle.Color = Config.FOV.Color
fovCircle.Filled = Config.FOV.Filled
fovCircle.Transparency = Config.FOV.Transparency
fovCircle.Thickness = Config.FOV.Thickness

// Loop principal
RunService.RenderStepped:Connect(function()
    // Actualizar FOV posición
    if Config.FOV.Enabled then
        local pos = Config.FOV.MouseFollow 
            and UserInputService:GetMouseLocation() 
            or Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        
        if Config.FOV.LockCenter then
            pos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        end
        
        fovCircle.Position = pos
    end

    // Actualizar ESP para todos
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            // Check de equipo
            if not Config.ESP.TeamCheck or player.Team ~= localPlayer.Team then
                local char = player.Character
                
                if not char or not validChar(char) then
                    if espCache[player] then
                        clearESP(player)
                    end
                    continue
                end

                // Check de distancia
                if Config.ESP.Distance then
                    local root = char.HumanoidRootPart
                    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (root.Position - hrp.Position).Magnitude
                        if dist > Config.ESP.DistanceMax then
                            if espCache[player] then clearESP(player) end
                            continue
                        end
                    end
                end

                // Crear ESP si no existe
                if not espCache[player] then
                    createESP(player)
                end

                local data = espCache[player]
                local root = char.HumanoidRootPart
                local head = char.Head
                local humanoid = char.Humanoid

                local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.5

                    // Actualizar Box
                    if Config.ESP.Box then
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Position = Vector2.new(headPos.X - (width / 2), headPos.Y)
                        data.Box.Visible = true
                        data.Box.Color = Config.ESP.BoxColor
                        data.Box.Filled = Config.ESP.BoxFilled
                    else
                        data.Box.Visible = false
                    end

                    // Actualizar Nombre
                    if Config.ESP.Name then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(headPos.X, headPos.Y - 18)
                        data.Name.Visible = true
                        data.Name.Color = Config.ESP.NameColor
                    else
                        data.Name.Visible = false
                    end

                    // Distancia
                    if Config.ESP.Distance then
                        local dist = math.floor((root.Position - camera.CFrame.Position).Magnitude)
                        data.Distance.Text = "[" .. dist .. "m]"
                        data.Distance.Position = Vector2.new(headPos.X, headPos.Y + 22)
                        data.Distance.Visible = true
                    else
                        data.Distance.Visible = false
                    end
                else
                    if data.Box then data.Box.Visible = false end
                    if data.Name then data.Name.Visible = false end
                    if data.Distance then data.Distance.Visible = false end
                end
            else
                if espCache[player] then clearESP(player) end
            end
        end
    end
end)
