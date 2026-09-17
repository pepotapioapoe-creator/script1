--[[
    ZVOLT HUB - FULL VERSION (OPTIMIZED & FIXED)
    ESP BOX CORREGIDO & CTRL+CLICK TOGGLE & TROLL & WALLBANG
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
	selectedTpPlayer = nil,
	killAuraEnabled = false,
}

--// Sistema de Keybinds
local keybinds = {
	aimbot = Enum.KeyCode.F1,
	esp = Enum.KeyCode.F2,
	noclip = Enum.KeyCode.F3,
	fly = Enum.KeyCode.F4,
	hitbox = Enum.KeyCode.F5,
	spinbot = Enum.KeyCode.F6
}

local isAimingRightClick = false

--// Conexiones de Mouse
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

// Funcionalidad Ctrl + Click (Teleport controlado)
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

// Notificaciones
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
gui.Name = "ZvoltUI_" .. tick()
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// Círculo de FOV (Indicador Visual)
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FovIndicator"
fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UserInputService:GetMouseLocation()
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(0, 242, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovFrame
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0) -- Hace que sea un círculo perfecto
fovCorner.Parent = fovFrame

--// ESTILO VISUAL NEÓN
local COLOR_BG = Color3.fromRGB(12, 12, 18)
local COLOR_CARD = Color3.fromRGB(17, 17, 25)
local COLOR_ACCENT = Color3.fromRGB(0, 242, 255)
local COLOR_SUBTEXT = Color3.fromRGB(130, 130, 150)
local COLOR_TEXT = Color3.fromRGB(230, 230, 240)
local FONT_MAIN = Enum.Font.GothamMedium
local FONT_TITLE = Enum.Font.FredokaOne

--// Función para crear páginas del menú
local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, -20, 1, -20)
	page.Position = UDim2.new(0, 10, 0, 10)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.CanvasSize = UDim2.new(0, 0, 0, 700)
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = COLOR_ACCENT
	page.Parent = contentArea
	return page
end

--// Estructura Principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 750, 0, 560)
mainFrame.Position = UDim2.new(0.5, -375, 0.5, -280)
mainFrame.BackgroundColor3 = COLOR_BG
mainFrame.Visible = true
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 12)
mfCorner.Parent = mainFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(30, 30, 40)
mfStroke.Thickness = 1.5
mfStroke.Parent = mainFrame

--// Barra Superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundTransparency = 1
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 130, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = COLOR_ACCENT
titleLabel.TextSize = 24
titleLabel.Font = FONT_TITLE
titleLabel.Text = "ZVOLT HUB"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

--// Arrastar Ventana
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

// Contenedor de pestañas
local tabsContainer = Instance.new("Frame")
tabsContainer.Size = UDim2.new(0, 200, 1, 0)
tabsContainer.Position = UDim2.new(0, 0, 0, 50)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = topBar

local function createTabButton(name, isActive)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 95, 0, 36)
	btn.BackgroundColor3 = isActive and COLOR_ACCENT or Color3.fromRGB(20, 20, 30)
	btn.TextColor3 = isActive and COLOR_BG or COLOR_SUBTEXT
	btn.TextSize = 11
	btn.Font = FONT_MAIN
	btn.Text = name:upper()
	btn.Parent = tabsContainer
	
	local corner = Instance.new("UICorner")
	 corner.CornerRadius = UDim.new(0, 8)
	 corner.Parent = btn
	
	return btn
end

local tabFunctions = {"combat", "visuals", "weapon", "teleport", "troll", "misc", "keybinds"}
local currentTab = "combat"

for i, tabName in ipairs(tabFunctions) do
	local btn = createTabButton(tabName, i == 1)
	btn.MouseButton1Click:Connect(function()
		// Resetear estilos
		for _, child in ipairs(tabsContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
				child.TextColor3 = COLOR_SUBTEXT
			end
		end
		btn.BackgroundColor3 = COLOR_ACCENT
		btn.TextColor3 = COLOR_BG
		
		// Mostrar/ocultar páginas
		for name, page in pairs(pages) do
			page.Visible = (name == tabName)
		end
		currentTab = tabName
	end)
end

// Área de contenido
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -220, 1, -50)
contentArea.Position = UDim2.new(0, 200, 0, 50)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local pages = {}
for _, name in ipairs(tabFunctions) do
	pages[name] = createPage(name)
end

