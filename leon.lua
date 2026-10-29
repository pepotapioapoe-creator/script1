--[[
    SOVICH - TWD3 PRO (UNIVERSAL 2D DRAWING ESP + SEARCH TELEPORT + SPINBOT + WEAPON CONFIG SKIN SWAPPER)
    v3.7 Update: Real Weapon Skin Swapper via ReplicatedStorage WeaponConfig + Visual Color Customizer
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultJumpHeight = 7.2

-- Cargar Configuración de Armas del Juego (Si existe)
local ok, WeaponConfig = pcall(function() return require(RS:WaitForChild("Config", 2):WaitForChild("WeaponConfig", 2)) end)
if not ok then WeaponConfig = nil end

local settings = {
	aimEnabled = false,
	aimSmoothness = 5,
	aimKey = Enum.UserInputType.MouseButton2,
	espEnabled = false,
	espBoxesEnabled = true,
	espNamesEnabled = true,
	espTracersEnabled = true,
	espHealthEnabled = true,
	espDistanceEnabled = true,
	flyEnabled = false,
	noclipEnabled = false,
	speedEnabled = false,
	jumpEnabled = false,
	bhopEnabled = false,
	hitboxEnabled = false,
	spinbotEnabled = false,
	spinbotSpeed = 20,
	targetPart = "Head",
	hitboxSize = 5,
	fovRadius = 140,
	flySpeed = 50,
	customSpeed = 32,
	customJump = 100,
	espColor = Color3.fromRGB(170, 0, 255),
	aimbotTargeting = false,
	tpSearchText = "",
	
	-- Configuración de Skins Visuales (Colors & Material)
	skinsEnabled = false,
	skinMaterial = Enum.Material.Neon,
	weaponR = 0,
	weaponG = 255,
	weaponB = 150,
	knifeR = 255,
	knifeG = 0,
	knifeB = 200
}

local knifeBases = {"ButterflyKnife","ClassKnife","CordKnife","FlipKnife","GutKnife","OutDoorKnife","TacticalKnife","Karambit","Kukri","Wakizashi","CrookSword","Axe","Chainsaw","Shovel","Skeleton","RadishBlade","Lollipop","Trumpet","Bayonet_M9","BeamSaber","PrismTwins","ScalySawTeeth","Glove"}
local sniperBases = {"SSG","Kar98k","AWP","M82A1","M200","DSR1","NTW20","WA2000","Sniper1","Sniper2","Specter","Crossbow"}

local function isKnifeBase(base)
	for _, b in ipairs(knifeBases) do if base == b then return true end end
	return false
end

local backups = {}

local function backupBase(baseKey)
	if backups[baseKey] or not WeaponConfig or not WeaponConfig[baseKey] then return end
	local base = WeaponConfig[baseKey]
	local b = {Display = base.Display, Image = base.Image, SoundGroup = base.SoundGroup, MeleeSeq = base.MeleeSeq, ControllerComponents = base.ControllerComponents}
	local parent = base.FirstPersonModel and base.FirstPersonModel.Parent
	if parent then
		b.FP = parent:FindFirstChild("FirstPerson") or parent:FindFirstChild("PrimeraPersona")
		b.TP = parent:FindFirstChild("ThirdPerson") or parent:FindFirstChild("TerceraPersona")
	end
	b.FakeArmAnims = {}
	for n, a in pairs(base.FakeArmAnims or {}) do if typeof(a) == "Instance" then b.FakeArmAnims[n] = a end end
	b.CharacterAnims = {}
	for n, a in pairs(base.CharacterAnims or {}) do if typeof(a) == "Instance" then b.CharacterAnims[n] = a end end
	backups[baseKey] = b
end

local function resetBase(baseKey)
	if not WeaponConfig or not WeaponConfig[baseKey] or not backups[baseKey] then return end
	local base = WeaponConfig[baseKey]
	local b = backups[baseKey]
	local parent = base.FirstPersonModel and base.FirstPersonModel.Parent
	if parent then
		local fp = parent:FindFirstChild("FirstPerson") or parent:FindFirstChild("PrimeraPersona")
		local tp = parent:FindFirstChild("ThirdPerson") or parent:FindFirstChild("TerceraPersona")
		if fp and fp ~= b.FP then fp:Destroy() end
		if tp and tp ~= b.TP then tp:Destroy() end
		if b.FP then b.FP.Name = "FirstPerson"; b.FP.Parent = parent end
		if b.TP then b.TP.Name = "ThirdPerson"; b.TP.Parent = parent end
	end
	base.FirstPersonModel = b.FP
	base.Display = b.Display
	base.Image = b.Image
	base.SoundGroup = b.SoundGroup
	base.MeleeSeq = b.MeleeSeq
	base.ControllerComponents = b.ControllerComponents
	if b.FakeArmAnims then for n, a in pairs(b.FakeArmAnims) do base.FakeArmAnims[n] = a end end
	if b.CharacterAnims then for n, a in pairs(b.CharacterAnims) do base.CharacterAnims[n] = a end end
end

local function swapWeapon(baseKey, exoticKey)
	if not WeaponConfig then return end
	local base = WeaponConfig[baseKey]
	local exotic = WeaponConfig[exoticKey]
	if not base or not exotic then return end
	local baseFP = base.FirstPersonModel
	local exoFP = exotic.FirstPersonModel
	if typeof(baseFP) ~= "Instance" or typeof(exoFP) ~= "Instance" then return end
	
	local baseParent = baseFP.Parent
	local exoParent = exoFP.Parent
	local oldFP = baseParent:FindFirstChild("FirstPerson") or baseParent:FindFirstChild("PrimeraPersona")
	local oldTP = baseParent:FindFirstChild("ThirdPerson") or baseParent:FindFirstChild("TerceraPersona")
	local newFP = exoParent:FindFirstChild("FirstPerson") or exoParent:FindFirstChild("PrimeraPersona") or exoFP
	local newTP = exoParent:FindFirstChild("ThirdPerson") or exoParent:FindFirstChild("TerceraPersona")
	
	if oldFP and oldFP ~= newFP then oldFP.Name = "FirstPerson_OLD" end
	if oldTP and oldTP ~= newTP then oldTP.Name = "ThirdPerson_OLD" end
	
	local clonedFP = newFP:Clone(); clonedFP.Name = "FirstPerson"; clonedFP.Parent = baseParent
	base.FirstPersonModel = clonedFP
	if newTP then
		local clonedTP = newTP:Clone(); clonedTP.Name = "ThirdPerson"; clonedTP.Parent = baseParent
	end
	if exotic.FakeArmAnims then
		for name, anim in pairs(exotic.FakeArmAnims) do
			if typeof(anim) == "Instance" then base.FakeArmAnims[name] = anim end
		end
	end
	if exotic.CharacterAnims then
		for name, anim in pairs(exotic.CharacterAnims) do
			if typeof(anim) == "Instance" then base.CharacterAnims[name] = anim end
		end
	end
	base.Display = exotic.Display
	base.Image = exotic.Image
	if exotic.SoundGroup and typeof(exotic.SoundGroup) == "Instance" then base.SoundGroup = exotic.SoundGroup:Clone() end
	if exotic.MeleeSeq then base.MeleeSeq = exotic.MeleeSeq end
	if exotic.ControllerComponents then base.ControllerComponents = exotic.ControllerComponents end
end

local function applySkin(skinKey)
	if not WeaponConfig or not WeaponConfig[skinKey] then return end
	local allBases = {}
	for k, v in pairs(WeaponConfig) do
		if type(k) == "string" and not k:find("%.") and v.FirstPersonModel then allBases[k] = true end
	end
	local function getBaseKey(sKey)
		if allBases[sKey] then return sKey end
		for segment in sKey:gmatch("[^%.]+") do if allBases[segment] then return segment end end
		return sKey:match("^([^%.]+)")
	end
	local baseKey = getBaseKey(skinKey)
	if not baseKey or not WeaponConfig[baseKey] then return end
	if isKnifeBase(baseKey) then baseKey = "ClassKnife" end
	if not WeaponConfig[baseKey] then return end
	
	backupBase(baseKey)
	swapWeapon(baseKey, skinKey)
end

local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		if not settings.speedEnabled then defaultWalkSpeed = humanoid.WalkSpeed end
		if not settings.jumpEnabled then
			defaultJumpPower = humanoid.JumpPower
			defaultJumpHeight = humanoid.JumpHeight
		end
	end
end

if localPlayer.Character then setupCharacter(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(setupCharacter)

--// GUI Principal
local gui = Instance.new("ScreenGui")
gui.Name = "SovichHub_" .. math.random(11111, 99999)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = localPlayer:WaitForChild("PlayerGui")

--// Círculo FOV
local fovFrame = Instance.new("Frame")
fovFrame.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = gui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = settings.espColor
fovStroke.Thickness = 2
fovStroke.Parent = fovFrame
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

--// BOTÓN FLOTANTE
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 45, 0, 45)
toggleButton.Position = UDim2.new(0, 25, 0, 150)
toggleButton.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
toggleButton.Text = "S"
toggleButton.TextColor3 = Color3.fromRGB(200, 130, 255)
toggleButton.TextSize = 20
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = gui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(1, 0)
tbCorner.Parent = toggleButton
local tbStroke = Instance.new("UIStroke")
tbStroke.Color = Color3.fromRGB(160, 0, 240)
tbStroke.Thickness = 2
tbStroke.Parent = toggleButton

local draggingBtn, dragStartBtn, startPosBtn
toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingBtn = true; dragStartBtn = input.Position; startPosBtn = toggleButton.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartBtn
		toggleButton.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingBtn = false end
end)

--// VENTANA PRINCIPAL
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 360)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 8)
mfCorner.Parent = mainFrame
local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(70, 45, 100)
mfStroke.Thickness = 1.5
mfStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(20, 17, 32)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
local tbCorner2 = Instance.new("UICorner")
tbCorner2.CornerRadius = UDim.new(0, 8)
tbCorner2.Parent = topBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 300, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(210, 160, 255)
titleText.TextSize = 13
titleText.Font = Enum.Font.GothamBold
titleText.Text = "SOVICH HUB  |  v3.7 Universal & Skin Swap"
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local draggingMain, dragInputMain, dragStartMain, startPosMain
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingMain = true; dragStartMain = input.Position; startPosMain = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then draggingMain = false end end)
	end
