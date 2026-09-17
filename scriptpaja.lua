--[[
    ZVOLT TRUE SILENT AIM & ESP (Sin mover cámara)
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
    SilentAim = true,
    ESP = true,
    FOV = 150,
    TargetPart = "Head"
}

-- Contenedor seguro para la interfaz
local coreGui = gethui and gethui() or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltSilent_" .. math.random(1000, 9999)
gui.Parent = coreGui

-- Círculo de FOV Visual (No afecta tu cámara)
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.new(0, SETTINGS.FOV * 2, 0, SETTINGS.FOV * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = true
fovCircle.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 0, 128)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

-- Función para encontrar el objetivo dentro del FOV
local function getClosestTarget()
    local target = nil
    local shortestDist = SETTINGS.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild(SETTINGS.TargetPart)
            
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

-- Hook de Silent Aim por Raycast (Redirige la bala/proyectil invisiblemente sin mover la cámara)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if SETTINGS.SilentAim and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
        local targetPart = getClosestTarget()
        if targetPart then
            local origin = args[1]
            if method == "Raycast" and typeof(origin) == "Vector3" then
                local direction = args[2]
                args[2] = (targetPart.Position - origin).Unit * direction.Magnitude
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- Sistema ESP por ScreenGui
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
    fovCircle.Visible = SETTINGS.SilentAim

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if SETTINGS.ESP and char and root and head and humanoid and humanoid.Health > 0 then
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
                    name.TextSize = 12
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
                    data.Name.Position = UDim2.new(0, headPos.X - 50, 0, headPos.Y - 20)
                    data.Name.Size = UDim2.new(0, 100, 0, 20)
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
