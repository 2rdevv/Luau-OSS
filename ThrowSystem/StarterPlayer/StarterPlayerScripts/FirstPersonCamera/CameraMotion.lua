local motion = {}
motion.__index = motion

local function slide(value, target, speed, dt)
	return value + (target - value) * (1 - math.exp(-speed * dt))
end

function motion.new(config)
	local self = setmetatable({}, motion)
	self.config = config
	self.walkClock = 0
	self.breathClock = 0
	self.walkAmount = 0
	self.lean = 0
	self.mouseLean = 0
	self.land = 0
	self.wasGrounded = true
	self.lastY = 0
	return self
end

function motion:step(dt, humanoid, root, mouseDelta)
	local config = self.config
	local velocity = root.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speedPart = math.clamp(flat.Magnitude / math.max(humanoid.WalkSpeed, 1), 0, 1.25)
	local moving = humanoid.MoveDirection.Magnitude > 0.05
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local walkGoal = moving and grounded and speedPart or 0

	self.walkAmount = slide(self.walkAmount, walkGoal, config.bobSmooth, dt)
	self.walkClock += dt * (config.walkRate + flat.Magnitude * config.walkSpeedRate)
	self.breathClock += dt * config.breathRate

	local sideMove = root.CFrame.RightVector:Dot(humanoid.MoveDirection)
	self.lean = slide(self.lean, -sideMove * config.moveTilt, config.tiltSmooth, dt)

	local mouseGoal = math.clamp(
		-mouseDelta.X * config.mouseTilt,
		-config.maxMouseTilt,
		config.maxMouseTilt
	)
	self.mouseLean = slide(self.mouseLean, mouseGoal, config.tiltSmooth * 1.5, dt)

	if grounded and not self.wasGrounded then
		self.land = math.clamp(math.abs(self.lastY) / 65, 0, config.landMax)
	elseif not grounded and self.wasGrounded and velocity.Y > 2 then
		self.land = -config.jumpKick
	end

	self.land = slide(self.land, 0, config.landRecover, dt)
	self.wasGrounded = grounded
	self.lastY = velocity.Y

	local x = math.sin(self.walkClock) * config.bobX * self.walkAmount
	local y = math.cos(self.walkClock * 2) * config.bobY * self.walkAmount
	x += math.sin(self.breathClock * 0.55) * config.breathAmount * 0.45
	y += math.sin(self.breathClock) * config.breathAmount
	y -= self.land

	local pitch = math.cos(self.walkClock * 2) * config.bobPitch * self.walkAmount
	pitch += math.sin(self.breathClock * 0.7) * math.rad(0.06)
	pitch += self.land * 0.32

	return Vector3.new(x, y, 0), pitch, self.lean + self.mouseLean
end

function motion:reset()
	self.walkClock = 0
	self.breathClock = 0
	self.walkAmount = 0
	self.lean = 0
	self.mouseLean = 0
	self.land = 0
	self.lastY = 0
	self.wasGrounded = true
end

return motion
