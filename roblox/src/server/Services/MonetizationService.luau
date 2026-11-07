local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Factory = require(Shared.ModelFactory)
local Receipts = require(script.Parent.Parent.Data.ReceiptRules)
local MonetizationService = {}
MonetizationService.__index = MonetizationService

local function validId(id)
	return type(id) == "number" and id >= 0 and id % 1 == 0 and id <= Config.MaxCurrency
end

function MonetizationService.new(context, config)
	local self = setmetatable({ Context = context, Config = config, Entitlements = {}, Known = {}, Refreshing = {}, Prompting = {}, PromptUntil = {}, ProductsById = {}, Connections = {}, Started = false }, MonetizationService)
	local passesSeen = {}
	for key, pass in pairs(config.Passes) do
		if not validId(pass.Id) or (pass.Id > 0 and passesSeen[pass.Id]) then self.ConfigError = "Проверьте ID Game Pass: " .. key end
		if validId(pass.Id) and pass.Id > 0 then passesSeen[pass.Id] = key end
	end
	for key, product in pairs(config.Products) do
		if not validId(product.Id) or (product.Id > 0 and self.ProductsById[product.Id]) then self.ConfigError = "Проверьте ID Developer Product: " .. key end
		if validId(product.Id) and product.Id > 0 then self.ProductsById[product.Id] = product end
		local amount = product.Grant == "currency" and product.Amount or product.Seconds
		if (product.Grant ~= "currency" and product.Grant ~= "boost") or not validId(amount) or amount <= 0 then self.ConfigError = "Некорректная выдача продукта: " .. key end
	end
	if self.ConfigError then warn("[Bonk] Monetization disabled:", self.ConfigError) end
	return self
end

function MonetizationService:Get(player)
	return self.Entitlements[player] or {}
end

function MonetizationService:GetKnown(player)
	return self.Known[player] or {}
end

function MonetizationService:ApplyCosmetics(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("BonkVIPBadge")
	if old and old:GetAttribute("BonkOwned") ~= true then return end
	if not self:Get(player).vip then if old then old:Destroy() end return end
	if old then return end
	local badge = Instance.new("BillboardGui")
	badge.Name = "BonkVIPBadge"
	badge:SetAttribute("BonkOwned", true)
	badge.Size = UDim2.fromOffset(72, 28)
	badge.StudsOffset = Vector3.new(0, 2.4, 0)
	badge.MaxDistance = 60
	badge.Adornee = head
	badge.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Factory.Color("Accent")
	label.TextColor3 = Factory.Color("Ink")
	label.Text = "VIP"
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.Parent = badge
end

function MonetizationService:Refresh(player, afterPurchaseId)
	if self.Refreshing[player] or not self.Context.Data:IsReady(player) then return false, "Проверка привилегий уже выполняется или профиль недоступен." end
	self.Refreshing[player] = true
	local entitlements = table.clone(self:Get(player))
	local known = table.clone(self:GetKnown(player))
	local errors = false
	for _, key in ipairs(self.Config.PassOrder) do
		local pass = self.Config.Passes[key]
		if pass.Id == 0 or self.Context.Data.Mock or self.ConfigError then
			entitlements[key] = false
			known[key] = true
		else
			local success, owned = false, false
			for attempt = 1, 3 do
				success, owned = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id) end)
				if success and (owned or pass.Id ~= afterPurchaseId) then break end
				if attempt < 3 then task.wait(attempt) end
			end
			if success then entitlements[key] = owned == true known[key] = true
			else errors = true known[key] = known[key] == true end
		end
	end
	self.Refreshing[player] = nil
	if player.Parent ~= Players or not self.Context.Data:IsReady(player) then return false, "Профиль закрыт." end
	self.Entitlements[player] = entitlements
	self.Known[player] = known
	self.Context.Data:MarkFull(player)
	self.Context.Pets:Publish(player)
	self:ApplyCosmetics(player)
	return not errors, errors and "Roblox не подтвердил часть привилегий. Уже проверенные права сохранены; повторите проверку позже." or "Привилегии проверены на сервере."
end

function MonetizationService:Catalog(player)
	local safe = self.Context.Data:IsPurchaseSafe(player)
	local result = { Available = safe and not self.ConfigError, Reason = "", Items = {} }
	if self.ConfigError then result.Reason = "ошибка конфигурации товаров"
	elseif self.Context.Data.Mock then result.Reason = "в StudioMock реальные покупки отключены"
	elseif not safe then result.Reason = "профиль загружается или сохраняется" end
	local anyEnabled = false
	for _, group in ipairs({ { Kind = "pass", Order = self.Config.PassOrder, Items = self.Config.Passes }, { Kind = "product", Order = self.Config.ProductOrder, Items = self.Config.Products } }) do
		for _, key in ipairs(group.Order) do
			local item = group.Items[key]
			local enabled = not self.ConfigError and item.Enabled == true and item.Id > 0
			anyEnabled = anyEnabled or enabled
			table.insert(result.Items, {
				Key = key, Kind = group.Kind, Id = item.Id, Enabled = enabled,
				Name = item.Name, Description = item.Description,
				Owned = group.Kind == "pass" and self:Get(player)[key] == true,
				OwnershipKnown = group.Kind ~= "pass" or self:GetKnown(player)[key] == true,
			})
		end
	end
	if not anyEnabled then
		result.Available = false
		if result.Reason == "" then result.Reason = "создатель ещё не настроил ID товаров" end
	end
	return true, "", result
