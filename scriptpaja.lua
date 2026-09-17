--[[
    ZVOLT LIGHTWEIGHT - SILENT AIM & ESP + UI COMPLETA
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

--// Configuración
local settings = {
	silentAimEnabled = false,
	espEnabled = true,
	espBox = true,
	espSkeleton = true,
	espTracers = true,
	espNames = true,
	fovRadius = 120,
	targetPart = "Head",
	maxDistance = 1500
}

--// GUI Principal
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltUI_" .. math.random(10000, 99999)
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// Círculo de FOV Independiente
local fovCircle = Instance.new("Frame")
fovCircle.Name = "SilentFOV"
fovCircle.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
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

--// Botón Flotante para Abrir/Cerrar Menú
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 80, 0, 35)
toggleBtn.Position = UDim2.new(0, 30, 0, 30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
toggleBtn.TextColor3 = Color3.fromRGB(0, 242, 255)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.Text = "ZVOLT"
toggleBtn.Parent = gui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 6)
tbCorner.Parent = toggleBtn

local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(0, 242, 255)
tbStroke.Thickness = 1.2
tbStroke.Parent = toggleBtn

--// Menú Principal (Ventana)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 380)
mainFrame.Position = UDim2.new(0, 30, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
mainFrame.Visible = true
mainFrame.Parent = gui

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 8)
mfCorner.Parent = mainFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(35, 35, 45)
mfStroke.Thickness = 1.5
mfStroke.Parent = mainFrame

-- Título del menú
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "SILENT AIM & ESP PANEL"
titleLabel.Parent = mainFrame

-- Contenedor de opciones
local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(1, -20, 1, -55)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 320)
container.ScrollBarThickness = 2
container.Parent = mainFrame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 8)
uiLayout.Parent = container

-- Toggle Funcionalidad visual y lógica
local function createToggleUI(text, initialValue, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	btn.TextColor3 = initialValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(145, 145, 165)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.Text = "  " .. text
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = container

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 5)
	bCorner.Parent = btn

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 14, 0, 14)
	indicator.Position = UDim2.new(1, -22, 0.5, -7)
	indicator.BackgroundColor3 = initialValue and Color3.fromRGB(0, 242, 255) or Color3.fromRGB(35, 35, 45)
	indicator.Parent = btn

	local iCorner = Instance.new("UICorner")
	iCorner.CornerRadius = UDim.new(0, 3)
	iCorner.Parent = indicator

	local state = initialValue
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(145, 145, 165)
		indicator.BackgroundColor3 = state and Color3.fromRGB(0, 242, 255) or Color3.fromRGB(35, 35, 45)
		callback(state)
	end)
end

-- Crear controles en la interfaz
createToggleUI("Silent Aim", settings.silentAimEnabled, function(v) settings.silentAimEnabled = v end)
createToggleUI("ESP Global", settings.espEnabled, function(v) settings.espEnabled = v end)
createToggleUI("ESP Box", settings.espBox, function(v) settings.espBox = v end)
createToggleUI("ESP Skeleton", settings.espSkeleton, function(v) settings.espSkeleton = v end)
createToggleUI("ESP Tracers (Líneas)", settings.espTracers, function(v) settings.espTracers = v end)
createToggleUI("ESP Names & HP", settings.espNames, function(v) settings.espNames = v end)

-- Botón para abrir y cerrar el menú
toggleBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

--// Conexiones de Huesos para el ESP Skeleton
local skeletonBones = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local espCache = {}

local function removeESP(player)
	if espCache[player] then
		if espCache[player].Box then espCache[player].Box:Destroy() end
		if espCache[player].Tracer then espCache[player].Tracer:Destroy() end
		if espCache[player].NameTag then espCache[player].NameTag:Destroy() end
		if espCache[player].Bones then
			for _, line in pairs(espCache[player].Bones) do line:Destroy() end
		end
		espCache[player] = nil
	end
end

local function createESP(player)
	if espCache[player] then return end
	
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.Visible = false
	box.Parent = gui
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(0, 242, 255)
	boxStroke.Thickness = 1.5
	boxStroke.Parent = box

	local tracer = Instance.new("Frame")
	tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	tracer.BackgroundColor3 = Color3.fromRGB(0, 242, 255)
	tracer.BorderSizePixel = 0
	tracer.Visible = false
	tracer.Parent = gui

	local nameTag = Instance.new("TextLabel")
	nameTag.Size = UDim2.new(0, 200, 0, 25)
	nameTag.BackgroundTransparency = 1
	nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameTag.TextStrokeTransparency = 0.3
	nameTag.TextSize = 12
	nameTag.Font = Enum.Font.GothamMedium
	nameTag.Visible = false
	nameTag.Parent = gui

	local bones = {}
	for _, _ in ipairs(skeletonBones) do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = Color3.fromRGB(0, 242, 255)
		line.BorderSizePixel = 0
		line.Size = UDim2.new(0, 1, 0, 0)
		line.Visible = false
		line.Parent = gui
		table.insert(bones, line)
	end

	espCache[player] = {Box = box, Tracer = tracer, NameTag = nameTag, Bones = bones}
