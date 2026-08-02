local grabService = {}
grabService.__index = grabService

function grabService.new(states, hold, validator, limiter, names, stateRemote)
	local self = setmetatable({}, grabService)
	self.states = states
	self.hold = hold
	self.validator = validator
	self.limiter = limiter
	self.names = names
	self.stateRemote = stateRemote
	return self
end

function grabService:request(player, item)
	if not self.limiter:allow(player, "grab", 0.12) then
		return
	end

	if self.states:get(player) then
		self.stateRemote:FireClient(player, self.names.denied)
		return
	end

	local allowed, root = self.validator:canGrab(player, item)
	if not allowed then
		self.stateRemote:FireClient(player, self.names.denied)
		return
	end

	if self.states:owner(item) then
		self.stateRemote:FireClient(player, self.names.denied)
		return
	end

	if not self.hold:grab(player, item, root) then
		self.stateRemote:FireClient(player, self.names.denied)
	end
end

return grabService