// Función para crear tarjetas dentro de las páginas
local function createCard(page, titleText, posX, posY, sizeX, sizeY)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, sizeX, 0, sizeY)
	card.Position = UDim2.new(0, posX, 0, posY)
	card.BackgroundColor3 = COLOR_CARD
	card.Parent = page

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(35, 35, 50)
	stroke.Thickness = 1.2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 25)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.TextColor3 = COLOR_TEXT
	title.TextSize = 13
	title.Font = FONT_TITLE
	title.Text = titleText:upper()
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -24, 1, -40)
	container.Position = UDim2.new(0, 12, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = card

	return container
end

local toggleStates = {}

// Toggle mejorado
local function createToggle(parent, posY, text, callback, settingKey)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.Position = UDim2.new(0, 0, 0, posY)
	btn.BackgroundTransparency = 1
	btn.TextColor3 = COLOR_SUBTEXT
	btn.TextSize = 12
	btn.Font = FONT_MAIN
	btn.Text = text
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = parent

	local checkbox = Instance.new("Frame")
	checkbox.Size = UDim2.new(0, 20, 0, 20)
	checkbox.Position = UDim2.new(1, -22, 0.5, -10)
	checkbox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	checkbox.Parent = btn

	local cbStroke = Instance.new("UIStroke")
	cbStroke.Color = Color3.fromRGB(50, 50, 70)
	cbStroke.Thickness = 1.5
	cbStroke.Parent = checkbox

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = checkbox

	local state = false
	
	local function updateVisuals(newState)
		state = newState
		btn.TextColor3 = state and COLOR_TEXT or COLOR_SUBTEXT
		checkbox.BackgroundColor3 = state and COLOR_ACCENT or Color3.fromRGB(25, 25, 35)
		cbStroke.Color = state and COLOR_ACCENT or Color3.fromRGB(50, 50, 70)
		if callback then callback(state) end
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

// Slider mejorado
local function createSlider(parent, posY, defaultVal, minVal, maxVal, titlePrefix, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 48)
	container.Position = UDim2.new(0, 0, 0, posY)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLOR_SUBTEXT
	label.TextSize = 12
	label.Font = FONT_MAIN
	label.Text = titlePrefix .. ": " .. defaultVal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	// Barra del slider
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 26)
	bar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	bar.Parent = container

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = COLOR_ACCENT
	fill.Parent = bar

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 12, 0, 12)
	indicator.AnchorPoint = Vector2.new(0.5, 0.5)
	indicator.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	indicator.Parent = bar

	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(1, 0)
	ic.Parent = indicator

	local dragging = false
	local function updateSlider(mouseX)
		local barPos = bar.AbsolutePosition.X
		local barSize = bar.AbsoluteSize.X
		local clampPos = math.clamp((mouseX - barPos) / barSize, 0, 1)
		fill.Size = UDim2.new(clampPos, 0, 1, 0)
		indicator.Position = UDim2.new(clampPos, 0, 0.5, 0)
		local calculatedVal = math.floor(minVal + (clampPos * (maxVal - minVal)))
		label.Text = titlePrefix .. ": " .. calculatedVal
		if callback then callback(calculatedVal) end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local mousePos = UserInputService:GetMousePosition().X
			updateSlider(mousePos)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMousePosition().X
			updateSlider(mousePos)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

//========================================
// PESTAÑA: COMBAT (Combat)
 //========================================
local cardCombatGen = createCard(pages["combat"], "General", 10, 10, 710, 200)

createToggle(cardCombatGen, 10, "Aimbot (Clic Derecho)", function(v) settings.aimEnabled = v end, "aimbot")
createToggle(cardCombatGen, 50, "Wallbang (Atravesar Paredes)", function(v) settings.wallbangEnabled = v end)
createToggle(cardCombatGen, 90, "Hitbox Extender", function(v) settings.hitboxEnabled = v end)
createSlider(cardCombatGen, 130, settings.hitboxSize, 2, 20, "Tamaño Hitbox", function(val) settings.hitboxSize = val end)

local cardCombatFov = createCard(pages["combat"], "FOV Settings", 10, 220, 710, 100)
createSlider(cardCombatFov, 10, settings.fovRadius, 50, 300, "Radio FOV", function(val)
	settings.fovRadius = val
	fovFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
	fovFrame.Position = UserInputService:GetMouseLocation()
end)