end)
topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInputMain = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInputMain and draggingMain then
		local delta = input.Position - dragStartMain
		mainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
	end
end)

local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 135, 1, -45)
sidebar.Position = UDim2.new(0, 6, 0, 40)
sidebar.BackgroundTransparency = 1
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.ScrollBarThickness = 0
sidebar.Parent = mainFrame
local sbLayout = Instance.new("UIListLayout")
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Padding = UDim.new(0, 4)
sbLayout.Parent = sidebar

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, -155, 1, -45)
pagesContainer.Position = UDim2.new(0, 148, 0, 40)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

toggleButton.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)

local tabs, currentTab = {}, nil
local function createTabContent(name)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name .. "Content"
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 650)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 0, 220)
	scroll.Visible = false
	scroll.Parent = pagesContainer
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = scroll
	return scroll
end

local tabMain = createTabContent("Principal")
local tabCombat = createTabContent("Combate")
local tabMovement = createTabContent("Movimiento")
local tabVisuals = createTabContent("Visuales")
local tabSkins = createTabContent("Skins")

local tabTeleport = Instance.new("Frame")
tabTeleport.Name = "TeleportContent"
tabTeleport.Size = UDim2.new(1, 0, 1, 0)
tabTeleport.BackgroundTransparency = 1
tabTeleport.Visible = false
tabTeleport.Parent = pagesContainer

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, 32)
searchBox.Position = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.PlaceholderColor3 = Color3.fromRGB(130, 120, 150)
searchBox.Text = ""
searchBox.TextSize = 13
searchBox.Font = Enum.Font.GothamMedium
searchBox.Parent = tabTeleport

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 6)
sbCorner.Parent = searchBox

