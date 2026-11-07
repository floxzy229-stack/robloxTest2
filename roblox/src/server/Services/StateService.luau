local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Rules = require(Shared.ProgressionRules)
local Schema = require(script.Parent.Parent.Data.DataSchema)
local StateService = {}
StateService.__index = StateService

function StateService.new(context)
	return setmetatable({ Context = context }, StateService)
end

function StateService:Hud(player, profile)
	local entitlements = self.Context.Monetization:Get(player)
	local progress = profile.Progression
	local training = self.Context.Training.Runtime[player]
	local rewardProgress = {}
	for id, definition in pairs(Config.Rewards) do rewardProgress[id] = profile.Statistics[definition.Stat] end
	return {
		Currency = profile.Currency, WeaponId = profile.EquippedWeapon,
		Rebirths = progress.Rebirths, Ascensions = progress.Ascensions, Crystals = progress.Crystals,
		SpeedLevel = progress.SpeedLevel, SpeedXP = progress.SpeedXP,
		SpeedRequired = Economy.SpeedRequired(progress.SpeedLevel), SpeedMultiplier = Economy.SpeedMultiplier(profile),
		TrainingId = training and training.Id or nil, ProgressionMultiplier = Economy.ProgressionMultiplier(profile),
		DailyAvailable = progress.LastDailyDay < math.floor(os.time() / 86400),
		ReadyRewards = Rules.RewardCount(profile, os.time()), RewardProgress = rewardProgress,
		Cooldown = Economy.Cooldown(profile), CritChance = Economy.CritChance(profile),
		PassiveRate = Economy.RawIncome(profile, entitlements, "pets", false, os.time()),
		AutoInterval = Economy.AutoInterval(profile), PetSlots = Economy.Slots(entitlements),
		VIP = entitlements.vip == true, Entitlements = table.clone(entitlements),
		PassesKnown = table.clone(self.Context.Monetization:GetKnown(player)),
		Zone = self.Context.Zones.Current[player] or "playroom",
		BoostSeconds = math.max(0, profile.BoostUntil - os.time()),
		PracticeHits = table.clone(profile.Statistics.PracticeHits),
		Mock = self.Context.Data.Mock, PurchasesSafe = self.Context.Data:IsPurchaseSafe(player),
	}
end

function StateService:Send(player, full)
	local profile = self.Context.Data:Get(player)
	local entry = self.Context.Data.Entries[player]
	if not profile or not entry then
		self.Context.Remotes.State:FireClient(player, { Kind = "Loading", Message = "Ожидание безопасной загрузки профиля…" })
		return
	end
	self.Context.Remotes.State:FireClient(player, {
		Kind = full and "Full" or "Hud", Version = entry.Version,
		Profile = full and Schema.Public(profile) or nil, Hud = self:Hud(player, profile),
	})
	entry.FullDirty = false
	entry.HudDirty = false
end

function StateService:Step()
	for player, entry in pairs(self.Context.Data.Entries) do
		if self.Context.Data:IsReady(player) and (entry.FullDirty or entry.HudDirty) then self:Send(player, entry.FullDirty) end
	end
end

return StateService
