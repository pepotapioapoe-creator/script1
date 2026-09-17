--[[
    ZVOLT HUB - FULL VERSION (FIXED ESP BOX & CTRL+CLICK TOGGLE + TROLL & WALLBANG)
    Versión optimizada y sin errores de ESP
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

--// Configuración General
local settings = {
	aimEnabled = false,
	espEnabled = false,
	espNamesEnabled = false,
	espLinesEnabled = true,
	espBoxEnabled = false,
	espHealthEnabled = true,
	ammoEnabled = false,
	flyEnabled = false,
	noclipEnabled = false,
	speedEnabled = false,
	jumpEnabled = false,
	bhopEnabled = false,
	hitboxEnabled = false,
	spinEnabled = false,
	ctrlClickTpEnabled = false,
	-- NUEVAS OPCIONES AÑADIDAS
	trollTrackEnabled = false,
	trollOrbitEnabled = false,
	wallbangEnabled = false,
	targetPart = "Head",
	hitboxSize = 5,
	spinSpeed = 50,
	smoothing = 0.3,
	fovRadius = 140,
	maxDistance = 1500,
	flySpeed = 50,
	customSpeed = 32,
	customJump = 100,
	selectedTpPlayer = nil
}

--// Sistema de Keybinds (F1 a F6)
local keybinds = {
	aimbot = Enum.KeyCode.F1,
	esp = Enum.KeyCode.F2,
	noclip = Enum.KeyCode.F3,
	fly = Enum.KeyCode.F4,
	hitbox = Enum.KeyCode.F5,
	spinbot = Enum.KeyCode.F6
}

local isAimingRightClick = false

UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAimingRightClick = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAimingRightClick = false
	end
end)

//// Funcionalidad Ctrl + Click (Controlada por variable)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and settings.ctrlClickTpEnabled then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if rootPart and mouse.Hit then
				rootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				rootPart.Velocity = Vector3.new(0, 0, 0)
			end
		end
	end
end)

//// Sistema de Notificaciones
local function sendNotification(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 1.5
		})
	end)
end

--// GUI Principal
local gui = Instance.new("ScreenGui")
gui.Name = "ZvoltUIContainer_" .. math.random(11111, 99999)
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// Círculo de FOV
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FovIndicator"
fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(0, 242, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovFrame
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

--// Pantallas de la GUI
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 520)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
mainFrame.Visible = true
mainFrame.Parent = gui

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 10)
mfCorner.Parent = mainFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(35, 35, 45)
mfStroke.Thickness = 1.5
mfStroke.Parent = mainFrame

--// BARRA SUPERIOR
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 55)
topBar.BackgroundTransparency = 1
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 120, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(0, 242, 255)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "ZVOLT"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local draggingMain, dragStartMain, startPosMain
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingMain = true
		dragStartMain = input.Position
		startPosMain = mainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartMain
		mainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingMain = false
	end
end)

local tabsContainer = Instance.new("Frame")
tabsContainer.Size = UDim2.new(0, 560, 1, 0)
tabsContainer.Position = UDim2.new(0, 140, 0, 0)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = topBar

local tcLayout = Instance.new("UIListLayout")
tcLayout.FillDirection = Enum.FillDirection.Horizontal
tcLayout.SortOrder = Enum.SortOrder.LayoutOrder
tcLayout.Padding = UDim.new(0, 8)
tcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tcLayout.Parent = tabsContainer

local pages = {}
local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, -20, 1, -20)
	page.Position = UDim2.new(0, 10, 0, 10)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.CanvasSize = UDim2.new(0, 0, 0, 700)
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(0, 242, 255)
	page.Parent = mainFrame

	pages[name] = page
	return page
end

createPage("combat")
createPage("visuals")
createPage("weapon")
createPage("teleport")
createPage("troll")
createPage("misc")
createPage("keybinds")

local function showPage(cat)
	for name, page in pairs(pages) do
		page.Visible = (name == cat)
	end
end

