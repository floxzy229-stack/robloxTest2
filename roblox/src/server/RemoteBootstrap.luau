local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Protocol = require(ReplicatedStorage:WaitForChild("BonkShared").Protocol)
local Bootstrap = {}

function Bootstrap.Create()
	local folder = ReplicatedStorage:FindFirstChild(Protocol.Folder)
	if folder then
		assert(folder:IsA("Folder") and folder:GetAttribute("BonkOwned") == true, "BonkRemotes namespace is occupied by another system")
	else
		folder = Instance.new("Folder")
		folder.Name = Protocol.Folder
		folder:SetAttribute("BonkOwned", true)
	end
	local result = {}
	for key, name in pairs(Protocol.Remotes) do
		local remote = folder:FindFirstChild(name)
		if remote then
			assert(remote:IsA("RemoteEvent") and remote:GetAttribute("BonkOwned") == true, "Conflicting Bonk RemoteEvent: " .. name)
		else
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote:SetAttribute("BonkOwned", true)
			remote.Parent = folder
		end
		result[key] = remote
	end
	folder.Parent = ReplicatedStorage
	return result
end

return Bootstrap
