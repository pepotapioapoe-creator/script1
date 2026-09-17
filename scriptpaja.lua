--[[
    ZVOLT PANEL - UI CORREGIDA Y VISIBLE
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Settings = {
    SilentAim = false,
    ESP = false,
    FOV = 150,
    TargetPart = "Head"
}

-- Contenedor ultra seguro usando PlayerGui para garantizar visibilidad
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltPanelSafe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

--// CREACIÓN DE LA INTERFAZ (MENÚ)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 180)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "ZVOLT CONTROL PANEL"
title.TextColor3 = Color3.fromRGB(0, 242, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = mainFrame

-- Función para crear botones
local function createButton(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 35)
    btn.Position = UDim2.new(0, 20, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.Text = name .. ": OFF"
    btn.Parent = mainFrame

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Text = name .. ": OFF"
        end
        callback(state)
    end)
end

createButton("ESP Boxes", 45, function(state)
    Settings.ESP = state
end)

createButton("Silent Aim", 90, function(state)
    Settings.SilentAim = state
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 30)
info.Position = UDim2.new(0, 10, 0, 135)
info.BackgroundTransparency = 1
info.Text = "Panel Activo - Arrastrable"
info.TextColor3 = Color3.fromRGB(100, 100, 110)
info.Font = Enum.Font.Gotham
info.TextSize = 10
info.Parent = mainFrame

--// Círculo de FOV
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 0, 128)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

--// Lógica de objetivos
local function getClosestTarget()
    local target = nil
    local shortestDist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild(Settings.TargetPart)
            
            if humanoid and humanoid.Health > 0 and part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if magnitude < shortestDist then
                        shortestDist = magnitude
                        target = part
                    end
                end
            end
        end
    end
    return target
end

--// Sistema ESP
local espCache = {}

local function removeESP(player)
    if espCache[player] then
        if espCache[player].Box then espCache[player].Box:Destroy() end
        if espCache[player].Name then espCache[player].Name:Destroy() end
        espCache[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    fovCircle.Visible = Settings.SilentAim

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if Settings.ESP and char and root and head and humanoid and humanoid.Health > 0 then
                if not espCache[player] then
                    local box = Instance.new("Frame")
                    box.BackgroundTransparency = 1
                    box.Parent = gui

                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.fromRGB(0, 255, 200)
                    stroke.Thickness = 1.5
                    stroke.Parent = box

                    local name = Instance.new("TextLabel")
                    name.BackgroundTransparency = 1
                    name.TextColor3 = Color3.fromRGB(255, 255, 255)
                    name.TextStrokeTransparency = 0.3
                    name.TextSize = 11
                    name.Font = Enum.Font.GothamBold
                    name.Parent = gui

                    espCache[player] = {Box = box, Name = name}
                end

                local data = espCache[player]
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local height = math.abs(headPos.Y - camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y)
                    local width = height * 0.5

                    data.Box.Size = UDim2.new(0, width, 0, height)
                    data.Box.Position = UDim2.new(0, headPos.X - (width / 2), 0, headPos.Y)
                    data.Box.Visible = true

                    data.Name.Text = player.Name
                    data.Name.Position = UDim2.new(0, headPos.X - 50, 0, headPos.Y - 18)
                    data.Name.Size = UDim2.new(0, 100, 0, 18)
                    data.Name.Visible = true
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                end
            else
                removeESP(player)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)