local tabNames = {"combat", "visuals", "weapon", "teleport", "troll", "misc", "keybinds"}
for i, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 75, 0, 32)
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	btn.BackgroundTransparency = (name == "combat") and 0 or 1
	btn.TextColor3 = (name == "combat") and Color3.fromRGB(0, 242, 255) or Color3.fromRGB(145, 145, 165)
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamMedium
	btn.Text = name:upper()
	btn.LayoutOrder = i
	btn.Parent = tabsContainer

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		for _, child in ipairs(tabsContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.TextColor3 = Color3.fromRGB(145, 145, 165)
				child.BackgroundTransparency = 1
			end
		end
		btn.TextColor3 = Color3.fromRGB(0, 242, 255)
		btn.BackgroundTransparency = 0
		showPage(name)
	end)
end

showPage("combat")

// Componentes Fijos
local function createCard(page, titleText, posX, posY, sizeX, sizeY)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, sizeX, 0, sizeY)
	card.Position = UDim2.new(0, posX, 0, posY)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	card.Parent = page

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(30, 30, 42)
	stroke.Thickness = 1.2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 25)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(245, 245, 250)
	title.TextSize = 13
	title.Font = Enum.Font.GothamMedium
	title.Text = titleText:upper()
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -24, 1, -45)
	container.Position = UDim2.new(0, 12, 0, 38)
	container.BackgroundTransparency = 1
	container.Parent = card

	return container
end

local toggleStates = {}

local function createToggle(parent, posY, text, callback, settingKey)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.Position = UDim2.new(0, 0, 0, posY)
	btn.BackgroundTransparency = 1
	btn.TextColor3 = Color3.fromRGB(145, 145, 165)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = parent

	local checkbox = Instance.new("Frame")
	checkbox.Size = UDim2.new(0, 16, 0, 16)
	checkbox.Position = UDim2.new(1, -16, 0.5, -8)
	checkbox.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	checkbox.Parent = btn

	local cbStroke = Instance.new("UIStroke")
	cbStroke.Color = Color3.fromRGB(50, 50, 70)
	cbStroke.Thickness = 1.5
	cbStroke.Parent = checkbox

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 4)
	cc.Parent = checkbox

	local state = false

	local function updateVisuals(newState)
		state = newState
		btn.TextColor3 = state and Color3.fromRGB(245, 245, 250) or Color3.fromRGB(145, 145, 165)
		checkbox.BackgroundColor3 = state and Color3.fromRGB(0, 242, 255) or Color3.fromRGB(24, 24, 32)
		cbStroke.Color = state and Color3.fromRGB(0, 242, 255) or Color3.fromRGB(50, 50, 70)
		callback(state)
	end

	if settingKey then
		toggleStates[settingKey] = {
			Set = updateVisuals,
			Get = function() return state end
		}
	end

	btn.MouseButton1Click:Connect(function()
		updateVisuals(not state)
	end)
	
	return btn
end

local function createSlider(parent, posY, defaultVal, minVal, maxVal, titlePrefix, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 42)
	container.Position = UDim2.new(0, 0, 0, posY)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(145, 145, 165)
	label.TextSize = 12
	label.Font = Enum.Font.GothamMedium
	label.Text = titlePrefix .. ": " .. defaultVal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.new(0, 0, 0, 24)
	bar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	bar.Parent = container

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 242, 255)
	fill.Parent = bar

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 12, 0, 12)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = ""
	btn.Parent = bar

	local btc = Instance.new("UICorner")
	btc.CornerRadius = UDim.new(1, 0)
	btc.Parent = btn

	local dragging = false
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMouseLocation().X
			local barPos = bar.AbsolutePosition.X
			local barSize = bar.AbsoluteSize.X
			local clampPos = math.clamp((mousePos - barPos) / barSize, 0, 1)
			fill.Size = UDim2.new(clampPos, 0, 1, 0)
			btn.Position = UDim2.new(clampPos, 0, 0.5, 0)
			local calculatedVal = math.floor(minVal + (clampPos * (maxVal - minVal)))
			label.Text = titlePrefix .. ": " .. calculatedVal
			callback(calculatedVal)
		end
	end)
