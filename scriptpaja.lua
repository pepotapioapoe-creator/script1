--[[
    ZVOLT TRUE SILENT AIM (Vector Redirection) & ESP
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
    SilentAim = true,
    ESPBox = true,
    ESPName = true,
    FOV = 160,
    TargetPart = "Head"
}

--// FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = SETTINGS.FOV
fovCircle.Color = Color3.fromRGB(255, 0, 128)
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Transparency = 0.8

--// Encontrar objetivo más cercano dentro del FOV
local function getClosestPlayer()
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

--// ESP Cache
local espCache = {}

local function clearESP(player)
    if espCache[player] then
        if espCache[player].Box then espCache[player].Box:Remove() end
        if espCache[player].Name then espCache[player].Name:Remove() end
        espCache[player] = nil
    end
end

--// Hook de Namecall para interceptar Raycasts del juego y desviarlos al objetivo silenciosamente
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if SETTINGS.SilentAim and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
        local target = getClosestPlayer()
        if target then
            local origin = args[1]
            -- Si es un Raycast clásico o de Workspace
            if method == "Raycast" and typeof(origin) == "Vector3" then
                local direction = args[2]
                args[2] = (target.Position - origin).Unit * direction.Magnitude
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

--// Loop Principal (ESP y FOV)
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos
    fovCircle.Visible = SETTINGS.SilentAim

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if char and root and head and humanoid and humanoid.Health > 0 then
                if not espCache[player] then
                    local box = Drawing.new("Square")
                    box.Visible = false
                    box.Color = Color3.fromRGB(0, 255, 200)
                    box.Thickness = 1.5
                    box.Filled = false

                    local name = Drawing.new("Text")
                    name.Visible = false
                    name.Color = Color3.fromRGB(255, 255, 255)
                    name.Size = 14
                    name.Center = true
                    name.Outline = true

                    espCache[player] = {Box = box, Name = name}
                end

                local data = espCache[player]
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.5

                    if SETTINGS.ESPBox then
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Position = Vector2.new(headPos.X - (width / 2), headPos.Y)
                        data.Box.Visible = true
                    else
                        data.Box.Visible = false
                    end

                    if SETTINGS.ESPName then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(headPos.X, headPos.Y - 18)
                        data.Name.Visible = true
                    else
                        data.Name.Visible = false
                    end
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                end
            else
                clearESP(player)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    clearESP(player)
end)