local sbStroke = Instance.new("UIStroke")
sbStroke.Color = Color3.fromRGB(80, 45, 120)
sbStroke.Thickness = 1
sbStroke.Parent = searchBox

local tpScroll = Instance.new("ScrollingFrame")
tpScroll.Size = UDim2.new(1, 0, 1, -40)
tpScroll.Position = UDim2.new(0, 0, 0, 40)
tpScroll.BackgroundTransparency = 1
tpScroll.ScrollBarThickness = 4
tpScroll.ScrollBarImageColor3 = Color3.fromRGB(150, 0, 220)
tpScroll.Parent = tabTeleport

local tpListLayout = Instance.new("UIListLayout")
tpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tpListLayout.Padding = UDim.new(0, 6)
tpListLayout.Parent = tpScroll

local function switchTab(tabName)
	for name, scroll in pairs(tabs) do scroll.Visible = (name == tabName) end
	currentTab = tabName
end

local function createSidebarButton(order, name, associatedScroll)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(22, 18, 35)
	btn.TextColor3 = Color3.fromRGB(180, 160, 210)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamMedium
	btn.Text = "  " .. name
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = order
	btn.Parent = sidebar
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	tabs[name] = associatedScroll
	btn.MouseButton1Click:Connect(function() switchTab(name) end)
	if not currentTab then switchTab(name) end
	return btn
