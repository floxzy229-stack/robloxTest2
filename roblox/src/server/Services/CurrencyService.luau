local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Economy = require(ReplicatedStorage:WaitForChild("BonkShared").Economy)
local CurrencyService = {}
CurrencyService.__index = CurrencyService

function CurrencyService.new(data)
	return setmetatable({ Data = data }, CurrencyService)
end

function CurrencyService:Credit(profile, amount)
	return Economy.Add(profile, amount)
end

function CurrencyService:Accrue(profile, entitlements, source, critical, now, ticks)
	return Economy.Accrue(profile, entitlements, source, critical, now, ticks)
end

function CurrencyService:Debit(profile, amount)
	return Economy.Spend(profile, amount)
end

return CurrencyService