end

// PESTAÑA: COMBAT
local cardCombatGen = createCard(pages["combat"], "General", 10, 10, 680, 200)
createToggle(cardCombatGen, 0, "Aimbot", function(v) settings.aimEnabled = v end, "aimbot")
createToggle(cardCombatGen, 36, "Hitbox Extender", function(v) settings.hitboxEnabled = v end, "hitbox")
createToggle(cardCombatGen, 72, "Wallbang (Atravesar paredes al disparar)", function(v) settings.wallbangEnabled = v end)
createSlider(cardCombatGen, 108, settings.hitboxSize, 2, 20, "Hitbox Size", function(val) settings.hitboxSize = val end)

local cardCombatFov = createCard(pages["combat"], "FOV Settings", 10, 210, 680, 85)
createSlider(cardCombatFov, 0, settings.fovRadius, 50, 300, "FOV Radius", function(val)
	settings.fovRadius = val
	fovFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
end)

local cardCombatSettings = createCard(pages["combat"], "Target Bone Selection", 10, 305, 680, 85)
local partsList = {"Head", "HumanoidRootPart", "UpperTorso"}
local currentPartIndex = 1
local boneBtn = Instance.new("TextButton")
boneBtn.Size = UDim2.new(1, 0, 0, 30)
boneBtn.Position = UDim2.new(0, 0, 0, 0)
boneBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
boneBtn.TextColor3 = Color3.fromRGB(0, 242, 255)
boneBtn.TextSize = 12
boneBtn.Font = Enum.Font.GothamMedium
boneBtn.Text = settings.targetPart
boneBtn.Parent = cardCombatSettings
local bbc = Instance.new("UICorner")
bbc.CornerRadius = UDim.new(0, 6)
bbc.Parent = boneBtn

boneBtn.MouseButton1Click:Connect(function()
	currentPartIndex = currentPartIndex + 1
	if currentPartIndex > #partsList then currentPartIndex = 1 end
	settings.targetPart = partsList[currentPartIndex]
	boneBtn.Text = settings.targetPart
end)

// PESTAÑA: VISUALS
local cardVisuals = createCard(pages["visuals"], "ESP Settings", 10, 10, 680, 300)
createToggle(cardVisuals, 0, "ESP Players", function(v) settings.espEnabled = v end, "esp")
createToggle(cardVisuals, 34, "ESP Names", function(v) settings.espNamesEnabled = v end)
createToggle(cardVisuals, 68, "ESP Lines", function(v) settings.espLinesEnabled = v end)
createToggle(cardVisuals, 102, "ESP Box", function(v) settings.espBoxEnabled = v end)
createToggle(cardVisuals, 136, "ESP Health Hearts", function(v) settings.espHealthEnabled = v end)
createSlider(cardVisuals, 172, settings.maxDistance, 100, 3000, "Max Distance", function(val) settings.maxDistance = val end)

// PESTAÑA: WEAPON
local cardWeapon = createCard(pages["weapon"], "Weapon Modifications", 10, 10, 680, 85)
createToggle(cardWeapon, 0, "Infinite Ammo", function(v) settings.ammoEnabled = v end)

// PESTAÑA: TELEPORT
local cardTp = createCard(pages["teleport"], "Player Teleporter List", 10, 10, 680, 380)

local playerListContainer = Instance.new("ScrollingFrame")
playerListContainer.Size = UDim2.new(1, 0, 0, 200)
playerListContainer.Position = UDim2.new(0, 0, 0, 0)
playerListContainer.BackgroundTransparency = 1
playerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListContainer.ScrollBarThickness = 3
playerListContainer.Parent = cardTp