end

createSidebarButton(1, "Principal", tabMain)
createSidebarButton(2, "Combate", tabCombat)
createSidebarButton(3, "Movimiento", tabMovement)
createSidebarButton(4, "Visuales", tabVisuals)
createSidebarButton(5, "Teleport", tabTeleport)
createSidebarButton(6, "Skins", tabSkins)

local function createButtonIn(parentScroll, order, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
	btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.LayoutOrder = order
	btn.Parent = parentScroll
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 35, 90)
	stroke.Thickness = 1
	stroke.Parent = btn
	if callback then btn.MouseButton1Click:Connect(function() callback(btn) end) end
	return btn
end

local function createSliderIn(parentScroll, order, defaultVal, minVal, maxVal, titlePrefix, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -10, 0, 48)
	container.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
	container.LayoutOrder = order
	container.Parent = parentScroll
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 20)
	label.Position = UDim2.new(0, 8, 0, 4)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(210, 210, 210)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Text = titlePrefix .. ": " .. defaultVal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 6)
	bar.Position = UDim2.new(0, 10, 0, 30)
	bar.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	bar.Parent = container

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(150, 0, 220)
	fill.Parent = bar

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 14, 0, 14)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = ""
	btn.Parent = bar

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
	return container
end

-- CONTROLES PRINCIPAL
createButtonIn(tabMain, 1, "SpeedHack: OFF", function(btn)
	settings.speedEnabled = not settings.speedEnabled
	btn.Text = settings.speedEnabled and "SpeedHack: ON" or "SpeedHack: OFF"
	btn.BackgroundColor3 = settings.speedEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
	if not settings.speedEnabled and localPlayer.Character then
		local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = defaultWalkSpeed end
	end
end)
createSliderIn(tabMain, 2, settings.customSpeed, 16, 150, "Velocidad Walk", function(val) settings.customSpeed = val end)

createButtonIn(tabMain, 3, "Super Jump: OFF", function(btn)
	settings.jumpEnabled = not settings.jumpEnabled
	btn.Text = settings.jumpEnabled and "Super Jump: ON" or "Super Jump: OFF"
	btn.BackgroundColor3 = settings.jumpEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
	if not settings.jumpEnabled and localPlayer.Character then
		local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.JumpPower = defaultJumpPower; hum.JumpHeight = defaultJumpHeight end
	end
end)
createSliderIn(tabMain, 4, settings.customJump, 50, 350, "Altura Salto", function(val) settings.customJump = val end)

