local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local root = script.Parent
if ServerScriptService:GetAttribute("BonkRuntimeStarted") == true then
	warn("[Bonk] Duplicate server entry point ignored")
	return
end
ServerScriptService:SetAttribute("BonkRuntimeStarted", true)

local ServerConfig = require(root.Config.ServerConfig)
local MonetizationConfig = require(root.Config.MonetizationConfig)
local Remotes = require(root.RemoteBootstrap).Create()
local World = require(root.WorldBuilder).Build()
local wantsMock = root:GetAttribute("StudioMock") == true
if wantsMock and not RunService:IsStudio() then
	local function refuse(player) player:Kick("StudioMock запрещён на опубликованном сервере. Владелец должен выключить атрибут StudioMock у BonkServer.") end
	Players.PlayerAdded:Connect(refuse)
	for _, player in ipairs(Players:GetPlayers()) do refuse(player) end
	warn("[Bonk] Refused to run a StudioMock place in production")
	return
end

local Services = root.Services
local context = { ServerConfig = ServerConfig, Remotes = Remotes, World = World }
context.Data = require(Services.PlayerDataService).new(ServerConfig, wantsMock, Remotes)
context.Currency = require(Services.CurrencyService).new(context.Data)
context.Zones = require(Services.ZoneService).new(context, World)
context.Pets = require(Services.PetService).new(context)
context.Weapons = require(Services.WeaponService).new(context)
context.Upgrades = require(Services.UpgradeService).new(context)
context.Monetization = require(Services.MonetizationService).new(context, MonetizationConfig)
context.Boss = require(Services.BossService).new(context, World)
context.Hits = require(Services.HitService).new(context)
context.Training = require(Services.TrainingService).new(context)
context.Progression = require(Services.ProgressionService).new(context)
context.State = require(Services.StateService).new(context)
context.Network = require(root.NetworkService).new(context)
context.Monetization:Start()
context.Network:Start()
context.Zones:Start()

local characterConnections = {}
local connected = {}
local function playerAdded(player)
	if connected[player] then return end
	connected[player] = true
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.spawn(function() context.Zones:PlaceCharacter(player, character) end)
	end)
	task.spawn(function()
		local ok, loaded = xpcall(function() return context.Data:Load(player) end, debug.traceback)
		if not ok then
			warn("[Bonk] Player startup failed:", loaded)
			if player.Parent == Players then player:Kick("Не удалось безопасно запустить профиль. Войдите позже.") end
			return
		end
		if not loaded then return end
		context.Zones.Current[player] = "playroom"
			context.Pets:Publish(player)
			local profile = context.Data:Get(player)
			local equipped = profile and profile.EquippedWeapon or "rubber_hammer"
			context.Weapons:ApplyTool(player, equipped)
			context.State:Send(player, true)
		context.Boss:Send(player)
		if player.Character then task.spawn(function() context.Zones:PlaceCharacter(player, player.Character) end) end
		task.spawn(function() context.Monetization:Refresh(player) end)
	end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
	if characterConnections[player] then characterConnections[player]:Disconnect() characterConnections[player] = nil end
	connected[player] = nil
	context.Network:Remove(player)
	context.Hits:Remove(player)
	context.Training:Remove(player)
	context.Pets:Remove(player)
	context.Boss:Remove(player)
	context.Zones:Remove(player)
	context.Monetization:Remove(player)
	context.Data:Close(player)
end)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end

local accumulator, stateAccumulator = 0, 0
local heartbeat = RunService.Heartbeat:Connect(function(dt)
	if context.Data.ShuttingDown then return end
	accumulator += dt
	stateAccumulator += dt
	if accumulator >= ServerConfig.SchedulerInterval then
		local elapsed = math.min(accumulator, 5)
		accumulator = 0
		context.Hits:Step()
		context.Training:Step(elapsed)
		context.Pets:Step(elapsed)
		context.Boss:Step()
	end
	if stateAccumulator >= ServerConfig.StateInterval then
		stateAccumulator = 0
		context.Data:Step()
		context.Zones:Step()
		context.State:Step()
	end
end)

game:BindToClose(function()
	heartbeat:Disconnect()
	context.Network:Destroy()
	context.Zones:Destroy()
	context.Monetization:Destroy()
	context.Data:Shutdown()
end)

print("[Bonk] Server started. Storage mode:", wantsMock and "EXPLICIT STUDIO MOCK" or "SESSION-LOCKED DATASTORE")
