-- Script path: ReplicatedStorage.Modules.GunFramework.GunClient
-- Decompile time: 36.13 ms

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
game:GetService("InsertService")
game:GetService("ContentProvider")
local Parent = script.Parent
local clock = os.clock
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Modules = Parent.Modules
local Signal = require(Modules.Signal)
local Spring = require(Modules.Spring)
local Projectile = require(Modules.Projectile)
local Trove = require(Modules.Trove)
local VFX = require(Modules.VFX)
local Device = require(Modules.Device)
local Shared = require(Modules.Shared)
local GunStyles = require(Modules.GunStyles)
local u83 = require(ReplicatedStorage.Modules.AimAssistController)
local AimAssistEnum = require(ReplicatedStorage.Modules.AimAssistController.AimAssistEnum)
local Coroutine = Shared.Coroutine
local Remotes = Parent.Remotes
local Fire = Remotes.Fire
local Reload = Remotes.Reload
local Ticked = Remotes.Ticked
local Slide = Remotes.Slide
local SwitchBeam = Remotes.SwitchBeam
local SwitchBeam_2 = Remotes.SwitchBeam
local Effect = Remotes.Effect
local Update = Remotes.Update
local Information = Remotes.Information
local u100 = nil

local function v1(a1) -- Line: 45 -- types: a1: string?
    if typeof(a1) ~= "string" then
        return 0
    end
    local v1 = 0
    local v2 = #a1
    for i = 1, v2 do
        v1 = v1 + string.byte(a1, i) * i
    end
    return v1 % 37 * 120 + 100
end

