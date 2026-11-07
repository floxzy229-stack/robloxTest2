local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Factory = require(ReplicatedStorage:WaitForChild("BonkShared").ModelFactory)
local UI = {}
UI.Color = Factory.Color

function UI.Create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties or {}) do instance[key] = value end
	instance.Parent = parent
	return instance
end

function UI.Round(parent, radius)
	return UI.Create("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

function UI.Stroke(parent, thickness, color)
	return UI.Create("UIStroke", {
		Color = UI.Color(color or "Ink"), Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round,
	}, parent)
end

function UI.Gradient(parent, color)
	local base = UI.Color(color)
	return UI.Create("UIGradient", {
		Color = ColorSequence.new(base:Lerp(Color3.new(1, 1, 1), 0.22), base:Lerp(Color3.new(0, 0, 0), 0.08)), Rotation = 90,
	}, parent)
end

function UI.Studs(parent)
	local texture = UI.Create("Frame", { Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = parent.ZIndex }, parent)
	for x = 0, 6 do
		for y = 0, 3 do
			local stud = UI.Create("Frame", {
				Position = UDim2.fromOffset(9 + x * 32, 9 + y * 29), Size = UDim2.fromOffset(13, 13),
				BackgroundColor3 = UI.Color("Paper"), BackgroundTransparency = 0.84, BorderSizePixel = 0,
			}, texture)
			UI.Round(stud, 2)
			UI.Create("UIStroke", { Color = UI.Color("Ink"), Transparency = 0.88, Thickness = 2 }, stud)
		end
	end
	return texture
end

function UI.Padding(parent, value)
	return UI.Create("UIPadding", {
		PaddingTop = UDim.new(0, value), PaddingBottom = UDim.new(0, value),
		PaddingLeft = UDim.new(0, value), PaddingRight = UDim.new(0, value),
	}, parent)
end

function UI.List(parent, padding)
	return UI.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 10), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, parent)
end

function UI.Label(parent, text, size, color, heading)
	return UI.Create("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Text = text, TextSize = size or 16, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		Font = heading and Enum.Font.FredokaOne or Enum.Font.Gotham,
		TextColor3 = UI.Color(color or "Ink"), RichText = false,
	}, parent)
end

function UI.Button(parent, text, callback, accent)
	local button = UI.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 44), Text = text, TextSize = 16,
		TextWrapped = true, Font = Enum.Font.FredokaOne,
		BackgroundColor3 = UI.Color(accent and "Accent" or "Brand"),
		TextColor3 = UI.Color(accent and "Ink" or "Paper"),
		AutoButtonColor = true, BorderSizePixel = 0, Selectable = true,
	}, parent)
	UI.Round(button, 8)
	UI.Stroke(button, 2)
	UI.Gradient(button, accent and "Accent" or "Brand")
	if callback then button.Activated:Connect(callback) end
	return button
end

function UI.Card(parent)
	local frame = UI.Create("Frame", {
		Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color("Paper"), BorderSizePixel = 0,
	}, parent)
	UI.Round(frame, 10)
	UI.Create("UIStroke", { Color = UI.Color("Sand"), Thickness = 2 }, frame)
	UI.Padding(frame, 14)
	UI.List(frame, 8)
	return frame
end

function UI.Format(value)
	if value >= 1e12 then return string.format("%.2f трлн", value / 1e12) end
	if value >= 1e9 then return string.format("%.2f млрд", value / 1e9) end
	if value >= 1e6 then return string.format("%.2f млн", value / 1e6) end
	if value >= 1e4 then return string.format("%.1f тыс.", value / 1e3) end
	return tostring(math.floor(value))
end

return UI
