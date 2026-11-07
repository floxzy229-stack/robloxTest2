local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Factory = require(ReplicatedStorage:WaitForChild("BonkShared").ModelFactory)
local UI = require(script.Parent.UIComponents)
local Icons = {}

local function piece(parent, name, size, position, color, rotation, shape)
	return Factory.Part(parent, name, size, CFrame.new(position) * (rotation or CFrame.identity), color, shape)
end

local function build(kind, world)
	if kind == "hammer" or string.sub(kind, 1, 7) == "weapon:" then
		local id = kind == "hammer" and "rubber_hammer" or string.sub(kind, 8)
		return Factory.Weapon(id, world, CFrame.new(0, -0.7, 0) * CFrame.Angles(0, 0, -0.35), 1)
	end
	if kind == "shop" then
		piece(world, "Basket", Vector3.new(1.9, 1.05, 1.35), Vector3.new(0, 0.3, 0), "Pink")
		piece(world, "Inside", Vector3.new(1.55, 0.1, 1.05), Vector3.new(0, 0.86, 0), "Ink")
		for _, side in ipairs({ -1, 1 }) do
			piece(world, "Rim", Vector3.new(2.1, 0.23, 0.18), Vector3.new(0, 0.94, side * 0.68), "Pink")
			piece(world, "Handle", Vector3.new(0.15, 1.05, 0.15), Vector3.new(side * 0.75, 1.32, 0), "Portal", CFrame.Angles(0, 0, -side * 0.18))
		end
		piece(world, "Grip", Vector3.new(1.35, 0.18, 0.18), Vector3.new(0, 1.86, 0), "Portal")
		for i = -2, 2 do piece(world, "Slot", Vector3.new(0.13, 0.6, 0.035), Vector3.new(i * 0.31, 0.3, -0.69), "Lava") end
	elseif kind == "inventory" then
		piece(world, "Bag", Vector3.new(1.65, 1.85, 0.9), Vector3.new(0, 0.65, 0), "Orange")
		piece(world, "Flap", Vector3.new(1.75, 0.45, 1), Vector3.new(0, 1.35, -0.08), "Lava")
		piece(world, "Pocket", Vector3.new(1.2, 0.72, 0.27), Vector3.new(0, 0.26, -0.6), "Lava")
		piece(world, "Latch", Vector3.new(0.19, 0.6, 0.08), Vector3.new(0, 0.38, -0.79), "Paper")
		for _, side in ipairs({ -1, 1 }) do
			piece(world, "Strap", Vector3.new(0.22, 1.4, 0.2), Vector3.new(side * 0.5, 0.7, 0.6), "Ink")
			piece(world, "SidePocket", Vector3.new(0.35, 0.7, 0.7), Vector3.new(side * 0.94, 0.3, 0), "Lava")
		end
		piece(world, "Loop", Vector3.new(0.7, 0.25, 0.3), Vector3.new(0, 1.73, 0), "Ink")
	elseif kind == "rewards" then
		piece(world, "Gift", Vector3.new(1.8, 1.4, 1.4), Vector3.new(0, 0.45, 0), "Brand")
		piece(world, "Lid", Vector3.new(2, 0.3, 1.6), Vector3.new(0, 1.25, 0), "Cyan")
		piece(world, "Ribbon", Vector3.new(0.35, 1.75, 1.65), Vector3.new(0, 0.55, 0), "Accent")
		piece(world, "CrossRibbon", Vector3.new(2.05, 0.1, 0.35), Vector3.new(0, 1.43, 0), "Accent")
		for _, side in ipairs({ -1, 1 }) do
			piece(world, "Bow", Vector3.new(0.9, 0.32, 0.7), Vector3.new(side * 0.42, 1.7, 0), "Accent", CFrame.Angles(0, 0, side * 0.65))
		end
	elseif kind == "rebirth" then
		piece(world, "Orb", Vector3.new(1.95, 1.95, 1.95), Vector3.new(0, 0.7, 0), "Pink", nil, Enum.PartType.Ball)
		piece(world, "Band", Vector3.new(0.28, 2.02, 2.02), Vector3.new(0, 0.5, 0), "Ink", CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
		piece(world, "Lower", Vector3.new(0.68, 1.77, 1.77), Vector3.new(0, 0.06, 0), "Paper", CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
		piece(world, "Seal", Vector3.new(0.58, 0.58, 0.15), Vector3.new(0, 0.5, -0.96), "Ink", nil, Enum.PartType.Ball)
		piece(world, "Shine", Vector3.new(0.34, 0.18, 0.13), Vector3.new(-0.4, 1.3, -0.78), "Paper", CFrame.Angles(0, 0, -0.4))
	elseif kind == "ascension" then
		piece(world, "Shoulders", Vector3.new(2, 0.65, 0.9), Vector3.new(0, -0.1, 0), "Brand")
		piece(world, "Head", Vector3.new(1.35, 1.45, 1.15), Vector3.new(0, 0.85, 0), "Sand")
		piece(world, "Hair", Vector3.new(1.48, 0.4, 1.3), Vector3.new(0, 1.55, 0), "Earth")
		for _, side in ipairs({ -1, 1 }) do
			piece(world, "Eye", Vector3.new(0.17, 0.17, 0.06), Vector3.new(side * 0.3, 0.95, -0.6), "Ink")
			piece(world, "HairSide", Vector3.new(0.2, 1.2, 1.22), Vector3.new(side * 0.7, 1.05, 0), "Earth")
		end
		piece(world, "Smile", Vector3.new(0.36, 0.08, 0.06), Vector3.new(0, 0.48, -0.6), "Ink")
		piece(world, "CrownBand", Vector3.new(1.55, 0.2, 1.3), Vector3.new(0, 1.79, 0), "Accent")
		for i = -1, 1 do piece(world, "CrownPoint", Vector3.new(0.2, 0.45, 0.2), Vector3.new(i * 0.56, 2.02, -0.5), "Accent", CFrame.Angles(0, 0, i * 0.2)) end
	elseif kind == "exchange" then
		for _, side in ipairs({ -1, 1 }) do
			local color = side == 1 and "Brand" or "Accent"
			local transform = CFrame.new(0, 0.65 + side * 0.44, 0) * CFrame.Angles(0, 0, side == 1 and 0 or math.pi)
			Factory.Part(world, "ArrowBody", Vector3.new(1.5, 0.45, 0.45), transform * CFrame.new(-0.15, 0, 0), color)
			for i = 0, 2 do
				Factory.Part(world, "ArrowTip", Vector3.new(0.22, 1.05 - i * 0.31, 0.45), transform * CFrame.new(0.55 + i * 0.2, 0, 0), color)
			end
		end
	elseif kind == "crystals" then
		piece(world, "Gem", Vector3.new(1.18, 1.18, 1.18), Vector3.new(0, 0.7, 0), "Purple", CFrame.Angles(0, 0, math.pi / 4))
		piece(world, "Facet", Vector3.new(0.45, 0.9, 0.08), Vector3.new(-0.3, 0.8, -0.7), "Pink", CFrame.Angles(0, 0, -0.4))
	end
end

function Icons.Add(parent, kind, size, position)
	local viewport = UI.Create("ViewportFrame", {
		Name = "Icon_" .. kind, Size = size or UDim2.fromScale(1, 1), Position = position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Active = false,
		Ambient = Color3.fromRGB(195, 200, 215), LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -3), ZIndex = parent.ZIndex + 1,
	}, parent)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.CFrame = CFrame.lookAt(Vector3.new(3, 2.6, -7.5), Vector3.new(0, 0.7, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	build(kind, world)
	return viewport
end

return Icons
