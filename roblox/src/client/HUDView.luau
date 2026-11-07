local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UI = require(script.Parent.UIComponents)
local Icons = require(script.Parent.MenuIcons)
local View = {}

View.Menus = {
	{ "shop", "Магазин", "Accent", "shop" },
	{ "weapons", "Инвентарь", "Lime", "inventory" },
	{ "rewards", "Награды", "Cyan", "rewards" },
	{ "rebirth", "Перерождение", "Pink", "rebirth" },
	{ "ascension", "Восхождение", "Brand", "ascension" },
	{ "exchange", "Обмен", "Purple", "exchange" },
	{ "zones", "Миры", "Purple" }, { "pets", "Питомцы", "Lime" },
	{ "donate", "VIP-магазин", "Accent" }, { "settings", "Настройки", "Brand" },
	{ "help", "Как играть", "Brand" }, { "training", "Беговые дорожки", "Cyan" },
}

local function outlined(parent, text, size, position, fontSize)
	return UI.Create("TextLabel", {
		Size = size, Position = position, Text = text, BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne, TextSize = fontSize, TextColor3 = UI.Color("Paper"),
		TextStrokeTransparency = 0, TextStrokeColor3 = UI.Color("Ink"), TextWrapped = true,
		ZIndex = parent.ZIndex + 2,
	}, parent)
end

local function stat(parent, icon, y)
	Icons.Add(parent, icon, UDim2.fromOffset(65, 65), UDim2.fromOffset(-2, y))
	local label = outlined(parent, "—", UDim2.fromOffset(164, 54), UDim2.fromOffset(65, y + 4), 43)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	UI.Create("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = 43 }, label)
	return label
end

local function tile(self, parent, entry, x, y, width, height)
	local shadow = UI.Create("Frame", { Position = UDim2.fromOffset(x + 4, y + 5), Size = UDim2.fromOffset(width, height), BackgroundColor3 = UI.Color("Ink"), BackgroundTransparency = 0.25, BorderSizePixel = 0 }, parent)
	UI.Round(shadow, 5)
	local button = UI.Create("TextButton", {
		Name = entry[1], Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
		Text = "", BackgroundColor3 = UI.Color(entry[3]), BorderSizePixel = 0, Selectable = true,
	}, parent)
	UI.Round(button, 4)
	UI.Stroke(button, 4)
	UI.Gradient(button, entry[3])
	UI.Studs(button)
	UI.Create("Frame", { Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 0, 4), BorderSizePixel = 0, BackgroundColor3 = UI.Color("Paper"), BackgroundTransparency = 0.4 }, button)
	Icons.Add(button, entry[4], UDim2.new(1, -6, 1, -16), UDim2.fromOffset(3, -5))
	local caption = outlined(button, entry[2], UDim2.new(1, -4, 0, 32), UDim2.new(0, 2, 1, -34), width > 150 and 28 or 19)
	caption.TextScaled = true
	UI.Create("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = width > 150 and 28 or 21 }, caption)
	button.Activated:Connect(function() self:Open(entry[1]) end)
	button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), { Rotation = -2 }):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), { Rotation = 0 }):Play() end)
	return button
end

