local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("BonkShared")
local Config = require(Shared.GameConfig)
local Economy = require(Shared.Economy)
local UI = require(script.Parent.UIComponents)
local HUDView = require(script.Parent.HUDView)
local Panels = require(script.Parent.ProgressionPanels)
local Icons = require(script.Parent.MenuIcons)
local UIController = {}
UIController.__index = UIController

local menus = HUDView.Menus

function UIController.new()
	local self = setmetatable({ Ready = false, Busy = false, Window = nil, Buttons = {}, Profile = nil, Hud = {}, Catalog = nil, NoticeToken = 0 }, UIController)
	HUDView.Build(self)
	return self
end

function UIController:Notify(message)
	if not message or message == "" then return end
	self.NoticeToken += 1
	local token = self.NoticeToken
	self.Toast.Text = message
	self.Toast.Visible = true
	self.Toast.TextTransparency = 0
	self.Toast.BackgroundTransparency = 0
	task.delay(4, function()
		if token ~= self.NoticeToken or not self.Gui.Parent then return end
		TweenService:Create(self.Toast, TweenInfo.new(0.25), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function() if token == self.NoticeToken and self.Gui.Parent then self.Toast.Visible = false end end)
	end)
end

function UIController:Act(action, payload)
	if self.Busy then return end
	if self.Send then self.Send(action, payload or {}) end
end

function UIController:SetBusy(busy)
	self.Busy = busy
	self:RefreshButtons()
end

function UIController:Track(button, evaluate)
	table.insert(self.Buttons, { Button = button, Evaluate = evaluate })
end

function UIController:RefreshButtons()
	for _, record in ipairs(self.Buttons) do
		if record.Button.Parent then
			local text, enabled = record.Evaluate()
			record.Button.Text = text
			record.Button.Active = enabled and not self.Busy
			record.Button.Selectable = record.Button.Active
			record.Button.AutoButtonColor = record.Button.Active
			record.Button.BackgroundTransparency = record.Button.Active and 0 or 0.32
		end
	end
end

function UIController:PurchaseButton(card, price, action, payload, owned)
	local button = UI.Button(card, "Купить", function() self:Act(action, payload) end)
	self:Track(button, function()
		if owned then return "Куплено", false end
		if (self.Hud.Currency or 0) < price then return "Недостаточно Терпения · " .. UI.Format(price), false end
		return "Купить · " .. UI.Format(price), true
	end)
	return button
end