local u102 = false
local u103 = false
local Position = Remotes:FindFirstChild("Position")
if not Position then
    local v2 = next
    local Children, Children_2 = Remotes:GetChildren()
    for k, v in v2, Children, Children_2 do
        if string.match(v.Name, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
            Position = v
            break
        end
    end
end
local u125 = -1
local u132 = Remotes.RequestCode:InvokeServer(true)
local u147 = ((ReplicatedStorage:WaitForChild("Remotes")):WaitForChild("GetConfigInfo")):InvokeServer("AimAssist")
local u150 = RaycastParams.new()
u150.CollisionGroup = "Bullet"
u150.FilterType = Enum.RaycastFilterType.Exclude
u150.FilterDescendantsInstances = {
    LocalPlayer.Character,
    workspace.Zones,
    workspace.Storage,
    workspace.Map.Background,
    (CollectionService:GetTagged("IgnoreBullets")),
}
local u171 = RaycastParams.new()
u171.CollisionGroup = "Bullet"
u171.FilterType = Enum.RaycastFilterType.Exclude
u171.FilterDescendantsInstances = {
    workspace.Zones,
    workspace.Storage,
    workspace.Map.Background,
    (CollectionService:GetTagged("IgnoreBullets")),
}
Mouse.TargetFilter = workspace.Zones
local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "GunBlur"
BlurEffect.Size = 0
BlurEffect.Enabled = false
BlurEffect.Parent = game.Lighting
local u198 = {Equip = 0, Shoot = 0}
local u199 = {}
local u200 = {}
local v3 = next
local Children_3, Children_4 = Parent.Effects:GetChildren()
for k2, i in v3, Children_3, Children_4 do
    u200[i.Name] = (require(i))
end

local function GetValidId(a1) -- Line: 115
    if not string.match(a1, "rbxassetid://") then
        return "rbxassetid://" .. a1
    end
    return a1
end

local function RandomChild(a1) -- Line: 122
    local Children = a1:GetChildren()
    return Children[math.random(1, #Children)]
end

local function GetMouseHitPosition(a1, a2, a3) -- Line: 127 -- upvalues: CurrentCamera (val), u150 (val)
    local v1 = a2.AbsolutePosition + a2.AbsoluteSize / 2
    local v2 = CurrentCamera:ScreenPointToRay(v1.X, v1.Y)
    v1 = workspace:Raycast(v2.Origin, v2.Direction * 5000, u150)
    return v1 and v1.Position or v2.Origin + v2.Direction * 5000
end

local function OnHumanoidHit(a1) -- Line: 135 -- upvalues: TweenService (val) -- types: a1: userdata
    local Parent = a1 and a1.Parent and a1.Parent:FindFirstChildWhichIsA("Humanoid")
    local Parent_2 = Parent and Parent.Parent
    if not Parent_2 then
        return
    end
    if Parent_2:FindFirstChild("OnboardingHighlight") then
        script.Parent.Parent.Parent.Remotes.Notify:FireServer("This Player is in a Tutorial!", 5)
        return
    end
    if _G.Effects ~= false and _G.HitMarkers ~= false then
        local u34 = Instance.new("Highlight")
        u34.OutlineTransparency = 0.8
        u34.FillTransparency = 1
        u34.Adornee = not (a1.Name ~= "HumanoidRootPart") and Parent_2.UpperTorso or a1
        u34.Name = "HitEffect"
        u34.Parent = Parent_2
        TweenService:Create(u34, TweenInfo.new(0.1), {FillTransparency = 0.5}):Play()
        task.delay(0.1, function() -- Line: 160 -- upvalues: u34 (val), TweenService (upval)
            if u34 then
                TweenService:Create(u34, TweenInfo.new(0.1), {FillTransparency = 1}):Play()
            end
        end)
        task.delay(0.2, function() -- Line: 166 -- upvalues: u34 (val)
            if u34 then
                u34:Destroy()
            end
        end)
        return
    end
end

local u223 = {}
u223.__index = u223

function u223.new(a1, a2) -- Line: 175 -- upvalues: Shared (val), Trove (val), Signal (val), u223 (val)
    if not a1:GetAttribute("_Loaded") then
        a1:GetAttributeChangedSignal("_Loaded"):Wait()
    end
    local Settings = a1:WaitForChild("Settings", 5)
    if not Settings then
        return nil
    end
    local v1 = require(Settings)
    local v2 = a1:GetAttribute("Id")
    local u33 = Shared.SetValues({}, a2)
    if not u33 then
        return nil
    end
    u33.Instance = a1
    u33.Handle = a1:WaitForChild("Handle", 5)
    u33.Id = v2
    u33.Settings = v1
    u33.IsEquipped = false
    u33.IsDestroyed = false
    u33._Random = Random.new(a1:GetAttribute("Seed"))
    u33.Trove = Trove.new()
    u33.EquipTrove = Trove.new()
    u33.Equipped = u33.Trove:Add((Signal.new()))
    u33.Unequipped = u33.Trove:Add((Signal.new()))
    setmetatable(u33, u223)
    u33.Trove:Add(((a1:GetAttributeChangedSignal("Seed")):Connect(function() -- Line: 212 -- upvalues: u33 (val), a1 (val)
        u33._Random = Random.new(a1:GetAttribute("Seed"))
    end)))
    return u33
end

function u223:Get(a2) -- Line: 219
    return self.Instance:GetAttribute(a2)
end

function u223:Set(a2, a3) -- Line: 223
    return self.Instance:SetAttribute(a2, a3)
end

function u223:FireBullet(a2, a3) -- Line: 227 -- upvalues: Projectile (val), u171 (val), VFX (val), LocalPlayer (val)
    local Settings = self.Settings
    local u9 = Projectile.new({
        Acceleration = Vector3.new(0, 0, 0),
        Origin = a2,
        Direction = a3,
        Speed = Settings.BulletSpeed,
        RaycastParams = u171,
    })
    local u16 = VFX:Tracer(u9.CFrame, self.Handle, Settings.AmmoType)

    function u9.Updated() -- Line: 239 -- upvalues: u9 (val), u16 (val), Settings (val)
        local Distance = u9.Distance
        local v1 = math.max(0.1, Distance / 600)
        if u16 then
            u16.CFrame = u9.CFrame
            u16.Attachment0.CFrame = CFrame.new(-v1, 0, 0)
            u16.Attachment1.CFrame = CFrame.new(v1, 0, 0)
        end
        if Settings.Range < Distance then
            return u9:Destroy()
        end
    end

    function u9.OnHit(a1, a2_2) -- Line: 254
        -- upvalues: u9 (val), VFX (upval), Settings (val), LocalPlayer (upval), a2 (val), self (val)
        u9:Destroy()
        local Instance = a2_2.Instance
        local Humanoid = Instance.Parent:FindFirstChildWhichIsA("Humanoid")
        if not Humanoid then
            VFX:GroundEffect(a2_2, Settings.Effect)
            return
        end
        if LocalPlayer.Character == Humanoid.Parent then
            VFX:MarkerHit(a2, LocalPlayer, self.Instance, Instance.Name)
        end
    end

    function u9.Destroyed() -- Line: 268 -- upvalues: u16 (val)
        if u16 then
            u16:Destroy()
        end
    end
end

function u223:Fire(a2, a3) -- Line: 275 -- upvalues: VFX (val), Shared (val)
    local Handle = self.Handle
    if Handle and Handle:FindFirstChild("FireSounds") then
        local Attribute, v1
        local _Random = self._Random
        local Settings = self.Settings
        local IsShotgun = Settings.IsShotgun
        local BulletCount = IsShotgun and Settings.BulletCount or 1
        VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
        VFX:EjectShell(self.Settings.AmmoType, Handle.FireSounds, self.Instance and self.Instance.Name)
        for i, j in Handle.FireSounds:GetChildren() do
            if _G.GunVolume then
                Attribute = j:GetAttribute("Volume")
                v1 = Attribute and Attribute * _G.GunVolume
                if Attribute and v1 then
                    j.Volume = v1
                end
            end
            j:Play()
        end
        for k = 1, BulletCount do
            self:FireBullet(a2, if not IsShotgun then a3 else Shared.RandomizeDirection(a2, a3, _Random, Settings))
        end
        return
    end
end

function u223.OnEquip(a1) -- Line: 314 -- upvalues: u199 (val)
    if a1.Id then
        u199[a1.Id] = a1
        a1.EquipTrove:Add(function() -- Line: 317 -- upvalues: u199 (upval), a1 (val)
            if u199[a1.Id] == a1 then
                u199[a1.Id] = nil
            end
        end)
    end
    local Handle = a1.Handle or a1.Instance and a1.Instance:FindFirstChild("Handle")
    a1.Handle = Handle
    if _G.GunVolume and a1.Handle then
        local Attribute
        for i, j in a1.Handle:GetChildren() do
            if j:IsA("Sound") then
                Attribute = j:GetAttribute("Volume")
                if Attribute then
                    j.Volume = Attribute * _G.GunVolume
                end
            end
        end
    end
    if a1.Instance and a1.Handle then
        if _G.LowGFX then
            for k, n in a1.Instance:QueryDescendants("ParticleEmitter [Enabled=true]") do
                n.Enabled = false
            end
            for m, i5 in a1.Instance:QueryDescendants("Beam [Enabled=true]") do
                if i5.Parent.Name ~= "BEAM" then
                    i5.Enabled = false
                end
            end
        elseif not _G.Effects then
            for i6, i7 in a1.Instance:QueryDescendants("ParticleEmitter [Enabled=true]") do
                i7.Enabled = false
            end
            for i8, i9 in a1.Instance:QueryDescendants("Beam [Enabled=true]") do
                if i9.Parent.Name ~= "BEAM" then
                    i9.Enabled = false
                end
            end
        end
    end
end

local u238 = {}
u238.__index = u238

function u238.new(a1) -- Line: 360
    -- upvalues: Shared (val), LocalPlayer (val), u103 (ref), Trove (val), Spring (val), Signal (val), u83 (val)
    -- upvalues: u238 (val)
    local Animation_2, Id, _Animations_2, v1, v2
    if not a1:GetAttribute("_Loaded") then
        a1:GetAttributeChangedSignal("_Loaded"):Wait()
    end
    local Settings = a1:WaitForChild("Settings", 5)
    if not Settings then
        return nil
    end
    local v3 = require(Settings)
    local v4 = a1:GetAttribute("Id")
    local u216 = Shared.SetValues({}, LocalPlayer)
    if not u216 then
        return nil
    end
    u216.Instance = a1
    u216.Handle = a1:WaitForChild("Handle", 5)
    u216.Id = v4
    u216.Settings = v3
    u216.PendingSlide = false
    u216.LastFired = 0
    u216.DeltaTime = (v3.FireRate / 60) ^ -1
    u216.IsEquipped = false
    u216.IsDestroyed = false
    u216._Animations = {}
    u216._FireRequest = false
    u216._LastRequest = false
    u216._HoldState = false
    u216._ScopeState = false
    u103 = false
    u216._EquipTime = 0
    u216._SlideTime = (1 / 0)
    u216._dt = 0
    u216._Random = Random.new(a1:GetAttribute("Seed"))
    u216.DualShot = 1
    u216.Trove = Trove.new()
    u216.EquipTrove = Trove.new()
    u216.Spring_Recoil = Spring.new(nil, 100, 5, 2)
    u216.Equipped = u216.Trove:Add((Signal.new()))
    u216.Unequipped = u216.Trove:Add((Signal.new()))
    u216.Beam = u216.Instance:FindFirstChild("BEAM", true) ~= nil
    u216.aimAssistController = u83.new()
    v4 = u216.Humanoid:WaitForChild("Animator")
    local v5 = nil
    local v6 = nil
    for i, j in v3.Animations, v5, v6 do
        Animation_2 = Instance.new("Animation")
        Id = j.Id
        Animation_2.AnimationId = if string.match(Id, "rbxassetid://") then Id else "rbxassetid://" .. Id
        Animation_2.Parent = u216.Handle
        Animation_2.Name = i
        v1 = v4:LoadAnimation(Animation_2)
        _Animations_2 = u216._Animations
        v2 = {Instance = Animation_2, Track = v1, Speed = j.Speed, Priority = j.Priority}
        _Animations_2[i] = v2
        u216.Trove:Add(Animation_2)
        u216.Trove:Add(v1)
    end
    v3 = a1:FindFirstChild("Settings")
    if v3 and v3:FindFirstChild("ShootRun") then
        local Animation = Instance.new("Animation")
        Animation.AnimationId = if string.match(127163229087574, "rbxassetid://") then 127163229087574 else "rbxassetid://" .. 127163229087574
        Animation.Parent = u216.Handle
        Animation.Name = "ShootRun"
        v5 = v4:LoadAnimation(Animation)
        u216._Animations[Animation.Name] = {
            Speed = 5,
            Instance = Animation,
            Track = v5,
            Priority = Enum.AnimationPriority.Action4,
        }
        u216.Trove:Add(Animation)
        u216.Trove:Add(v5)
    end
    setmetatable(u216, u238)
    u216:Set("Ammo_Client", (u216:Get("Ammo_Server")))
    u216:Set("Jammed", false)
    u216:Set("Slided", false)
    u216.Trove:Add(((a1:GetAttributeChangedSignal("Seed")):Connect(function() -- Line: 452 -- upvalues: u216 (val), a1 (val)
        u216._Random = Random.new(a1:GetAttribute("Seed"))
    end)))
    return u216
end

function u238:Get(a2) -- Line: 459
    return self.Instance:GetAttribute(a2)
end

function u238:Set(a2, a3) -- Line: 463
    return self.Instance:SetAttribute(a2, a3)
end

function u238:PlayAnimation(a2) -- Line: 467
    local v1 = self._Animations[a2]
    if not v1 then
        return
    end
    if v1.Priority ~= nil then
        v1.Track.Priority = v1.Priority
    end
    v1.Track:Play(1 / v1.Speed)
end

function u238:StopAnimation(a2) -- Line: 477
    local v1 = self._Animations[a2]
    v1.Track:Stop(1 / v1.Speed)
end

local function v4() -- Line: 482 -- upvalues: CurrentCamera (val)
    if CurrentCamera and CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then
        return (CurrentCamera.Focus.Position - CurrentCamera.CFrame.Position).Magnitude <= 1
    end
    return false
end

local function v5() -- Line: 492 -- upvalues: CurrentCamera (val), GuiService (val)
    local ViewportSize = CurrentCamera.ViewportSize
    return UDim2.fromOffset(ViewportSize.X / 2, ViewportSize.Y / 2 - (GuiService:GetGuiInset()).Y)
end

function u238:Update(a2) -- Line: 502
    -- upvalues: clock (val), Device (val), CurrentCamera (val), LocalPlayer (val), GuiService (val), Mouse (val)
    -- upvalues: Ticked (val)
    local v1 = clock()
    local Settings = self.Settings
    local Instance = self.Instance
    local _FireRequest = self._FireRequest
    local v2 = math.min(a2, 0.03333333333333333)
    local v3 = self.Spring_Recoil:Update(v2 * (Settings.RecoilSpeed * 0.9))
    local v4 = self._FireRequest ~= self._LastRequest
    local v5 = _FireRequest and self.DeltaTime <= v1 - self.LastFired
    if v1 - self._EquipTime < Settings.EquipTime then
        v5 = false
    end
    if not Settings.IsAutomatic then
        v5 = v5 and v4
    end
    local _HoldState = self.Humanoid:GetAttribute("_RagdollState")
    if not _HoldState then
        _HoldState = self._HoldState
        if not _HoldState then
            _HoldState = self:Get("IsReloading")
            if not _HoldState then
                _HoldState = true
                if not ((self:Get("Ammo_Client")) <= 0) then
                    _HoldState = self:Get("IsJammed") or not self:Get("Slided") or v1 - self._SlideTime < 0.8
                end
            end
        end
    end
    if not Device:IsOnMobile() then
        self._Crosshair.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
    else
        v1 = CurrentCamera.ViewportSize / 2
        if (if not CurrentCamera then false else if CurrentCamera.CameraType == Enum.CameraType.Scriptable then false else (CurrentCamera.Focus.Position - CurrentCamera.CFrame.Position).Magnitude <= 1)
            or false
            or LocalPlayer:GetAttribute("ShiftLock") then
            local _Crosshair = self._Crosshair
            local ViewportSize = CurrentCamera.ViewportSize
            local GuiInset = GuiService:GetGuiInset()
            _Crosshair.Position = UDim2.fromOffset(ViewportSize.X / 2, ViewportSize.Y / 2 - GuiInset.Y)
        else
            self._Crosshair.Position = UDim2.fromOffset(v1.X, v1.Y + (-180 - (CurrentCamera.ViewportSize.Y - 720) * 0.2))
        end
    end
    self._dt = a2
    self._LastRequest = _FireRequest
    local v6 = v2 * 60
    local v7 = CurrentCamera
    v7.CFrame = v7.CFrame * CFrame.Angles(math.rad(v3.Y * v6), math.rad(v3.X * v6), (math.rad(v3.Z)))
    if v5 then
        if not _HoldState then
            self:Fire(self.Settings.IsMultiple or 1)
            return
        end
        if v4 then
            Ticked:FireServer()
        end
    end
end

function u238:FireBullet(a2, a3) -- Line: 549
    -- upvalues: Projectile (val), u150 (val), VFX (val), u100 (ref), Position (ref), u132 (val), TweenService (val)
    -- upvalues: OnHumanoidHit (val), Players (val), LocalPlayer (val), CurrentCamera (val)
    local Settings = self.Settings
    local u9 = Projectile.new({
        Acceleration = Vector3.new(0, 0, 0),
        Origin = a2,
        Direction = a3,
        Speed = Settings.BulletSpeed,
        RaycastParams = u150,
    })
    local u16 = VFX:Tracer(u9.CFrame, self.Handle, Settings.AmmoType)

    function u9.Updated() -- Line: 560 -- upvalues: u9 (val), u16 (val), Settings (val)
        local Distance = u9.Distance
        local v1 = math.max(0.1, Distance / 600)
        if u16 then
            u16.CFrame = u9.CFrame
            u16.Attachment0.CFrame = CFrame.new(-v1, 0, 0)
            u16.Attachment1.CFrame = CFrame.new(v1, 0, 0)
        end
        if Settings.Range < Distance then
            return u9:Destroy()
        end
    end

    function u9.OnHit(a1, a2) -- Line: 575
        -- upvalues: Settings (val), self (val), u9 (val), u100 (upval), Position (upval), u132 (upval)
        -- upvalues: TweenService (upval), OnHumanoidHit (upval), VFX (upval), Players (upval), LocalPlayer (upval)
        local ExplosionRadius, v1, v2, v3
        if Settings.AmmoType == "Rocket" then
            ExplosionRadius = Settings.ExplosionRadius and Settings.ExplosionDamage
        else
            ExplosionRadius = false
            if self.Instance.Name == "Raygun" then
                ExplosionRadius = Settings.ExplosionRadius and Settings.ExplosionDamage
            end
        end
        local Position_2 = u9 and u9.Position
        if u9 then
            u9:Destroy()
        end
        local Instance = a2.Instance
        local Humanoid = Instance.Parent:FindFirstChildWhichIsA("Humanoid")
        local v4 = Instance:FindFirstAncestorWhichIsA("Model")
        local Parent = Humanoid and Humanoid.Parent
        if not Humanoid or not Parent or ExplosionRadius then
            VFX:GroundEffect(a2, Settings.Effect)
        else
            local ServerTimeNow = workspace:GetServerTimeNow()
            v1 = u100
            if typeof(v1) == "string" then
                local v5 = 0
                v2 = #v1
                for i = 1, v2 do
                    v5 = v5 + string.byte(v1, i) * i
                end
                v3 = v5 % 37 * 120 + 100
            else
                v3 = 0
            end
            v1 = ServerTimeNow - v3
            local v6 = u100
            Position:FireServer(u132, self.Id, Instance, u9.Direction, nil, v6, v1)
            task.spawn(function() -- Line: 594 -- upvalues: TweenService (upval), self (upval)
                TweenService:Create(self._Crosshair, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 42, 46)}):Play()
                task.wait(0.2)
                TweenService:Create(self._Crosshair, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)
            OnHumanoidHit(Instance)
        end
        if v4 and v4.Name == "Target" and v4.Parent.Name == "Targets" then
            local Damage = Settings.Damage
            if Settings.IsShotgun then
                Damage = Damage / Settings.BulletCount
            end
            VFX:HitTarget(a2.Position, v4, Damage)
        end
        if ExplosionRadius and Position_2 then
            local Character, HumanoidRootPart, Humanoid_2, Magnitude, v7, v8, v9, v10, v11, v12, v13
            local ExplosionRadius_2 = Settings.ExplosionRadius
            local ExplosionDamage = Settings.ExplosionDamage
            local v14 = nil
            local v15 = 0

            function v3(a1, a2) -- Line: 623
                -- upvalues: u100 (upval), Position (upval), u132 (upval), self (upval), u9 (upval)
                local v1
                local ServerTimeNow = workspace:GetServerTimeNow()
                local v2 = u100
                if typeof(v2) == "string" then
                    local v3 = 0
                    local v4 = #v2
                    for i = 1, v4 do
                        v3 = v3 + string.byte(v2, i) * i
                    end
                    v1 = v3 % 37 * 120 + 100
                else
                    v1 = 0
                end
                v2 = ServerTimeNow - v1
                local v5 = u100
                Position:FireServer(u132, self.Id, a1, u9.Direction, a2, v5, v2)
            end

            v1 = next
            local Players_2, Players_3 = Players:GetPlayers()
            for k, v in v1, Players_2, Players_3 do
                Character = v.Character
                Humanoid_2 = Character and Character:FindFirstChildWhichIsA("Humanoid")
                HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                if Character and Humanoid_2 and HumanoidRootPart then
                    Magnitude = (HumanoidRootPart.Position - Position_2).Magnitude
                    if not (ExplosionRadius_2 < Magnitude) then
                        v7 = Magnitude / ExplosionRadius_2
                        v8 = ExplosionDamage * math.clamp(math.exp(-v7 * 3) * 2.5, 0, 1)
                        if v7 <= 0.2 then
                            v8 = ExplosionDamage
                        end
                        if v ~= LocalPlayer then
                            v7 = workspace:GetServerTimeNow()
                            v10 = u100
                            if typeof(v10) == "string" then
                                v11 = 0
                                v12 = #v10
                                for j = 1, v12 do
                                    v11 = v11 + string.byte(v10, j) * j
                                end
                                v9 = v11 % 37 * 120 + 100
                            else
                                v9 = 0
                            end
                            v10 = v7 - v9
                            v13 = u100
                            Position:FireServer(u132, self.Id, HumanoidRootPart, u9.Direction, v8, v13, v10)
                        else
                            v14 = HumanoidRootPart
                            v15 = v8
                        end
                    end
                end
            end
            if v14 then
                local v16
                v4 = workspace:GetServerTimeNow()
                v2 = u100
                if typeof(v2) == "string" then
                    local v17 = 0
                    local v18 = #v2
                    for k2 = 1, v18 do
                        v17 = v17 + string.byte(v2, k2) * k2
                    end
                    v16 = v17 % 37 * 120 + 100
                else
                    v16 = 0
                end
                v2 = v4 - v16
                v10 = u100
                Position:FireServer(u132, self.Id, v14, u9.Direction, v15, v10, v2)
            end
        end
    end

    function u9.Destroyed() -- Line: 666 -- upvalues: u16 (val)
        if u16 then
            u16:Destroy()
        end
    end

    if self.Instance.Name == "Flintlock" and not _G.Crouching and not _G.Crawling then
        local Character = self.Character
        if Character then
            local PrimaryPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
            if PrimaryPart then
                local Unit = (-CurrentCamera.CFrame.LookVector + Vector3.new(0, 0.30000001192092896, 0)).Unit
                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                BodyVelocity.Velocity = Unit * 200
                BodyVelocity.P = 1500
                BodyVelocity.Parent = PrimaryPart
                task.delay(0.3, BodyVelocity.Destroy, BodyVelocity)
            end
        end
    end
end

local u260 = {"Finger-Guns", "Dual-Uzis", "Dual-Beretta"}

function u238:Fire(a2) -- Line: 697
    -- upvalues: clock (val), u150 (val), Device (val), u260 (val), CurrentCamera (val), Mouse (val), Fire (val)
    -- upvalues: u132 (val), VFX (val), TweenService (val), BlurEffect (val), Shared (val)
    local BulletCount, Character, Handle, Handle_2, IsShotgun, JamChance, MuzzleAttachment, Position, Position_3, Position_4, RootPart, Unit, _Crosshair, _Random, v1, v2, v3, v4, v5
    if not a2 then
        a2 = 1
    end
    for i = 1, a2 do
        if (self:Get("Ammo_Client")) <= 0 then
            return
        end
        local u522 = clock()
        if self.Settings.EquipTime <= u522 - self._EquipTime and not self._HoldState then
            if self.Instance.Name == "Minigun" and 10 <= self.Humanoid.WalkSpeed then
                return
            end
            if self.Character:GetAttribute("Critical") then
                return
            end
            _Random = self._Random
            local Settings = self.Settings
            IsShotgun = Settings.IsShotgun
            BulletCount = IsShotgun and Settings.BulletCount or 1
            v1 = Settings.Recoil / 5.5
            local u623 = 3
            if Device:IsOnMobile() then
                u623 = u623 * 2
            end
            if _G.Crouching then
                v1 = v1 * 0.75
                u623 = u623 * 1.25
            elseif _G.Crawling then
                v1 = v1 * 0.5
                u623 = u623 * 1.5
            end
            JamChance = not (workspace:GetAttribute("CanJam") ~= true) and Settings.JamChance or nil
            RootPart = self.RootPart
            Handle = self.Handle
            if not Handle:FindFirstChild("MuzzleAttachment") then
                return
            end
            MuzzleAttachment = Handle.MuzzleAttachment
            if table.find(u260, self.Instance.Name) and self.DualShot == 2 then
                MuzzleAttachment = Handle.SecondMuzzleAttachment
            end
            Position = MuzzleAttachment.WorldCFrame.Position
            Position_3 = workspace:Raycast(RootPart.Position, Position - RootPart.Position, u150) and RootPart.Position or Position
            if not Device:IsOnMobile() then
                Position_4 = Mouse.Hit.Position
            else
                Character = self.Character
                _Crosshair = self._Crosshair
                Handle_2 = self.Handle
                v3 = _Crosshair.AbsolutePosition + _Crosshair.AbsoluteSize / 2
                v2 = CurrentCamera:ScreenPointToRay(v3.X, v3.Y)
                v3 = workspace:Raycast(v2.Origin, v2.Direction * 5000, u150)
                Position_4 = v3 and v3.Position or v2.Origin + v2.Direction * 5000
            end
            Unit = (Position_4 - Position_3).Unit
            if Unit.Magnitude < 0.001 then
                Unit = (CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 5000 - Position_3).Unit
            end
            v4 = math.random(30, 100) * v1 / 3
            local u607 = Vector3.new((math.random(-10, 10)) * v1 / 2, v4, -(math.random(5, 10)))
            self.LastFired = u522
            Fire:FireServer(u132, Position_3, Unit)
            if not Handle.Parent.Settings:FindFirstChild("ShootRun") or not (10 <= self.Humanoid.WalkSpeed) then
                if not table.find(u260, self.Instance.Name) then
                    VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
                    self:PlayAnimation("Fire")
                elseif self.DualShot ~= 1 then
                    VFX:Muzzle(Handle:FindFirstChild("SecondGunMuzzlePoint"), self.Instance.Name)
                    self:PlayAnimation("FireSecond")
                else
                    VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
                    self:PlayAnimation("Fire")
                end
            elseif self.Humanoid.MoveDirection.Magnitude ~= 0 then
                VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
                self:PlayAnimation("ShootRun")
            elseif not table.find(u260, self.Instance.Name) then
                VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
                self:PlayAnimation("Fire")
            elseif self.DualShot ~= 1 then
                VFX:Muzzle(Handle:FindFirstChild("SecondGunMuzzlePoint"), self.Instance.Name)
                self:PlayAnimation("FireSecond")
            else
                VFX:Muzzle(Handle:FindFirstChild("GunMuzzlePoint"), self.Instance.Name)
                self:PlayAnimation("Fire")
            end
            VFX:EjectShell(self.Settings.AmmoType, Handle.FireSounds, self.Instance and self.Instance.Name)
            self:Set("Ammo_Client", (self:Get("Ammo_Client")) - 1)
            if JamChance then
                self:Set("IsJammed", math.random(1, JamChance * 1.5) == 1)
            end
            for j, k in Handle.FireSounds:GetChildren() do
                if _G.GunVolume then
                    v5 = k:GetAttribute("Volume")
                    v4 = v5 and v5 * _G.GunVolume
                    if v5 and v4 then
                        k.Volume = v4
                    end
                end
                k:Play()
            end
            self.Spring_Recoil:Shove(u607)
            task.delay(0.2, function() -- Line: 803 -- upvalues: self (val), u607 (val), Settings (val), u623 (ref)
                if not self.IsEquipped then
                    return
                end
                self.Spring_Recoil:Shove(-u607 - (Vector3.new(0, -math.clamp(Settings.Recoil, 0, 1) / u623, 0)))
            end)
            if _G.Shadows and _G.Effects and not _G.LowGFX then
                TweenService:Create(BlurEffect, TweenInfo.new(0.1), {Size = 10, Enabled = true}):Play()
                task.delay(0.1, function() -- Line: 814 -- upvalues: self (val), u522 (val), TweenService (upval), BlurEffect (upval)
                    if self.LastFired ~= u522 then
                        return
                    end
                    TweenService:Create(BlurEffect, TweenInfo.new(0.1), {Size = 0, Enabled = false}):Play()
                end)
            end
            for n = 1, BulletCount do
                self:FireBullet(Position_3, if not IsShotgun then Unit else Shared.RandomizeDirection(Position_3, Unit, _Random, Settings))
                if table.find(u260, self.Instance.Name) then
                    self.DualShot = if self.DualShot ~= 1 then 1 else 2
                end
            end
            task.wait(60 / self.Settings.FireRate / 2)
        end
    end
end

function u238:SwitchHold() -- Line: 842
    self._HoldState = not self._HoldState
    if self._HoldState then
        self:PlayAnimation("HoldDown")
        self:StopAnimation("Idle")
        return
    end
    self:StopAnimation("HoldDown")
    self:PlayAnimation("Idle")
end

function u238:RestoreScopeCamera() -- Line: 854 -- upvalues: LocalPlayer (val), UserInputService (val)
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    local _ScopeZoom = self._ScopeZoom
    if _ScopeZoom and _ScopeZoom > 1 then
        if self._Sensitivity then
            UserInputService.MouseDeltaSensitivity = self._Sensitivity
        end
        self._ScopeZoom = nil
        local CameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance
        local CameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
        LocalPlayer.CameraMinZoomDistance = _ScopeZoom
        LocalPlayer.CameraMaxZoomDistance = _ScopeZoom
        task.delay(0.1, function() -- Line: 871 -- upvalues: LocalPlayer (upval), CameraMinZoomDistance (val), CameraMaxZoomDistance (val)
            LocalPlayer.CameraMinZoomDistance = CameraMinZoomDistance
            LocalPlayer.CameraMaxZoomDistance = CameraMaxZoomDistance
        end)
    end
end

function u238:ToggleScope(a2) -- Line: 878
    -- upvalues: u103 (ref), UserInputService (val), CurrentCamera (val), LocalPlayer (val), TweenService (val)
    local ScopeGUI = a2:FindFirstChild("ScopeGUI")
    local Scope = ScopeGUI and ScopeGUI:FindFirstChild("Scope")
    if not Scope then
        return
    end
    self._ScopeState = not self._ScopeState
    u103 = self._ScopeState
    if not self._ScopeState then
        UserInputService.MouseDeltaSensitivity = self._Sensitivity or 1
        self._Sensitivity = nil
        Scope.Visible = false
        self:RestoreScopeCamera()
        if self._Crosshair then
            self._Crosshair.Visible = true
        end
        TweenService:Create(
            CurrentCamera,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {FieldOfView = (_G.FOV or 70) + (if _G.Running ~= true then 0 else 5)}
        ):Play()
        return
    end
    self._Sensitivity = UserInputService.MouseDeltaSensitivity
    self._ScopeZoom = (CurrentCamera.CFrame.Position - CurrentCamera.Focus.Position).Magnitude
    Scope.Visible = true
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    UserInputService.MouseDeltaSensitivity = self._Sensitivity / 10
    if self._Crosshair then
        self._Crosshair.Visible = false
    end
    TweenService:Create(
        CurrentCamera,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {FieldOfView = self.Settings.ScopeFOV or 15}
    ):Play()
end

function u238.SwitchBeam(a1) -- Line: 914 -- upvalues: u102 (ref), SwitchBeam (val)
    if u102 then
        return
    end
    u102 = true
    SwitchBeam:FireServer()
    task.wait(0.5)
    u102 = false
end

function u238:Slide() -- Line: 928 -- upvalues: clock (val), Slide (val)
    local v1 = clock()
    if self.Settings.EquipTime <= v1 - self._EquipTime and not self._HoldState then
        if not self:Get("Slided") or self:Get("IsJammed") then
            self._SlideTime = v1
            Slide:FireServer()
            self:PlayAnimation("Slide")
        end
        self:Set("Slided", true)
        self:Set("IsJammed", false)
    end
end

function u238:Reload() -- Line: 941 -- upvalues: clock (val), LocalPlayer (val), Reload (val)
    if clock() - self._EquipTime < self.Settings.EquipTime then
        return
    end
    local v1 = true
    if self:Get("IsReloading")
        or self:Get("IsJammed")
        or (self:Get("Capacity")) <= 0 and not LocalPlayer.Backpack:FindFirstChild(self.Settings.AmmoType .. " Ammo") then
        v1 = false
    end
    if not v1 then
        return
    end
    Reload:FireServer(self.Instance)
    self:Set("IsReloading", true)
    task.delay(self.Settings.ReloadTime + 0.5, function() -- Line: 963 -- upvalues: self (val)
        if self.Instance and self:Get("IsReloading") then
            self:Set("IsReloading", false)
        end
    end)
    if not self.Settings.IsShotgun or self.Settings.IsAutomatic then
        self:PlayAnimation("Reload")
    else
        task.spawn(function() -- Line: 970 -- upvalues: self (val)
            local BulletCount = self.Settings.BulletCount
            for i = 1, BulletCount do
                if not self.IsEquipped then
                    break
                end
                self:PlayAnimation("Reload")
                task.wait(self.Settings.ReloadTime / self.Settings.BulletCount)
            end
        end)
    end
    if self.Settings.AmmoType == "Rocket" then
        local Rocket = self.Instance.Model:FindFirstChild("Rocket")
        local Extra = Rocket and Rocket:IsA("BasePart") and Rocket:FindFirstChild("Extra")
        if Rocket and Rocket:IsA("BasePart") and Extra then
            local v2 = next
            local Descendants, Descendants_2 = Extra:GetDescendants()
            for k, v in v2, Descendants, Descendants_2 do
                if v:IsA("ParticleEmitter") or v:IsA("Beam") then
                    v.Enabled = true
                elseif v:IsA("BasePart") then
                    v.Transparency = 0
                end
            end
        end
    end
end

function u238:AutoSlide() -- Line: 1004
    if not self or not _G.AutoSlide then
        return
    end
    local v1 = self:Get("IsJammed")
    if self:Get("Slided") and not v1 then
        return
    end
    if self.PendingSlide then
        return
    end
    local Instance = self.Instance
    local Character = self.Character
    if Instance and Character then
        if Instance.Parent ~= Character then
            return
        end
        local EquipTime = self.Settings.EquipTime
        self.PendingSlide = true
        task.delay(not v1 and EquipTime or EquipTime / 1.5, function() -- Line: 1037 -- upvalues: self (val), Instance (val), Character (val)
            self.PendingSlide = false
            if Instance and Instance.Parent and Character and Instance.Parent == Character then
                self:Slide()
            end
        end)
        return
    end
end

local u279 = {
    FieldOfView = 5,
    Friction = 0.5,
    Tracking = 0.5,
    Centering = 0.4,
    MinRange = 35,
    MaxRange = 200,
    Enabled = true,
}
local u287 = {
    FieldOfView = 6,
    Friction = 0.6,
    Tracking = 0.6,
    Centering = 0.5,
    MinRange = 35,
    MaxRange = 200,
    Enabled = true,
}

function u238.OnEquip(a1) -- Line: 1067
    -- upvalues: Device (val), u147 (val), u287 (val), u279 (val), CurrentCamera (val), AimAssistEnum (val), u150 (val)
    -- upvalues: UserInputService (val), u198 (val), TweenService (val), GunStyles (val), LocalPlayer (val), clock (val)
    -- upvalues: u125 (ref), RunService (val), CollectionService (val)
    local Instance = a1.Instance
    local JamKey = a1.Settings.JamKey
    local EquipTrove = a1.EquipTrove
    local Scope = a1.Settings.Scope
    local u11 = script.GunGUI:Clone()
    local MobileButtons = u11.MobileButtons
    local Frame_2 = u11.Frame
    local Ammo = Frame_2.Frame.Ammo
    local Slide = Frame_2.Slide
    local Jam = Frame_2.Jam
    local v1 = Device:IsOnConsole()
    local v2 = Device:IsOnMobile()
    local v3 = Device:IsOnPC()
    local v4 = Device:IsOnBoth()
    local u35 = 0
    local u36 = false
    if a1.aimAssistController then
        local Mobile = if not u147 or u147 == nil then v2 and u287 or u279 else if not v2 then u147.Controller else u147.Mobile
        a1.aimAssistController:setSubject(CurrentCamera)
        a1.aimAssistController:setRange(Mobile.MaxRange)
        a1.aimAssistController:setFieldOfView(Mobile.FieldOfView)
        a1.aimAssistController:addTargetTag("Target")
        a1.aimAssistController:addPlayerTargets(true, true)
        a1.aimAssistController:setMethodStrength(AimAssistEnum.AimAssistMethod.Friction, Mobile.Friction)
        a1.aimAssistController:setMethodStrength(AimAssistEnum.AimAssistMethod.Tracking, Mobile.Tracking)
        a1.aimAssistController:setMethodStrength(AimAssistEnum.AimAssistMethod.Centering, Mobile.Centering)
        a1.aimAssistController:setEasingFunc(AimAssistEnum.AimAssistEasingAttribute.Distance, function(a1) -- Line: 1108 -- upvalues: Mobile (ref) -- types: a1: number
            if a1 < Mobile.MinRange then
                return 0
            end
            return 1
        end)
        if not workspace:GetAttribute("AimAssist") then
            a1.aimAssistController:disable()
        elseif Mobile.Enabled ~= false then
            a1.aimAssistController:enable()
        else
            a1.aimAssistController:disable()
        end
        if v2 then
            a1.aimAssistController:setCursorDirectionGetter(function() -- Line: 1123 -- upvalues: a1 (val), CurrentCamera (upval), u150 (upval)
                local Character = a1.Character
                local _Crosshair = a1._Crosshair
                local Handle = a1.Handle
                local v1 = _Crosshair.AbsolutePosition + _Crosshair.AbsoluteSize / 2
                local v2 = CurrentCamera:ScreenPointToRay(v1.X, v1.Y)
                v1 = workspace:Raycast(v2.Origin, v2.Direction * 5000, u150)
                local Position = v1 and v1.Position or v2.Origin + v2.Direction * 5000
                return (Position - CurrentCamera.CFrame.Position).Unit
            end)
        end
        if v1 or v4 then
            EquipTrove:Connect(UserInputService.InputChanged, function(a1_2) -- Line: 1130 -- upvalues: a1 (val) -- types: a1_2: userdata
                if a1_2.KeyCode == Enum.KeyCode.Thumbstick2 then
                    a1.aimAssistController:updateGamepadEligibility(a1_2.KeyCode, a1_2.Position)
                end
            end)
            EquipTrove:Connect(UserInputService.TouchStarted, function() -- Line: 1136 -- upvalues: a1 (val)
                a1.aimAssistController:updateTouchEligibility()
            end)
            EquipTrove:Connect(UserInputService.TouchMoved, function() -- Line: 1140 -- upvalues: a1 (val)
                a1.aimAssistController:updateTouchEligibility()
            end)
        end
    end

    local function OnAmmoUpdate() -- Line: 1146
        -- upvalues: a1 (val), u36 (ref), u35 (ref), Ammo (val), Instance (val), u198 (upval), u11 (val)
        -- upvalues: TweenService (upval)
        local v1 = a1:Get("Ammo_Client") or 0
        if not u36 then
            u36 = true
            u35 = v1
        end
        Ammo.Text = v1 .. " / " .. (a1:Get("Capacity") or "0")
        if a1.Settings.AmmoType == "Rocket" then
            local Rocket = Instance.Model:FindFirstChild("Rocket")
            local Extra = Rocket and Rocket:IsA("BasePart") and Rocket:FindFirstChild("Extra")
            if Rocket and Rocket:IsA("BasePart") then
                local v2 = if v1 ~= 0 then 0 else 1
                local v3 = v1 > 0
                if Extra then
                    local v4 = next
                    local Descendants, Descendants_2 = Extra:GetDescendants()
                    for k, v in v4, Descendants, Descendants_2 do
                        if v:IsA("ParticleEmitter") or v:IsA("Beam") then
                            v.Enabled = v3
                        elseif v:IsA("BasePart") then
                            v.Transparency = v2
                        end
                    end
                end
            end
        end
        if _G.Effects and v1 - u35 < 0 then
            local v5 = u198
            v5.Shoot = v5.Shoot + 1
            local Shoot = u198.Shoot
            local Ammo_2 = u11.Frame.Frame.Ammo
            TweenService:Create(
                Ammo_2,
                TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {Rotation = math.random(5, 10)}
            ):Play()
            task.delay(0.05, function() -- Line: 1191 -- upvalues: Shoot (val), u198 (upval), u11 (upval), Ammo_2 (val), TweenService (upval)
                if Shoot == u198.Shoot and u11 and u11.Parent and Ammo_2 and Ammo_2.Parent then
                    TweenService:Create(Ammo_2, TweenInfo.new(0.75, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = 0}):Play()
                    return
                end
            end)
        end
        u35 = v1
    end

    local function OnSlideUpdate() -- Line: 1207 -- upvalues: a1 (val), Jam (val), Slide (val), MobileButtons (val)
        local v1 = a1:Get("IsJammed")
        Jam.Visible = v1
        Slide.Visible = not a1:Get("Slided")
        local Unjam = MobileButtons.Unjam
        local v2 = a1:Get("IsJammed") or not a1:Get("Slided")
        Unjam.Visible = v2
        local Beam = MobileButtons.Beam
        local Beam_2 = a1.Beam and not MobileButtons.Unjam.Visible
        Beam.Visible = Beam_2
        if v1 then
            script.Parent.Parent.Parent.Remotes.Notify:FireServer("Gun Jammed! Unjamming Gun.", 1.5)
            a1:AutoSlide()
        end
    end

    OnAmmoUpdate()
    OnSlideUpdate()
    a1:AutoSlide()
    a1:PlayAnimation("Idle")
    a1:PlayAnimation("Equip")
    GunStyles.Equip(a1)
    local v5 = "973818318"
    local v6 = 2
    if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Settings") then
        local v7 = tonumber((tostring(LocalPlayer.Data.Settings.Crosshair.Value):match("%d+")))
        if v7 and v7 > 1 then
            v5 = tostring(v7)
        end
        v7 = tonumber(LocalPlayer.Data.Settings.CrosshairSize.Value)
        if v7 then
            v6 = math.clamp(v7, 0.1, 3)
        end
    end
    if v5 ~= "973818318" then
        u11.Crosshair.Image = "rbxthumb://type=Asset&id=" .. (tostring(v5)) .. "&w=420&h=420"
    else
        u11.Crosshair.Image = "rbxassetid://973818318"
    end
    u11.Crosshair.UIScale.Scale = v6
    u11.Crosshair.Visible = true
    u11.Crosshair.ImageTransparency = 0
    a1._Crosshair = u11.Crosshair
    a1._EquipTime = clock()
    UserInputService.MouseIconEnabled = false
    MobileButtons.Visible = v2
    u11.Parent = LocalPlayer.PlayerGui
    if _G.Effects then
        local v8 = u198
        v8.Equip = v8.Equip + 1
        local Equip = u198.Equip
        local Frame = u11.Frame.Frame
        local Size = Frame.Size
        local Position = Frame.Position
        Frame.Position = Position + UDim2.fromScale(1, 0)
        Frame.Rotation = 10
        TweenService:Create(u11.Frame.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Position = Position}):Play()
        TweenService:Create(u11.Frame.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Rotation = 20}):Play()
        task.delay(0.25, function() -- Line: 1282 -- upvalues: u11 (val), Frame (val), TweenService (upval)
            if u11 and u11.Parent and Frame and Frame.Parent then
                TweenService:Create(u11.Frame.Frame, TweenInfo.new(1, Enum.EasingStyle.Elastic), {Rotation = 0}):Play()
                return
            end
        end)
    end
    if v2 then
        Slide.Text = "SLIDE"
        Jam.Text = "JAMMED"
        EquipTrove:Connect(MobileButtons.FireButton.MouseButton1Down, function() -- Line: 1296 -- upvalues: a1 (val)
            a1._FireRequest = true
        end)
        EquipTrove:Connect(MobileButtons.FireButton.MouseButton1Up, function() -- Line: 1299 -- upvalues: a1 (val), clock (upval), u125 (upval)
            if a1.Settings.IsBinary then
                local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                if not Attribute then
                    Attribute = a1._HoldState
                    if not Attribute then
                        Attribute = a1:Get("IsReloading")
                        if not Attribute then
                            Attribute = true
                            if not ((a1:Get("Ammo_Client")) <= 0) then
                                Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                            end
                        end
                    end
                end
                if not Attribute then
                    local v1 = clock()
                    if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                        or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                        return
                    end
                    a1:Fire()
                    u125 = v1
                end
            end
            a1._FireRequest = false
        end)
        EquipTrove:Connect(MobileButtons.ReloadButton.MouseButton1Click, function() -- Line: 1321 -- upvalues: a1 (val)
            a1:Reload()
        end)
        EquipTrove:Connect(MobileButtons.HoldDownButton.MouseButton1Click, function() -- Line: 1324 -- upvalues: a1 (val)
            a1:SwitchHold()
        end)
        EquipTrove:Connect(MobileButtons.Unjam.MouseButton1Click, function() -- Line: 1327 -- upvalues: a1 (val)
            a1:Slide()
        end)
        EquipTrove:Connect(MobileButtons.Beam.MouseButton1Click, function() -- Line: 1330 -- upvalues: a1 (val)
            a1:SwitchBeam()
        end)
        MobileButtons.Scope.Visible = Scope
        if Scope then
            EquipTrove:Connect(MobileButtons.Scope.MouseButton1Click, function() -- Line: 1336 -- upvalues: a1 (val), u11 (val)
                a1:ToggleScope(u11)
            end)
        end
    elseif not v1 then
        if not v3 then
            if v4 then
                Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
                Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
                EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1448 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
                    if not a2 or a1_2.KeyCode == Enum.KeyCode.ButtonA then
                        local KeyCode = a1_2.KeyCode
                        if KeyCode == JamKey or KeyCode == Enum.KeyCode.ButtonB then
                            a1:Slide()
                        elseif KeyCode == Enum.KeyCode.X or KeyCode == Enum.KeyCode.ButtonA then
                            a1:SwitchBeam()
                        elseif KeyCode == Enum.KeyCode.R or KeyCode == Enum.KeyCode.ButtonX then
                            a1:Reload()
                        elseif KeyCode == Enum.KeyCode.G or KeyCode == Enum.KeyCode.ButtonY then
                            a1:SwitchHold()
                        end
                        if a1_2.UserInputType == Enum.UserInputType.MouseButton1
                            or a1_2.KeyCode == Enum.KeyCode.ButtonR2 then
                            a1._FireRequest = true
                        end
                        if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                            if Scope and not a1._ScopeState then
                                a1:ToggleScope(u11)
                            end
                        elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and not a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                    end
                end)
                EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1470
                    -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
                    if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1
                        and a1_2.KeyCode ~= Enum.KeyCode.ButtonR2 then
                        if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                            if Scope and a1._ScopeState then
                                a1:ToggleScope(u11)
                            end
                        elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                        return
                    end
                    if a1.Settings.IsBinary then
                        local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                        if not Attribute then
                            Attribute = a1._HoldState
                            if not Attribute then
                                Attribute = a1:Get("IsReloading")
                                if not Attribute then
                                    Attribute = true
                                    if not ((a1:Get("Ammo_Client")) <= 0) then
                                        Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                                    end
                                end
                            end
                        end
                        if not Attribute then
                            local v1 = clock()
                            if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                                or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                                return
                            end
                            a1:Fire()
                            u125 = v1
                        end
                    end
                    a1._FireRequest = false
                end)
            end
        elseif not v1 then
            Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
            Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
            EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1393 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
                if not a2 then
                    local KeyCode = a1_2.KeyCode
                    if KeyCode == JamKey then
                        a1:Slide()
                    elseif KeyCode == Enum.KeyCode.X then
                        a1:SwitchBeam()
                    elseif KeyCode == Enum.KeyCode.R then
                        a1:Reload()
                    elseif KeyCode == Enum.KeyCode.G then
                        a1:SwitchHold()
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton1 then
                        a1._FireRequest = true
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 and Scope and not a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                end
            end)
            EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1417
                -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
                if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 and Scope and a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                    return
                end
                if a1.Settings.IsBinary then
                    local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                    if not Attribute then
                        Attribute = a1._HoldState
                        if not Attribute then
                            Attribute = a1:Get("IsReloading")
                            if not Attribute then
                                Attribute = true
                                if not ((a1:Get("Ammo_Client")) <= 0) then
                                    Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                                end
                            end
                        end
                    end
                    if not Attribute then
                        local v1 = clock()
                        if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                            or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                            return
                        end
                        a1:Fire()
                        u125 = v1
                    end
                end
                a1._FireRequest = false
            end)
        elseif v4 then
            Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
            Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
            EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1448 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
                if not a2 or a1_2.KeyCode == Enum.KeyCode.ButtonA then
                    local KeyCode = a1_2.KeyCode
                    if KeyCode == JamKey or KeyCode == Enum.KeyCode.ButtonB then
                        a1:Slide()
                    elseif KeyCode == Enum.KeyCode.X or KeyCode == Enum.KeyCode.ButtonA then
                        a1:SwitchBeam()
                    elseif KeyCode == Enum.KeyCode.R or KeyCode == Enum.KeyCode.ButtonX then
                        a1:Reload()
                    elseif KeyCode == Enum.KeyCode.G or KeyCode == Enum.KeyCode.ButtonY then
                        a1:SwitchHold()
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton1
                        or a1_2.KeyCode == Enum.KeyCode.ButtonR2 then
                        a1._FireRequest = true
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                        if Scope and not a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                    elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and not a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                end
            end)
            EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1470
                -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
                if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1
                    and a1_2.KeyCode ~= Enum.KeyCode.ButtonR2 then
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                        if Scope and a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                    elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                    return
                end
                if a1.Settings.IsBinary then
                    local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                    if not Attribute then
                        Attribute = a1._HoldState
                        if not Attribute then
                            Attribute = a1:Get("IsReloading")
                            if not Attribute then
                                Attribute = true
                                if not ((a1:Get("Ammo_Client")) <= 0) then
                                    Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                                end
                            end
                        end
                    end
                    if not Attribute then
                        local v1 = clock()
                        if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                            or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                            return
                        end
                        a1:Fire()
                        u125 = v1
                    end
                end
                a1._FireRequest = false
            end)
        end
    elseif not v3 then
        Slide.Text = "SLIDE"
        Jam.Text = "JAMMED"
        EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1343 -- upvalues: a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
            if a2 and a1_2.KeyCode ~= Enum.KeyCode.ButtonA then
                return
            end
            local KeyCode = a1_2.KeyCode
            if KeyCode == Enum.KeyCode.ButtonR2 then
                a1._FireRequest = true
                return
            end
            if KeyCode == Enum.KeyCode.ButtonB then
                a1:Slide()
                return
            end
            if KeyCode == Enum.KeyCode.ButtonY then
                a1:SwitchHold()
                return
            end
            if KeyCode == Enum.KeyCode.ButtonX then
                a1:Reload()
                return
            end
            if KeyCode == Enum.KeyCode.ButtonA then
                a1:SwitchBeam()
                return
            end
            if KeyCode == Enum.KeyCode.ButtonL2 and Scope and not a1._ScopeState then
                a1:ToggleScope(u11)
            end
        end)
        EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1363
            -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
            if a1_2.KeyCode ~= Enum.KeyCode.ButtonR2 then
                if a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and a1._ScopeState then
                    a1:ToggleScope(u11)
                end
                return
            end
            if a1.Settings.IsBinary then
                local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                if not Attribute then
                    Attribute = a1._HoldState
                    if not Attribute then
                        Attribute = a1:Get("IsReloading")
                        if not Attribute then
                            Attribute = true
                            if not ((a1:Get("Ammo_Client")) <= 0) then
                                Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                            end
                        end
                    end
                end
                if not Attribute then
                    local v1 = clock()
                    if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                        or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                        return
                    end
                    a1:Fire()
                    u125 = v1
                end
            end
            a1._FireRequest = false
        end)
    elseif not v3 then
        if v4 then
            Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
            Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
            EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1448 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
                if not a2 or a1_2.KeyCode == Enum.KeyCode.ButtonA then
                    local KeyCode = a1_2.KeyCode
                    if KeyCode == JamKey or KeyCode == Enum.KeyCode.ButtonB then
                        a1:Slide()
                    elseif KeyCode == Enum.KeyCode.X or KeyCode == Enum.KeyCode.ButtonA then
                        a1:SwitchBeam()
                    elseif KeyCode == Enum.KeyCode.R or KeyCode == Enum.KeyCode.ButtonX then
                        a1:Reload()
                    elseif KeyCode == Enum.KeyCode.G or KeyCode == Enum.KeyCode.ButtonY then
                        a1:SwitchHold()
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton1
                        or a1_2.KeyCode == Enum.KeyCode.ButtonR2 then
                        a1._FireRequest = true
                    end
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                        if Scope and not a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                    elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and not a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                end
            end)
            EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1470
                -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
                if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1
                    and a1_2.KeyCode ~= Enum.KeyCode.ButtonR2 then
                    if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                        if Scope and a1._ScopeState then
                            a1:ToggleScope(u11)
                        end
                    elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                    return
                end
                if a1.Settings.IsBinary then
                    local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                    if not Attribute then
                        Attribute = a1._HoldState
                        if not Attribute then
                            Attribute = a1:Get("IsReloading")
                            if not Attribute then
                                Attribute = true
                                if not ((a1:Get("Ammo_Client")) <= 0) then
                                    Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                                end
                            end
                        end
                    end
                    if not Attribute then
                        local v1 = clock()
                        if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                            or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                            return
                        end
                        a1:Fire()
                        u125 = v1
                    end
                end
                a1._FireRequest = false
            end)
        end
    elseif not v1 then
        Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
        Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
        EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1393 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
            if not a2 then
                local KeyCode = a1_2.KeyCode
                if KeyCode == JamKey then
                    a1:Slide()
                elseif KeyCode == Enum.KeyCode.X then
                    a1:SwitchBeam()
                elseif KeyCode == Enum.KeyCode.R then
                    a1:Reload()
                elseif KeyCode == Enum.KeyCode.G then
                    a1:SwitchHold()
                end
                if a1_2.UserInputType == Enum.UserInputType.MouseButton1 then
                    a1._FireRequest = true
                end
                if a1_2.UserInputType == Enum.UserInputType.MouseButton2 and Scope and not a1._ScopeState then
                    a1:ToggleScope(u11)
                end
            end
        end)
        EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1417
            -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
            if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1 then
                if a1_2.UserInputType == Enum.UserInputType.MouseButton2 and Scope and a1._ScopeState then
                    a1:ToggleScope(u11)
                end
                return
            end
            if a1.Settings.IsBinary then
                local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                if not Attribute then
                    Attribute = a1._HoldState
                    if not Attribute then
                        Attribute = a1:Get("IsReloading")
                        if not Attribute then
                            Attribute = true
                            if not ((a1:Get("Ammo_Client")) <= 0) then
                                Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                            end
                        end
                    end
                end
                if not Attribute then
                    local v1 = clock()
                    if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                        or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                        return
                    end
                    a1:Fire()
                    u125 = v1
                end
            end
            a1._FireRequest = false
        end)
    elseif v4 then
        Slide.Text = string.format("PRESS %s TO SLIDE", JamKey.Name)
        Jam.Text = string.format("JAMMED - PRESS %s TO UNJAM", JamKey.Name)
        EquipTrove:Connect(UserInputService.InputBegan, function(a1_2, a2) -- Line: 1448 -- upvalues: JamKey (val), a1 (val), Scope (val), u11 (val) -- types: a1_2: userdata
            if not a2 or a1_2.KeyCode == Enum.KeyCode.ButtonA then
                local KeyCode = a1_2.KeyCode
                if KeyCode == JamKey or KeyCode == Enum.KeyCode.ButtonB then
                    a1:Slide()
                elseif KeyCode == Enum.KeyCode.X or KeyCode == Enum.KeyCode.ButtonA then
                    a1:SwitchBeam()
                elseif KeyCode == Enum.KeyCode.R or KeyCode == Enum.KeyCode.ButtonX then
                    a1:Reload()
                elseif KeyCode == Enum.KeyCode.G or KeyCode == Enum.KeyCode.ButtonY then
                    a1:SwitchHold()
                end
                if a1_2.UserInputType == Enum.UserInputType.MouseButton1 or a1_2.KeyCode == Enum.KeyCode.ButtonR2 then
                    a1._FireRequest = true
                end
                if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                    if Scope and not a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and not a1._ScopeState then
                    a1:ToggleScope(u11)
                end
            end
        end)
        EquipTrove:Connect(UserInputService.InputEnded, function(a1_2) -- Line: 1470
            -- upvalues: a1 (val), clock (upval), u125 (upval), Scope (val), u11 (val)
            if a1_2.UserInputType ~= Enum.UserInputType.MouseButton1 and a1_2.KeyCode ~= Enum.KeyCode.ButtonR2 then
                if a1_2.UserInputType == Enum.UserInputType.MouseButton2 then
                    if Scope and a1._ScopeState then
                        a1:ToggleScope(u11)
                    end
                elseif a1_2.KeyCode == Enum.KeyCode.ButtonL2 and Scope and a1._ScopeState then
                    a1:ToggleScope(u11)
                end
                return
            end
            if a1.Settings.IsBinary then
                local Attribute = a1.Humanoid:GetAttribute("_RagdollState")
                if not Attribute then
                    Attribute = a1._HoldState
                    if not Attribute then
                        Attribute = a1:Get("IsReloading")
                        if not Attribute then
                            Attribute = true
                            if not ((a1:Get("Ammo_Client")) <= 0) then
                                Attribute = a1:Get("IsJammed") or not a1:Get("Slided") or clock() - a1._SlideTime < 0.8
                            end
                        end
                    end
                end
                if not Attribute then
                    local v1 = clock()
                    if v1 - u125 <= 60 / a1.Settings.FireRate * 0.95
                        or v1 - a1.LastFired < a1.DeltaTime * 0.23170731707317074 then
                        return
                    end
                    a1:Fire()
                    u125 = v1
                end
            end
            a1._FireRequest = false
        end)
    end
    EquipTrove:Add(u11)
    EquipTrove:Connect(Instance:GetAttributeChangedSignal("Ammo_Client"), OnAmmoUpdate)
    EquipTrove:Connect(Instance:GetAttributeChangedSignal("IsJammed"), OnSlideUpdate)
    EquipTrove:Connect(Instance:GetAttributeChangedSignal("Slided"), OnSlideUpdate)
    a1:Set("Ammo_Client", (a1:Get("Ammo_Server")))
    EquipTrove:Connect(Instance:GetAttributeChangedSignal("Capacity"), function() -- Line: 1505 -- upvalues: a1 (val)
        a1:Set("Ammo_Client", (a1:Get("Ammo_Server")))
    end)
    RunService:BindToRenderStep("GunFramework", Enum.RenderPriority.Camera.Value + 1, function(a1_2) -- Line: 1509 -- upvalues: a1 (val)
        a1:Update(a1_2)
    end)
    EquipTrove:Add(function() -- Line: 1513 -- upvalues: RunService (upval), a1 (val), UserInputService (upval), CurrentCamera (upval)
        RunService:UnbindFromRenderStep("GunFramework")
        for i, j in a1._Animations do
            a1:StopAnimation(i)
        end
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if a1.Settings.Scope then
            CurrentCamera.FieldOfView = (_G.FOV or 70) + (if _G.Running ~= true then 0 else 5)
            a1:RestoreScopeCamera()
        end
    end)
    a1:Set("IsReloading", false)
    if _G.GunVolume then
        for i, j in a1.Handle:GetChildren() do
            if j:IsA("Sound") then
                v5 = j:GetAttribute("Volume")
                if v5 then
                    j.Volume = v5 * _G.GunVolume
                end
            end
        end
    end
    u150.FilterDescendantsInstances = {
        LocalPlayer.Character,
        workspace.Zones,
        workspace.Storage,
        workspace.Map.Background,
        CollectionService:GetTagged("IgnoreBullets"),
    }
    if _G.LowGFX then
        for k, n in a1.Instance:QueryDescendants("ParticleEmitter [Enabled=true]") do
            n.Enabled = false
        end
        for m, i5 in a1.Instance:QueryDescendants("Beam [Enabled=true]") do
            if i5.Parent.Name ~= "BEAM" then
                i5.Enabled = false
            end
        end
    elseif not _G.Effects then
        for i6, i7 in a1.Instance:QueryDescendants("ParticleEmitter [Enabled=true]") do
            i7.Enabled = false
        end
        for i8, i9 in a1.Instance:QueryDescendants("Beam [Enabled=true]") do
            if i9.Parent.Name ~= "BEAM" then
                i9.Enabled = false
            end
        end
    end