end

function MonetizationService:Prompt(player, kind, key)
	if self.ConfigError or not self.Started or not self.Context.Data:IsPurchaseSafe(player) then return false, "Покупки недоступны: профиль должен быть безопасно загружен без mock-режима." end
	local group = kind == "pass" and self.Config.Passes or (kind == "product" and self.Config.Products or nil)
	local item = group and group[key]
	if not item or not item.Enabled or item.Id <= 0 then return false, "Покупки недоступны: товар отключён." end
	local pending = self.Prompting[player]
	if os.clock() < (self.PromptUntil[player] or 0) or (pending and os.clock() < pending.Expires) then return false, "Завершите текущее окно покупки." end
	if kind == "pass" then
		if not self:GetKnown(player)[key] then return false, "Roblox ещё не подтвердил владение. Обновите привилегии." end
		if self:Get(player)[key] then return false, "Эта привилегия уже куплена." end
	else
		local profile = self.Context.Data:Get(player)
		if Receipts.Count(profile) >= self.Context.ServerConfig.MaxReceiptHistory then return false, "Лимит истории покупок достигнут. Обратитесь к создателю игры; не покупайте повторно." end
		if item.Grant == "currency" and profile.Currency > Config.MaxCurrency - item.Amount then return false, "Достигнут лимит валюты. Сначала потратьте Терпение." end
	end
	self.PromptUntil[player] = os.clock() + self.Context.ServerConfig.PromptCooldown
	if not self.Context.Data:Save(player, false) or not self.Context.Data:IsPurchaseSafe(player) or player.Parent ~= Players then return false, "Покупка не открыта: сохранение профиля не подтверждено." end
	self.Prompting[player] = { Kind = kind, Id = item.Id, Expires = os.clock() + 90 }
	local ok, err = pcall(function()
		if kind == "pass" then MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else MarketplaceService:PromptProductPurchase(player, item.Id) end
	end)
	if not ok then
		self.Prompting[player] = nil
		warn("[Bonk] Purchase prompt failed:", tostring(err))
		return false, "Roblox не смог открыть покупку. Попробуйте позже."
	end
	return true, "Проверьте окончательную цену в окне Roblox."
end

function MonetizationService:HandleReceipt(info)
	local deferred = Enum.ProductPurchaseDecision.NotProcessedYet
	if self.ConfigError or self.Context.Data.Mock or type(info) ~= "table" then return deferred end
	if not validId(info.ProductId) or not validId(info.PlayerId) or type(info.PurchaseId) ~= "string" or #info.PurchaseId == 0 or #info.PurchaseId > 200 then return deferred end
	local product = self.ProductsById[info.ProductId]
	if not product then
		warn("[Bonk] Unknown ProductId left unacknowledged:", info.ProductId)
		return deferred
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then return deferred end
	local ok, granted = pcall(function() return self.Context.Data:ProcessReceipt(player, info.PurchaseId, info.ProductId, product) end)
	if not ok then warn("[Bonk] Receipt processing error:", tostring(granted)) return deferred end
	return granted and Enum.ProductPurchaseDecision.PurchaseGranted or deferred
end

function MonetizationService:Start()
	if self.Started then return end
	assert(MarketplaceService:GetAttribute("BonkReceiptBound") ~= true, "Bonk ProcessReceipt is already registered")
	local readable, existing = pcall(function() return MarketplaceService.ProcessReceipt end)
	if readable and type(existing) == "function" then
		self.ConfigError = "В игре уже есть другой ProcessReceipt. Объедините обработчики перед включением товаров."
		warn("[Bonk]", self.ConfigError)
		return
	end
	MarketplaceService.ProcessReceipt = function(info) return self:HandleReceipt(info) end
	MarketplaceService:SetAttribute("BonkReceiptBound", true)
	self.Started = true
	table.insert(self.Connections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pending = self.Prompting[player]
		if pending and pending.Kind == "pass" and pending.Id == passId then self.Prompting[player] = nil end
		if purchased then task.spawn(function() self:Refresh(player, passId) end) end
	end))
	table.insert(self.Connections, MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId)
		local player = Players:GetPlayerByUserId(userId)
		local pending = player and self.Prompting[player]
		if pending and pending.Kind == "product" and pending.Id == productId then self.Prompting[player] = nil end
	end))
end

function MonetizationService:Remove(player)
	self.Entitlements[player] = nil
	self.Known[player] = nil
	self.Refreshing[player] = nil
	self.Prompting[player] = nil
	self.PromptUntil[player] = nil
end

function MonetizationService:Destroy()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return MonetizationService
