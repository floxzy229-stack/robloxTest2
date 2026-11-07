local Config = require(script.Parent.GameConfig)
local Economy = {}

function Economy.IsFinite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Economy.UpgradePrice(id, level)
	local upgrade = Config.Upgrades[id]
	return math.floor(upgrade.BasePrice * upgrade.Growth ^ level)
end

function Economy.ManualMultiplier(profile)
	return 1 + profile.Upgrades.manual * Config.Upgrades.manual.Step
end

function Economy.SpeedMultiplier(profile)
	return 1 + (profile.Progression and profile.Progression.SpeedLevel or 0) * Config.Training.SpeedPerLevel
end

function Economy.SpeedRequired(level)
	return Config.Training.BaseXP + level * Config.Training.XPPerLevel
end

function Economy.AddTraining(profile, amount)
	assert(Economy.IsFinite(amount) and amount >= 0 and amount % 1 == 0, "Invalid training credit")
	local progress = profile.Progression
	if progress.SpeedLevel >= Config.Training.MaxLevel then return false end
	progress.SpeedXP += amount
	while progress.SpeedLevel < Config.Training.MaxLevel and progress.SpeedXP >= Economy.SpeedRequired(progress.SpeedLevel) do
		progress.SpeedXP -= Economy.SpeedRequired(progress.SpeedLevel)
		progress.SpeedLevel += 1
	end
	if progress.SpeedLevel >= Config.Training.MaxLevel then progress.SpeedXP = 0 end
	return true
end

function Economy.RebirthCost(profile)
	return math.floor(math.min(Config.MaxCurrency, Config.Progression.RebirthBasePrice * Config.Progression.RebirthGrowth ^ profile.Progression.Rebirths))
end

function Economy.AscensionCost(profile)
	return Config.Progression.AscensionCrystals * (profile.Progression.Ascensions + 1)
end

function Economy.ProgressionMultiplier(profile)
	local progress = profile.Progression
	if not progress then return 1 end
	return (1 + progress.Rebirths * Config.Progression.IncomePerRebirth) * (1 + progress.Ascensions * Config.Progression.IncomePerAscension)
end

function Economy.Cooldown(profile)
	local upgraded = math.max(Config.MinCooldown, Config.BaseCooldown - profile.Upgrades.cooldown * Config.Upgrades.cooldown.Step)
	return math.max(Config.TrainedMinCooldown, upgraded / Economy.SpeedMultiplier(profile))
end

function Economy.CritChance(profile)
	return math.min(Config.MaxCritChance, Config.BaseCritChance + profile.Upgrades.critical * Config.Upgrades.critical.Step)
end

function Economy.AutoInterval(profile)
	local level = profile.Upgrades.auto
	if level == 0 then return nil end
	local upgrade = Config.Upgrades.auto
	return math.max(upgrade.MinInterval, upgrade.Interval - (level - 1) * upgrade.Step)
end

function Economy.Slots(entitlements)
	return Config.BasePetSlots + (entitlements.extra_slot and 1 or 0)
end

function Economy.GlobalMultiplier(profile, entitlements, now)
	return (entitlements.vip and 1.1 or 1)
		* (entitlements.double and 2 or 1)
		* (profile.BoostUntil > now and 2 or 1)
		* Economy.ProgressionMultiplier(profile)
end

function Economy.PetIncome(pet)
	return Config.Pets[pet.Kind].Income * Config.PetLevelMultiplier ^ pet.Level
end

function Economy.ActivePets(profile, entitlements)
	local byId = {}
	for _, pet in ipairs(profile.Pets) do byId[pet.Uid] = pet end
	local result = {}
	for _, uid in ipairs(profile.EquippedPets) do
		if byId[uid] and #result < Economy.Slots(entitlements) then
			table.insert(result, byId[uid])
		end
	end
	return result
end

function Economy.RawIncome(profile, entitlements, source, critical, now)
	local base, sourceMultiplier = 0, 1
	if source == "manual" or source == "auto" then
		base = Config.Weapons[profile.EquippedWeapon].Base
		sourceMultiplier = source == "manual" and Economy.ManualMultiplier(profile) or 1
	elseif source == "pets" then
		for _, pet in ipairs(Economy.ActivePets(profile, entitlements)) do
			base += Economy.PetIncome(pet)
		end
		sourceMultiplier = 1 + profile.Upgrades.pet_income * Config.Upgrades.pet_income.Step
	else
		error("Unknown income source")
	end
	local criticalMultiplier = source ~= "pets" and critical and Config.CritMultiplier or 1
	return base * sourceMultiplier * Economy.GlobalMultiplier(profile, entitlements, now) * criticalMultiplier
end

function Economy.Accrue(profile, entitlements, source, critical, now, ticks)
	local raw = Economy.RawIncome(profile, entitlements, source, critical, now) * (ticks or 1) + profile.IncomeCarry[source]
	local whole = math.floor(raw + 1e-7)
	profile.IncomeCarry[source] = math.max(0, raw - whole)
	return Economy.Add(profile, whole)
end

function Economy.BossDamage(profile, critical)
	local raw = Config.Weapons[profile.EquippedWeapon].Base * Economy.ManualMultiplier(profile)
	return math.min(Config.Boss.MaxDamagePerHit, math.floor(raw * (critical and Config.CritMultiplier or 1)))
end

function Economy.Add(profile, amount)
	assert(Economy.IsFinite(amount) and amount >= 0 and amount % 1 == 0, "Invalid currency credit")
	local credited = math.min(amount, Config.MaxCurrency - profile.Currency)
	profile.Currency += credited
	profile.Statistics.TotalEarned = math.min(Config.MaxCurrency, profile.Statistics.TotalEarned + credited)
	return credited
end

function Economy.Spend(profile, amount)
	assert(Economy.IsFinite(amount) and amount >= 0 and amount % 1 == 0, "Invalid currency debit")
	if profile.Currency < amount then return false end
	profile.Currency -= amount
	return true
end

function Economy.UpgradeEffect(id, level)
	local u = Config.Upgrades[id]
	if id == "manual" then return string.format("x%.2f вручную", 1 + level * u.Step) end
	if id == "cooldown" then return string.format("%.2f сек.", math.max(Config.MinCooldown, Config.BaseCooldown - level * u.Step)) end
	if id == "critical" then return string.format("%d%% крит", math.floor((Config.BaseCritChance + level * u.Step) * 100 + 0.5)) end
	if id == "auto" then
		return level == 0 and "Выключен" or string.format("Раз в %.2f сек.", math.max(u.MinInterval, u.Interval - (level - 1) * u.Step))
	end
	return string.format("x%.2f доход питомцев", 1 + level * u.Step)
end

return Economy
