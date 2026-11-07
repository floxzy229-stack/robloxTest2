local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local HitService = {}
HitService.__index = HitService

function HitService.new(context)
	return setmetatable({ Context = context, Runtime = {}, Random = Random.new(), Sequence = 0 }, HitService)
end

function HitService:_perform(player, source)
	local profile = self.Context.Data:Get(player)
	if not profile then return false, "Загрузка данных. Бонк пока недоступен.", 0.5 end
	if not self.Context.Zones:CanHit(player) then return false, "Подождите появления персонажа в доступной зоне.", 0.5 end
	local runtime = self.Runtime[player] or { NextManual = 0 }
	self.Runtime[player] = runtime
	local now = os.clock()
	if source == "manual" and now < runtime.NextManual then return false, nil, runtime.NextManual - now end
	local critical = self.Random:NextNumber() < Economy.CritChance(profile)
	local practice = source == "manual" and self.Context.Zones:PracticeFor(player) or nil
	local reward, damage = 0, 0
	local accepted, message = self.Context.Data:Mutate(player, function(candidate)
		reward = self.Context.Currency:Accrue(candidate, self.Context.Monetization:Get(player), source, critical, os.time(), 1)
		local stat = source == "manual" and "ManualHits" or "AutoHits"
		candidate.Statistics[stat] += 1
		if critical then candidate.Statistics.CriticalHits += 1 end
		if practice then candidate.Statistics.PracticeHits[practice] = math.min(Config.MaxCurrency, candidate.Statistics.PracticeHits[practice] + 1) end
		damage = Economy.BossDamage(candidate, critical)
		return true
	end, false)
	if not accepted then return false, message, 0.25 end
	if source == "manual" then runtime.NextManual = now + Economy.Cooldown(profile) end
	self.Context.Remotes.HitResult:FireClient(player, { Ok = true, Source = source, Reward = reward, Critical = critical })
	if source == "manual" then
		self.Sequence += 1
		self.Context.Boss:Hit(player, self.Sequence, damage)
	end
	return true
end

function HitService:Manual(player)
	local ok, message, wait = self:_perform(player, "manual")
	if not ok then self.Context.Remotes.HitResult:FireClient(player, { Ok = false, Source = "manual", Message = message, Wait = wait }) end
end

function HitService:Step()
	local now = os.clock()
	for player in pairs(self.Context.Data.Entries) do
		local profile = self.Context.Data:Get(player)
		if not profile then continue end
		local runtime = self.Runtime[player] or { NextManual = 0 }
		self.Runtime[player] = runtime
		local interval = Economy.AutoInterval(profile)
		if not interval then runtime.NextAuto = nil continue end
		if not runtime.NextAuto then runtime.NextAuto = now + interval end
		if now >= runtime.NextAuto then
			local accepted = self:_perform(player, "auto")
			runtime.NextAuto = now + (accepted and interval or 0.25)
		end
	end
end

function HitService:Remove(player)
	self.Runtime[player] = nil
end

return HitService
