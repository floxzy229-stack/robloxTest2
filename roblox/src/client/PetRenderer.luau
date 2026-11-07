local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Factory = require(Shared.ModelFactory)
local PetRenderer = {}
PetRenderer.__index = PetRenderer

function PetRenderer.new()
	local folder = Instance.new("Folder")
	folder.Name = "BonkLocalPets"
	folder.Parent = workspace
	local self = setmetatable({ Folder = folder, Records = {}, ShowOthers = true, Connections = {} }, PetRenderer)
	local function add(player)
		if self.Records[player] then return end
		self.Records[player] = { Models = {}, Data = {} }
		self.Records[player].Connection = player:GetAttributeChangedSignal("BonkPets"):Connect(function() self:Rebuild(player) end)
		self:Rebuild(player)
	end
	for _, player in ipairs(Players:GetPlayers()) do add(player) end
	table.insert(self.Connections, Players.PlayerAdded:Connect(add))
	table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player) self:Remove(player) end))
	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		local localRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		for player, record in pairs(self.Records) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local visible = root and localRoot and (root.Position - localRoot.Position).Magnitude <= 120 and (player == Players.LocalPlayer or self.ShowOthers)
			for index, pet in ipairs(record.Data) do
				local object = record.Models[pet.Uid]
				if object then
					object.Parent = visible and folder or nil
					if visible then
						local x = (index - (#record.Data + 1) / 2) * 2.6
						local target = root.CFrame * CFrame.new(x, -1.5 + math.sin(os.clock() * 3 + index) * 0.25, 4)
						if (object:GetPivot().Position - target.Position).Magnitude > 30 then object:PivotTo(target)
						else object:PivotTo(object:GetPivot():Lerp(target, math.min(1, dt * 10))) end
					end
				end
			end
		end
	end))
	return self
end

function PetRenderer:Rebuild(player)
	local record = self.Records[player]
	if not record then return end
	local ok, data = pcall(function() return HttpService:JSONDecode(player:GetAttribute("BonkPets") or "[]") end)
	if not ok or type(data) ~= "table" or #data > Config.MaxPetSlots then data = {} end
	local keep, validated = {}, {}
	for _, pet in ipairs(data) do
		if type(pet) == "table" and type(pet.Uid) == "string" and Config.Pets[pet.Kind] and type(pet.Level) == "number" then
			keep[pet.Uid] = true
			table.insert(validated, pet)
			if not record.Models[pet.Uid] then
				local object = Factory.Pet(pet.Kind, pet.Level, self.Folder, CFrame.new())
				record.Models[pet.Uid] = object
				local labelGui = Instance.new("BillboardGui")
				labelGui.Size = UDim2.fromOffset(180, 36)
				labelGui.StudsOffset = Vector3.new(0, 2.7, 0)
				labelGui.MaxDistance = 45
				labelGui.Adornee = object.PrimaryPart
				labelGui.Parent = object.PrimaryPart
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundColor3 = Factory.Color("Ink")
				label.BackgroundTransparency = 0.15
				label.TextColor3 = Factory.Color("Paper")
				label.TextSize = 14
				label.Font = Enum.Font.Gotham
				label.TextWrapped = true
				label.Text = Config.Pets[pet.Kind].Name .. " · " .. pet.Level
				label.Parent = labelGui
			end
		end
	end
	for uid, object in pairs(record.Models) do if not keep[uid] then object:Destroy() record.Models[uid] = nil end end
	record.Data = validated
end

function PetRenderer:SetSettings(settings)
	self.ShowOthers = settings.ShowOtherPets
end

function PetRenderer:Remove(player)
	local record = self.Records[player]
	if not record then return end
	record.Connection:Disconnect()
	for _, object in pairs(record.Models) do object:Destroy() end
	self.Records[player] = nil
end

function PetRenderer:Destroy()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	for player in pairs(self.Records) do self:Remove(player) end
	self.Folder:Destroy()
end

return PetRenderer
