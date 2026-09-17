--[[
    ZVOLT WORKING SILENT AIM & ESP (No-Anticheat Optimized)
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local settings = {
	silentAimEnabled = true,
	espEnabled = true,
	espBox = true,
	espTracers = true,
	espNames = true,
	fovRadius = 150,
	targetPart = "Head"
}

--// Interfaz visual principal
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltWorking_" .. math.random(1000, 9999)
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 0, 128)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

--// Menú Flotante simple para comprobar funcionalidad
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 200, 0, 120)
menu.Position = UDim2.new(0, 30, 0, 30)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menu.Parent = gui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 6)
mCorner.Parent = menu

local mTitle = Instance.new("TextLabel")
mTitle.Size = UDim2.new(1, 0, 0, 30)
mTitle.BackgroundTransparency = 1
mTitle.Text = "ZVOLT PANEL"
mTitle.TextColor3 = Color3.fromRGB(0, 242, 255)
mTitle.Font = Enum.Font.FredokaOne
mTitle.TextSize = 14
mTitle.Parent = menu

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: ACTIVO\nUsa Click Derecho para Silent"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.Parent = menu

--// Obtener jugador más cercano al centro de la pantalla / mouse dentro del FOV
local function getClosestTarget()
	local closestTarget = nil
	local shortestDist = settings.fovRadius
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local part = player.Character:FindFirstChild(settings.targetPart)
			if humanoid and humanoid.Health > 0 and part then
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						closestTarget = part
					end
				end
			end
		end
	end
	return closestTarget
end

--// Sistema ESP sencillo basado en Drawing/Frames directos por personaje
local espCache = {}

local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local head = char and char:FindFirstChild("Head")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			
			if settings.espEnabled and root and head and humanoid and humanoid.Health > 0 then
				if not espCache[player] then
					local box = Instance.new("Frame")
					box.BackgroundTransparency = 1
					box.Visible = false
					box.Parent = gui
					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.fromRGB(0, 255, 200)
					stroke.Thickness = 1.2
					stroke.Parent = box
					
					espCache[player] = {Box = box}
				end
				
				local data = espCache[player]
				local pos, onScreen = camera:WorldToViewportPoint(root.Position)
				if onScreen then
					local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
					local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
					local height = math.abs(headPos.Y - legPos.Y)
					local width = height * 0.5
					
					data.Box.Size = UDim2.new(0, width, 0, height)
					data.Box.Position = UDim2.new(0, headPos.X - (width / 2), 0, headPos.Y)
                    data.Box.Visible = true
				else
					data.Box.Visible = false
				end
			else
				if espCache[player] then
					espCache[player].Box:Destroy()
					espCache[player] = nil
				end
			end
		end
	end
end

--// Loop principal
RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	fovCircle.Visible = settings.silentAimEnabled
	
	updateESP()
end)

--// Silent Aim Funcional (Modifica temporalmente la dirección de la cámara o mira al disparar)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if settings.silentAimEnabled and input.UserInputType == Enum.UserInputType.MouseButton2 then -- Click derecho o tecla de acción
		local target = getClosestTarget()
		if target then
			-- Si el juego no tiene anticheat y usa proyectiles basados en CFrame de cámara:
			camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
		end
	end
end)
