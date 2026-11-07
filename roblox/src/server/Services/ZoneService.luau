local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("BonkShared").GameConfig)
local ZoneService = {}
ZoneService.__index = ZoneService

function ZoneService.new(context, world)
	return setmetatable({ Context = context, World = world, Current = {}, NextTeleport = {}, NextPrompt = {}, Connections = {} }, ZoneService)
end

function ZoneService:Root(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return root
end

function ZoneService:IsInZone(player, id)
	local profile = self.Context.Data:Get(player)
	local root = self:Root(player)
	local center = self.World.Centers[id]
	if not profile or not profile.Zones[id] or not root or not center or self.Current[player] ~= id then return false end
	local delta = root.Position - center
	return math.abs(delta.X) <= Config.ZoneHalfSize + 2 and math.abs(delta.Z) <= Config.ZoneHalfSize + 2 and delta.Y >= -8 and delta.Y <= 75
end

function ZoneService:CanHit(player)
	return self:IsInZone(player, self.Current[player] or "playroom")
end

function ZoneService:PracticeFor(player)
	local zone = self.Current[player]
	if not zone or not self:IsInZone(player, zone) then return nil end
	local root = self:Root(player)
	local dummy = self.World.Dummies[zone]
	if root and (root.Position - dummy:GetPivot().Position).Magnitude <= Config.PracticeRadius then return zone end
	return nil
end

function ZoneService:Buy(player, id)
	local definition = Config.Zones[id]
	if not definition then return false, "Неизвестная зона." end
	return self.Context.Data:Mutate(player, function(profile)
		if profile.Zones[id] then return false, "Эта зона уже открыта." end
		if not self.Context.Currency:Debit(profile, definition.Price) then return false, "Недостаточно Терпения." end
		profile.Zones[id] = true
		return true, "Открыто: " .. definition.Name .. ". Нажмите «Телепорт»."
	end, true)
end

function ZoneService:Teleport(player, id, forced)
	if not Config.Zones[id] then return false, "Неизвестная зона." end
	local profile = self.Context.Data:Get(player)
	if not profile or not profile.Zones[id] then return false, "Зона ещё не открыта." end
	local root = self:Root(player)
	if not root then return false, "Подождите появления персонажа." end
	if not forced and os.clock() < (self.NextTeleport[player] or 0) then return false, "Портал готовится. Подождите секунду." end
	self.NextTeleport[player] = os.clock() + 1
	if self.Context.Training then self.Context.Training:Stop(player) end
	self.Current[player] = id
	player.Character:PivotTo(CFrame.new(self.World.Spawns[id].Position + Vector3.new(0, 4, 0)))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	self.Context.Data:MarkFull(player)
	return true, "Добро пожаловать: " .. Config.Zones[id].Name
end

function ZoneService:PlaceCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root and character == player.Character and self.Context.Data:Get(player) then
		self:Teleport(player, self.Current[player] or "playroom", true)
		self.Context.Monetization:ApplyCosmetics(player)
	end
end

function ZoneService:ClaimPractice(player, id)
	local definition = Config.Zones[id]
	if not definition or not definition.PracticeTarget then return false, "В этой зоне нет премии за практику." end
	if self:PracticeFor(player) ~= id then return false, "Подойдите к манекену в нужной открытой зоне." end
	return self.Context.Data:Mutate(player, function(profile)
		if profile.Statistics.PracticeClaims[id] then return false, "Премия уже получена. Манекен остаётся для практики." end
		if profile.Statistics.PracticeHits[id] < definition.PracticeTarget then return false, "Сначала выполните указанное число ручных бонков у манекена." end
		profile.Statistics.PracticeClaims[id] = true
		self.Context.Currency:Credit(profile, definition.PracticeReward)
		return true, "Премия за практику: +" .. definition.PracticeReward .. " Терпения."
	end, true)
end

function ZoneService:Start()
	for _, prompt in ipairs(self.World.Prompts) do
		table.insert(self.Connections, prompt.Triggered:Connect(function(player)
			local root = self:Root(player)
			if not root or not prompt.Parent:IsA("BasePart") or (root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance + 2 then return end
			if os.clock() < (self.NextPrompt[player] or 0) then return end
			self.NextPrompt[player] = os.clock() + 1
			local profile = self.Context.Data:Get(player)
			if not profile then return end
			local weaponId = prompt:GetAttribute("WeaponId")
			if weaponId and Config.Weapons[weaponId] then
				local accepted, message
				if profile.Weapons[weaponId] then
					accepted, message = self.Context.Weapons:Equip(player, weaponId)
				else
					accepted, message = self.Context.Weapons:Buy(player, weaponId)
				end
				self.Context.Remotes.Notice:FireClient(player, { Message = message, OpenWindow = accepted and "weapons" or "shop" })
				return
			end
			local target = prompt:GetAttribute("TargetZone")
			if target and Config.Zones[target] then
				if profile.Zones[target] then
					local _, message = self:Teleport(player, target, false)
					self.Context.Remotes.Notice:FireClient(player, { Message = message })
				else
					local bought, message = self:Buy(player, target)
					if bought then
						local _, teleportMessage = self:Teleport(player, target, false)
						message = teleportMessage
					end
					self.Context.Remotes.Notice:FireClient(player, { Message = message, OpenWindow = bought and nil or "zones" })
				end
			else
				local _, message = self:ClaimPractice(player, prompt:GetAttribute("PracticeZone"))
				self.Context.Remotes.Notice:FireClient(player, { Message = message })
			end
		end))
	end
end

function ZoneService:Step()
	for player, id in pairs(self.Current) do
		local root = self:Root(player)
		if root and self.Context.Data:IsReady(player) and not self:IsInZone(player, id) then self:Teleport(player, id, false) end
	end
end

function ZoneService:Remove(player)
	self.Current[player] = nil
	self.NextTeleport[player] = nil
	self.NextPrompt[player] = nil
end

function ZoneService:Destroy()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return ZoneService