local plLayout = Instance.new("UIListLayout")
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Padding = UDim.new(0, 5)
plLayout.Parent = playerListContainer

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, 0, 0, 26)
selectedLabel.Position = UDim2.new(0, 0, 0, 210)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = Color3.fromRGB(145, 145, 165)
selectedLabel.TextSize = 12
selectedLabel.Font = Enum.Font.GothamMedium
selectedLabel.Text = "Selected: None"
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = cardTp

local tpActionBtn = Instance.new("TextButton")
tpActionBtn.Size = UDim2.new(1, 0, 0, 34)
tpActionBtn.Position = UDim2.new(0, 0, 0, 244)
tpActionBtn.BackgroundColor3 = Color3.fromRGB(0, 242, 255)
tpActionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
tpActionBtn.TextSize = 13
tpActionBtn.Font = Enum.Font.GothamMedium
tpActionBtn.Text = "TELEPORT TO PLAYER"
tpActionBtn.Parent = cardTp

local tac = Instance.new("UICorner")
tac.CornerRadius = UDim.new(0, 6)
tac.Parent = tpActionBtn

local function updatePlayerList()
	for _, child in ipairs(playerListContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local players = Players:GetPlayers()
	playerListContainer.CanvasSize = UDim2.new(0, 0, 0, #players * 30)
	
	for i, p in ipairs(players) do
		if p ~= localPlayer then
			local pBtn = Instance.new("TextButton")
			pBtn.Size = UDim2.new(1, 0, 0, 26)
			pBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
			pBtn.TextColor3 = Color3.fromRGB(245, 245, 250)
			pBtn.TextSize = 12
			pBtn.Font = Enum.Font.GothamMedium
			pBtn.Text = "  " .. p.Name
			pBtn.TextXAlignment = Enum.TextXAlignment.Left
			pBtn.LayoutOrder = i
			pBtn.Parent = playerListContainer
			
			local pbc = Instance.new("UICorner")
			pbc.CornerRadius = UDim.new(0, 5)
			pbc.Parent = pBtn
			
			pBtn.MouseButton1Click:Connect(function()
				settings.selectedTpPlayer = p
				selectedLabel.Text = "Selected: " .. p.Name
			end)
		end
	end
end

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

tpActionBtn.MouseButton1Click:Connect(function()
	local targetPlayer = settings.selectedTpPlayer
	if not targetPlayer or not targetPlayer.Character or not localPlayer.Character then return end
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local myRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if targetRoot and myRoot then
		local startPos = myRoot.CFrame
		local endPos = targetRoot.CFrame + Vector3.new(0, 3, 0)
		for i = 1, 10 do
			if not myRoot or not targetRoot then break end
			myRoot.CFrame = startPos:Lerp(endPos, i / 10)
			myRoot.Velocity = Vector3.new(0, 0, 0)
			task.wait(0.01)
		end
	end
end)

// PESTAÑA: TROLL
local cardTroll = createCard(pages["troll"], "Troll Actions", 10, 10, 680, 120)
createToggle(cardTroll, 0, "Tracker (Frente a su cara sin animación)", function(v) settings.trollTrackEnabled = v end)
createToggle(cardTroll, 36, "Orbit (Girar alrededor del seleccionado)", function(v) settings.trollOrbitEnabled = v end)

// PESTAÑA: MISC
local cardMisc = createCard(pages["misc"], "Movement & Misc", 10, 10, 680, 440)
createToggle(cardMisc, 0, "Ctrl + Click TP", function(v) settings.ctrlClickTpEnabled = v end)
createToggle(cardMisc, 36, "Fly Mode", function(v) settings.flyEnabled = v end, "fly")
createSlider(cardMisc, 72, settings.flySpeed, 10, 150, "Fly Speed", function(val) settings.flySpeed = val end)
createToggle(cardMisc, 118, "Custom Speed", function(v) settings.speedEnabled = v end, "speed")
createSlider(cardMisc, 154, settings.customSpeed, 16, 120, "Speed Value", function(val) settings.customSpeed = val end)
createToggle(cardMisc, 200, "Super Jump", function(v) settings.jumpEnabled = v end, "jump")
createSlider(cardMisc, 236, settings.customJump, 50, 350, "Jump Power", function(val) settings.customJump = val end)
createToggle(cardMisc, 282, "Noclip", function(v) settings.noclipEnabled = v end, "noclip")
createToggle(cardMisc, 318, "Bhop", function(v) settings.bhopEnabled = v end)
createToggle(cardMisc, 354, "Spinbot", function(v) settings.spinEnabled = v end, "spinbot")

// PESTAÑA: KEYBINDS
local cardBinds = createCard(pages["keybinds"], "Keybind Configuration", 10, 10, 680, 280)

local function createKeybindRow(parent, posY, labelName, bindKeyName)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.Position = UDim2.new(0, 0, 0, posY)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 180, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(145, 145, 165)
	label.TextSize = 12
	label.Font = Enum.Font.GothamMedium
	label.Text = labelName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0, 110, 0, 26)
	bindBtn.Position = UDim2.new(1, -110, 0.5, -13)
	bindBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	bindBtn.TextColor3 = Color3.fromRGB(0, 242, 255)
	bindBtn.TextSize = 11
	bindBtn.Font = Enum.Font.GothamMedium
	bindBtn.Text = keybinds[bindKeyName] and keybinds[bindKeyName].Name or "None"
	bindBtn.Parent = row

	local bbc = Instance.new("UICorner")
	bbc.CornerRadius = UDim.new(0, 5)
	bbc.Parent = bindBtn

	local bbs = Instance.new("UIStroke")
	bbs.Color = Color3.fromRGB(50, 50, 70)
	bbs.Thickness = 1
	bbs.Parent = bindBtn

	local listening = false
	bindBtn.MouseButton1Click:Connect(function()
		listening = true
		bindBtn.Text = "[ Press a Key... ]"
		bindBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					keybinds[bindKeyName] = nil
					bindBtn.Text = "None"
				else
					keybinds[bindKeyName] = input.KeyCode
					bindBtn.Text = input.KeyCode.Name
				end
				listening = false
				bindBtn.TextColor3 = Color3.fromRGB(0, 242, 255)
			end
		end
	end)
end

createKeybindRow(cardBinds, 0, "Toggle Aimbot", "aimbot")
createKeybindRow(cardBinds, 34, "Toggle ESP", "esp")
createKeybindRow(cardBinds, 68, "Toggle Noclip", "noclip")
createKeybindRow(cardBinds, 102, "Toggle Fly", "fly")
createKeybindRow(cardBinds, 136, "Toggle Hitbox Ext.", "hitbox")
createKeybindRow(cardBinds, 170, "Toggle Spinbot", "spinbot")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		for feature, keyCode in pairs(keybinds) do
			if input.KeyCode == keyCode and toggleStates[feature] then
				local newState = not toggleStates[feature].Get()
				toggleStates[feature].Set(newState)
				sendNotification("Zvolt Keybind", feature:upper() .. ": " .. (newState and "ENABLED" or "DISABLED"))
			end
		end
	end
end)

