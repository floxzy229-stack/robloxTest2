local Session = {}

local function validEnvelope(record)
	assert(type(record) == "table" and record.EnvelopeVersion == 1 and type(record.Data) == "table", "Unsupported or damaged save envelope")
	assert(type(record.Revision) == "number" and record.Revision >= 0 and record.Revision % 1 == 0, "Invalid saved revision")
	if record.Session ~= nil then
		assert(type(record.Session) == "table" and type(record.Session.Token) == "string" and type(record.Session.ExpiresAt) == "number", "Invalid session lease")
	end
end

function Session.Claim(record, owner, writeId, now, lease, normalize)
	if record ~= nil then
		validEnvelope(record)
		local lock = record.Session
		if lock and lock.Token ~= owner and lock.ExpiresAt > now then return nil, "locked" end
		if lock and lock.Token == owner and record.LastWriteId == writeId and lock.ExpiresAt > now then return record, "confirmed" end
	end
	local data = normalize(record and record.Data or nil)
	return {
		EnvelopeVersion = 1, Data = data, Revision = (record and record.Revision or 0) + 1,
		Session = { Token = owner, ExpiresAt = now + lease }, LastWriteId = writeId, UpdatedAt = now,
	}, "claimed"
end

function Session.Write(record, owner, expectedRevision, data, writeId, now, lease, release)
	if record == nil then return nil, "missing" end
	validEnvelope(record)
	if record.LastWriteId == writeId and record.Revision == expectedRevision + 1 then
		local sameOwner = record.Session and record.Session.Token == owner
		if sameOwner or (release and record.Session == nil) then return record, "confirmed" end
	end
	if not record.Session or record.Session.Token ~= owner then return nil, "owner_changed" end
	if record.Session.ExpiresAt <= now then return nil, "lease_expired" end
	if record.Revision ~= expectedRevision then return nil, "revision_changed" end
	return {
		EnvelopeVersion = 1, Data = data, Revision = expectedRevision + 1,
		Session = not release and { Token = owner, ExpiresAt = now + lease } or nil,
		LastWriteId = writeId, UpdatedAt = now,
	}, "written"
end

return Session
