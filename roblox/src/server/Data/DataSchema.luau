local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Schema = {}

function Schema.Clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = Schema.Clone(item) end
	return result
end

function Schema.Default()
	local upgrades, practice = {}, {}
	for key in pairs(Config.Upgrades) do upgrades[key] = 0 end
	for key in pairs(Config.Zones) do practice[key] = 0 end
	return {
		Version = Config.SchemaVersion, Currency = 0,
		Weapons = { rubber_hammer = true }, EquippedWeapon = "rubber_hammer", Upgrades = upgrades,
		Pets = {}, EquippedPets = {}, Zones = { playroom = true },
		Statistics = { ManualHits = 0, AutoHits = 0, CriticalHits = 0, TotalEarned = 0, EggsOpened = 0, BossWins = 0, SecondsPlayed = 0, PracticeHits = practice, PracticeClaims = {}, LastBossRound = "" },
		Settings = { Volume = 0.5, Effects = true, ShowOtherPets = true },
		Progression = { Rebirths = 0, Ascensions = 0, Crystals = 0, SpeedLevel = 0, SpeedXP = 0, LastDailyDay = 0, RewardClaims = {} },
		BoostUntil = 0, Receipts = {}, IncomeCarry = { manual = 0, auto = 0, pets = 0 },
	}
end

local function integer(value, minimum, maximum, name)
	assert(Economy.IsFinite(value) and value % 1 == 0 and value >= minimum and value <= maximum, "Invalid profile field: " .. name)
	return value
end

