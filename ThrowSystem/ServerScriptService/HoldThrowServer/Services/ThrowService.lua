local throwService = {}
throwService.__index = throwService

function throwService.new(states, hold, validator, limiter, config, names)
	local self = setmetatable({}, throwService)
	self.states = states
	self.hold = hold
	self.validator = validator
	self.limiter = limiter
	self.config = config
	self.names = names
	return self
end

function throwService:charge(player, started)
	local data = self.states:get(player)
	if not data or type(started) ~= "boolean" then
		return
	end

	if started then
		if not self.limiter:allow(player, "charge", 0.08) then
			return
		end

		if not data.chargeAt then
			data.chargeAt = os.clock()
		end
	else
		data.chargeAt = nil
	end
end

function throwService:throw(player, direction)
	if not self.limiter:allow(player, "throw", 0.1) then
		return
	end

	local data = self.states:get(player)
	if not data or not data.chargeAt or not self.validator:direction(direction) then
		return
	end

	local heldFor = math.clamp(os.clock() - data.chargeAt, 0, self.config.chargeTime)
	local amount = heldFor / self.config.chargeTime
	local speed = self.config.minSpeed + (self.config.maxSpeed - self.config.minSpeed) * amount
	local velocity = direction.Unit * speed + Vector3.new(0, self.config.upBoost, 0)

	local character = player.Character
	local bodyRoot = character and character:FindFirstChild("HumanoidRootPart")
	if bodyRoot then
		velocity += bodyRoot.AssemblyLinearVelocity * 0.3
	end

	self.hold:release(player, self.names.thrown, velocity)
end

return throwService
