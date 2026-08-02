local rotationService = {}
rotationService.__index = rotationService

function rotationService.new(states, hold, validator, limiter)
	local self = setmetatable({}, rotationService)
	self.states = states
	self.hold = hold
	self.validator = validator
	self.limiter = limiter
	return self
end

function rotationService:update(player, cf)
	if not self.limiter:allow(player, "holdUpdate", 0.02) then
		return
	end

	local data = self.states:get(player)
	if not self.validator:target(player, data, cf) then
		return
	end

	self.hold:setTarget(player, cf)
end

return rotationService