-- CONTROLES COMBATE
createButtonIn(tabCombat, 1, "Aimbot / AimAssist: OFF", function(btn)
	settings.aimEnabled = not settings.aimEnabled
	btn.Text = settings.aimEnabled and "Aimbot / AimAssist: ON" or "Aimbot / AimAssist: OFF"
	btn.BackgroundColor3 = settings.aimEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)
createSliderIn(tabCombat, 2, settings.fovRadius, 50, 300, "Tamaño FOV", function(val)
	settings.fovRadius = val; fovFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
end)
createSliderIn(tabCombat, 3, settings.aimSmoothness, 1, 10, "AimAssist Suavizado (1=Fuerte, 10=Súper Suave)", function(val) settings.aimSmoothness = val end)

createButtonIn(tabCombat, 4, "Head Hitbox Extender: OFF", function(btn)
	settings.hitboxEnabled = not settings.hitboxEnabled
	btn.Text = settings.hitboxEnabled and "Head Hitbox Extender: ON" or "Head Hitbox Extender: OFF"
	btn.BackgroundColor3 = settings.hitboxEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)
createSliderIn(tabCombat, 5, settings.hitboxSize, 2, 20, "Tamaño Hitbox Cabeza", function(val) settings.hitboxSize = val end)

createButtonIn(tabCombat, 6, "Spinbot: OFF", function(btn)
	settings.spinbotEnabled = not settings.spinbotEnabled
	btn.Text = settings.spinbotEnabled and "Spinbot: ON" or "Spinbot: OFF"
	btn.BackgroundColor3 = settings.spinbotEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
	if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
		localPlayer.Character:FindFirstChildOfClass("Humanoid").AutoRotate = not settings.spinbotEnabled
	end
end)
createSliderIn(tabCombat, 7, settings.spinbotSpeed, 5, 100, "Velocidad Spinbot", function(val) settings.spinbotSpeed = val end)

-- CONTROLES MOVIMIENTO
createButtonIn(tabMovement, 1, "Fly (Volar): OFF", function(btn)
	settings.flyEnabled = not settings.flyEnabled
	btn.Text = settings.flyEnabled and "Fly (Volar): ON" or "Fly (Volar): OFF"
	btn.BackgroundColor3 = settings.flyEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)
createSliderIn(tabMovement, 2, settings.flySpeed, 10, 150, "Velocidad Fly", function(val) settings.flySpeed = val end)

createButtonIn(tabMovement, 3, "Noclip (Paredes): OFF", function(btn)
	settings.noclipEnabled = not settings.noclipEnabled
	btn.Text = settings.noclipEnabled and "Noclip (Paredes): ON" or "Noclip (Paredes): OFF"
	btn.BackgroundColor3 = settings.noclipEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)

createButtonIn(tabMovement, 4, "BunnyHop (Bhop): OFF", function(btn)
	settings.bhopEnabled = not settings.bhopEnabled
	btn.Text = settings.bhopEnabled and "BunnyHop (Bhop): ON" or "BunnyHop (Bhop): OFF"
	btn.BackgroundColor3 = settings.bhopEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)

-- CONTROLES VISUALES
createButtonIn(tabVisuals, 1, "ESP Master: OFF", function(btn)
	settings.espEnabled = not settings.espEnabled
	btn.Text = settings.espEnabled and "ESP Master: ON" or "ESP Master: OFF"
	btn.BackgroundColor3 = settings.espEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)
