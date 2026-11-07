local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Operations = {}

function Operations.Roll(sample)
	assert(type(sample) == "number" and sample >= 0 and sample < 100, "Invalid egg roll")
	local cumulative = 0
	local totalWeight = 0
	for _, id in ipairs(Config.PetOrder) do totalWeight += Config.Pets[id].Weight end
	assert(math.abs(totalWeight - 100) < 0.001, "Pet weights must sum to 100")
	for _, id in ipairs(Config.PetOrder) do
		cumulative += Config.Pets[id].Weight
		if sample < cumulative then return id end
	end
	error("Pet weights do not sum to 100")
end

function Operations.Merge(profile, uids, newUid)
	if #uids ~= 3 then return false, "Нужно ровно три экземпляра." end
	local byId, selected = {}, {}
	for _, pet in ipairs(profile.Pets) do byId[pet.Uid] = pet end
	if byId[newUid] then return false, "Конфликт ID. Повторите операцию." end
	local first = byId[uids[1]]
	if not first or first.Level >= Config.MaxPetLevel then return false, "Питомец отсутствует или уже максимального уровня." end
	for _, uid in ipairs(uids) do
		local pet = byId[uid]
		if selected[uid] or not pet or pet.Kind ~= first.Kind or pet.Level ~= first.Level then return false, "Нужны три разных экземпляра одного вида и уровня." end
		selected[uid] = true
	end
	local remaining, equipped, wasEquipped = {}, {}, false
	for _, pet in ipairs(profile.Pets) do if not selected[pet.Uid] then table.insert(remaining, pet) end end
	for _, uid in ipairs(profile.EquippedPets) do
		if selected[uid] then wasEquipped = true else table.insert(equipped, uid) end
	end
	local merged = { Uid = newUid, Kind = first.Kind, Level = first.Level + 1 }
	table.insert(remaining, merged)
	if wasEquipped then table.insert(equipped, merged.Uid) end
	profile.Pets = remaining
	profile.EquippedPets = equipped
	return true, "Три помощника стали одним сильнее.", merged
end

function Operations.Best(profile, slots)
	local pets = table.clone(profile.Pets)
	table.sort(pets, function(a, b)
		local first, second = Economy.PetIncome(a), Economy.PetIncome(b)
		return first == second and a.Uid < b.Uid or first > second
	end)
	local result = {}
	for i = 1, math.min(slots, #pets) do table.insert(result, pets[i].Uid) end
	profile.EquippedPets = result
end

return Operations
