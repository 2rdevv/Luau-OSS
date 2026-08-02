local thrower = {}
thrower.__index = thrower

function thrower.new(remotes, config, holdController, uiController)
	local self = setmetatable({}, thrower)
	self.remotes = remotes
	self.config = config
	self.hold = holdController
	self.ui = uiController
	self.charging = false
	self.startedAt = 0
	return self
end

function thrower:start()
	if self.charging or not self.hold:isHolding() then
		return
	end

	self.charging = true
	self.startedAt = os.clock()
	self.remotes.ChargeRequest:FireServer(true)
	self.ui:charge(true, 0)
end

function thrower:finish(direction)
	if not self.charging or not self.hold:isHolding() then
		self:cancel(false)
		return false
	end

	local heldFor = math.clamp(os.clock() - self.startedAt, 0, self.config.chargeTime)
	local amount = heldFor / self.config.chargeTime
	local speed = self.config.minSpeed + (self.config.maxSpeed - self.config.minSpeed) * amount
	local velocity = direction.Unit * speed + Vector3.new(0, self.config.upBoost, 0)

	self.charging = false
	self.startedAt = 0
	self.ui:charge(false, 0)
	self.remotes.ThrowRequest:FireServer(direction)
	self.hold:throwNow(velocity)
	return true
end

function thrower:cancel(tellServer)
	if self.charging and tellServer then
		self.remotes.ChargeRequest:FireServer(false)
	end

	self.charging = false
	self.startedAt = 0
	self.ui:charge(false, 0)
end

function thrower:update()
	if not self.charging then
		return
	end

	local amount = (os.clock() - self.startedAt) / self.config.chargeTime
	self.ui:charge(true, amount)
end

return thrower
