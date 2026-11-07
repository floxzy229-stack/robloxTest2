local Limiter = {}
Limiter.__index = Limiter

function Limiter.new(capacity, refill)
	return setmetatable({ Capacity = capacity, Refill = refill, Records = {} }, Limiter)
end

function Limiter:Allow(key, now)
	local record = self.Records[key] or { Tokens = self.Capacity, Time = now }
	self.Records[key] = record
	record.Tokens = math.min(self.Capacity, record.Tokens + math.max(0, now - record.Time) * self.Refill)
	record.Time = now
	if record.Tokens < 1 then return false end
	record.Tokens -= 1
	return true
end

function Limiter:Remove(key)
	self.Records[key] = nil
end

return Limiter
