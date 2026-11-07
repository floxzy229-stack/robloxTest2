local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage:WaitForChild("BonkShared").ProgressionRules)
local ProgressionService = {}
ProgressionService.__index = ProgressionService

function ProgressionService.new(context)
	return setmetatable({ Context = context }, ProgressionService)
end

function ProgressionService:Act(player, action, payload)
	return self.Context.Data:Mutate(player, function(profile)
		if action == "ClaimDaily" then return Rules.Daily(profile, os.time()) end
		if action == "ClaimReward" then return Rules.Reward(profile, payload.id) end
		if action == "Rebirth" then return Rules.Rebirth(profile, payload.expected) end
		if action == "Ascend" then return Rules.Ascend(profile, payload.expected) end
		if action == "Exchange" then return Rules.Exchange(profile, payload.id) end
		return false, "Неизвестное действие прогрессии."
	end, true)
end

return ProgressionService