local function array(value, maximum, name)
	assert(type(value) == "table", "Invalid array: " .. name)
	local count = 0
	for key in pairs(value) do
		assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= maximum, "Invalid array index: " .. name)
		count += 1
	end
	assert(count == #value and count <= maximum, "Sparse or oversized array: " .. name)
	return value
end

local function ownedMap(value, catalog, name)
	assert(type(value) == "table", "Invalid ownership map: " .. name)
	local result = {}
	for key, owned in pairs(value) do
		assert(type(key) == "string" and catalog[key] and type(owned) == "boolean", "Unknown ownership entry: " .. name)
		if owned then result[key] = true end
	end
	return result
end

function Schema.Normalize(raw)
	assert(type(raw) == "table", "Existing profile is not a table")
	local data = Schema.Clone(raw)
	local version = data.Version or 1
	integer(version, 1, Config.SchemaVersion, "Version")
	if version == 1 then
		if data.Currency == nil then data.Currency = data.Patience end
		data.Receipts = data.Receipts or data.ProcessedReceipts or {}
		for purchaseId, entry in pairs(data.Receipts) do
			if entry == true then data.Receipts[purchaseId] = { ProductId = 0, GrantedAt = 0 } end
		end
		data.Version = 2
	end
	local defaults = Schema.Default()
	local result = Schema.Default()
	result.Currency = integer(data.Currency, 0, Config.MaxCurrency, "Currency")
	result.Weapons = ownedMap(data.Weapons or defaults.Weapons, Config.Weapons, "Weapons")
	result.Weapons.rubber_hammer = true
	result.EquippedWeapon = data.EquippedWeapon or "rubber_hammer"
	assert(result.Weapons[result.EquippedWeapon], "Equipped weapon is not owned")
	local upgrades = data.Upgrades or {}
	assert(type(upgrades) == "table", "Invalid upgrades")
	for id, definition in pairs(Config.Upgrades) do result.Upgrades[id] = integer(upgrades[id] or 0, 0, definition.Max, "Upgrades." .. id) end
	result.Zones = ownedMap(data.Zones or defaults.Zones, Config.Zones, "Zones")
	result.Zones.playroom = true
	local ids = {}
	for _, pet in ipairs(array(data.Pets or {}, Config.MaxPets, "Pets")) do
		assert(type(pet) == "table" and type(pet.Uid) == "string" and #pet.Uid > 0 and #pet.Uid <= 64 and not ids[pet.Uid], "Invalid or duplicate pet UID")
		assert(Config.Pets[pet.Kind], "Unknown saved pet kind")
		integer(pet.Level, 0, Config.MaxPetLevel, "Pet.Level")
		ids[pet.Uid] = true
		table.insert(result.Pets, { Uid = pet.Uid, Kind = pet.Kind, Level = pet.Level })
	end
	local equipped = {}
	for _, uid in ipairs(array(data.EquippedPets or {}, Config.MaxPetSlots, "EquippedPets")) do
		assert(ids[uid] and not equipped[uid], "Invalid equipped pet")
		equipped[uid] = true
		table.insert(result.EquippedPets, uid)
	end
	local stats = data.Statistics or {}
	assert(type(stats) == "table", "Invalid statistics")
	for key, value in pairs(defaults.Statistics) do
		if type(value) == "number" then result.Statistics[key] = integer(stats[key] or 0, 0, Config.MaxCurrency, "Statistics." .. key) end
	end
	local hits, claims = stats.PracticeHits or {}, stats.PracticeClaims or {}
	assert(type(hits) == "table" and type(claims) == "table", "Invalid practice statistics")
	for zone in pairs(Config.Zones) do
		result.Statistics.PracticeHits[zone] = integer(hits[zone] or 0, 0, Config.MaxCurrency, "PracticeHits." .. zone)
		if claims[zone] ~= nil then assert(type(claims[zone]) == "boolean", "Invalid practice claim") end
		if claims[zone] == true then result.Statistics.PracticeClaims[zone] = true end
	end
	result.Statistics.LastBossRound = stats.LastBossRound or ""
	assert(type(result.Statistics.LastBossRound) == "string" and #result.Statistics.LastBossRound <= 80, "Invalid boss receipt")
	local settings = data.Settings or defaults.Settings
	assert(type(settings) == "table", "Invalid settings")
	for key, defaultValue in pairs(defaults.Settings) do
		local value = settings[key]
		if value == nil then value = defaultValue end
		if key == "Volume" then assert(Economy.IsFinite(value) and value >= 0 and value <= 1, "Invalid volume")
		else assert(type(value) == "boolean", "Invalid setting: " .. key) end
		result.Settings[key] = value
	end
	local progress = data.Progression or defaults.Progression
	assert(type(progress) == "table", "Invalid progression")
	result.Progression.Rebirths = integer(progress.Rebirths or 0, 0, Config.Progression.MaxRebirths, "Rebirths")
	result.Progression.Ascensions = integer(progress.Ascensions or 0, 0, Config.Progression.MaxAscensions, "Ascensions")
	result.Progression.Crystals = integer(progress.Crystals or 0, 0, Config.MaxCurrency, "Crystals")
	result.Progression.SpeedLevel = integer(progress.SpeedLevel or 0, 0, Config.Training.MaxLevel, "SpeedLevel")
	local maxXP = result.Progression.SpeedLevel >= Config.Training.MaxLevel and 0 or Economy.SpeedRequired(result.Progression.SpeedLevel) - 1
	result.Progression.SpeedXP = integer(progress.SpeedXP or 0, 0, maxXP, "SpeedXP")
	result.Progression.LastDailyDay = integer(progress.LastDailyDay or 0, 0, 1_000_000, "LastDailyDay")
	result.Progression.RewardClaims = ownedMap(progress.RewardClaims or {}, Config.Rewards, "RewardClaims")
	result.BoostUntil = integer(data.BoostUntil or 0, 0, 20_000_000_000, "BoostUntil")
	local carry = data.IncomeCarry or defaults.IncomeCarry
	assert(type(carry) == "table", "Invalid income remainder map")
	for source in pairs(defaults.IncomeCarry) do
		local value = carry[source] or 0
		assert(Economy.IsFinite(value) and value >= 0 and value < 1, "Invalid income remainder")
		result.IncomeCarry[source] = value
	end
	local receipts = data.Receipts or {}
	assert(type(receipts) == "table", "Invalid purchase ledger")
	for purchaseId, receipt in pairs(receipts) do
		assert(type(purchaseId) == "string" and #purchaseId > 0 and #purchaseId <= 200 and type(receipt) == "table", "Invalid persisted receipt")
		result.Receipts[purchaseId] = {
			ProductId = integer(receipt.ProductId, 0, Config.MaxCurrency, "Receipt.ProductId"),
			GrantedAt = integer(receipt.GrantedAt, 0, 20_000_000_000, "Receipt.GrantedAt"),
		}
	end
	return result
end

function Schema.Public(profile)
	local result = Schema.Clone(profile)
	result.Receipts = nil
	result.IncomeCarry = nil
	return result
end

return Schema
