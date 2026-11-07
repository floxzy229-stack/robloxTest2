local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Schema = require(script.Parent.Parent.Data.DataSchema)
local Session = require(script.Parent.Parent.Data.SessionRules)
local Receipts = require(script.Parent.Parent.Data.ReceiptRules)
local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

function PlayerDataService.new(config, mock, remotes)
	assert(not mock or RunService:IsStudio(), "Studio mock must never run in a published server")
	local self = setmetatable({ Config = config, Mock = mock, Remotes = remotes, Entries = {}, Loading = {}, ShuttingDown = false }, PlayerDataService)
	if mock then
		local memory = {}
		self.Store = {
			UpdateAsync = function(_, key, transform)
				local result = transform(Schema.Clone(memory[key]))
				if result == nil then return nil end
				memory[key] = Schema.Clone(result)
				return Schema.Clone(result)
			end,
		}
	else
		local ok, store = pcall(function()
			return DataStoreService:GetDataStore(RunService:IsStudio() and config.StudioStore or config.ProductionStore)
		end)
		if ok then self.Store = store else self.StoreError = tostring(store) end
	end
	return self
end

function PlayerDataService:_update(key, transform)
	if not self.Store then return false, nil, "store_unavailable" end
	for attempt = 1, self.Config.SaveAttempts do
		local ok, result = pcall(function() return self.Store:UpdateAsync(key, transform) end)
		if ok then
			if result == nil then return false, nil, "transaction_cancelled" end
			return true, result
		end
		warn("[Bonk] DataStore attempt", attempt, key, tostring(result))
		if attempt < self.Config.SaveAttempts then task.wait(self.Config.RetryDelays[attempt] or 2) end
	end
	return false, nil, "storage_error_or_unknown_commit"
end

function PlayerDataService:_block(entry, reason)
	if entry.Blocked then return end
	entry.Blocked = true
	entry.Player:SetAttribute("BonkProfileReady", false)
	warn("[Bonk] Profile frozen to prevent overwrite:", entry.Player.UserId, reason)
	if entry.Player.Parent == Players then
		self.Remotes.State:FireClient(entry.Player, { Kind = "Loading", Message = "Сохранение не подтверждено. Профиль закрыт для защиты данных." })
		entry.Player:Kick("Не удалось безопасно подтвердить сохранение. Перезайдите через 3 минуты. Пустой профиль не записывался.")
	end
end

function PlayerDataService:Load(player)
	if self.ShuttingDown or self.Loading[player] or self.Entries[player] then return false end
	self.Loading[player] = true
	self.Remotes.State:FireClient(player, { Kind = "Loading", Message = "Проверяем сохранение и блокировку сессии…" })
	if RunService:IsStudio() and self.Config.DebugFailureUserId ~= 0 and self.Config.DebugFailureUserId == player.UserId then
		self.Loading[player] = nil
		player:Kick("Тестовый отказ загрузки. Ничего не сохранено.")
		return false
	end
	local key = "Player_" .. player.UserId
	local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
	local claimId = HttpService:GenerateGUID(false)
	local reason
	local ok, saved, errorCode = self:_update(key, function(old)
		local candidate, status = Session.Claim(old, token, claimId, os.time(), self.Config.SessionLeaseSeconds, function(raw)
			return raw == nil and Schema.Default() or Schema.Normalize(raw)
		end)
		reason = status
		return candidate
	end)
	self.Loading[player] = nil
	if not ok or not saved.Session or saved.Session.Token ~= token then
		warn("[Bonk] Load refused:", player.UserId, reason or errorCode)
		if player.Parent == Players then
			player:Kick(reason == "locked" and "Этот профиль ещё занят другой сессией. Подождите до 3 минут и войдите снова." or "Не удалось загрузить сохранение. Игровые действия и покупки отключены; стартовый профиль не записан поверх старого.")
		end
		return false
	end
	local entry = {
		Player = player, Key = key, Token = token, Profile = Schema.Clone(saved.Data),
		SavedRevision = saved.Revision, LeaseUntil = saved.Session.ExpiresAt,
		LastSaved = os.time(), NextSave = os.clock() + self.Config.AutosaveSeconds + math.random(0, 5),
		Version = 1, FullDirty = true, HudDirty = true, Dirty = false,
		Busy = false, Closing = false, Blocked = false, Queued = {},
	}
	self.Entries[player] = entry
	if player.Parent ~= Players or self.ShuttingDown then self:Close(player) return false end
	player:SetAttribute("BonkProfileReady", true)
	return true
end

function PlayerDataService:IsReady(player)
	local entry = self.Entries[player]
	return not self.ShuttingDown and entry ~= nil and not entry.Closing and not entry.Blocked and (self.Mock or entry.LeaseUntil - os.time() > self.Config.LeaseSafetySeconds)
end

function PlayerDataService:Get(player)
	if not self:IsReady(player) then return nil end
	return self.Entries[player].Profile
end

function PlayerDataService:IsPurchaseSafe(player)
	local entry = self.Entries[player]
	return not self.Mock and self:IsReady(player) and not entry.Busy and not self.ShuttingDown and os.time() - entry.LastSaved <= self.Config.AutosaveSeconds + 20
end

function PlayerDataService:MarkFull(player)
	local entry = self.Entries[player]
	if not entry then return end
	entry.Version += 1
	entry.FullDirty = true
	entry.HudDirty = true
end

