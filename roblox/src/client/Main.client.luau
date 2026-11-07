local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BonkUI") then warn("[Bonk] Existing BonkUI found; duplicate client ignored") return end

local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Protocol = require(Shared.Protocol)
local UIController = require(script.Parent.UIController)
local EffectsController = require(script.Parent.EffectsController)
local ClientNetwork = require(script.Parent.ClientNetwork)
local InputController = require(script.Parent.InputController)
local PetRenderer = require(script.Parent.PetRenderer)
local PurchaseController = require(script.Parent.PurchaseController)

local ui = UIController.new()
local remoteFolder = ReplicatedStorage:WaitForChild(Protocol.Folder, 20)
if not remoteFolder then ui:Notify("Серверные модули не запущены. Проверьте Output и установку BonkServer.") return end
local remotes = {}
for key, name in pairs(Protocol.Remotes) do
	local remote = remoteFolder:WaitForChild(name, 10)
	if not remote or not remote:IsA("RemoteEvent") then ui:Notify("Не найден RemoteEvent: " .. name) return end
	remotes[key] = remote
end

local effects = EffectsController.new(ui)
local network = ClientNetwork.new(remotes, ui, effects)
local input = InputController.new(ui, remotes)
local pets = PetRenderer.new()
local purchases = PurchaseController.new(network, ui)
ui.Send = function(action, payload) network:Request(action, payload) end
ui.LoadCatalog = function() purchases:Load() end
ui.RefreshPurchases = function() purchases:Refresh() end
local connections = {}

table.insert(connections, remotes.State.OnClientEvent:Connect(function(packet)
	ui:Update(packet)
	if ui.Profile then
		effects:SetState(ui.Profile.Settings, ui.Hud.WeaponId)
		pets:SetSettings(ui.Profile.Settings)
	end
	if ui.Catalog and packet.Hud then
		for _, item in ipairs(ui.Catalog.Items) do
			if item.Kind == "pass" then
				item.Owned = (packet.Hud.Entitlements or {})[item.Key] == true
				item.OwnershipKnown = (packet.Hud.PassesKnown or {})[item.Key] == true
			end
		end
		ui:RefreshButtons()
	end
end))
table.insert(connections, remotes.HitResult.OnClientEvent:Connect(function(result) effects:Hit(result) end))
table.insert(connections, remotes.BossState.OnClientEvent:Connect(function(packet) ui:UpdateBoss(packet) end))
table.insert(connections, remotes.Notice.OnClientEvent:Connect(function(packet)
	ui:Notify(packet.Message)
	if type(packet.OpenWindow) == "string" and ui.Window ~= packet.OpenWindow then ui:Open(packet.OpenWindow) end
end))
network:Request("Sync", {})

script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	input:Destroy()
	network:Destroy()
	purchases:Destroy()
	pets:Destroy()
	effects:Destroy()
	ui:Destroy()
end)
