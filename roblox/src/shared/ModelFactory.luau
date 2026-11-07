local Config = require(script.Parent.GameConfig)
local Factory = {}

function Factory.Color(name)
	local rgb = Config.Palette[name] or Config.Palette.Brand
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

function Factory.Part(parent, name, size, transform, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = transform
	part.Color = Factory.Color(color)
	part.Material = Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function model(name, parent)
	local result = Instance.new("Model")
	result.Name = name
	local root = Factory.Part(result, "Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), "Paper")
	root.Transparency = 1
	result.PrimaryPart = root
	result.Parent = parent
	return result
end

local function piece(parent, name, size, x, y, z, color, shape, rotation)
	return Factory.Part(parent, name, size, CFrame.new(x, y, z) * (rotation or CFrame.new()), color, shape)
end

local function eyes(parent, y, z, spacing)
	for _, side in ipairs({ -1, 1 }) do
		piece(parent, "Eye", Vector3.new(0.13, 0.18, 0.1), side * spacing, y, z, "Ink", Enum.PartType.Ball)
	end
end

function Factory.Weapon(id, parent, pivot, scale)
	local definition = Config.Weapons[id]
	assert(definition, "Unknown cosmetic weapon")
	local result = model("Toy_" .. id, parent)
	local kind, color = definition.Model, definition.Color
	if kind == "hammer" or kind == "space" then
		piece(result, "Handle", Vector3.new(0.3, 1.9, 0.3), 0, 0.65, 0, "Ink")
		piece(result, "Head", Vector3.new(1.8, 0.85, 0.85), 0, 1.75, 0, color)
		for _, side in ipairs({ -1, 1 }) do
			local cap = piece(result, "SoftCap", Vector3.new(0.22, 1, 1), side * 0.95, 1.75, 0, "Accent", Enum.PartType.Cylinder)
			if kind == "space" then cap.Material = Enum.Material.Neon end
		end
	elseif kind == "bread" then
		piece(result, "Loaf", Vector3.new(0.8, 2.9, 0.8), 0, 1.1, 0, color, Enum.PartType.Ball)
		for i = 1, 4 do
			piece(result, "Crust", Vector3.new(0.64, 0.09, 0.12), 0, i * 0.42, -0.37, "Paper", nil, CFrame.Angles(0, 0, 0.3))
		end
	elseif kind == "pan" then
		piece(result, "Handle", Vector3.new(0.3, 1.7, 0.3), 0, 0.4, 0, "Brand")
		piece(result, "Pan", Vector3.new(0.35, 1.9, 1.9), 0, 1.8, 0, color, Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0))
		piece(result, "SoftCenter", Vector3.new(0.4, 1.5, 1.5), 0, 1.8, 0, "Paper", Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0))
	elseif kind == "guitar" then
		piece(result, "Body", Vector3.new(1.3, 1.6, 0.45), 0, 0.45, 0, color, Enum.PartType.Ball)
		piece(result, "Neck", Vector3.new(0.32, 1.9, 0.25), 0, 1.8, 0, "Accent")
		piece(result, "Strings", Vector3.new(0.08, 2.3, 0.05), 0, 1.25, -0.26, "Paper")
	elseif kind == "duck" then
		piece(result, "Body", Vector3.new(1.8, 1.3, 1.6), 0, 0.7, 0, color, Enum.PartType.Ball)
		piece(result, "Head", Vector3.new(0.9, 0.9, 0.9), 0, 1.55, -0.35, color, Enum.PartType.Ball)
		piece(result, "Beak", Vector3.new(0.65, 0.23, 0.55), 0, 1.4, -0.85, "Brand")
		eyes(result, 1.65, -0.76, 0.2)
	elseif kind == "banana" then
		for i = 0, 4 do
			local angle = (i - 2) * 0.28
			piece(result, "BananaSegment", Vector3.new(0.7, 0.8, 0.7), math.cos(angle) * 1.4 - 1.2, i * 0.48, 0, color, Enum.PartType.Ball)
		end
		piece(result, "Stem", Vector3.new(0.26, 0.4, 0.26), 0, 2.3, 0, "Ink")
	elseif kind == "tub" then
		piece(result, "Base", Vector3.new(2.2, 0.35, 1.5), 0, 0.4, 0, "Brand")
		for _, side in ipairs({ -1, 1 }) do
			piece(result, "LongRim", Vector3.new(2.4, 0.65, 0.3), 0, 0.8, side * 0.7, color)
			piece(result, "ShortRim", Vector3.new(0.3, 0.65, 1.5), side * 1.1, 0.8, 0, color)
		end
		piece(result, "Bubble", Vector3.new(0.65, 0.65, 0.65), 0.4, 1.1, 0.1, "Accent", Enum.PartType.Ball)
	end
	result:ScaleTo(scale or 1)
	result:PivotTo(pivot or CFrame.new())
	return result
