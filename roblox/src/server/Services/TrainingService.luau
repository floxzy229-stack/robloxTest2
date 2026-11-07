local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local Rules = require(Shared.ProgressionRules)
local TrainingService = {}
TrainingService.__index = TrainingService

function TrainingService.new(context)
	return setmetatable({ Context = context, Runtime = {}, Accumulator = 0 }, TrainingService)
end

function TrainingService:Locate(player, profile)
	local zones = self.Context.Zones
	local zoneId = zones.Current[player]
	if not zoneId or not zones:IsInZone(player, zoneId) then return nil end
	local root = zones:Root(player)
	if not root then return nil end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Sit or humanoid.PlatformStand then return nil end
	if profile.Progression.SpeedLevel >= Config.Training.MaxLevel then return nil end
	for _, belt in ipairs(self.Context.World.Treadmills[zoneId] or {}) do
		local id = belt:GetAttribute("TreadmillId")
		local definition = Config.Treadmills[id]
		if not definition or profile.Progression.Rebirths < definition.Rebirths then continue end
		local point = belt.CFrame:PointToObjectSpace(root.Position)
		if not Rules.InBelt(point.X, point.Y - belt.Size.Y / 2, point.Z, belt.Size.X, belt.Size.Z) then continue end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), params)
		if hit and hit.Instance == belt then return belt, id end
	end
	return nil
end

function TrainingService:Stop(player)
	local runtime = self.Runtime[player]
	if runtime then
		self.Runtime[player] = nil
		player:SetAttribute("BonkTrainingId", nil)
		self.Context.Data:MarkFull(player)
	end
end

function TrainingService:Step(dt)
	self.Accumulator += math.min(dt, 0.5)
	if self.Accumulator < 0.25 then return end
	local elapsed = math.min(self.Accumulator, 0.5)
	self.Accumulator = 0
	for player in pairs(self.Context.Data.Entries) do
		local profile = self.Context.Data:Get(player)
		local belt, id
		if profile then belt, id = self:Locate(player, profile) end
		if not belt then self:Stop(player) continue end
		local runtime = self.Runtime[player]
		if not runtime or runtime.Belt ~= belt then
			runtime = { Belt = belt, Id = id, Seconds = 0 }
			self.Runtime[player] = runtime
			player:SetAttribute("BonkTrainingId", id)
			self.Context.Data:MarkFull(player)
		else
			runtime.Seconds = math.min(1.5, runtime.Seconds + elapsed)
		end
		if runtime.Seconds < 1 then continue end
		local previous = profile.Progression.SpeedLevel
		local accepted = self.Context.Data:Mutate(player, function(candidate)
			return Economy.AddTraining(candidate, Config.Treadmills[id].XP)
		end, false)
		if accepted then
			runtime.Seconds -= 1
			local current = self.Context.Data:Get(player)
			if current and current.Progression.SpeedLevel > previous then
				self.Context.Data:MarkFull(player)
				self.Context.Remotes.Notice:FireClient(player, { Message = string.format("Скорость тапов выросла! Уровень %d · ×%.2f", current.Progression.SpeedLevel, Economy.SpeedMultiplier(current)) })
			end
		end
	end
end

function TrainingService:Remove(player)
	self.Runtime[player] = nil
end

return TrainingService