function View.Build(self)
	self.Gui = UI.Create("ScreenGui", {
		Name = "BonkUI", ResetOnSpawn = false, DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ClipToDeviceSafeArea = true,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.Root = UI.Create("Frame", { Name = "GameHUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, self.Gui)
	local sidebar = UI.Create("Frame", { Name = "ReferenceMenu", Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(224, 650), BackgroundTransparency = 1 }, self.Root)
	local scale = UI.Create("UIScale", { Scale = 1 }, sidebar)
	self.RebirthCount = stat(sidebar, "rebirth", 0)
	self.Money = stat(sidebar, "hammer", 57)
	self.Crystals = stat(sidebar, "crystals", 114)
	tile(self, sidebar, View.Menus[1], 0, 184, 224, 104)
	tile(self, sidebar, View.Menus[2], 0, 300, 106, 106)
	local rewards = tile(self, sidebar, View.Menus[3], 118, 300, 106, 106)
	tile(self, sidebar, View.Menus[4], 0, 418, 106, 106)
	tile(self, sidebar, View.Menus[5], 118, 418, 106, 106)
	tile(self, sidebar, View.Menus[6], 59, 536, 106, 106)
	self.RewardBadge = outlined(rewards, "!", UDim2.fromOffset(36, 48), UDim2.new(1, -19, 0, -21), 44)
	self.RewardBadge.TextColor3 = UI.Color("Lava")
	self.RewardBadge.Rotation = 12
	self.RewardBadge.Visible = false

	local shortcuts = UI.Create("Frame", { Name = "Shortcuts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(250, 44), BackgroundTransparency = 1 }, self.Root)
	UI.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, shortcuts)
	for order, entry in ipairs({ { "zones", "Миры" }, { "pets", "Петы" }, { "donate", "VIP" }, { "settings", "Опции" }, { "help", "?" } }) do
		local button = UI.Button(shortcuts, entry[2], function() self:Open(entry[1]) end, entry[1] == "donate")
		button.Size = UDim2.fromOffset(44, 44)
		button.TextSize = 12
		button.LayoutOrder = order
	end
	self.Goal = outlined(self.Root, "ДОБРО ПОЖАЛОВАТЬ В БОНК", UDim2.fromOffset(420, 55), UDim2.new(1, -16, 0, 61), 17)
	self.Goal.AnchorPoint = Vector2.new(1, 0)
	self.Goal.TextXAlignment = Enum.TextXAlignment.Right
	self.Status = outlined(self.Root, "Подключаем сохранение…", UDim2.fromOffset(400, 36), UDim2.new(1, -16, 0, 119), 12)
	self.Status.AnchorPoint = Vector2.new(1, 0)
	self.Status.TextXAlignment = Enum.TextXAlignment.Right

	self.Bonk = UI.Button(self.Root, "ЗАГРУЗКА", nil, true)
	self.Bonk.Name = "BonkButton"
	self.Bonk.AnchorPoint = Vector2.new(0.5, 1)
	self.Bonk.Position = UDim2.new(0.58, 0, 1, -12)
	self.Bonk.Size = UDim2.fromOffset(250, 64)
	self.Bonk.TextSize = 30
	UI.Stroke(self.Bonk, 3)
	self.TrainingPanel = UI.Create("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -91), Size = UDim2.fromOffset(300, 98), BackgroundColor3 = UI.Color("Ink"), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, self.Root)
	UI.Round(self.TrainingPanel, 10)
	UI.Stroke(self.TrainingPanel, 2, "Brand")
	self.Rate = outlined(self.TrainingPanel, "СКОРОСТЬ ТАПОВ · 1.00×", UDim2.new(1, -20, 0, 25), UDim2.fromOffset(10, 5), 15)
	self.Rate.TextXAlignment = Enum.TextXAlignment.Left
	local track = UI.Create("Frame", { Size = UDim2.new(1, -20, 0, 11), Position = UDim2.fromOffset(10, 35), BackgroundColor3 = UI.Color("Muted"), BorderSizePixel = 0, ClipsDescendants = true }, self.TrainingPanel)
	UI.Round(track, 6)
	self.TrainingFill = UI.Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.Color("Cyan"), BorderSizePixel = 0 }, track)
	UI.Round(self.TrainingFill, 6)
	self.SpeedProgress = outlined(self.TrainingPanel, "Встаньте на дорожку, чтобы тренироваться", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 48), 12)
	self.Weapon = outlined(self.TrainingPanel, "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 71), 12)

	self.Boss = outlined(self.Root, "", UDim2.new(0.6, 0, 0, 64), UDim2.fromScale(0.65, 0.23), 17)
	self.Boss.AnchorPoint = Vector2.new(0.5, 0)
	self.Boss.Visible = false
	self.Boss.BackgroundColor3 = UI.Color("Ink")
	self.Boss.BackgroundTransparency = 0.18
	UI.Round(self.Boss, 10)
	UI.Create("UISizeConstraint", { MaxSize = Vector2.new(600, 64) }, self.Boss)

	self.Shade = UI.Create("Frame", { Name = "ModalLayer", Visible = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.Color("Ink"), BackgroundTransparency = 0.3, BorderSizePixel = 0, Active = true, ZIndex = 10 }, self.Root)
	self.Panel = UI.Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.92, 0.9), BackgroundColor3 = UI.Color("Sand"), BorderSizePixel = 0 }, self.Shade)
	UI.Round(self.Panel, 15)
	UI.Stroke(self.Panel, 4)
	UI.Create("UISizeConstraint", { MaxSize = Vector2.new(820, 710) }, self.Panel)
	self.TitleBar = UI.Create("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = UI.Color("Accent"), BorderSizePixel = 0 }, self.Panel)
	UI.Round(self.TitleBar, 13)
	UI.Studs(self.TitleBar)
	self.Title = outlined(self.TitleBar, "Магазин", UDim2.new(1, -90, 1, 0), UDim2.fromOffset(20, 0), 29)
	self.Title.TextXAlignment = Enum.TextXAlignment.Left
	local close = UI.Button(self.TitleBar, "×", function() self:Close() end)
	close.Size = UDim2.fromOffset(44, 44)
	close.Position = UDim2.new(1, -55, 0, 11)
	close.BackgroundColor3 = UI.Color("Pink")
	close.TextSize = 30
	self.Scroll = UI.Create("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 78), Size = UDim2.new(1, -24, 1, -90), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = UI.Color("Ink"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
	}, self.Panel)
	self.Content = UI.Create("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, self.Scroll)
	UI.List(self.Content, 12)
	self.Toast = UI.Create("TextLabel", {
		Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.new(0.9, 0, 0, 80),
		BackgroundColor3 = UI.Color("Accent"), TextColor3 = UI.Color("Ink"), TextSize = 16, TextWrapped = true,
		Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 100,
	}, self.Root)
	UI.Round(self.Toast, 10)
	UI.Stroke(self.Toast, 3)
	UI.Padding(self.Toast, 12)
	UI.Create("UISizeConstraint", { MaxSize = Vector2.new(660, 80) }, self.Toast)

	local function resize()
		local size = self.Root.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		scale.Scale = math.min(1, (size.Y - 30) / 650, math.max(0.46, size.X / 1100))
		local freeWidth = math.max(145, size.X - 224 * scale.Scale - 35)
		self.Goal.Size = UDim2.fromOffset(math.min(460, freeWidth), 55)
		self.Status.Size = UDim2.fromOffset(math.min(450, freeWidth), 36)
		self.TrainingPanel.Size = UDim2.fromOffset(math.min(300, freeWidth), 98)
		self.Bonk.Size = UDim2.fromOffset(math.min(250, freeWidth), 60)
		self.Bonk.Position = UDim2.new(1, -14 - math.min(300, freeWidth) / 2, 1, -12)
		self.TrainingPanel.Visible = size.Y >= 460
		self.Status.Visible = size.Y >= 420
	end
	self.ResizeConnection = self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	task.defer(resize)
end

return View
