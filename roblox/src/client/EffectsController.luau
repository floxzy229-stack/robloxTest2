local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Factory = require(Shared.ModelFactory)
local UI = require(script.Parent.UIComponents)
local Effects = {}
Effects.__index = Effects

function Effects.new(ui)
	local folder = Instance.new("Folder")
	folder.Name = "BonkLocalEffects"
	folder.Parent = workspace
	local self = setmetatable({ UI = ui, Folder = folder, Settings = { Volume = 0.5, Effects = true }, LastHit = -10, WeaponId = "rubber_hammer", Toy = nil, FloatCount = 0, HatchToken = 0 }, Effects)
	self.Connection = RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then if self.Toy then self.Toy.Parent = nil end return end
		if not self.Toy then self.Toy = Factory.Weapon(self.WeaponId, folder, CFrame.new(), 0.8) end
		self.Toy.Parent = folder
		local elapsed = os.clock() - self.LastHit
		local swing = self.Settings.Effects and elapsed < 0.38 and math.sin(elapsed / 0.38 * math.pi) or 0
		self.Toy:PivotTo(root.CFrame * CFrame.new(1.65, -0.4, -1.7) * CFrame.Angles(-swing * 1.15, 0, -0.2))
	end)
	return self
end

function Effects:SetState(settings, weaponId)
	if settings then self.Settings = settings end
	if weaponId and self.WeaponId ~= weaponId then
		self.WeaponId = weaponId
		if self.Toy then self.Toy:Destroy() self.Toy = nil end
	end
end

function Effects:Sound(kind)
	local id = Config.Sounds[kind]
	if not id or id <= 0 or self.Settings.Volume <= 0 then return end
	local sound = Instance.new("Sound")
	sound.Name = "BonkSound"
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = self.Settings.Volume
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

function Effects:Hit(result)
	if not result.Ok then return end
	self.LastHit = os.clock()
	if not self.Settings.Effects then return end
	self:Sound(result.Critical and "Critical" or "Bonk")
	if self.FloatCount >= 6 then return end
	self.FloatCount += 1
		local character = Players.LocalPlayer.Character
		local head = character and character:FindFirstChild("Head")
		if not head then return end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "BonkReward"
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(120, 34)
		billboard.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.8, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = result.Critical and 17 or 14
		label.TextColor3 = result.Critical and UI.Color("Accent") or UI.Color("Paper")
		label.TextStrokeTransparency = 0.35
		label.Text = (result.Critical and "КРИТ! " or "") .. "+" .. UI.Format(result.Reward) .. (result.Source == "auto" and " · авто" or "")
		label.Parent = billboard
		TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad), { StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.3, 0) }):Play()
		TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		Debris:AddItem(billboard, 1.1)
	task.delay(1.1, function() self.FloatCount = math.max(0, self.FloatCount - 1) end)
end

function Effects:Hatch(pet)
	if not self.Settings.Effects then self.UI:Notify("Вылупился: " .. Config.Pets[pet.Kind].Name) return end
	self.HatchToken += 1
	local token = self.HatchToken
	if self.HatchFrame then self.HatchFrame:Destroy() end
	local frame = UI.Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.55), BackgroundColor3 = UI.Color("Accent"), BorderSizePixel = 0, ZIndex = 50 }, self.UI.Root)
	self.HatchFrame = frame
	UI.Round(frame, 22)
	UI.Create("UISizeConstraint", { MaxSize = Vector2.new(430, 400) }, frame)
	local title = UI.Create("TextLabel", { Size = UDim2.new(1, -24, 0.22, 0), Position = UDim2.fromOffset(12, 8), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = 25, TextWrapped = true, TextColor3 = UI.Color("Ink"), Text = "Тук-тук… помощник внутри!" }, frame)
	local viewport = UI.Create("ViewportFrame", { Size = UDim2.fromScale(1, 0.68), Position = UDim2.fromScale(0, 0.26), BackgroundTransparency = 1, Ambient = UI.Color("Paper"), LightColor = UI.Color("Paper") }, frame)
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(3, 2.3, -5), Vector3.new(0, 1, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local egg = Factory.Part(world, "Egg", Vector3.new(1.5, 2, 1.5), CFrame.new(0, 1, 0), "Paper", Enum.PartType.Ball)
	TweenService:Create(frame, TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true), { Rotation = 4 }):Play()
	task.delay(1.1, function()
		if token ~= self.HatchToken or not frame.Parent then return end
		frame.Rotation = 0
		egg:Destroy()
		Factory.Pet(pet.Kind, pet.Level, world, CFrame.new())
		title.Text = Config.Pets[pet.Kind].Name .. "!"
		self:Sound("Hatch")
	end)
	task.delay(3.1, function()
		if token == self.HatchToken then frame:Destroy() self.HatchFrame = nil end
	end)
end

function Effects:Destroy()
	self.Connection:Disconnect()
	self.HatchToken += 1
	if self.HatchFrame then self.HatchFrame:Destroy() end
	if self.Toy then self.Toy:Destroy() end
	self.Folder:Destroy()
end

return Effects