//// BOTÓN FLOTANTE MOVIBLE
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ZvoltFloatingButton"
toggleButton.Size = UDim2.new(0, 90, 0, 42)
toggleButton.Position = UDim2.new(0, 40, 0, 100)
toggleButton.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
toggleButton.Text = "ZVOLT"
toggleButton.TextColor3 = Color3.fromRGB(0, 242, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.FredokaOne
toggleButton.ZIndex = 99999
toggleButton.Parent = gui

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 8)
tbc.Parent = toggleButton

local tbs = Instance.new("UIStroke")
tbs.Color = Color3.fromRGB(0, 242, 255)
tbs.Thickness = 1.5
tbs.Parent = toggleButton

local draggingBtn, dragStartBtn, startPosBtn
toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingBtn = true
		dragStartBtn = input.Position
		startPosBtn = toggleButton.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartBtn
		toggleButton.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingBtn = false
	end
end)

toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

//// LÓGICA DE ESP CORREGIDA Y OPTIMIZADA
local espObjects = {}

local function removeESP(player)
	if espObjects[player] then
		if espObjects[player].Highlight then espObjects[player].Highlight:Destroy() end
		if espObjects[player].Billboard then espObjects[player].Billboard:Destroy() end
		if espObjects[player].Line then espObjects[player].Line:Destroy() end
		if espObjects[player].Box then espObjects[player].Box:Destroy() end
		espObjects[player] = nil
	end
