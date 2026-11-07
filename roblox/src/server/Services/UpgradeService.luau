local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local UpgradeService = {}
UpgradeService.__index = UpgradeService

function UpgradeService.new(context)
	return setmetatable({ Context = context }, UpgradeService)
end

function UpgradeService:Buy(player, id)
	local definition = Config.Upgrades[id]
	if not definition then return false, "Такого улучшения нет." end
	return self.Context.Data:Mutate(player, function(profile)
		local level = profile.Upgrades[id]
		if level >= definition.Max then return false, "Достигнут максимальный уровень." end
		local price = Economy.UpgradePrice(id, level)
		if not self.Context.Currency:Debit(profile, price) then return false, "Недостаточно Терпения." end
		profile.Upgrades[id] = level + 1
		return true, definition.Name .. ": " .. Economy.UpgradeEffect(id, level + 1)
	end, true)
end

return UpgradeService
