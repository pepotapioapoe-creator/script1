--[[--[[
    ZVOLT ESP PURO (Sin Aimbot, Sin Movimiento de Cámara)
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
    ESPBox = true,
    ESPName = true,
}

local espCache = {}

local function clearESP(player)
    if espCache[player] then
        if espCache[player].Box then espCache[player].Box:Remove() end
        if espCache[player].Name then espCache[player].Name:Remove() end
        espCache[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
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
