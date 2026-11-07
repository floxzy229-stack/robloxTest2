local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Factory = require(Shared.ModelFactory)
local WorldBuilder = {}
local WORLD_VERSION = 5

local function center(zoneId)
	local offset = Config.Zones[zoneId].Offset
	local origin = Config.WorldOrigin
	return Vector3.new(origin[1] + offset[1], origin[2] + offset[2], origin[3] + offset[3])
end

local function solid(parent, name, size, position, color)
	local part = Factory.Part(parent, name, size, CFrame.new(position), color)
	part.CanCollide = true
	part.CanQuery = true
	return part
end

local function lamp(parent, name, position)
	local post = solid(parent, name, Vector3.new(0.6, 6, 0.6), position + Vector3.new(0, 3, 0), "Ink")
	post.Material = Enum.Material.Metal
	local cap = solid(parent, name .. "Glow", Vector3.new(1.8, 0.7, 1.8), position + Vector3.new(0, 6.2, 0), "Accent")
	cap.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = Factory.Color("Accent")
	light.Brightness = 1.5
	light.Range = 18
	light.Parent = cap
end

local sign, prompt

local function tree(parent, name, position, scale)
	scale = scale or 1
	local trunk = solid(parent, name .. "Trunk", Vector3.new(2.4, 7, 2.4) * scale, position + Vector3.new(0, 3.5 * scale, 0), "Ink")
	trunk.Material = Enum.Material.Wood
	local lower = solid(parent, name .. "Lower", Vector3.new(8, 6, 8) * scale, position + Vector3.new(0, 8 * scale, 0), "Brand")
	lower.Shape = Enum.PartType.Ball
	local upper = solid(parent, name .. "Upper", Vector3.new(6, 5, 6) * scale, position + Vector3.new(0, 12 * scale, 0), "Accent")
	upper.Shape = Enum.PartType.Ball
end

local function treadmill(parent, name, position, id, color)
	local base = solid(parent, name .. "Base", Vector3.new(13, 0.7, 7), position, "Ink")
	base.Material = Enum.Material.Metal
	base:SetAttribute("TreadmillId", id)
	local belt = solid(parent, name .. "Belt", Vector3.new(11.5, 0.35, 5.8), position + Vector3.new(0, 0.55, 0), color)
	belt.Material = Enum.Material.Neon
	belt:SetAttribute("TreadmillId", id)
	local light = Instance.new("PointLight")
	light.Color = Factory.Color(color)
	light.Brightness = 1.2
	light.Range = 16
	light.Parent = belt
	for i = -2, 2 do
		local stripe = solid(parent, name .. "Stripe" .. i, Vector3.new(0.22, 0.08, 5.2), position + Vector3.new(i * 2.05, 0.77, 0), "Paper")
		stripe.Material = Enum.Material.Neon
		stripe.Transparency = 0.2
	end
	sign(parent, name .. "Sign", position + Vector3.new(0, 3.2, -3.5), Config.Treadmills[id].Name .. "\n+" .. Config.Treadmills[id].XP .. " XP/сек", color, 10)
	return belt
end

local function portalArch(parent, name, position, target, color)
	local base = solid(parent, name .. "Base", Vector3.new(18, 1, 9), position, "Portal")
	base.Material = Enum.Material.Metal
	local left = solid(parent, name .. "Left", Vector3.new(2.5, 15, 2.5), position + Vector3.new(-7, 8, 0), color)
	local right = solid(parent, name .. "Right", Vector3.new(2.5, 15, 2.5), position + Vector3.new(7, 8, 0), color)
	local top = solid(parent, name .. "Top", Vector3.new(16.5, 2.5, 2.5), position + Vector3.new(0, 15.2, 0), color)
	for _, part in ipairs({ left, right, top }) do
		part.Material = Enum.Material.Neon
		local glow = Instance.new("PointLight")
		glow.Color = Factory.Color(color)
		glow.Brightness = 1.5
		glow.Range = 20
		glow.Parent = part
	end
	local opening = solid(parent, name .. "Opening", Vector3.new(12, 13, 0.4), position + Vector3.new(0, 7.5, 0), color)
	opening.Material = Enum.Material.Neon
	opening.Transparency = 0.18
	local targetZone = Config.Zones[target]
	sign(parent, name .. "Sign", position + Vector3.new(0, 19, 0), targetZone.Name .. "\nВХОД: " .. targetZone.Price .. " ТЕРПЕНИЯ", "Accent", 18)
	prompt(opening, "Открыть портал", target, "TargetZone")
