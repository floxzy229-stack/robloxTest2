local Config = {}

Config.Title = "БОНК: симулятор терпения"
Config.SchemaVersion = 3
Config.MaxCurrency = 9_000_000_000_000_000
Config.Palette = {
	Ink = { 23, 25, 39 }, Paper = { 255, 253, 242 }, Muted = { 93, 113, 143 },
	Brand = { 17, 169, 229 }, Accent = { 255, 215, 37 },
	Grass = { 176, 224, 24 }, Leaf = { 133, 188, 22 }, Earth = { 171, 75, 25 },
	Clay = { 231, 108, 25 }, Rock = { 91, 49, 38 }, Sand = { 226, 212, 179 },
	Path = { 100, 132, 167 }, Portal = { 40, 67, 146 },
	Cyan = { 28, 228, 255 }, Pink = { 255, 57, 166 }, Purple = { 160, 72, 249 },
	Lime = { 73, 219, 42 }, Orange = { 255, 132, 35 }, Lava = { 255, 65, 16 },
}
Config.TrainedMinCooldown = 0.12
Config.BaseCooldown = 1
Config.MinCooldown = 0.2
Config.BaseCritChance = 0.05
Config.MaxCritChance = 0.30
Config.CritMultiplier = 2
Config.BasePetSlots = 3
Config.MaxPetSlots = 4
Config.MaxPets = 100
Config.MaxPetLevel = 3
Config.PetLevelMultiplier = 3
Config.EggPrice = 250
Config.WorldOrigin = { 0, 50, 0 }
Config.ZoneHalfSize = 64
Config.PracticeRadius = 16
Config.Sounds = { Bonk = 0, Critical = 0, Hatch = 0 }

Config.WeaponOrder = {
	"rubber_hammer", "baguette", "toy_pan", "toy_guitar",
	"rubber_duck", "giant_banana", "inflatable_tub", "space_hammer",
}
-- Saved ownership uses these original IDs; only the names and models change.
Config.Weapons = {
	rubber_hammer = { Name = "Резиновый молот", Price = 0, Base = 1, Rarity = "Обычный", Color = "Brand", Model = "hammer", Tier = 1 },
	baguette = { Name = "Лесной молот", Price = 100, Base = 5, Rarity = "Обычный", Color = "Lime", Model = "hammer", Tier = 2 },
	toy_pan = { Name = "Стальной молот", Price = 1_000, Base = 25, Rarity = "Необычный", Color = "Muted", Model = "hammer", Tier = 3 },
	toy_guitar = { Name = "Ледяной молот", Price = 10_000, Base = 100, Rarity = "Редкий", Color = "Cyan", Model = "hammer", Tier = 4 },
	rubber_duck = { Name = "Солнечный молот", Price = 100_000, Base = 500, Rarity = "Редкий", Color = "Accent", Model = "hammer", Tier = 5 },
	giant_banana = { Name = "Лавовый молот", Price = 1_000_000, Base = 2_500, Rarity = "Эпический", Color = "Lava", Model = "hammer", Tier = 6 },
	inflatable_tub = { Name = "Кристальный молот", Price = 10_000_000, Base = 10_000, Rarity = "Легендарный", Color = "Pink", Model = "hammer", Tier = 7 },
	space_hammer = { Name = "Космический молот", Price = 100_000_000, Base = 100_000, Rarity = "Космический", Color = "Purple", Model = "space", Tier = 8 },
}

Config.UpgradeOrder = { "manual", "cooldown", "critical", "auto", "pet_income" }
Config.Upgrades = {
	manual = { Name = "Уверенный бонк", BasePrice = 25, Growth = 1.65, Max = 40, Step = 0.25, Description = "Множитель только ручных бонков" },
	cooldown = { Name = "Ловкие руки", BasePrice = 75, Growth = 2.0, Max = 10, Step = 0.08, Description = "Пауза между ручными бонками" },
	critical = { Name = "Комичный акцент", BasePrice = 150, Growth = 1.8, Max = 25, Step = 0.01, Description = "Шанс крита ручных и автоударов" },
	auto = { Name = "Бонк по расписанию", BasePrice = 120, Growth = 2.3, Max = 10, Interval = 3, Step = 0.25, MinInterval = 0.5, Description = "Отдельный серверный автоудар" },
	pet_income = { Name = "Премия помощникам", BasePrice = 100, Growth = 1.8, Max = 25, Step = 0.20, Description = "Множитель только дохода питомцев" },
}

