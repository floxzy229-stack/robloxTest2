local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PurchaseController = {}
PurchaseController.__index = PurchaseController

function PurchaseController.new(network, ui)
	local self = setmetatable({ Network = network, UI = ui, Generation = 0, Connections = {} }, PurchaseController)
	table.insert(self.Connections, MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _, purchased)
		if userId ~= Players.LocalPlayer.UserId then return end
		ui:Notify(purchased and "Ожидаем серверное подтверждение покупки и сохранение награды." or "Покупка отменена. Награда не выдана.")
	end))
	table.insert(self.Connections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _, purchased)
		if player ~= Players.LocalPlayer then return end
		ui:Notify(purchased and "Roblox проверяет владение привилегией." or "Покупка привилегии отменена.")
	end))
	return self
end

function PurchaseController:Load()
	self.Network:Request("Catalog", {}, function(result)
		if not result.Ok or not result.Data then return end
		self.Generation += 1
		local generation = self.Generation
		local catalog = result.Data
		self.UI.Catalog = catalog
		if self.UI.Window == "donate" then self.UI:Render(true) end
		for _, item in ipairs(catalog.Items) do
			if item.Enabled and item.Id > 0 then
				task.spawn(function()
					local ok, information = pcall(function()
						return MarketplaceService:GetProductInfoAsync(item.Id, item.Kind == "pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
					end)
					if generation ~= self.Generation then return end
					if ok and type(information.PriceInRobux) == "number" and information.IsForSale ~= false then
						item.Price = information.PriceInRobux
					else item.PriceError = true end
					self.UI:RefreshButtons()
				end)
			end
		end
	end)
end

function PurchaseController:Refresh()
	self.Network:Request("RefreshPasses", {}, function() self:Load() end)
end

function PurchaseController:Destroy()
	self.Generation += 1
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return PurchaseController