end

function u238.OnUnequip(a1) -- Line: 1563 -- upvalues: GunStyles (val), u103 (ref)
    GunStyles.Unequip(a1)
    a1._FireRequest = false
    a1._LastRequest = false
    a1._HoldState = false
    a1._ScopeState = false
    u103 = false
    a1:Set("IsJammed", false)
    a1.Spring_Recoil:ResetState()
    if a1.aimAssistController then
        a1.aimAssistController:setCursorDirectionGetter(nil)
        a1.aimAssistController:disable()
    end
end

return {
    Init = function() -- Line: 1579
        -- upvalues: Update (val), u100 (ref), u150 (val), LocalPlayer (val), CollectionService (val), u171 (val)
        -- upvalues: Shared (val), u238 (val), u223 (val), Coroutine (val), Fire (val), u199 (val), Effect (val)
        -- upvalues: u103 (ref), u200 (val), Information (val), GunStyles (val)
        Update.OnClientEvent:Connect(function(a1, a2, a3) -- Line: 1580
            -- upvalues: u100 (upval), u150 (upval), LocalPlayer (upval), CollectionService (upval), u171 (upval)
            if a1 == "Update" then
                if a2 and tonumber(a3) then
                    a2:SetAttribute("Ammo_Client", a3)
                    return
                end
                return
            end
            if a1 == "Token" then
                u100 = a2
                u150.FilterDescendantsInstances = {
                    LocalPlayer.Character,
                    workspace.Zones,
                    workspace.Storage,
                    workspace.Map.Background,
                    CollectionService:GetTagged("IgnoreBullets"),
                }
                u171.FilterDescendantsInstances = {
                    workspace.Zones,
                    workspace.Storage,
                    workspace.Map.Background,
                    CollectionService:GetTagged("IgnoreBullets"),
                }
            end
        end)
        local CollectionService_2 = game:GetService("CollectionService")
        local u11 = {}

        local function v1(a1) -- Line: 1597
            a1.IsEquipped = false
            a1.IsDestroyed = true
            a1.EquipTrove:Destroy(true)
            a1.Trove:Destroy(true)
            if a1.aimAssistController then
                a1.aimAssistController:destroy()
            end
        end

        local function OnGunAdded(a1) -- Line: 1619
            -- upvalues: u11 (val), Shared (upval), LocalPlayer (upval), u238 (upval), u223 (upval), Coroutine (upval)
            local v1 = u11[a1]
            if v1 then
                u11[a1] = nil
                v1.Connection:Disconnect()
                v1.Destroy()
            end
            local u11_2 = nil
            local u12 = nil
            local u13 = 0
            local u14 = {}

            local function DestroyCurrent() -- Line: 1627 -- upvalues: u13 (ref), u12 (ref)
                u13 = u13 + 1
                if not u12 then
                    return
                end
                local v1 = u12
                v1.IsEquipped = false
                v1.IsDestroyed = true
                v1.EquipTrove:Destroy(true)
                v1.Trove:Destroy(true)
                if v1.aimAssistController then
                    v1.aimAssistController:destroy()
                end
                u12 = nil
            end

            local function OnParentChanged() -- Line: 1638
                -- upvalues: u11 (upval), a1 (val), u14 (val), Shared (upval), u11_2 (ref), u13 (ref), u12 (ref)
                -- upvalues: LocalPlayer (upval), u238 (upval), u223 (upval)
                local v1
                if u11[a1] ~= u14 then
                    return
                end
                local v2 = Shared.GetPlayerFromTool(a1)
                if not v2 then
                    u11_2 = nil
                    if not a1.Parent then
                        u13 = u13 + 1
                        if not u12 then
                            return
                        end
                        v1 = u12
                        v1.IsEquipped = false
                        v1.IsDestroyed = true
                        v1.EquipTrove:Destroy(true)
                        v1.Trove:Destroy(true)
                        if v1.aimAssistController then
                            v1.aimAssistController:destroy()
                        end
                        u12 = nil
                    end
                    return
                end
                if v2 == u11_2 then
                    return
                end
                u11_2 = v2
                u13 = u13 + 1
                if u12 then
                    v1 = u12
                    v1.IsEquipped = false
                    v1.IsDestroyed = true
                    v1.EquipTrove:Destroy(true)
                    v1.Trove:Destroy(true)
                    if v1.aimAssistController then
                        v1.aimAssistController:destroy()
                    end
                    u12 = nil
                end
                v1 = u13
                local v3 = (not (v2 ~= LocalPlayer) and u238 or u223).new(a1, v2)
                if u13 == v1 then
                    if not v3 then
                        u11_2 = nil
                        return
                    end
                    u12 = v3
                    Shared.Client_BindEvents(v3)
                    return
                end
                if v3 then
                    v3.IsEquipped = false
                    v3.IsDestroyed = true
                    v3.EquipTrove:Destroy(true)
                    v3.Trove:Destroy(true)
                    if v3.aimAssistController then
                        v3.aimAssistController:destroy()
                    end
                end
            end

            u14.Connection = (a1:GetPropertyChangedSignal("Parent")):Connect(OnParentChanged)

            function u14.Destroy() -- Line: 1681 -- upvalues: u11_2 (ref), u13 (ref), u12 (ref)
                u11_2 = nil
                u13 = u13 + 1
                if not u12 then
                    return
                end
                local v1 = u12
                v1.IsEquipped = false
                v1.IsDestroyed = true
                v1.EquipTrove:Destroy(true)
                v1.Trove:Destroy(true)
                if v1.aimAssistController then
                    v1.aimAssistController:destroy()
                end
                u12 = nil
            end

            u11[a1] = u14
            Coroutine(OnParentChanged)
        end

        for i, j in CollectionService_2:GetTagged("Gun") do
            Coroutine(OnGunAdded, j)
        end
        ;(CollectionService_2:GetInstanceAddedSignal("Gun")):Connect(OnGunAdded)
        ;(CollectionService_2:GetInstanceRemovedSignal("Gun")):Connect(function(a1) -- Line: 1608 -- upvalues: u11 (val)
            local v1 = u11[a1]
            if not v1 then
                return
            end
            u11[a1] = nil
            v1.Connection:Disconnect()
            v1.Destroy()
        end)
        Fire.OnClientEvent:Connect(function(a1, a2, a3) -- Line: 1697 -- upvalues: u199 (upval) -- types: a1: string, a2: vector, a3: vector
            local v1 = u199[a1]
            if v1 and not v1.IsDestroyed and v1.IsEquipped then
                v1:Fire(a2, a3)
                return
            end
        end)
        Effect.OnClientEvent:Connect(function(a1) -- Line: 1706 -- upvalues: u103 (upval), u200 (upval)
            if u103 then
                return
            end
            if u200[a1] then
                u200[a1]:Play()
            end
        end)
        Information.OnClientEvent:Connect(function(a1, a2, a3) -- Line: 1716 -- upvalues: GunStyles (upval) -- types: a1: string, a2: userdata?, a3: userdata?
            GunStyles.Kill(a3, a2)
        end)
    end,
}
