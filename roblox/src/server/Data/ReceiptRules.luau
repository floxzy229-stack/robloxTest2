local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Receipts = {}

function Receipts.Count(profile)
	local count = 0
	for _ in pairs(profile.Receipts) do count += 1 end
	return count
end

function Receipts.Apply(profile, purchaseId, productId, product, now, maximum)
	local prior = profile.Receipts[purchaseId]
	if prior then
		if prior.ProductId ~= productId and prior.ProductId ~= 0 then return false, "receipt_product_conflict" end
		return true, "already_granted"
	end
	if Receipts.Count(profile) >= maximum then return false, "receipt_ledger_full" end
	if product.Grant == "currency" then
		if profile.Currency > Config.MaxCurrency - product.Amount then return false, "currency_cap" end
		Economy.Add(profile, product.Amount)
	elseif product.Grant == "boost" then
		local untilTime = math.max(profile.BoostUntil, now) + product.Seconds
		if untilTime > 20_000_000_000 then return false, "boost_cap" end
		profile.BoostUntil = untilTime
	else return false, "unknown_grant" end
	profile.Receipts[purchaseId] = { ProductId = productId, GrantedAt = now }
	return true, "granted"
end

return Receipts
