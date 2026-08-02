local limiter = {}
limiter.__index = limiter

function limiter.new()
	return setmetatable({times = {}}, limiter)
end

function limiter:allow(player, key, gap)
	local now = os.clock()
	local row = self.times[player]

	if not row then
		row = {}
		self.times[player] = row
	end

	local last = row[key]
	if last and now - last < gap then
		return false
	end

	row[key] = now
	return true
end

function limiter:clear(player)
	self.times[player] = nil
end

return limiter
