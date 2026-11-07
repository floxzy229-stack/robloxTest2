local ClientNetwork = {}
ClientNetwork.__index = ClientNetwork

function ClientNetwork.new(remotes, ui, effects)
	local self = setmetatable({ Remotes = remotes, UI = ui, Effects = effects, NextId = 0, Pending = {}, Active = false }, ClientNetwork)
	self.Connection = remotes.ActionResult.OnClientEvent:Connect(function(result)
		local pending = self.Pending[result.Id]
		if not pending then return end
		self.Pending[result.Id] = nil
		self.Active = false
		ui:SetBusy(false)
		ui:Notify(result.Message)
		if result.Ok and result.Data and result.Data.Hatched then effects:Hatch(result.Data.Hatched) end
		if pending.Callback then pending.Callback(result) end
	end)
	return self
end

function ClientNetwork:Request(action, payload, callback)
	if self.Active then return false end
	self.NextId += 1
	local id = self.NextId
	self.Pending[id] = { Callback = callback }
	self.Active = true
	self.UI:SetBusy(true)
	self.Remotes.Action:FireServer(id, action, payload or {})
	task.delay(15, function()
		if not self.Pending[id] then return end
		self.Pending[id] = nil
		self.Active = false
		self.UI:SetBusy(false)
		self.UI:Notify("Сервер не ответил вовремя. Состояние обновится после подтверждения; не повторяйте платёж.")
		if callback then callback({ Ok = false, Message = "Тайм-аут запроса" }) end
	end)
	return true
end

function ClientNetwork:Destroy()
	self.Connection:Disconnect()
	table.clear(self.Pending)
end

return ClientNetwork