function PlayerDataService:Mutate(player, callback, full)
	local entry = self.Entries[player]
	if not self:IsReady(player) then return false, "Профиль ещё не загружен безопасно." end
	if entry.Busy then return false, "Профиль сохраняется. Повторите через секунду." end
	local candidate = Schema.Clone(entry.Profile)
	local callOk, accepted, message, result = pcall(callback, candidate)
	if not callOk then
		warn("[Bonk] Mutation rejected:", player.UserId, accepted)
		return false, "Не удалось выполнить действие. Ваши предметы не изменены."
	end
	if not accepted then return false, message or "Действие недоступно." end
	entry.Profile = candidate
	entry.Dirty = true
	entry.Version += 1
	entry.HudDirty = true
	if full then entry.FullDirty = true end
	return true, message or "", result
end

function PlayerDataService:_drain(entry)
	local queued = entry.Queued
	entry.Queued = {}
	for _, job in ipairs(queued) do
		local candidate = Schema.Clone(entry.Profile)
		local ok, accepted, message = pcall(job.Callback, candidate)
		if ok and accepted then
			entry.Profile = candidate
			entry.Version += 1
			entry.FullDirty = true
			entry.HudDirty = true
			entry.Dirty = true
		end
		if not ok then warn("[Bonk] Queued reward rejected:", accepted) end
		if job.OnApplied then job.OnApplied(ok and accepted == true, message) end
	end
end

function PlayerDataService:Enqueue(player, callback, onApplied)
	local entry = self.Entries[player]
	if not self:IsReady(player) or #entry.Queued >= 16 then return false end
	table.insert(entry.Queued, { Callback = callback, OnApplied = onApplied })
	if not entry.Busy then self:_drain(entry) end
	return true
end

function PlayerDataService:_acquire(entry, allowClosing)
	local deadline = os.clock() + self.Config.MutexTimeout
	while entry.Busy and os.clock() < deadline and not entry.Blocked do task.wait(0.05) end
	if entry.Busy or entry.Blocked or (entry.Closing and not allowClosing) then return false end
	entry.Busy = true
	return true
end

function PlayerDataService:_writeLocked(entry, candidate, release)
	local encoded, serialized = pcall(function() return HttpService:JSONEncode(candidate) end)
	if not encoded or #serialized > self.Config.MaxSerializedBytes then
		self:_block(entry, "serialization_or_size_limit")
		return false
	end
	local writeId = HttpService:GenerateGUID(false)
	local expectedRevision = entry.SavedRevision
	local reason
	local ok, saved, errorCode = self:_update(entry.Key, function(old)
		local result, status = Session.Write(old, entry.Token, expectedRevision, candidate, writeId, os.time(), self.Config.SessionLeaseSeconds, release)
		reason = status
		return result
	end)
	if not ok or saved.LastWriteId ~= writeId or saved.Revision ~= expectedRevision + 1 then
		-- A failed response may hide a committed write: never follow it with an older snapshot.
		self:_block(entry, reason or errorCode or "unconfirmed_write")
		return false
	end
	entry.Profile = Schema.Clone(saved.Data)
	entry.SavedRevision = saved.Revision
	entry.LeaseUntil = saved.Session and saved.Session.ExpiresAt or 0
	entry.LastSaved = os.time()
	entry.NextSave = os.clock() + self.Config.AutosaveSeconds + math.random(0, 5)
	entry.Dirty = false
	return true
end

function PlayerDataService:Save(player, release)
	local entry = self.Entries[player]
	if not entry or entry.Blocked or not self:_acquire(entry, release == true) then return false end
	self:_drain(entry)
	local ok = self:_writeLocked(entry, Schema.Clone(entry.Profile), release == true)
	entry.Busy = false
	return ok
end

function PlayerDataService:ProcessReceipt(player, purchaseId, productId, product)
	local entry = self.Entries[player]
	if self.Mock or not self:IsReady(player) or not self:_acquire(entry, false) then return false end
	local candidate = Schema.Clone(entry.Profile)
	local accepted, status = Receipts.Apply(candidate, purchaseId, productId, product, os.time(), self.Config.MaxReceiptHistory)
	if not accepted then
		entry.Busy = false
		warn("[Bonk] Receipt deferred:", player.UserId, status)
		return false
	end
	if status == "already_granted" then
		entry.Busy = false
		return true
	end
	local saved = self:_writeLocked(entry, candidate, false)
	entry.Busy = false
	if not saved then return false end
	self:MarkFull(player)
	if player.Parent == Players then self.Remotes.Notice:FireClient(player, { Message = "Покупка подтверждена. Награда сохранена: " .. product.Name }) end
	return true
end

function PlayerDataService:Step()
	for player, entry in pairs(self.Entries) do
		if entry.Blocked or entry.Closing or entry.Busy then continue end
		self:_drain(entry)
		if not self.Mock and entry.LeaseUntil - os.time() <= self.Config.LeaseSafetySeconds then
			self:_block(entry, "lease_safety_margin")
		elseif os.clock() >= entry.NextSave then
			entry.NextSave = os.clock() + self.Config.AutosaveSeconds
			task.spawn(function() self:Save(player, false) end)
		end
	end
end

function PlayerDataService:Close(player)
	local entry = self.Entries[player]
	if not entry or entry.CloseStarted then return end
	entry.CloseStarted = true
	entry.Closing = true
	player:SetAttribute("BonkProfileReady", false)
	if not entry.Blocked then self:Save(player, true) end
	self.Entries[player] = nil
end

function PlayerDataService:Shutdown()
	self.ShuttingDown = true
	for player in pairs(self.Entries) do task.spawn(function() self:Close(player) end) end
	local deadline = os.clock() + 25
	while (next(self.Entries) ~= nil or next(self.Loading) ~= nil) and os.clock() < deadline do task.wait(0.1) end
	if next(self.Entries) or next(self.Loading) then warn("[Bonk] Shutdown deadline reached; remaining session leases will expire naturally") end
end

return PlayerDataService