local cardCombatBone = createCard(pages["combat"], "Target Selection", 10, 330, 710, 80)
local partsList = {"Head", "HumanoidRootPart", "UpperTorso"}
local boneBtn = Instance.new("TextButton")
boneBtn.Size = UDim2.new(1, 0, 0, 30)
boneBtn.Position = UDim2.new(0, 0, 0, 0)
boneBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
boneBtn.TextColor3 = COLOR_ACCENT
boneBtn.TextSize = 12
boneBtn.Font = FONT_MAIN
boneBtn.Text = "Goal: " .. settings.targetPart
boneBtn.Parent = cardCombatBone
local bbc = Instance.new("UICorner")
bbc.CornerRadius = UDim.new(0, 6)
bbc.Parent = boneBtn

boneBtn.MouseButton1Click:Connect(function()
	settings.targetPart = partsList[#boneBtn.Text:match("Goal: (%a+)") and #boneBtn.Text:match("Goal: (%a+)") or 1] -- Lógica simplificada para cambiar
	-- Cambio manual más limpio:
	settings.targetPart = (settings.targetPart == "Head") and "HumanoidRootPart" or "Head"
	boneBtn.Text = "Goal: " .. settings.targetPart
end)

//========================================
// PESTAÑA: VISUALS (Visuals)
//========================================
local cardVisuals = createCard(pages["visuals"], "ESP Settings", 10, 10, 710, 350)

createToggle(cardVisuals, 10, "ESP Players", function(v) settings.espEnabled = v end, "esp")
createToggle(cardVisuals, 50, "ESP Names", function(v) settings.espNamesEnabled = v end)
createToggle(cardVisuals, 90, "ESP Lines (Centro)", function(v) settings.espLinesEnabled = v end)
createToggle(cardVisuals, 130, "ESP Box", function(v) settings.espBoxEnabled = v end)
createToggle(cardVisuals, 170, "ESP Health (Corazones)", function(v) settings.espHealthEnabled = v end)
createSlider(cardVisuals, 210, settings.maxDistance, 100, 3000, "Distancia Máx.", function(val) settings.maxDistance = val end)

//========================================
// PESTAÑA: WEAPON (Weapon)
//========================================
local cardWeapon = createCard(pages["weapon"], "Weapon Mods", 10, 10, 710, 80)
createToggle(cardWeapon, 10, "Infinite Ammo", function(v) settings.ammoEnabled = v end)

//========================================
// PESTAÑA: TELEPORT (Teleport)
//========================================
local cardTp = createCard(pages["teleport"], "Teleport", 10, 10, 710, 420)

local playerListContainer = Instance.new("ScrollingFrame")
playerListContainer.Size = UDim2.new(1, 0, 0, 250)
playerListContainer.Position = UDim2.new(0, 0, 0, 50)
playerListContainer.BackgroundTransparency = 1
playerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListContainer.ScrollBarThickness = 3
playerListContainer.Parent = cardTp

local plLayout = Instance.new("UIListLayout")
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Padding = UDim.new(0, 5)
plLayout.Parent = playerListContainer

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, 0, 0, 25)
selectedLabel.Position = UDim2.new(0, 0, 0, 310)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = COLOR_SUBTEXT
selectedLabel.TextSize = 12
selectedLabel.Font = FONT_MAIN
selectedLabel.Text = "Selected: None"
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = cardTp

local tpActionBtn = Instance.new("TextButton")
tpActionBtn.Size = UDim2.new(1, 0, 0, 35)
tpActionBtn.Position = UDim2.new(0, 0, 0, 350)
tpActionBtn.BackgroundColor3 = COLOR_ACCENT
tpActionBtn.TextColor3 = COLOR_BG
tpActionBtn.TextSize = 13
tpActionBtn.Font = FONT_TITLE
tpActionBtn.Text = "TELEPORT TO PLAYER"
tpActionBtn.Parent = cardTp
local tac = Instance.new("UICorner")
tac.CornerRadius = UDim.new(0, 6)
tac.Parent = tpActionBtn

local function updatePlayerList()
	playerListContainer:GetChildren():Destroy() -- Limpiar
	local players = Players:GetPlayers()
	playerListContainer.CanvasSize = UDim2.new(0, 0, 0, #players * 30)
	
	for i, p in ipairs(players) do
		if p ~= localPlayer then
			local pBtn = Instance.new("TextButton")
			pBtn.Size = UDim2.new(1, 0, 0, 26)
			pBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
			pBtn.TextColor3 = COLOR_TEXT
			pBtn.TextSize = 11
			pBtn.Font = FONT_MAIN
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
		for i = 1, 20 do
			if not myRoot or not targetRoot then break end
			myRoot.CFrame = myRoot.CFrame:Lerp(targetRoot.CFrame + Vector3.new(0, 3, 0), i / 20)
			myRoot.Velocity = Vector3.new(0, 0, 0)
			task.wait(0.01)
		end
	end
end)