createButtonIn(tabVisuals, 2, "Cajas 2D (Boxes): ON", function(btn)
	settings.espBoxesEnabled = not settings.espBoxesEnabled
	btn.Text = settings.espBoxesEnabled and "Cajas 2D (Boxes): ON" or "Cajas 2D (Boxes): OFF"
end)
createButtonIn(tabVisuals, 3, "Mostrar Nombres: ON", function(btn)
	settings.espNamesEnabled = not settings.espNamesEnabled
	btn.Text = settings.espNamesEnabled and "Mostrar Nombres: ON" or "Mostrar Nombres: OFF"
end)
createButtonIn(tabVisuals, 4, "Mostrar Vida (♥ %): ON", function(btn)
	settings.espHealthEnabled = not settings.espHealthEnabled
	btn.Text = settings.espHealthEnabled and "Mostrar Vida (♥ %): ON" or "Mostrar Vida (♥ %): OFF"
end)
createButtonIn(tabVisuals, 5, "Mostrar Distancia (m): ON", function(btn)
	settings.espDistanceEnabled = not settings.espDistanceEnabled
	btn.Text = settings.espDistanceEnabled and "Mostrar Distancia (m): ON" or "Mostrar Distancia (m): OFF"
end)
createButtonIn(tabVisuals, 6, "Líneas (Tracers): ON", function(btn)
	settings.espTracersEnabled = not settings.espTracersEnabled
	btn.Text = settings.espTracersEnabled and "Líneas (Tracers): ON" or "Líneas (Tracers): OFF"
end)

-- CONTROLES SKINS (INTEGRACIÓN COMPLETA DE WEAPONCONFIG & COLOR CHANGER)
createButtonIn(tabSkins, 1, "Changer Color/Neon Visual: OFF", function(btn)
	settings.skinsEnabled = not settings.skinsEnabled
	btn.Text = settings.skinsEnabled and "Changer Color/Neon Visual: ON" or "Changer Color/Neon Visual: OFF"
	btn.BackgroundColor3 = settings.skinsEnabled and Color3.fromRGB(60, 0, 110) or Color3.fromRGB(25, 20, 40)
end)

createButtonIn(tabSkins, 2, "Restaurar Skins por Defecto", function()
	for b, _ in pairs(backups) do resetBase(b) end
end)

-- CARGA DE SKINS DEL JUEGO (SI EL JUEGO USA WEAPONCONFIG)
if WeaponConfig then
	local goodSkins = {knives = {}, snipers = {}}
	local allBases = {}
	for k, v in pairs(WeaponConfig) do
		if type(k) == "string" and not k:find("%.") and v.FirstPersonModel then allBases[k] = true end
	end
	local function getBaseKey(skinKey)
		if allBases[skinKey] then return skinKey end
		for segment in skinKey:gmatch("[^%.]+") do if allBases[segment] then return segment end end
		return skinKey:match("^([^%.]+)")
	end

	for k, v in pairs(WeaponConfig) do
		if type(k) == "string" then
			local sec = v.SecondaryRarity or ""
			if v.Rarity == "Místico" or sec == "Exótico" or sec == "Secreto" or sec == "Recuerdo" then
				local base = getBaseKey(k)
				if base and WeaponConfig[base] then
					local entry = {key = k, display = v.Display or k, base = base}
					if isKnifeBase(base) then
						table.insert(goodSkins.knives, entry)
					else
						for _, b in ipairs(sniperBases) do
							if base == b then table.insert(goodSkins.snipers, entry); break end
						end
					end
				end
			end
		end
	end

	table.sort(goodSkins.knives, function(a, b) return a.display < b.display end)
	table.sort(goodSkins.snipers, function(a, b) return a.display < b.display end)

	-- SECCIÓN DE BOTONES DE ACCESO RÁPIDO PARA SWAP DE SKINS
	createButtonIn(tabSkins, 3, "--- APLICAR SKIN REAL (REINICIAR AL MORIR) ---", function() end)

	for _, s in ipairs(goodSkins.knives) do
		createButtonIn(tabSkins, 4, "Knife: " .. s.display, function() applySkin(s.key) end)
	end
	for _, s in ipairs(goodSkins.snipers) do
		createButtonIn(tabSkins, 5, "Sniper: " .. s.display, function() applySkin(s.key) end)
	end
end

createSliderIn(tabSkins, 6, settings.weaponR, 0, 255, "Arma - Rojo (R)", function(val) settings.weaponR = val end)
createSliderIn(tabSkins, 7, settings.weaponG, 0, 255, "Arma - Verde (G)", function(val) settings.weaponG = val end)
createSliderIn(tabSkins, 8, settings.weaponB, 0, 255, "Arma - Azul (B)", function(val) settings.weaponB = val end)