end

local function updateESPForPlayer(player)
	if player == localPlayer then return end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		removeESP(player)
		return
	end

	// Obtener datos del cache ANTES de cualquier condición
	local data = espObjects[player]
	
	if settings.espEnabled then
		// Crear ESP si no existe (solo si data es nil, significó que removeESP lo borró o nunca existió)
		if not data then
			-- Highlight
			local hl = Instance.new("Highlight")
			hl.Adornee = char
			hl.FillColor = Color3.fromRGB(0, 242, 255)
			hl.OutlineColor = Color3.fromRGB(0, 242, 255)
			hl.FillTransparency = 0.75
			hl.Parent = char

			-- BillboardGui
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 160, 0, 60)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.Parent = char

			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 0.5, 0)
			txt.BackgroundTransparency = 1
			txt.TextColor3 = Color3.fromRGB(245, 245, 250)
			txt.TextStrokeTransparency = 0.3
			txt.TextSize = 12
			txt.Font = Enum.Font.GothamMedium
			txt.Parent = bb

			local heartsTxt = Instance.new("TextLabel")
			heartsTxt.Size = UDim2.new(1, 0, 0.5, 0)
			heartsTxt.Position = UDim2.new(0, 0, 0.5, 0)
			heartsTxt.BackgroundTransparency = 1
			heartsTxt.TextColor3 = Color3.fromRGB(255, 60, 90)
			heartsTxt.TextStrokeTransparency = 0.3
			heartsTxt.TextSize = 13
			heartsTxt.Font = Enum.Font.GothamMedium
			heartsTxt.Parent = bb

			-- Line
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundColor3 = Color3.fromRGB(0, 242, 255)
			line.BorderSizePixel = 0
			line.Visible = false
			line.Parent = gui

			-- Box
			local box = Instance.new("Frame")
			box.BackgroundTransparency = 1
			box.Visible = false
			box.Parent = gui

			local boxStroke = Instance.new("UIStroke")
			boxStroke.Color = Color3.fromRGB(0, 242, 255)
			boxStroke.Thickness = 1.5
			boxStroke.Parent = box

			// Guardar en cache
			data = {
				Character = char, 
				Highlight = hl, 
				Billboard = bb, 
				Text = txt, 
				HeartsText = heartsTxt, 
				Line = line, 
				Box = box
			}
			espObjects[player] = data
		end

		// Ahora 'data' está garantizado que existe
		data = espObjects[player]
		local root = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		
		if root and localRoot and humanoid then
			local dist = math.floor((localRoot.Position - root.Position).Magnitude)
			if dist <= settings.maxDistance then
				local infoString = ""
				if settings.espNamesEnabled then 
					infoString = player.Name .. " " 
				end
				infoString = infoString .. "[" .. dist .. "m]"
				data.Text.Text = infoString
				data.Text.Visible = true

				data.HeartsText.Visible = settings.espHealthEnabled
				if settings.espHealthEnabled then
					local hpPercent = math.clamp(humanoid.Health / (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100), 0, 1)
					local totalHearts = 5
					local activeHearts = math.ceil(hpPercent * totalHearts)
					local heartsStr = ""
					for h = 1, totalHearts do
						if h <= activeHearts then
							heartsStr = heartsStr .. "❤️"
						else
							heartsStr = heartsStr .. "🖤"
						end
					end
					data.HeartsText.Text = heartsStr
				end
				data.Billboard.Enabled = true

				if settings.espLinesEnabled then
					local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
					if onScreen then
						local guiSize = camera.ViewportSize
						local startVector = Vector2.new(guiSize.X / 2, guiSize.Y)
						local endVector = Vector2.new(screenPos.X, screenPos.Y)
						local distance = (endVector - startVector).Magnitude
						
						data.Line.Size = UDim2.new(0, 1, 0, distance)
						data.Line.Position = UDim2.new(0, (startVector.X + endVector.X) / 2, 0, (startVector.Y + endVector.Y) / 2)
						data.Line.Rotation = math.deg(math.atan2(endVector.Y - startVector.Y, endVector.X - startVector.X)) - 90
						data.Line.Visible = true
					else
						data.Line.Visible = false
					end
				else
					data.Line.Visible = false
				end

				// Cálculo correcto de caja 2D
				if settings.espBoxEnabled then
					local head = char:FindFirstChild("Head")
					local _, onScreen = camera:WorldToViewportPoint(root.Position)
					
					if onScreen and head then
						local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
						local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
						
						local height = math.abs(headPos.Y - legPos.Y)
						local width = height * 0.6
						
						data.Box.Size = UDim2.new(0, width, 0, height)
						data.Box.Position = UDim2.new(0, headPos.X - (width / 2), 0, headPos.Y)
						data.Box.Visible = true
					else
						data.Box.Visible = false
					end
				else
					data.Box.Visible = false
				end
			else
				// Fuera de distancia: Ocultar todo
				data.Billboard.Enabled = false
				data.Line.Visible = false
				data.Box.Visible = false
			end
		end
	else
		// ESP Desactivado: Limpiar
		removeESP(player)
	end
