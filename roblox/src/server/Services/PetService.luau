local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Operations = require(script.Parent.Parent.Data.PetOperations)
local PetService = {}
PetService.__index = PetService

function PetService.new(context)
	return setmetatable({ Context = context, Random = Random.new(), Runtime = {} }, PetService)
end

function PetService:Slots(player)
	return Economy.Slots(self.Context.Monetization:Get(player))
end

function PetService:Publish(player)
	local profile = self.Context.Data:Get(player)
	if not profile then return end
	player:SetAttribute("BonkPets", HttpService:JSONEncode(Economy.ActivePets(profile, self.Context.Monetization:Get(player))))
end

function PetService:Hatch(player)
	local uid = HttpService:GenerateGUID(false)
	local ok, message, result = self.Context.Data:Mutate(player, function(profile)
		if #profile.Pets >= Config.MaxPets then return false, "Инвентарь заполнен (100). Сначала объедините питомцев." end
		if not self.Context.Currency:Debit(profile, Config.EggPrice) then return false, "Недостаточно Терпения: яйцо стоит 250." end
		local kind = Operations.Roll(self.Random:NextNumber() * 100)
		local pet = { Uid = uid, Kind = kind, Level = 0 }
		table.insert(profile.Pets, pet)
		if #profile.EquippedPets < self:Slots(player) then table.insert(profile.EquippedPets, uid) end
		profile.Statistics.EggsOpened += 1
		return true, "Новый помощник: " .. Config.Pets[kind].Name, { Hatched = pet }
	end, true)
	if ok then self:Publish(player) end
	return ok, message, result
end

function PetService:Equip(player, uid, remove)
	local ok, message = self.Context.Data:Mutate(player, function(profile)
		local owned = false
		for _, pet in ipairs(profile.Pets) do if pet.Uid == uid then owned = true break end end
		if not owned then return false, "Этот питомец вам не принадлежит." end
		local index = table.find(profile.EquippedPets, uid)
		if remove then
			if not index then return false, "Питомец уже снят." end
			table.remove(profile.EquippedPets, index)
		else
			if index then return false, "Уже экипировано." end
			if #profile.EquippedPets >= self:Slots(player) then return false, "Нет свободных слотов. Снимите питомца или экипируйте лучших." end
			table.insert(profile.EquippedPets, uid)
		end
		return true, remove and "Питомец отдыхает в инвентаре." or "Питомец готов помогать."
	end, true)
	if ok then self:Publish(player) end
	return ok, message
end

function PetService:Best(player)
	local ok, message = self.Context.Data:Mutate(player, function(profile)
		if #profile.Pets == 0 then return false, "Сначала откройте яйцо." end
		Operations.Best(profile, self:Slots(player))
		return true, "Лучшие помощники экипированы."
	end, true)
	if ok then self:Publish(player) end
	return ok, message
end

function PetService:Merge(player, uids)
	local uid = HttpService:GenerateGUID(false)
	local ok, message = self.Context.Data:Mutate(player, function(profile)
		return Operations.Merge(profile, uids, uid)
	end, true)
	if ok then self:Publish(player) end
	return ok, message
end

function PetService:Step(dt)
	for player, entry in pairs(self.Context.Data.Entries) do
		if not self.Context.Data:IsReady(player) then continue end
		local runtime = self.Runtime[player] or { Seconds = 0 }
		self.Runtime[player] = runtime
		runtime.Seconds = math.min(5, runtime.Seconds + dt)
		if runtime.Seconds < 1 or entry.Busy then continue end
		local seconds = math.floor(runtime.Seconds)
		local ok = self.Context.Data:Mutate(player, function(profile)
			self.Context.Currency:Accrue(profile, self.Context.Monetization:Get(player), "pets", false, os.time(), seconds)
			profile.Statistics.SecondsPlayed += seconds
			return true
		end, false)
		if ok then runtime.Seconds -= seconds end
	end
end

function PetService:Remove(player)
	self.Runtime[player] = nil
end

return PetService