--// ESP ENGINE UNIVERSAL (DRAWING API 2D)
local esp2D = {}

local function createESP2D(player)
	if esp2D[player] then return end
	local box = Drawing.new("Square")
	box.Visible = false
	box.Color = settings.espColor
	box.Thickness = 1.5
	box.Filled = false

	local name = Drawing.new("Text")
	name.Visible = false
	name.Color = Color3.fromRGB(255, 255, 255)
	name.Size = 13
	name.Center = true
	name.Outline = true

	local info = Drawing.new("Text")
	info.Visible = false
	info.Color = Color3.fromRGB(200, 200, 200)
	info.Size = 12
	info.Center = true
	info.Outline = true

	local line = Drawing.new("Line")
	line.Visible = false
	line.Color = settings.espColor
	line.Thickness = 1.5

	esp2D[player] = {box = box, name = name, info = info, line = line}
end

local function removeESP2D(player)
	if esp2D[player] then
		esp2D[player].box:Remove()
		esp2D[player].name:Remove()
		esp2D[player].info:Remove()
		esp2D[player].line:Remove()
		esp2D[player] = nil
	end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then createESP2D(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= localPlayer then createESP2D(p) end end)
Players.PlayerRemoving:Connect(removeESP2D)

local function getHeadPart(char)
	if not char then return nil end
	return char:FindFirstChild("Head") or char:FindFirstChild("FakeHead") or char:FindFirstChild("head")
end

local function getRootPart(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or getHeadPart(char) or char:FindFirstChildOfClass("BasePart")
end

local function updateTeleportList()
	tpScroll:ClearAllChildren()
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = tpScroll

	local order = 1
	local filter = settings.tpSearchText:lower()

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= localPlayer then
			local pName = targetPlayer.Name:lower()
			local pDisplayName = targetPlayer.DisplayName:lower()
			
			if filter == "" or pName:find(filter, 1, true) or pDisplayName:find(filter, 1, true) then
				createButtonIn(tpScroll, order, "TP a: " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")", function()
					local tChar = targetPlayer.Character
					local myChar = localPlayer.Character
					local tRoot = getRootPart(tChar)
					local myRoot = getRootPart(myChar)
					if tRoot and myRoot then myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3) end
				end)
				order = order + 1
			end
		end
	end
	tpScroll.CanvasSize = UDim2.new(0, 0, 0, order * 42)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	settings.tpSearchText = searchBox.Text
	updateTeleportList()
end)

Players.PlayerAdded:Connect(updateTeleportList)
Players.PlayerRemoving:Connect(updateTeleportList)
updateTeleportList()

local function getClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = settings.fovRadius
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local head = getHeadPart(player.Character) or getRootPart(player.Character)
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if head and (not hum or hum.Health > 0) then
				local pos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestPlayer = head
					end
				end
			end
		end
	end
	return closestPlayer
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == settings.aimKey and settings.aimEnabled then settings.aimbotTargeting = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == settings.aimKey then settings.aimbotTargeting = false end
end)