end

Players.PlayerRemoving:Connect(function(player) removeESP(player) end)

// Variables para lógica de jugador objetivo (Troll)
local targetPlayer = settings.selectedTpPlayer
local orbitAngle = 0

RunService.RenderStepped:Connect(function(dt)
	if not camera or not localPlayer.Character then return end
	
	local mouseLocation = UserInputService:GetMouseLocation()
	// Actualizar posición del círculo FOV
	fovFrame.Position = UDim2.new(0, mouseLocation.X - (settings.fovRadius), 0, mouseLocation.Y - (settings.fovRadius))
	fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
	fovFrame.Visible = settings.aimEnabled

	// Actualizar ESP para todos los jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			updateESPForPlayer(player)
		end
	end

	// LÓGICA DE WALLBANG (Optimizada)
	if settings.wallbangEnabled then
		// Solo aplicamos CanCollide=false a las partes principales de los jugadores para evitar lag extremo
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				// Aplicar a la raíz y la cabeza principalmente
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				local head = player.Character:FindFirstChild("Head")
				if root then root.CanCollide = false end
				if head then head.CanCollide = false end
			end
		end
	end

	// LÓGICA DE TROLL: TRACKER Y ÓRBITA
	targetPlayer = settings.selectedTpPlayer
	local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")

	if targetPlayer and targetPlayer.Character and rootPart then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			if settings.trollTrackEnabled then
				if humanoid then humanoid.PlatformStand = true end
				
				// Posicionarse exactamente frente a la cara usando LookVector
				local frontPosition = targetRoot.Position + (targetRoot.CFrame.LookVector * 2.5) + Vector3.new(0, 0.5, 0)
				rootPart.CFrame = CFrame.new(frontPosition, targetRoot.Position)
				
				rootPart.Velocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			elseif settings.trollOrbitEnabled then
				if humanoid then humanoid.PlatformStand = true end
				orbitAngle = orbitAngle + (dt * 3)
				local radius = 6
				local x = targetRoot.Position.X + math.cos(orbitAngle) * radius
				local z = targetRoot.Position.Z + math.sin(orbitAngle) * radius
				local targetPos = Vector3.new(x, targetRoot.Position.Y + 2, z)
				
				rootPart.CFrame = CFrame.new(targetPos, targetRoot.Position)
				rootPart.Velocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			else
				// Si el troll está off, resetear platformStand si no fly
				if humanoid and not settings.flyEnabled then humanoid.PlatformStand = false end
			end
		end
	end

	// Spinbot mejorado
	if settings.spinEnabled then
		if rootPart and not settings.trollTrackEnabled and not settings.trollOrbitEnabled then 
			// Rotación más suave usando el setting de spinSpeed
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(settings.spinSpeed * dt), 0) 
		end
	end

	// Infinite Ammo
	if settings.ammoEnabled then
		local char = localPlayer.Character
		local backpack = localPlayer:FindFirstChild("Backpack")
		for _, container in ipairs({char, backpack}) do
			if container then
				for _, tool in ipairs(container:GetChildren()) do
					if tool:IsA("Tool") then
						for _, v in ipairs(tool:GetDescendants()) do
							if v:IsA("NumberValue") or v:IsA("IntValue") then
								local nameL = v.Name:lower()
								if nameL:find("ammo") or nameL:find("clip") or nameL:find("bullet") or nameL:find("mag") then
									v.Value = 999
								end
							end
						end
					end
				end
			end
		end
	end

	// Aimbot con FOV y Right Click
	if settings.aimEnabled and isAimingRightClick then
		// Buscar jugador más cercano dentro del FOV
		local closestPlayer = nil
		local shortestDistance = settings.fovRadius
		local mouseLocation = UserInputService:GetMouseLocation()

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				local targetPart = player.Character:FindFirstChild(settings.targetPart) or player.Character:FindFirstChild("Head")
				local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")

				if humanoid and humanoid.Health > 0 and targetPart and localRoot then
					if (localRoot.Position - targetPart.Position).Magnitude <= settings.maxDistance then
						local screenPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
						if onScreen then
							local distCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
							if distCenter <= settings.fovRadius and distCenter < shortestDistance then
								shortestDistance = distCenter
								closestPlayer = player
							end
						end
					end
				end
			end
		end

		if closestPlayer then
			local targetPart = closestPlayer.Character:FindFirstChild(settings.targetPart) or closestPlayer.Character:FindFirstChild("Head")
			if targetPart then
				pcall(function()
					// Lerp suave hacia el objetivo
					camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPart.Position), settings.smoothing)
				end)
			end
		end
	end

	// Noclip optimizado
	if settings.noclipEnabled and localPlayer.Character then
		local char = localPlayer.Character
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end

	// Hitbox Extender
	if settings.hitboxEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				local tp = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
				if tp then
					// Aumentar tamaño y hacerlo transparente
					tp.Size = Vector3.new(settings.hitboxSize, settings.hitboxSize, settings.hitboxSize)
					tp.Transparency = 0.6
					tp.CanCollide = false
				end
			end
		end
	end

	// Movimiento y Stats
	local currentHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if currentHumanoid then
		if settings.speedEnabled then
			currentHumanoid.WalkSpeed = settings.customSpeed
		else
			currentHumanoid.WalkSpeed = 16 // Valor por defecto
		end
		
		if settings.jumpEnabled then
			currentHumanoid.JumpPower = settings.customJump
			currentHumanoid.UseJumpPower = true
		end
		
		if settings.bhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			if currentHumanoid.FloorMaterial ~= Enum.Material.Air then currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end

	// Fly logic
	if settings.flyEnabled and localPlayer.Character then
		local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if rootPart and humanoid then
			humanoid.PlatformStand = true
			local camCF = camera.CFrame
			local mv = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0, 1, 0) end
			
			rootPart.CFrame = rootPart.CFrame + (mv * settings.flySpeed * dt)
			rootPart.Velocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	elseif localPlayer.Character and not settings.trollTrackEnabled and not settings.trollOrbitEnabled then
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.PlatformStand = false end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	// Este eventoHeartbeat es bueno para el fly suave y delta time consistente
end)