end

--// Obtener objetivo dentro del FOV independiente
local function getClosestPlayerInFOV()
	local closestPlayer = nil
	local shortestDistance = settings.fovRadius
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local targetPart = player.Character:FindFirstChild(settings.targetPart)
			local root = player.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and targetPart and root then
				local dist = (root.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
				if dist <= settings.maxDistance then
					local screenPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local magnitude = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
						if magnitude <= settings.fovRadius and magnitude < shortestDistance then
							shortestDistance = magnitude
							closestPlayer = player
						end
					end
				end
			end
		end
	end
	return closestPlayer
end

--// Hook de Silent Aim
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
	local args = {...}
	local method = getnamecallmethod()

	if settings.silentAimEnabled and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
		local targetPlayer = getClosestPlayerInFOV()
		if targetPlayer and targetPlayer.Character then
			local targetPart = targetPlayer.Character:FindFirstChild(settings.targetPart)
			if targetPart then
				if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
					local origin = args[1]
					args[2] = (targetPart.Position - origin).Unit * args[2].Magnitude
					return oldNamecall(self, unpack(args))
				end
			end
		end
	end

	return oldNamecall(self, ...)
end)
setreadonly(mt, true)

--// Loop principal
RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	fovCircle.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
	fovCircle.Visible = settings.silentAimEnabled

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local char = player.Character
			if settings.espEnabled and char and char:FindFirstChild("HumanoidRootPart") then
				if not espCache[player] then createESP(player) end
				local data = espCache[player]
				local root = char.HumanoidRootPart
				local head = char:FindFirstChild("Head")
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

				if root and head and humanoid and localRoot then
					local dist = math.floor((localRoot.Position - root.Position).Magnitude)
					if dist <= settings.maxDistance then
						local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)

						-- ESP Box
						if settings.espBox and onScreen then
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

						-- ESP Tracers
						if settings.espTracers and onScreen then
							local viewportSize = camera.ViewportSize
							local startVector = Vector2.new(viewportSize.X / 2, viewportSize.Y)
							local endVector = Vector2.new(screenPos.X, screenPos.Y)
							local magnitude = (endVector - startVector).Magnitude
							data.Tracer.Size = UDim2.new(0, 1, 0, magnitude)
							data.Tracer.Position = UDim2.new(0, (startVector.X + endVector.X) / 2, 0, (startVector.Y + endVector.Y) / 2)
							data.Tracer.Rotation = math.deg(math.atan2(endVector.Y - startVector.Y, endVector.X - startVector.X)) - 90
							data.Tracer.Visible = true
						else
							data.Tracer.Visible = false
						end

						-- ESP Names & HP
						if settings.espNames and onScreen then
							data.NameTag.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "HP]"
							data.NameTag.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - 40)
							data.NameTag.Visible = true
						else
							data.NameTag.Visible = false
						end

						-- ESP Skeleton
						if settings.espSkeleton then
							for i, boneConn in ipairs(skeletonBones) do
								local pA = char:FindFirstChild(boneConn[1])
								local pB = char:FindFirstChild(boneConn[2])
								local line = data.Bones[i]
								if pA and pB and line then
									local posA, onA = camera:WorldToViewportPoint(pA.Position)
									local posB, onB = camera:WorldToViewportPoint(pB.Position)
									if onA or onB then
										local vA = Vector2.new(posA.X, posA.Y)
										local vB = Vector2.new(posB.X, posB.Y)
										local mag = (vB - vA).Magnitude
										line.Size = UDim2.new(0, 1.5, 0, mag)
										line.Position = UDim2.new(0, (vA.X + vB.X) / 2, 0, (vA.Y + vB.Y) / 2)
										line.Rotation = math.deg(math.atan2(vB.Y - vA.Y, vB.X - vA.X)) - 90
										line.Visible = true
									else
										line.Visible = false
									end
								else
									if line then line.Visible = false end
								end
							end
						else
							for _, line in ipairs(data.Bones) do line.Visible = false end
						end
					else
						data.Box.Visible = false
						data.Tracer.Visible = false
						data.NameTag.Visible = false
						for _, line in ipairs(data.Bones) do line.Visible = false end
					end
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
