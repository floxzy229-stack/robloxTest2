local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Protocol = require(ReplicatedStorage:WaitForChild("BonkShared").Protocol)
local Limiter = require(script.Parent.RateLimiter)
local NetworkService = {}
NetworkService.__index = NetworkService

function NetworkService.new(context)
	local config = context.ServerConfig
	return setmetatable({ Context = context, Actions = Limiter.new(config.ActionBucket.Capacity, config.ActionBucket.Refill), Hits = Limiter.new(config.HitBucket.Capacity, config.HitBucket.Refill), Records = {}, Connections = {} }, NetworkService)
end

function NetworkService:Dispatch(player, action, payload)
	local c = self.Context
	if action == "Sync" then c.State:Send(player, true) c.Boss:Send(player) return true, "" end
	if not c.Data:IsReady(player) then return false, "Загрузка данных. Действие пока недоступно." end
	if action == "BuyWeapon" then return c.Weapons:Buy(player, payload.id)
	elseif action == "EquipWeapon" then return c.Weapons:Equip(player, payload.id)
	elseif action == "BuyUpgrade" then return c.Upgrades:Buy(player, payload.id)
	elseif action == "HatchEgg" then return c.Pets:Hatch(player)
	elseif action == "EquipPet" then return c.Pets:Equip(player, payload.id, false)
	elseif action == "UnequipPet" then return c.Pets:Equip(player, payload.id, true)
	elseif action == "BestPets" then return c.Pets:Best(player)
	elseif action == "MergePets" then return c.Pets:Merge(player, payload.uids)
	elseif action == "BuyZone" then return c.Zones:Buy(player, payload.id)
	elseif action == "Teleport" then return c.Zones:Teleport(player, payload.id, false)
	elseif action == "ClaimPractice" then return c.Zones:ClaimPractice(player, payload.id)
	elseif action == "ClaimDaily" or action == "ClaimReward" or action == "Rebirth" or action == "Ascend" or action == "Exchange" then return c.Progression:Act(player, action, payload)
	elseif action == "SetSetting" then
		return c.Data:Mutate(player, function(profile)
			profile.Settings[payload.key] = payload.key == "Volume" and math.floor(payload.value * 100 + 0.5) / 100 or payload.value
			return true, "Настройка изменена."
		end, true)
	elseif action == "Catalog" then return c.Monetization:Catalog(player)
	elseif action == "PromptPurchase" then return c.Monetization:Prompt(player, payload.kind, payload.key)
	elseif action == "RefreshPasses" then
		local record = self.Records[player]
		if os.clock() < (record.NextRefresh or 0) then return false, "Повторить проверку можно через 15 секунд." end
		record.NextRefresh = os.clock() + 15
		return c.Monetization:Refresh(player)
	end
	return false, "Неизвестное действие."
end

function NetworkService:_reply(player, record, result)
	record.Cache[result.Id] = result
	table.insert(record.Order, result.Id)
	if #record.Order > self.Context.ServerConfig.MaxActionCache then record.Cache[table.remove(record.Order, 1)] = nil end
	if player.Parent == Players then self.Context.Remotes.ActionResult:FireClient(player, result) end
end

function NetworkService:Start()
	table.insert(self.Connections, self.Context.Remotes.Action.OnServerEvent:Connect(function(player, ...)
		if not self.Actions:Allow(player, os.clock()) or select("#", ...) ~= 3 then return end
		local id, action, payload = ...
		if not Protocol.Validate(id, action, payload) then return end
		local record = self.Records[player] or { LastId = 0, Busy = false, Cache = {}, Order = {} }
		self.Records[player] = record
		if record.Cache[id] then self.Context.Remotes.ActionResult:FireClient(player, record.Cache[id]) return end
		if id <= record.LastId then self.Context.Remotes.ActionResult:FireClient(player, { Id = id, Ok = false, Message = "Устаревший запрос не повторён." }) return end
		record.LastId = id
		if record.Busy then self:_reply(player, record, { Id = id, Ok = false, Message = "Предыдущее действие ещё выполняется." }) return end
		record.Busy = true
		local executed, accepted, message, data = xpcall(function() return self:Dispatch(player, action, payload) end, debug.traceback)
		record.Busy = false
		if not executed then
			warn("[Bonk] Action error:", action, accepted)
			self:_reply(player, record, { Id = id, Ok = false, Message = "Сервер не смог завершить действие. Повторите позже." })
		else self:_reply(player, record, { Id = id, Ok = accepted == true, Message = message or "", Data = data }) end
	end))
	table.insert(self.Connections, self.Context.Remotes.Hit.OnServerEvent:Connect(function(player, ...)
		if select("#", ...) ~= 0 or not self.Hits:Allow(player, os.clock()) then return end
		self.Context.Hits:Manual(player)
	end))
end

function NetworkService:Remove(player)
	self.Actions:Remove(player)
	self.Hits:Remove(player)
	self.Records[player] = nil
end

function NetworkService:Destroy()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return NetworkService
