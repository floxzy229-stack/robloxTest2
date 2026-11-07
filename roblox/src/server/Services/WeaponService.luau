local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("BonkShared").GameConfig)
local WeaponService = {}
WeaponService.__index = WeaponService

function WeaponService.new(context)
	return setmetatable({ Context = context }, WeaponService)
end

function WeaponService:ApplyTool(player, id)
	local character = player.Character
	if not character then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	for _, container in ipairs({ backpack, character }) do
		local old = container:FindFirstChild("BonkHammer")
		if old then old:Destroy() end
	end
	local tool = Instance.new("Tool")
	tool.Name = "BonkHammer"
	tool.ToolTip = "Бонк: " .. (Config.Weapons[id] and Config.Weapons[id].Name or id)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.35, 0.35)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool
	local model = require(ReplicatedStorage.BonkShared.ModelFactory).Weapon(id, tool, CFrame.new(), 1)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		end
	end
	tool.Grip = CFrame.new(0, -0.7, -0.25) * CFrame.Angles(math.rad(-90), 0, math.rad(90))
	tool.Parent = backpack
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:EquipTool(tool) end
end

function WeaponService:Buy(player, id)
	local item = Config.Weapons[id]
	if not item then return false, "Такой игрушки нет." end
	local accepted, message = self.Context.Data:Mutate(player, function(profile)
		if profile.Weapons[id] then return false, "Куплено: повторное списание не требуется." end
		if not self.Context.Currency:Debit(profile, item.Price) then return false, "Недостаточно Терпения." end
		profile.Weapons[id] = true
		profile.EquippedWeapon = id
		return true, "Куплено и экипировано: " .. item.Name
	end, true)
	if accepted then self:ApplyTool(player, id) end
	return accepted, message
end

function WeaponService:Equip(player, id)
	if not Config.Weapons[id] then return false, "Такой игрушки нет." end
	local accepted, message = self.Context.Data:Mutate(player, function(profile)
		if not profile.Weapons[id] then return false, "Сначала купите эту игрушку." end
		if profile.EquippedWeapon == id then return false, "Уже экипировано." end
		profile.EquippedWeapon = id
		return true, "Экипировано: " .. Config.Weapons[id].Name
	end, true)
	if accepted then self:ApplyTool(player, id) end
	return accepted, message
end

return WeaponService