end

function Factory.Pet(kind, level, parent, pivot)
	local definition = Config.Pets[kind]
	assert(definition, "Unknown cosmetic pet")
	local result = model("Pet_" .. kind, parent)
	local shape, color = definition.Model, definition.Color
	if shape == "banana" then
		for i = 0, 3 do
			piece(result, "Banana", Vector3.new(0.65, 0.72, 0.65), math.sin(i * 0.5) * 0.35, 0.3 + i * 0.43, 0, color, Enum.PartType.Ball)
		end
		eyes(result, 1.2, -0.32, 0.15)
	elseif shape == "mushroom" then
		piece(result, "Stem", Vector3.new(0.9, 1.3, 0.9), 0, 0.7, 0, "Paper", Enum.PartType.Ball)
		piece(result, "Cap", Vector3.new(2.1, 0.9, 1.8), 0, 1.5, 0, color, Enum.PartType.Ball)
		eyes(result, 0.85, -0.44, 0.22)
	else
		piece(result, "Body", Vector3.new(1.45, 1.3, 1.35), 0, 0.8, 0, color, Enum.PartType.Ball)
		eyes(result, 0.95, -0.64, 0.27)
		if shape == "hamster" then
			for _, side in ipairs({ -1, 1 }) do
				piece(result, "Ear", Vector3.new(0.5, 0.6, 0.3), side * 0.52, 1.4, 0, "Accent", Enum.PartType.Ball)
			end
			piece(result, "TinyHammer", Vector3.new(0.8, 0.4, 0.4), 0.95, 0.6, -0.2, "Brand")
		elseif shape == "pigeon" then
			piece(result, "Beak", Vector3.new(0.35, 0.24, 0.5), 0, 0.7, -0.8, "Accent")
			for _, side in ipairs({ -1, 1 }) do
				piece(result, "Wing", Vector3.new(0.4, 0.9, 1.1), side * 0.8, 0.75, 0, "Paper", Enum.PartType.Ball)
			end
		else
			for _, side in ipairs({ -1, 1 }) do
				piece(result, "Antenna", Vector3.new(0.12, 0.8, 0.12), side * 0.35, 1.65, 0, "Ink", nil, CFrame.Angles(0, 0, -side * 0.25))
				piece(result, "Leg", Vector3.new(0.15, 0.8, 1.2), side * 0.8, 0.35, 0.2, color)
			end
		end
	end
	if level > 0 then
		piece(result, "LevelBadge", Vector3.new(0.35 + level * 0.12, 0.25, 0.35), 0, 2.1, 0, "Accent")
	end
	result:ScaleTo(0.8 + level * 0.08)
	result:PivotTo(pivot or CFrame.new())
	return result
end

function Factory.Dummy(parent, pivot)
	local result = model("PracticeDummy", parent)
	piece(result, "Foot", Vector3.new(5, 0.4, 4), 0, 0.2, 0, "Muted")
	piece(result, "Spring", Vector3.new(0.7, 3.2, 0.7), 0, 1.8, 0, "Ink")
	piece(result, "Pillow", Vector3.new(3.2, 3.4, 1.7), 0, 4.2, 0, "Brand", Enum.PartType.Ball)
	eyes(result, 4.6, -0.83, 0.55)
	result:PivotTo(pivot)
	return result
end

function Factory.Boss(parent, pivot)
	local result = model("CoachPillow", parent)
	piece(result, "Body", Vector3.new(7, 7, 3), 0, 4, 0, "Accent", Enum.PartType.Ball)
	piece(result, "Headband", Vector3.new(7.1, 0.7, 3.1), 0, 6.1, 0, "Brand")
	eyes(result, 5.3, -1.48, 1.15)
	for _, side in ipairs({ -1, 1 }) do
		piece(result, "Glove", Vector3.new(2.7, 2.7, 2.7), side * 4.5, 3.5, 0, "Paper", Enum.PartType.Ball)
	end
	result:PivotTo(pivot)
	return result
end

return Factory
