local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local UI = require(script.Parent.UIComponents)
local Icons = require(script.Parent.MenuIcons)
local Panels = {}

local function hero(self, icon, title, body)
	local card = UI.Card(self.Content)
	local preview = UI.Create("Frame", { Size = UDim2.new(1, 0, 0, 130), BackgroundTransparency = 1 }, card)
	Icons.Add(preview, icon)
	UI.Label(card, title, 24, nil, true)
	UI.Label(card, body, 15)
	return card
end

function Panels.rewards(self)
	local intro = hero(self, "rewards", "Каждый бонк — шаг к награде", "Кристаллы выдаются за игру, задания и перерождения. Все награды проверяет сервер.")
	local daily = UI.Button(intro, "Забрать ежедневную награду", function() self:Act("ClaimDaily", {}) end, true)
	self:Track(daily, function() return self.Hud.DailyAvailable and "+250 Терпения · +10 кристаллов" or "Сегодня получено · обновление в 00:00 UTC", self.Hud.DailyAvailable == true end)
	for _, id in ipairs(Config.RewardOrder) do
		local definition = Config.Rewards[id]
		local card = UI.Card(self.Content)
		UI.Label(card, definition.Name, 21, nil, true)
		UI.Label(card, "+" .. UI.Format(definition.Currency) .. " Терпения и " .. definition.Crystals .. " кристаллов")
		local button = UI.Button(card, "Получить", function() self:Act("ClaimReward", { id = id }) end)
		self:Track(button, function()
			local progress = (self.Hud.RewardProgress or {})[id] or 0
			local claimed = self.Profile.Progression.RewardClaims[id]
			return claimed and "Награда получена" or (progress >= definition.Target and "Забрать награду" or (math.min(progress, definition.Target) .. " / " .. definition.Target)), not claimed and progress >= definition.Target
		end)
	end
end

function Panels.rebirth(self)
	local progress = self.Profile.Progression
	local card = hero(self, "rebirth", "Начни заново. Стань сильнее.", "Сбросятся ВСЁ текущее Терпение и купленные улучшения. Молотки, питомцы, открытые миры, кристаллы и натренированная скорость останутся. Награда: +25 кристаллов, постоянный бонус и доступ к новым дорожкам.")
	UI.Label(card, "Перерождений: " .. progress.Rebirths .. " / " .. Config.Progression.MaxRebirths, 20, nil, true)
	UI.Label(card, string.format("Бонус перерождений: ×%.2f → ×%.2f", 1 + progress.Rebirths * Config.Progression.IncomePerRebirth, 1 + (progress.Rebirths + 1) * Config.Progression.IncomePerRebirth))
	UI.Label(card, "Нужно накопить: " .. UI.Format(Economy.RebirthCost(self.Profile)) .. " Терпения", 18)
	local confirmed = false
	local checkbox = UI.Button(card, "Подтвердить сброс Терпения и улучшений", function()
		confirmed = not confirmed
		self:RefreshButtons()
	end)
	self:Track(checkbox, function() return confirmed and "Сброс подтверждён · отменить" or "Я понимаю: Терпение и улучшения обнулятся", true end)
	local button = UI.Button(card, "Переродиться", function() if confirmed then self:Act("Rebirth", { expected = progress.Rebirths }) end end, true)
	self:Track(button, function()
		if progress.Rebirths >= Config.Progression.MaxRebirths then return "Максимум перерождений", false end
		if (self.Hud.Currency or 0) < Economy.RebirthCost(self.Profile) then return "Нужно больше Терпения", false end
		return "Переродиться и обнулить Терпение", confirmed
	end)
end

function Panels.ascension(self)
	local progress = self.Profile.Progression
	local card = hero(self, "ascension", "Выше с каждым восхождением", "Восхождение усиливает доход от бонков и питомцев. Списываются только указанные кристаллы: молотки, перерождения, скорость и миры сохраняются.")
	local required = (progress.Ascensions + 1) * Config.Progression.RebirthsPerAscension
	UI.Label(card, "Ступень: " .. progress.Ascensions .. " / " .. Config.Progression.MaxAscensions, 22, nil, true)
	UI.Label(card, string.format("Бонус восхождений: ×%.2f → ×%.2f", 1 + progress.Ascensions * Config.Progression.IncomePerAscension, 1 + (progress.Ascensions + 1) * Config.Progression.IncomePerAscension))
	UI.Label(card, "Нужно перерождений: " .. required .. ". Цена: " .. Economy.AscensionCost(self.Profile) .. " кристаллов.")
	local button = UI.Button(card, "Восхождение", function() self:Act("Ascend", { expected = progress.Ascensions }) end, true)
	self:Track(button, function()
		if progress.Ascensions >= Config.Progression.MaxAscensions then return "Вершина достигнута", false end
		return "Подняться · " .. Economy.AscensionCost(self.Profile) .. " кристаллов", progress.Rebirths >= required and (self.Hud.Crystals or 0) >= Economy.AscensionCost(self.Profile)
	end)
end

function Panels.exchange(self)
	hero(self, "exchange", "Обменник кристаллов", "Обмен с игрой по фиксированному курсу — не торговля между игроками. Цена показана до подтверждения; предметы других игроков не затрагиваются.")
	for _, id in ipairs(Config.ExchangeOrder) do
		local offer = Config.Exchanges[id]
		local card = UI.Card(self.Content)
		UI.Label(card, offer.Name, 21, nil, true)
		UI.Label(card, offer.Currency and ("+" .. UI.Format(offer.Currency) .. " Терпения") or ("+" .. offer.XP .. " опыта скорости тапов"))
		local button = UI.Button(card, "Обменять", function() self:Act("Exchange", { id = id }) end, true)
		self:Track(button, function()
			local maxed = offer.XP and (self.Hud.SpeedLevel or 0) >= Config.Training.MaxLevel
			return maxed and "Скорость максимальная" or ("Обменять за " .. offer.Cost .. " кристаллов"), not maxed and (self.Hud.Crystals or 0) >= offer.Cost
		end)
	end
end

function Panels.training(self)
	local intro = UI.Card(self.Content)
	UI.Label(intro, "Беги, чтобы бонкать быстрее", 24, nil, true)
	UI.Label(intro, "Встаньте на полотно доступной дорожки. Сервер начисляет опыт раз в секунду, пока вы на ней. Каждый уровень даёт +3,5% скорости тапов. Уход, смерть и телепорт останавливают тренировку. Скорость сохраняется после выхода и перерождения.")
	UI.Label(intro, "Скорость: " .. string.format("×%.2f", self.Hud.SpeedMultiplier or 1) .. " · уровень " .. (self.Hud.SpeedLevel or 0) .. "/" .. Config.Training.MaxLevel, 19, nil, true)
	for _, id in ipairs(Config.TreadmillOrder) do
		local item = Config.Treadmills[id]
		local card = UI.Card(self.Content)
		UI.Label(card, item.Name .. " · " .. item.XP .. " опыта/сек.", 20, nil, true)
		UI.Label(card, item.Rebirths == 0 and "Доступна сразу. Бесплатно." or ("Нужно перерождений: " .. item.Rebirths))
	end
end

return Panels