//========================================
// PESTAÑA: TROLL (Troll)
//========================================
local cardTroll = createCard(pages["troll"], "Troll Actions", 10, 100, 710, 120)
createToggle(cardTroll, 10, "Tracker (Frente a la cara)", function(v) settings.trollTrackEnabled = v end)
createToggle(cardTroll, 50, "Orbit (Girar alrededor)", function(v) settings.trollOrbitEnabled = v end)

//========================================
// PESTAÑA: MISC (Misc)
//========================================
local cardMisc = createCard(pages["misc"], "Movement & Misc", 10, 230, 710, 300)
createToggle(cardMisc, 10, "Ctrl + Click TP", function(v) settings.ctrlClickTpEnabled = v end)
createToggle(cardMisc, 50, "Fly Mode", function(v) settings.flyEnabled = v end, "fly")
createSlider(cardMisc, 90, settings.flySpeed, 10, 150, "Fly Speed", function(val) settings.flySpeed = val end)
createToggle(cardMisc, 130, "Custom Speed", function(v) settings.speedEnabled = v end, "speed")
createSlider(cardMisc, 170, settings.customSpeed, 16, 120, "Speed Value", function(val) settings.customSpeed = val end)
createToggle(cardMisc, 210, "Super Jump", function(v) settings.jumpEnabled = v end, "jump")
createSlider(cardMisc, 250, settings.customJump, 50, 350, "Jump Power", function(val) settings.customJump = val end)
createToggle(cardMisc, 290, "Noclip", function(v) settings.noclipEnabled = v end, "noclip")
createToggle(cardMisc, 330, "Bhop", function(v) settings.bhopEnabled = v end)
createToggle(cardMisc, 370, "Spinbot", function(v) settings.spinEnabled = v end, "spinbot")

//========================================
// PESTAÑA: KEYBINDS (Keybinds)
//========================================
local cardBinds = createCard(pages["keybinds"], "Keybind Configuration", 10, 10, 710, 320)

local function createKeybindRow(parent, posY, labelName)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.Position = UDim2.new(0, 0, 0, posY)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLOR_SUBTEXT
	label.TextSize = 12
	label.Font = FONT_MAIN
	label.Text = labelName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0, 130, 0, 28)
	bindBtn.Position = UDim2.new(1, -130, 0.5, -14)
	bindBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	bindBtn.TextColor3 = COLOR_ACCENT
	bindBtn.TextSize = 11
	bindBtn.Font = FONT_MAIN
	bindBtn.Text = "F1" -- Default
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
		bindBtn.Text = "[ Press Key ]"
		bindBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
				bindBtn.Text = "None"
			else
				bindBtn.Text = input.KeyCode.Name
			end
			listening = false
			bindBtn.TextColor3 = COLOR_ACCENT
		end
	end)
end

createKeybindRow(cardBinds, 50, "Aimbot")
createKeybindRow(cardBinds, 100, "ESP")
createKeybindRow(cardBinds, 150, "Noclip")
createKeybindRow(cardBinds, 200, "Fly")
createKeybindRow(cardBinds, 250, "Hitbox Ext.")
createKeybindRow(cardBinds, 300, "Spinbot")

// Conexiones de Keybinds globales
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		for feature, keyCode in pairs(keybinds) do
			if input.KeyCode == keyCode and toggleStates[feature] then
				local newState = not toggleStates[feature].Get()
				toggleStates[feature].Set(newState)
				sendNotification("Zvolt", feature:upper() .. ": " .. (newState and "ON" or "OFF"))
			end
		end
	end
end)

//========================================
// LÓGICA DEL JUEGO (RenderStepped)
//========================================

// Sistema ESP Mejorado y Corregido
local espObjects = {}

local function removeESP(player)
	if espObjects[player] then
		for _, v in pairs(espObjects[player]) do
			if v and v.Parent then
				v:Destroy()
			end
		end
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

	if settings.espEnabled then
		if not espObjects[player] then
			// Crear ESP
			local hl = Instance.new("Highlight")
			hl.Adornee = char
			hl.FillColor = COLOR_ACCENT
			hl.OutlineColor = COLOR_ACCENT
			hl.FillTransparency = 0.8
			hl.Parent = char

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 150, 0, 50)
			bb.StudsOffset = Vector3.new(0, 2, 0)
			bb.AlwaysOnTop = true
			bb.Parent = char

			local nameTag = Instance.new("TextLabel")
			nameTag.Size = UDim2.new(1, 0, 0