function UIController:Open(name)
	if not self.Ready and name ~= "help" then self:Notify("Загрузка данных. Подождите безопасного подключения.") return end
	if self.Window == name then self:Close() return end
	self.Window = name
	self.Shade.Visible = true
	for _, menu in ipairs(menus) do
		if menu[1] == name then
			self.Title.Text = menu[2]
			self.TitleBar.BackgroundColor3 = UI.Color(menu[3])
		end
	end
	self.Panel.Position = UDim2.fromScale(0.5, 0.54)
	TweenService:Create(self.Panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	self:Render(false)
	if name == "donate" and self.LoadCatalog then self.LoadCatalog() end
end

function UIController:Close()
	self.Window = nil
	self.Shade.Visible = false
end

function UIController:Render(keepScroll)
	if not self.Window then return end
	local oldScroll = keepScroll and self.Scroll.CanvasPosition or Vector2.zero
	for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	table.clear(self.Buttons)
	if self.Window == "shop" then self:Shop()
	elseif self.Window == "weapons" then self:Weapons()
	elseif self.Window == "pets" then self:Pets()
	elseif self.Window == "zones" then self:Zones()
	elseif self.Window == "donate" then self:Donations()
	elseif self.Window == "settings" then self:Settings()
	elseif Panels[self.Window] then Panels[self.Window](self)
	else self:Help() end
	self:RefreshButtons()
	task.defer(function() if self.Scroll.Parent then self.Scroll.CanvasPosition = oldScroll end end)
end

function UIController:Shop()
	local intro = UI.Card(self.Content)
	UI.Label(intro, "Коллекция легендарных молотков", 24, nil, true)
	UI.Label(intro, "Молотки покупаются один раз и сразу экипируются. Найдите их на светящихся стендах или выберите здесь. Ниже — улучшения бонков.")
	UI.Button(intro, "Беговые дорожки · как ускорить тапы", function() self:Open("training") end, true)
	for _, id in ipairs(Config.WeaponOrder) do
		local item = Config.Weapons[id]
		local card = UI.Card(self.Content)
		local preview = UI.Create("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundTransparency = 1 }, card)
		Icons.Add(preview, "weapon:" .. id)
		UI.Label(card, item.Name, 20, nil, true)
		UI.Label(card, item.Rarity .. " · базовая награда " .. UI.Format(item.Base))
		self:PurchaseButton(card, item.Price, "BuyWeapon", { id = id }, self.Profile.Weapons[id] == true)
	end
	for _, id in ipairs(Config.UpgradeOrder) do
		local definition = Config.Upgrades[id]
		local level = self.Profile.Upgrades[id]
		local card = UI.Card(self.Content)
		UI.Label(card, definition.Name .. " · " .. level .. "/" .. definition.Max, 20, nil, true)
		UI.Label(card, definition.Description .. "\nСейчас: " .. Economy.UpgradeEffect(id, level) .. (level < definition.Max and ("\nДалее: " .. Economy.UpgradeEffect(id, level + 1)) or "\nМаксимальный уровень"))
		self:PurchaseButton(card, Economy.UpgradePrice(id, level), "BuyUpgrade", { id = id }, level >= definition.Max)
	end
end

function UIController:Weapons()
	local intro = UI.Card(self.Content)
	UI.Label(intro, "Твоя коллекция", 24, nil, true)
	UI.Button(intro, "Открыть питомцев и слияние", function() self:Open("pets") end, true)
	UI.Button(intro, "Купить новый молоток", function() self:Open("shop") end)
	for _, id in ipairs(Config.WeaponOrder) do
		if self.Profile.Weapons[id] then
			local card = UI.Card(self.Content)
			local preview = UI.Create("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundTransparency = 1 }, card)
			Icons.Add(preview, "weapon:" .. id)
			UI.Label(card, Config.Weapons[id].Name, 20, nil, true)
			UI.Label(card, "База " .. UI.Format(Config.Weapons[id].Base) .. " · " .. Config.Weapons[id].Rarity)
			local button = UI.Button(card, "Экипировать", function() self:Act("EquipWeapon", { id = id }) end)
			self:Track(button, function() local active = self.Hud.WeaponId == id return active and "Экипировано" or "Экипировать", not active end)
		end
	end
end

function UIController:Pets()
	local profile = self.Profile
	local card = UI.Card(self.Content)
	UI.Label(card, "Яйцо помощника · 250 Терпения", 21, nil, true)
	UI.Label(card, "Только игровая валюта. Шансы известны до открытия. Редкость влияет на базовый доход; уровень питомца умножает его в 3 раза:")
	for _, id in ipairs(Config.PetOrder) do
		local pet = Config.Pets[id]
		UI.Label(card, pet.Rarity .. " · " .. pet.Name .. " — " .. pet.Weight .. "% · +" .. UI.Format(pet.Income) .. "/сек.", 14)
	end
	local hatch = UI.Button(card, "Открыть яйцо", function() self:Act("HatchEgg", {}) end, true)
	self:Track(hatch, function()
		if #profile.Pets >= Config.MaxPets then return "Инвентарь заполнен. Объедините питомцев.", false end
		return (self.Hud.Currency or 0) >= Config.EggPrice and "Открыть яйцо · 250" or "Недостаточно Терпения", (self.Hud.Currency or 0) >= Config.EggPrice
	end)
	local controls = UI.Card(self.Content)
	UI.Label(controls, "Помощники: " .. #profile.Pets .. "/" .. Config.MaxPets .. " · слотов " .. (self.Hud.PetSlots or 3), 18, nil, true)
	UI.Label(controls, "3 одинаковых одного уровня → 1 следующего. До уровня 3; каждый уровень даёт x3 доход. Дубликаты разрешены.", 14)
	local best = UI.Button(controls, "Экипировать лучших", function() self:Act("BestPets", {}) end)
	self:Track(best, function() return "Экипировать лучших", #profile.Pets > 0 end)
	local equipped, groups = {}, {}
	for _, uid in ipairs(profile.EquippedPets) do equipped[uid] = true end
	for _, pet in ipairs(profile.Pets) do
		local key = pet.Kind .. ":" .. pet.Level
		groups[key] = groups[key] or {}
		table.insert(groups[key], pet.Uid)
		local row = UI.Card(self.Content)
		local definition = Config.Pets[pet.Kind]
		UI.Label(row, definition.Rarity .. " · " .. definition.Name .. " · ур. " .. pet.Level, 20, nil, true)
		UI.Label(row, "+" .. UI.Format(Economy.PetIncome(pet)) .. "/сек. до бонусов · ID " .. string.sub(pet.Uid, 1, 8), 14)
		local button = UI.Button(row, equipped[pet.Uid] and "Экипировано · снять" or "Экипировать", function()
			self:Act(equipped[pet.Uid] and "UnequipPet" or "EquipPet", { id = pet.Uid })
		end)
		self:Track(button, function() return equipped[pet.Uid] and "Экипировано · снять" or "Экипировать", true end)
	end
	for _, kind in ipairs(Config.PetOrder) do
		for level = 0, Config.MaxPetLevel - 1 do
			local candidates = groups[kind .. ":" .. level]
			if candidates and #candidates >= 3 then
				local row = UI.Card(self.Content)
				UI.Label(row, "Слияние: " .. Config.Pets[kind].Name .. " · ур. " .. level, 18, nil, true)
				UI.Label(row, "Будут использованы экземпляры " .. string.sub(candidates[1], 1, 8) .. ", " .. string.sub(candidates[2], 1, 8) .. ", " .. string.sub(candidates[3], 1, 8) .. ". Экипированные тоже могут участвовать.", 14)
				local uids = { candidates[1], candidates[2], candidates[3] }
				local merge = UI.Button(row, "Объединить 3 → 1", function() self:Act("MergePets", { uids = uids }) end, true)
				self:Track(merge, function() return "Объединить 3 → 1", true end)
			end
		end
	end
end

function UIController:Zones()
	for _, id in ipairs(Config.ZoneOrder) do
		local zone = Config.Zones[id]
		local card = UI.Card(self.Content)
		UI.Label(card, zone.Name, 22, nil, true)
		UI.Label(card, zone.Goal)
		if self.Profile.Zones[id] then
			local teleport = UI.Button(card, "Телепорт", function() self:Act("Teleport", { id = id }) end)
			self:Track(teleport, function() return self.Hud.Zone == id and "Вы здесь" or "Телепорт", self.Hud.Zone ~= id end)
			if zone.PracticeTarget then
				local claimed = self.Profile.Statistics.PracticeClaims[id]
				local button = UI.Button(card, "Получить премию у манекена", function() self:Act("ClaimPractice", { id = id }) end, true)
				self:Track(button, function()
					local progress = (self.Hud.PracticeHits or {})[id] or 0
					return claimed and "Премия получена" or (math.min(progress, zone.PracticeTarget) .. "/" .. zone.PracticeTarget .. " · получить у манекена"), not claimed and progress >= zone.PracticeTarget
				end)
			end
		else self:PurchaseButton(card, zone.Price, "BuyZone", { id = id }, false) end
	end
end

function UIController:Donations()
	local intro = UI.Card(self.Content)
	UI.Label(intro, "Понятные привилегии", 22, nil, true)
	UI.Label(intro, "Никаких платных случайных яиц, удачи или торговли. Окончательная цена — в окне Roblox. Отмена покупки не выдаёт награду.")
	if not self.Catalog then UI.Label(intro, "Загрузка каталога…", 16) return end
	if not self.Catalog.Available then UI.Label(intro, "Покупки недоступны: " .. self.Catalog.Reason, 16) end
	for _, item in ipairs(self.Catalog.Items) do
		local card = UI.Card(self.Content)
		UI.Label(card, item.Name, 21, nil, true)
		UI.Label(card, (item.Kind == "pass" and "Постоянная привилегия\n" or "Повторный продукт\n") .. item.Description)
		local button = UI.Button(card, "Покупки недоступны", function() self:Act("PromptPurchase", { kind = item.Kind, key = item.Key }) end)
		self:Track(button, function()
			if item.Owned then return "Куплено", false end
			if not item.Enabled or not self.Catalog.Available or self.Hud.PurchasesSafe == false then return "Покупки недоступны", false end
			if item.Kind == "pass" and not item.OwnershipKnown then return "Проверка владения недоступна", false end
			if not item.Price then return item.PriceError and "Цена недоступна" or "Загрузка цены…", false end
			return "Купить · " .. item.Price .. " Robux", true
		end)
	end
	local refresh = UI.Button(intro, "Обновить цены и привилегии", function()
		if self.Busy then return end
		if self.RefreshPurchases then self.RefreshPurchases() end
	end)
	self:Track(refresh, function() return "Обновить цены и привилегии", true end)
end

function UIController:Settings()
	local settings = self.Profile.Settings
	local volume = UI.Card(self.Content)
	UI.Label(volume, "Громкость: " .. math.floor(settings.Volume * 100 + 0.5) .. "%", 22, nil, true)
	UI.Label(volume, "Звуки отключены, пока создатель не добавит свои доступные Sound ID. Визуальные эффекты работают без ассетов.", 14)
	for _, choice in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
		local button = UI.Button(volume, math.floor(choice * 100) .. "%", function() self:Act("SetSetting", { key = "Volume", value = choice }) end)
		self:Track(button, function() return math.floor(choice * 100) .. "%" .. (choice == settings.Volume and " · выбрано" or ""), choice ~= settings.Volume end)
	end
	for _, setting in ipairs({ { "Effects", "Анимации и эффекты" }, { "ShowOtherPets", "Чужие питомцы" } }) do
		local card = UI.Card(self.Content)
		UI.Label(card, setting[2], 21, nil, true)
		local button = UI.Button(card, "", function() self:Act("SetSetting", { key = setting[1], value = not settings[setting[1]] }) end)
		self:Track(button, function() return settings[setting[1]] and "Включено · выключить" or "Выключено · включить", true end)
	end
end

function UIController:Help()
	local card = UI.Card(self.Content)
	UI.Label(card, "Терпение — дело игрушечное", 23, nil, true)
	UI.Label(card, "Нажимайте БОНК, E или R2 на геймпаде. Клик по свободной сцене тоже делает бонк. На телефоне используйте кнопку БОНК: управление персонажем не вызывает случайные удары. В открытом меню ручные удары заблокированы.")
	UI.Label(card, "Дорожки постоянно улучшают скорость тапов. Встаньте на полотно: опыт начисляется автоматически, бесплатно и только пока вы на нём. Более сильные дорожки открываются за перерождения.")
	UI.Button(card, "Показать все дорожки", function() self:Open("training") end, true)
	UI.Label(card, "Награды — ежедневный подарок и задания. Перерождение обнуляет Терпение и улучшения после вашего подтверждения. Восхождение усиливает доход за кристаллы. Обменник меняет кристаллы на Терпение или опыт, это не обмен с другими игроками.")
	UI.Label(card, "Бонк → Терпение → улучшение → игрушка → питомец → новая зона → Тренер-подушка. Купленная игрушка сразу экипируется. Здоровье от бонков не меняется.")
	UI.Label(card, "Питомцы зарабатывают, пока вы в игре. Лучшие — по базовому доходу с учётом уровня. Слияние необратимо, но заменяет три экземпляра одним за одну операцию.")
	UI.Label(card, "Манекены считают ручную практику вблизи. Они не дают второй доход за тот же удар. В офисе и кухне есть одноразовые задания. Подойдите и нажмите F или кнопку подсказки на телефоне.")
	UI.Label(card, "Босс: ручные бонки в пределах 24 studs. Для премии 2 500 нанесите хотя бы 100 урона, оставайтесь рядом и участвуйте в последнюю минуту. Возвращается через 5 минут.")
	UI.Label(card, "VIP, постоянный x2 и временный x2 применяются по одному разу к бонкам и питомцам. Пакеты валюты и фиксированные премии не умножаются. Буст продолжает отсчитывать время вне игры.")
	UI.Label(card, "При проблемах сохранения игра закрывает профиль, а не подменяет его пустым. Не покупайте ничего, если показано «Покупки недоступны».")
end

function UIController:Update(packet)
	if packet.Kind == "Loading" then
		self.Ready = false
		self.Money.Text = "Загрузка данных"
		self.Status.Text = packet.Message or "Ожидание безопасной загрузки"
		return
	end
	if packet.Version and self.Version and packet.Version < self.Version then return end
	self.Version = packet.Version or self.Version
	if packet.Profile then self.Profile = packet.Profile end
	if packet.Hud then self.Hud = packet.Hud end
	if not self.Profile then return end
	self.Ready = true
	local hud = self.Hud
	self.Money.Text = UI.Format(hud.Currency or 0)
	self.RebirthCount.Text = UI.Format(hud.Rebirths or 0)
	self.Crystals.Text = UI.Format(hud.Crystals or 0)
	self.RewardBadge.Visible = (hud.ReadyRewards or 0) > 0
	self.Rate.Text = string.format("СКОРОСТЬ ТАПОВ · ×%.2f", hud.SpeedMultiplier or 1)
	local maxed = (hud.SpeedLevel or 0) >= Config.Training.MaxLevel
	local ratio = maxed and 1 or math.clamp((hud.SpeedXP or 0) / math.max(1, hud.SpeedRequired or 40), 0, 1)
	TweenService:Create(self.TrainingFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
	local active = hud.TrainingId and Config.Treadmills[hud.TrainingId]
	self.SpeedProgress.Text = maxed and "МАКСИМАЛЬНАЯ СКОРОСТЬ" or ("Ур. " .. (hud.SpeedLevel or 0) .. " · " .. (hud.SpeedXP or 0) .. "/" .. (hud.SpeedRequired or 40) .. " XP" .. (active and (" · +" .. active.XP .. "/с") or " · на дорожку!"))
	self.Weapon.Text = Config.Weapons[hud.WeaponId or "rubber_hammer"].Name .. string.format(" · %.2f с/тап", hud.Cooldown or 1)
	self.Status.Text = hud.Mock and "STUDIO: тест без сохранений и покупок" or string.format("%sДоход ×%.2f · питомцы %.1f/с", hud.VIP and "VIP · " or "", hud.ProgressionMultiplier or 1, hud.PassiveRate or 0)
	local zone = Config.Zones[hud.Zone or "playroom"]
	local boost = hud.BoostSeconds and hud.BoostSeconds > 0 and (" · x2 ещё " .. hud.BoostSeconds .. " сек.") or ""
	self.Goal.Text = zone.Name .. boost .. "\n" .. zone.Goal
	if packet.Profile and self.Window then self:Render(true) else self:RefreshButtons() end
	self.Boss.Visible = hud.Zone == Config.Boss.Zone and self.BossPacket ~= nil
end

function UIController:UpdateBoss(packet)
	self.BossPacket = packet
	self.Boss.Visible = self.Hud.Zone == Config.Boss.Zone
	if packet.Alive then
		self.Boss.Text = Config.Boss.Name .. " · " .. UI.Format(packet.HP) .. " / " .. UI.Format(packet.MaxHP) .. " HP\nВстаньте рядом и нажимайте БОНК"
	else
		self.Boss.Text = "Тренер отдыхает\nВозвращение через " .. math.max(0, packet.RespawnAt - packet.ServerTime) .. " сек."
	end
end

function UIController:Destroy()
	if self.ResizeConnection then self.ResizeConnection:Disconnect() end
	self.Gui:Destroy()
end

return UIController