local function applyVisualSkins()
	if not settings.skinsEnabled then return end
	local viewModel = camera:FindFirstChild("ViewModel") or camera:FindFirstChildOfClass("Model")
	if not viewModel then return end

	local weaponColor = Color3.fromRGB(settings.weaponR, settings.weaponG, settings.weaponB)
	for _, part in ipairs(viewModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local partName = part.Name:lower()
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Texture") or child:IsA("Decal") then child.Transparency = 1 end
			end
			if not partName:find("arm") and not partName:find("hand") and not partName:find("glove") then
				part.Material = settings.skinMaterial
				part.Color = weaponColor
			end
		end
	end
end

--// BUCLE PRINCIPAL
RunService.RenderStepped:Connect(function(delta)
	if not camera or not localPlayer.Character then return end
	
	local mousePos = UserInputService:GetMouseLocation()
	fovFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	fovFrame.Visible = settings.aimEnabled

	applyVisualSkins()

	if settings.aimbotTargeting and settings.aimEnabled then
		local target = getClosestPlayer()
		if target then
			local targetCF = CFrame.new(camera.CFrame.Position, target.Position)
			local smoothAlpha = math.clamp(0.15 / (settings.aimSmoothness * 0.8), 0.01, 0.2)
			camera.CFrame = camera.CFrame:Lerp(targetCF, smoothAlpha)
		end
	end

	if settings.spinbotEnabled then
		local myRoot = getRootPart(localPlayer.Character)
		local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myRoot then
			if hum then hum.AutoRotate = false end
			myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(settings.spinbotSpeed), 0)
		end
	end

	local myRoot = getRootPart(localPlayer.Character)

	for player, draw in pairs(esp2D) do
		local char = player.Character
		local root = getRootPart(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if settings.espEnabled and char and root and (not hum or hum.Health > 0) then
			local pos, onScreen = camera:WorldToViewportPoint(root.Position)

			if onScreen then
				local headPos = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
				local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
				local height = math.abs(headPos.Y - legPos.Y)
				local width = height / 1.8

				if settings.espBoxesEnabled then
					draw.box.Size = Vector2.new(width, height)
					draw.box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
					draw.box.Color = settings.espColor
					draw.box.Visible = true
				else draw.box.Visible = false end

				if settings.espNamesEnabled then
					draw.name.Text = player.DisplayName or player.Name
					draw.name.Position = Vector2.new(pos.X, (pos.Y - height / 2) - 16)
					draw.name.Visible = true
				else draw.name.Visible = false end

				local infoText = ""
				if settings.espHealthEnabled and hum then
					local hp = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
					infoText = infoText .. "♥ " .. hp .. "% "
				end
				if settings.espDistanceEnabled and myRoot then
					local dist = math.floor((myRoot.Position - root.Position).Magnitude / 3.57)
					infoText = infoText .. "[" .. dist .. "m]"
				end

				if infoText ~= "" then
					draw.info.Text = infoText
					draw.info.Position = Vector2.new(pos.X, (pos.Y + height / 2) + 2)
					draw.info.Visible = true
				else draw.info.Visible = false end

				if settings.espTracersEnabled then
					draw.line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
					draw.line.To = Vector2.new(pos.X, pos.Y)
					draw.line.Color = settings.espColor
					draw.line.Visible = true
				else draw.line.Visible = false end
			else
				draw.box.Visible = false
				draw.name.Visible = false
				draw.info.Visible = false
				draw.line.Visible = false
			end
		else
			draw.box.Visible = false
			draw.name.Visible = false
			draw.info.Visible = false
			draw.line.Visible = false
		end
	end

	if settings.noclipEnabled then
		for _, part in ipairs(localPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end

	if settings.hitboxEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				local head = getHeadPart(player.Character)
				if head then
					head.Size = Vector3.new(settings.hitboxSize, settings.hitboxSize, settings.hitboxSize)
					head.Transparency = 0.6
					head.CanCollide = false
				end
			end
		end
	end

	local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and myRoot then
		if settings.speedEnabled then
			humanoid.WalkSpeed = settings.customSpeed
			if humanoid.MoveDirection.Magnitude > 0 then
				local moveDir = humanoid.MoveDirection
				myRoot.CFrame = myRoot.CFrame + (moveDir * (settings.customSpeed / 10) * delta * 10)
			end
		end
		if settings.jumpEnabled then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = settings.customJump
			humanoid.JumpHeight = (settings.customJump / 5)
		end
		if settings.bhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			if humanoid.FloorMaterial ~= Enum.Material.Air then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if settings.flyEnabled and localPlayer.Character then
		local rootPart = getRootPart(localPlayer.Character)
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if rootPart and humanoid then
			humanoid.PlatformStand = true
			local camCF = camera.CFrame
			local moveVector = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
			local vel = moveVector * settings.flySpeed
			rootPart.Velocity = vel; rootPart.AssemblyLinearVelocity = vel
		end
	elseif localPlayer.Character then
		local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
	end
end)
