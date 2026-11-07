local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Factory = require(Shared.ModelFactory)
local BossService = {}
BossService.__index = BossService

function BossService.new(context, world)
	local self = setmetatable({ Context = context, Model = world.Boss, HP = Config.Boss.MaxHP, Alive = true, Round = HttpService:GenerateGUID(false), RespawnAt = 0, Contributions = {}, LastSequence = {}, LastBroadcast = 0 }, BossService)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BossStatus"
	billboard.Size = UDim2.fromOffset(330, 100)
	billboard.StudsOffset = Vector3.new(0, 11, 0)
	billboard.MaxDistance = 130
	billboard.AlwaysOnTop = true
	billboard.Adornee = world.Boss.PrimaryPart
	billboard.Parent = world.Boss.PrimaryPart
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Factory.Color("Ink")
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.75)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Factory.Color("Paper")
	label.TextSize = 18
	label.TextWrapped = true
	label.Parent = frame
	self.Label = label
	local track = Instance.new("Frame")
	track.Position = UDim2.fromScale(0.05, 0.78)
	track.Size = UDim2.fromScale(0.9, 0.13)
	track.BackgroundColor3 = Factory.Color("Muted")
	track.BorderSizePixel = 0
	track.Parent = frame
	self.Fill = Instance.new("Frame")
	self.Fill.BackgroundColor3 = Factory.Color("Accent")
	self.Fill.BorderSizePixel = 0
	self.Fill.Size = UDim2.fromScale(1, 1)
	self.Fill.Parent = track
	self:UpdateBillboard()
	return self
end

function BossService:Packet()
	return { Alive = self.Alive, HP = self.HP, MaxHP = Config.Boss.MaxHP, RespawnAt = self.RespawnAt, ServerTime = os.time() }
end

function BossService:Send(player)
	self.Context.Remotes.BossState:FireClient(player, self:Packet())
end

function BossService:UpdateBillboard()
	self.Fill.Size = UDim2.fromScale(self.HP / Config.Boss.MaxHP, 1)
	self.Label.Text = self.Alive and (Config.Boss.Name .. "\n" .. self.HP .. " / " .. Config.Boss.MaxHP .. " HP") or ("Перерыв на мягкость\n" .. math.max(0, self.RespawnAt - os.time()) .. " сек.")
end

function BossService:Eligible(player, contribution)
	if not contribution or contribution.Damage < Config.Boss.MinContribution or os.clock() - contribution.LastHit > Config.Boss.ContributionTimeout then return false end
	if not self.Context.Zones:IsInZone(player, Config.Boss.Zone) then return false end
	local root = self.Context.Zones:Root(player)
	return root ~= nil and (root.Position - self.Model:GetPivot().Position).Magnitude <= Config.Boss.RewardRadius
end

function BossService:Defeat()
	if not self.Alive then return end
	self.Alive = false
	self.HP = 0
	self.RespawnAt = os.time() + Config.Boss.RespawnSeconds
	local round = self.Round
	for userId, contribution in pairs(self.Contributions) do
		local player = Players:GetPlayerByUserId(userId)
		if player and self:Eligible(player, contribution) then
			self.Context.Data:Enqueue(player, function(profile)
				if profile.Statistics.LastBossRound == round then return false, "already_rewarded" end
				profile.Statistics.LastBossRound = round
				profile.Statistics.BossWins += 1
				self.Context.Currency:Credit(profile, Config.Boss.Reward)
				return true
			end, function(granted)
				if granted and player.Parent == Players then self.Context.Remotes.Notice:FireClient(player, { Message = "Тренер взял перерыв! Награда участнику: +" .. Config.Boss.Reward .. " Терпения." }) end
			end)
		end
	end
	for _, part in ipairs(self.Model:GetChildren()) do if part:IsA("BasePart") and part.Name ~= "Root" then part.Transparency = 0.55 end end
end

function BossService:Hit(player, sequence, damage)
	if not self.Alive or not self.Context.Zones:IsInZone(player, Config.Boss.Zone) then return false end
	local root = self.Context.Zones:Root(player)
	if not root or (root.Position - self.Model:GetPivot().Position).Magnitude > Config.Boss.Radius then return false end
	if sequence <= (self.LastSequence[player.UserId] or 0) then return false end
	if type(damage) ~= "number" or damage % 1 ~= 0 or damage <= 0 or damage > Config.Boss.MaxDamagePerHit then return false end
	self.LastSequence[player.UserId] = sequence
	local applied = math.min(self.HP, damage)
	local contribution = self.Contributions[player.UserId] or { Damage = 0, LastHit = 0 }
	contribution.Damage += applied
	contribution.LastHit = os.clock()
	self.Contributions[player.UserId] = contribution
	self.HP -= applied
	local body = self.Model:FindFirstChild("Body")
	if body then
		body.Color = Factory.Color("Brand")
		TweenService:Create(body, TweenInfo.new(0.2), { Color = Factory.Color("Accent") }):Play()
	end
	if self.HP <= 0 then self:Defeat() end
	self:UpdateBillboard()
	return true
end

function BossService:Step()
	if not self.Alive and os.time() >= self.RespawnAt then
		self.Alive = true
		self.HP = Config.Boss.MaxHP
		self.Round = HttpService:GenerateGUID(false)
		self.Contributions = {}
		self.LastSequence = {}
		for _, part in ipairs(self.Model:GetChildren()) do if part:IsA("BasePart") and part.Name ~= "Root" then part.Transparency = 0 end end
	end
	if os.clock() - self.LastBroadcast >= 1 then
		self.LastBroadcast = os.clock()
		self:UpdateBillboard()
		self.Context.Remotes.BossState:FireAllClients(self:Packet())
	end
end

function BossService:Remove(player)
	self.Contributions[player.UserId] = nil
	self.LastSequence[player.UserId] = nil
end

return BossService