Config.PetOrder = {
	"grasshopper", "hammer_hamster", "iron_pigeon", "smith_mushroom", "golden_banana",
	"ember_fox", "crystal_dragon", "cosmic_owl", "rainbow_golem", "void_cat",
}
Config.Pets = {
	grasshopper = { Name = "Кузнечик", Rarity = "Обычный", Weight = 43, Income = 1, Color = "Brand", Model = "grasshopper" },
	hammer_hamster = { Name = "Молот-хомяк", Rarity = "Необычный", Weight = 25, Income = 5, Color = "Accent", Model = "hamster" },
	iron_pigeon = { Name = "Железный голубь", Rarity = "Редкий", Weight = 14, Income = 25, Color = "Muted", Model = "pigeon" },
	smith_mushroom = { Name = "Гриб-кузнец", Rarity = "Сверхредкий", Weight = 8, Income = 100, Color = "Brand", Model = "mushroom" },
	golden_banana = { Name = "Золотой банан", Rarity = "Эпический", Weight = 4, Income = 500, Color = "Accent", Model = "banana" },
	ember_fox = { Name = "Искристая лиса", Rarity = "Легендарный", Weight = 3, Income = 1_500, Color = "Lava", Model = "fox" },
	crystal_dragon = { Name = "Кристальный дракон", Rarity = "Мифический", Weight = 1.5, Income = 5_000, Color = "Cyan", Model = "dragon" },
	cosmic_owl = { Name = "Космическая сова", Rarity = "Божественный", Weight = 1, Income = 15_000, Color = "Purple", Model = "owl" },
	rainbow_golem = { Name = "Радужный голем", Rarity = "Секретный", Weight = 0.4, Income = 50_000, Color = "Pink", Model = "golem" },
	void_cat = { Name = "Кот из пустоты", Rarity = "Скрытый", Weight = 0.1, Income = 250_000, Color = "Ink", Model = "cat" },
}

Config.ZoneOrder = { "playroom", "gym", "office", "kitchen" }
Config.Zones = {
	playroom = { Name = "Игровая комната", Price = 0, Offset = { 0, 0, 0 }, Color = "Brand", Goal = "Освойте бонк. Первое улучшение стоит 25 Терпения." },
	gym = { Name = "Спортзал", Price = 1_000, Offset = { 180, 0, 0 }, Color = "Accent", Goal = "Тренер-подушка ждёт: подойдите к нему и бонкайте." },
	office = { Name = "Офис", Price = 25_000, Offset = { 360, 0, 0 }, Color = "Muted", Goal = "30 ручных бонков у манекена: премия 5 000.", PracticeTarget = 30, PracticeReward = 5_000 },
	kitchen = { Name = "Кухня", Price = 250_000, Offset = { 540, 0, 0 }, Color = "Accent", Goal = "50 ручных бонков у манекена: премия 50 000.", PracticeTarget = 50, PracticeReward = 50_000 },
}
Config.Boss = {
	Name = "Тренер-подушка", Zone = "gym", MaxHP = 10_000,
	RespawnSeconds = 300, Radius = 24, RewardRadius = 70,
	MinContribution = 100, ContributionTimeout = 60,
	Reward = 2_500, MaxDamagePerHit = 2_000,
	Offset = { 28, 0, -25 },
}

Config.Training = { MaxLevel = 100, SpeedPerLevel = 0.035, BaseXP = 40, XPPerLevel = 16 }
Config.TreadmillOrder = { "starter", "spark", "charged", "turbo", "plasma", "solar", "quantum", "cosmic" }
Config.Treadmills = {
	starter = { Name = "Старт", Color = "Brand", XP = 1, Rebirths = 0 },
	spark = { Name = "Искра", Color = "Accent", XP = 2, Rebirths = 0 },
	charged = { Name = "Импульс", Color = "Lime", XP = 3, Rebirths = 1 },
	turbo = { Name = "Турбо", Color = "Cyan", XP = 5, Rebirths = 3 },
	plasma = { Name = "Плазма", Color = "Purple", XP = 8, Rebirths = 6 },
	solar = { Name = "Солнце", Color = "Orange", XP = 12, Rebirths = 10 },
	quantum = { Name = "Квант", Color = "Pink", XP = 20, Rebirths = 20 },
	cosmic = { Name = "Космос", Color = "Lava", XP = 32, Rebirths = 35 },
}
Config.Progression = {
	MaxRebirths = 50, RebirthBasePrice = 25_000, RebirthGrowth = 1.65,
	IncomePerRebirth = 0.25, CrystalsPerRebirth = 25,
	MaxAscensions = 10, AscensionCrystals = 100, RebirthsPerAscension = 5,
	IncomePerAscension = 0.5, DailyCurrency = 250, DailyCrystals = 10,
}
Config.RewardOrder = { "first_bonks", "dedication", "explorer", "boss" }
Config.Rewards = {
	first_bonks = { Name = "Первые 100 бонков", Stat = "ManualHits", Target = 100, Currency = 500, Crystals = 5 },
	dedication = { Name = "15 минут в игре", Stat = "SecondsPlayed", Target = 900, Currency = 2_500, Crystals = 15 },
	explorer = { Name = "Мастер 1 000 бонков", Stat = "ManualHits", Target = 1_000, Currency = 10_000, Crystals = 25 },
	boss = { Name = "Победитель тренера", Stat = "BossWins", Target = 1, Currency = 5_000, Crystals = 20 },
}
Config.ExchangeOrder = { "patience", "training" }
Config.Exchanges = {
	patience = { Name = "Запас терпения", Cost = 10, Currency = 1_000 },
	training = { Name = "Тренировочный заряд", Cost = 20, XP = 200 },
}

return Config
