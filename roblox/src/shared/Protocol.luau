local Protocol = {}

Protocol.Folder = "BonkRemotes"
Protocol.Remotes = {
	Action = "Action", ActionResult = "ActionResult", State = "State",
	Hit = "Hit", HitResult = "HitResult", BossState = "BossState", Notice = "Notice",
}
Protocol.Actions = {
	Sync = true, BuyWeapon = true, EquipWeapon = true, BuyUpgrade = true,
	HatchEgg = true, EquipPet = true, UnequipPet = true, BestPets = true,
	MergePets = true, BuyZone = true, Teleport = true, ClaimPractice = true,
	SetSetting = true, Catalog = true, PromptPurchase = true, RefreshPasses = true,
	ClaimDaily = true, ClaimReward = true, Rebirth = true, Ascend = true, Exchange = true,
}

function Protocol.ShortString(value, limit)
	return type(value) == "string" and #value > 0 and #value <= limit
end

function Protocol.Validate(requestId, action, payload)
	if type(requestId) ~= "number" or requestId % 1 ~= 0 or requestId < 1 or requestId > 2_147_483_647 then
		return false
	end
	if not Protocol.ShortString(action, 32) or not Protocol.Actions[action] or type(payload) ~= "table" then
		return false
	end
	local count = 0
	for key, value in pairs(payload) do
		count += 1
		if count > 3 or not Protocol.ShortString(key, 16) then return false end
		if type(value) == "string" and #value > 64 then return false end
		if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then return false end
		if type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" and type(value) ~= "table" then return false end
	end
	local noPayload = { Sync = true, HatchEgg = true, BestPets = true, Catalog = true, RefreshPasses = true, ClaimDaily = true }
	if noPayload[action] then return count == 0 end
	if action == "Rebirth" or action == "Ascend" then
		return count == 1 and type(payload.expected) == "number" and payload.expected % 1 == 0 and payload.expected >= 0 and payload.expected <= 50
	end
	if action == "MergePets" then
		if count ~= 1 or type(payload.uids) ~= "table" then return false end
		local seen, size = {}, 0
		for key, uid in pairs(payload.uids) do
			if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 3 or not Protocol.ShortString(uid, 64) or seen[uid] then return false end
			seen[uid] = true
			size += 1
		end
		return size == 3
	end
	if action == "SetSetting" then
		if count ~= 2 then return false end
		if payload.key == "Volume" then return type(payload.value) == "number" and payload.value >= 0 and payload.value <= 1 end
		return (payload.key == "Effects" or payload.key == "ShowOtherPets") and type(payload.value) == "boolean"
	end
	if action == "PromptPurchase" then
		return count == 2 and (payload.kind == "pass" or payload.kind == "product") and Protocol.ShortString(payload.key, 40)
	end
	return count == 1 and Protocol.ShortString(payload.id, 64)
end

return Protocol
