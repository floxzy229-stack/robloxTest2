local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local InputController = {}
InputController.__index = InputController

function InputController.new(ui, remotes)
	local self = setmetatable({ UI = ui, Remotes = remotes, NextHit = 0, Connections = {}, Accumulator = 0 }, InputController)
	local function attempt()
		if not ui.Ready or ui.Window or UserInputService:GetFocusedTextBox() or os.clock() < self.NextHit then return end
		self.NextHit = os.clock() + (ui.Hud.Cooldown or 1)
		remotes.Hit:FireServer()
	end
	table.insert(self.Connections, ui.Bonk.Activated:Connect(attempt))
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then return end
			if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then attempt() end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then attempt() end
		if input.KeyCode == Enum.KeyCode.Escape and ui.Window then ui:Close() end
	end))
	table.insert(self.Connections, remotes.HitResult.OnClientEvent:Connect(function(result)
		if result.Source == "manual" and not result.Ok then
			self.NextHit = os.clock() + math.max(0.15, result.Wait or 0)
			if result.Message then ui:Notify(result.Message) end
		end
	end))
	table.insert(self.Connections, RunService.Heartbeat:Connect(function(dt)
		self.Accumulator += dt
		if self.Accumulator < 0.03 then return end
		self.Accumulator = 0
		local wait = math.max(0, self.NextHit - os.clock())
		local enabled = ui.Ready and not ui.Window and wait == 0
		ui.Bonk.Active = enabled
		ui.Bonk.Selectable = enabled
		ui.Bonk.AutoButtonColor = enabled
		ui.Bonk.Text = not ui.Ready and "ЗАГРУЗКА" or (wait > 0 and string.format("%.1f сек.", wait) or "БОНК")
	end))
	return self
end

function InputController:Destroy()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
end

return InputController
