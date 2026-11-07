return {
	PassOrder = { "vip", "double", "extra_slot" },
	Passes = {
		vip = { Id = 0, Enabled = false, Name = "VIP", Description = "Косметический значок и +10% к доходу бонков и питомцев." },
		double = { Id = 0, Enabled = false, Name = "x2 Терпение навсегда", Description = "Удваивает доход бонков и питомцев. Не удваивает пакеты валюты и фиксированные награды." },
		extra_slot = { Id = 0, Enabled = false, Name = "Четвёртый помощник", Description = "Один дополнительный слот питомца: всего 4." },
	},
	ProductOrder = { "patience_1000", "patience_10000", "boost_10m" },
	Products = {
		patience_1000 = { Id = 0, Enabled = false, Name = "1 000 Терпения", Description = "Фиксированный пакет без множителей.", Grant = "currency", Amount = 1_000 },
		patience_10000 = { Id = 0, Enabled = false, Name = "10 000 Терпения", Description = "Фиксированный пакет без множителей.", Grant = "currency", Amount = 10_000 },
		boost_10m = { Id = 0, Enabled = false, Name = "x2 на 10 минут", Description = "Повторная покупка продлевает время, а не множитель.", Grant = "boost", Seconds = 600 },
	},
}
