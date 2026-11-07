local Config = require(script.Parent.GameConfig)
local Economy = require(script.Parent.Economy)
local Rules = {}

local function addCrystals(profile, amount)
	profile.Progression.Crystals = math.min(Config.MaxCurrency, profile.Progression.Crystals + amount)
end

function Rules.RewardCount(profile, now)
	local count = profile.Progression.LastDailyDay < math.floor(now / 86400) and 1 or 0
	for _, id in ipairs(Config.RewardOrder) do
		local definition = Config.Rewards[id]
		if not profile.Progression.RewardClaims[id] and profile.Statistics[definition.Stat] >= definition.Target then count += 1 end
	end
	return count
end

function Rules.Daily(profile, now)
	local day = math.floor(now / 86400)
	if profile.Progression.LastDailyDay >= day then return false, "Сегодня награда уже получена. Новая — в 00:00 UTC." end
	profile.Progression.LastDailyDay = day
	Economy.Add(profile, Config.Progression.DailyCurrency)
	addCrystals(profile, Config.Progression.DailyCrystals)
	return true, "Ежедневная награда: +250 Терпения и +10 кристаллов!"
end

function Rules.Reward(profile, id)
	local reward = Config.Rewards[id]
	if not reward then return false, "Неизвестная награда." end
	if profile.Progression.RewardClaims[id] then return false, "Эта награда уже получена." end
	if profile.Statistics[reward.Stat] < reward.Target then return false, "Задание ещё не выполнено." end
	profile.Progression.RewardClaims[id] = true
	Economy.Add(profile, reward.Currency)
	addCrystals(profile, reward.Crystals)
	return true, "Получена награда: " .. reward.Name
end

function Rules.Rebirth(profile, expectedCount)
	local progress = profile.Progression
	if expectedCount ~= progress.Rebirths then return false, "Условия изменились. Откройте окно перерождения заново." end
	if progress.Rebirths >= Config.Progression.MaxRebirths then return false, "Достигнут максимум перерождений." end
	if profile.Currency < Economy.RebirthCost(profile) then return false, "Недостаточно Терпения для перерождения." end
	profile.Currency = 0
	for id in pairs(Config.Upgrades) do profile.Upgrades[id] = 0 end
	for source in pairs(profile.IncomeCarry) do profile.IncomeCarry[source] = 0 end
	progress.Rebirths += 1
	addCrystals(profile, Config.Progression.CrystalsPerRebirth)
	return true, "Перерождение! Постоянный бонус вырос, получено 25 кристаллов. Молотки, питомцы, миры и скорость сохранены."
end

function Rules.Ascend(profile, expectedCount)
	local progress = profile.Progression
	if expectedCount ~= progress.Ascensions then return false, "Условия изменились. Откройте окно восхождения заново." end
	if progress.Ascensions >= Config.Progression.MaxAscensions then return false, "Достигнута вершина восхождения." end
	local required = (progress.Ascensions + 1) * Config.Progression.RebirthsPerAscension
	if progress.Rebirths < required then return false, "Для следующего восхождения нужно " .. required .. " перерождений." end
	local cost = Economy.AscensionCost(profile)
	if progress.Crystals < cost then return false, "Недостаточно кристаллов." end
	progress.Crystals -= cost
	progress.Ascensions += 1
	return true, "Новая ступень восхождения! Постоянный доход увеличен. Прогресс не сброшен."
end

function Rules.Exchange(profile, id)
	local offer = Config.Exchanges[id]
	if not offer then return false, "Такого предложения нет." end
	if profile.Progression.Crystals < offer.Cost then return false, "Недостаточно кристаллов." end
	if offer.XP and profile.Progression.SpeedLevel >= Config.Training.MaxLevel then return false, "Скорость уже максимальная." end
	if offer.Currency and profile.Currency > Config.MaxCurrency - offer.Currency then return false, "Сначала потратьте Терпение: достигнут лимит." end
	profile.Progression.Crystals -= offer.Cost
	if offer.Currency then Economy.Add(profile, offer.Currency) end
	if offer.XP then Economy.AddTraining(profile, offer.XP) end
	return true, "Обмен выполнен: " .. offer.Name
end

function Rules.InBelt(x, y, z, width, length)
	return Economy.IsFinite(x) and Economy.IsFinite(y) and Economy.IsFinite(z)
		and math.abs(x) <= width / 2 and math.abs(z) <= length / 2 and y >= 0.5 and y <= 6
end

return Rules