end

local function building(parent, name, position, color, title)
	local body = solid(parent, name .. "Body", Vector3.new(24, 16, 18), position + Vector3.new(0, 8, 0), color)
	body.Material = Enum.Material.SmoothPlastic
	solid(parent, name .. "Roof", Vector3.new(28, 3, 22), position + Vector3.new(0, 17.5, 0), "Accent")
	solid(parent, name .. "Door", Vector3.new(5, 8, 0.6), position + Vector3.new(0, 4, -9.3), "Ink")
	for i = -1, 1 do
		solid(parent, name .. "Window" .. i, Vector3.new(4, 4, 0.5), position + Vector3.new(i * 7, 10, -9.4), "Paper")
	end
	sign(parent, name .. "Sign", position + Vector3.new(0, 21, -9), title, "Ink", 20)
end

sign = function(parent, name, position, text, color, width)
	local board = solid(parent, name, Vector3.new(width or 24, 6, 0.5), position, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Lettering"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Factory.Color(color == "Ink" and "Paper" or "Ink")
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = label
	return board
end

prompt = function(parent, text, target, attribute)
	local item = Instance.new("ProximityPrompt")
	item.Name = "BonkPrompt"
	item.ActionText = text
	item.ObjectText = "БОНК"
	item.KeyboardKeyCode = Enum.KeyCode.F
	item.GamepadKeyCode = Enum.KeyCode.ButtonX
	item.MaxActivationDistance = 12
	item.HoldDuration = 0.25
	item.RequiresLineOfSight = false
	item:SetAttribute(attribute, target)
	item.Parent = parent
end

local function resolve(folder)
	local world = { Folder = folder, Centers = {}, Spawns = {}, Dummies = {}, Prompts = {}, Treadmills = {}, Boss = nil }
	for _, zoneId in ipairs(Config.ZoneOrder) do
		local zone = assert(folder:FindFirstChild(zoneId), "Incomplete BonkWorld zone")
		world.Centers[zoneId] = center(zoneId)
		world.Spawns[zoneId] = assert(zone:FindFirstChild("Spawn"), "Missing Bonk spawn")
		world.Dummies[zoneId] = assert(zone:FindFirstChild("PracticeDummy"), "Missing Bonk dummy")
		world.Treadmills[zoneId] = {}
		for _, item in ipairs(zone:GetChildren()) do
			if item:IsA("BasePart") and item:GetAttribute("TreadmillId") then table.insert(world.Treadmills[zoneId], item) end
		end
	end
	world.Boss = assert(folder.gym:FindFirstChild("CoachPillow"), "Missing Bonk boss")
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("ProximityPrompt") and child.Name == "BonkPrompt" then table.insert(world.Prompts, child) end
	end
	return world
end

function WorldBuilder.Build()
	local existing = workspace:FindFirstChild("BonkWorld")
	if existing then
		assert(existing:IsA("Folder") and existing:GetAttribute("BonkOwned") == true, "BonkWorld name is occupied by foreign content; rename it or change the project namespace")
		assert(existing:GetAttribute("WorldVersion") == WORLD_VERSION, "BonkWorld version mismatch")
		return resolve(existing)
	end
	local world = Instance.new("Folder")
	world.Name = "BonkWorld"
	world:SetAttribute("BonkOwned", true)
	world:SetAttribute("WorldVersion", WORLD_VERSION)
	for _, zoneId in ipairs(Config.ZoneOrder) do
		local definition = Config.Zones[zoneId]
		local zone = Instance.new("Folder")
		zone.Name = zoneId
		zone.Parent = world
		local origin = center(zoneId)
			local floor = solid(zone, "Floor", Vector3.new(128, 2, 128), origin, "Brand")
			floor.Material = Enum.Material.Grass
			floor.TopSurface = Enum.SurfaceType.Studs
			for ridge = 1, 3 do
				local hill = solid(zone, "TerrainRidge" .. ridge, Vector3.new(128, 3 + ridge * 2, 12), origin + Vector3.new(0, 1.5 + ridge, -52 + ridge * 12), ridge % 2 == 0 and "Brand" or definition.Color)
				hill.Material = Enum.Material.Grass
				hill.TopSurface = Enum.SurfaceType.Studs
			end
		for i = -2, 2 do
			local tile = solid(zone, "PathTile" .. i, Vector3.new(14, 0.18, 7), origin + Vector3.new(i * 16, 1.12, 28), i % 2 == 0 and "Brand" or "Muted")
			tile.Material = Enum.Material.Neon
		end
		local order = Config.TreadmillOrder
		for i = 1, math.min(6, #order) do
			local id = order[i]
			local belt = treadmill(zone, "Treadmill_" .. id, origin + Vector3.new(-42 + ((i - 1) % 3) * 42, 1.35, -5 + math.floor((i - 1) / 3) * 15), id, Config.Treadmills[id].Color)
			belt:SetAttribute("TreadmillId", id)
		end
		lamp(zone, "LampLeft", origin + Vector3.new(-55, 1, -48))
		lamp(zone, "LampRight", origin + Vector3.new(55, 1, -48))
		lamp(zone, "LampCenter", origin + Vector3.new(0, 1, -48))
		tree(zone, "TreeLeft", origin + Vector3.new(-54, 1, 42), 1.1)
		tree(zone, "TreeRight", origin + Vector3.new(54, 1, 42), 0.9)
		tree(zone, "TreeBack", origin + Vector3.new(-52, 1, -42), 0.8)
			building(zone, "Clubhouse", origin + Vector3.new(-38, 1, -38), definition.Color, definition.Name)
			for i = 1, 5 do
				local rock = solid(zone, "DirtRock" .. i, Vector3.new(10 + i * 2, 8 + i, 8 + i * 2), origin + Vector3.new(-50 + i * 22, 4 + i * 1.5, -58 + (i % 2) * 8), i % 2 == 0 and "Earth" or "Clay")
				rock.Material = Enum.Material.Brick
				rock.TopSurface = Enum.SurfaceType.Studs
			end
			if zoneId == "kitchen" then
				local volcano = solid(zone, "Volcano", Vector3.new(34, 28, 34), origin + Vector3.new(-42, 14, -48), "Rock")
				volcano.Shape = Enum.PartType.Cylinder
				volcano.Material = Enum.Material.Slate
				local lava = solid(zone, "VolcanoLava", Vector3.new(7, 25, 7), origin + Vector3.new(-42, 28, -48), "Lava")
				lava.Material = Enum.Material.Neon
			end
		for _, side in ipairs({ -1, 1 }) do
			local wallX = solid(zone, "WallX" .. side, Vector3.new(3, 20, 128), origin + Vector3.new(side * 64, 10, 0), definition.Color)
			wallX.Material = Enum.Material.Brick
			wallX.FrontSurface = Enum.SurfaceType.Studs
			local wallZ = solid(zone, "WallZ" .. side, Vector3.new(128, 20, 3), origin + Vector3.new(0, 10, side * 64), definition.Color)
			wallZ.Material = Enum.Material.Brick
			wallZ.FrontSurface = Enum.SurfaceType.Studs
			solid(zone, "GrassTrimX" .. side, Vector3.new(4, 1.5, 128), origin + Vector3.new(side * 64, 20.7, 0), "Brand")
			solid(zone, "GrassTrimZ" .. side, Vector3.new(128, 1.5, 4), origin + Vector3.new(0, 20.7, side * 64), "Brand")
		end
		sign(zone, "ZoneSign", origin + Vector3.new(0, 12, -61), definition.Name .. "\n" .. definition.Goal, "Ink", 65)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Size = Vector3.new(9, 0.4, 9)
		spawn.CFrame = CFrame.new(origin + Vector3.new(0, 1.2, 36))
		spawn.Color = Factory.Color("Brand")
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Enabled = zoneId == "playroom"
		spawn.Parent = zone
		Factory.Dummy(zone, CFrame.new(origin + Vector3.new(-28, 1, -20)))
		local practice = sign(zone, "PracticeSign", origin + Vector3.new(-28, 8, -24), definition.PracticeTarget and ("РАЗМИНКА\n" .. definition.PracticeTarget .. " бонков, затем F") or "МЯГКИЙ МАНЕКЕН\nТолько практика. Никаких травм.", "Paper", 22)
		if definition.PracticeTarget then prompt(practice, "Получить премию", zoneId, "PracticeZone") end
			for i = 1, 6 do
				local display = origin + Vector3.new(-55 + (i - 1) * 22, 2, 52)
				local pedestal = solid(zone, "ToyPedestal" .. i, Vector3.new(8, 2, 8), display, "Muted")
				local index = (i + table.find(Config.ZoneOrder, zoneId) - 2) % #Config.WeaponOrder + 1
				local weaponId = Config.WeaponOrder[index]
				Factory.Weapon(weaponId, zone, CFrame.new(display + Vector3.new(0, 1.3, 0)), 1.25)
				prompt(pedestal, "Купить / экипировать", weaponId, "WeaponId")
			end
		if zoneId == "playroom" then
			for i, target in ipairs({ "gym", "office", "kitchen" }) do
				local spot = origin + Vector3.new(45, 4, -36 + i * 25)
				solid(zone, "PortalBase_" .. target, Vector3.new(10, 1, 12), spot - Vector3.new(0, 2.5, 0), "Brand")
				portalArch(zone, "Portal_" .. target, spot, target, "Accent")
			end
		else
			local back = sign(zone, "ReturnPortal", origin + Vector3.new(43, 7, 28), "ИГРОВАЯ КОМНАТА\nF — вернуться", "Accent", 20)
			prompt(back, "Вернуться", "playroom", "TargetZone")
		end
		if zoneId == "gym" then
			local o = Config.Boss.Offset
			Factory.Boss(zone, CFrame.new(origin + Vector3.new(o[1], o[2] + 1, o[3])))
			solid(zone, "BossMat", Vector3.new(40, 0.15, 40), origin + Vector3.new(o[1], 1.1, o[3]), "Muted")
		elseif zoneId == "office" then
			for i = 1, 3 do
				local desk = origin + Vector3.new(24, 3, -40 + i * 18)
				solid(zone, "Desk" .. i, Vector3.new(14, 4, 7), desk, "Muted")
				solid(zone, "PaperStack" .. i, Vector3.new(4, 1, 3), desk + Vector3.new(0, 2.5, 0), "Paper")
			end
		elseif zoneId == "kitchen" then
			solid(zone, "Counter", Vector3.new(16, 5, 36), origin + Vector3.new(38, 3.5, -12), "Brand")
			Factory.Weapon("inflatable_tub", zone, CFrame.new(origin + Vector3.new(38, 6, -17)), 3)
			Factory.Weapon("baguette", zone, CFrame.new(origin + Vector3.new(38, 6, 0)), 2)
		end
	end
	world.Parent = workspace
	return resolve(world)
end

return WorldBuilder
