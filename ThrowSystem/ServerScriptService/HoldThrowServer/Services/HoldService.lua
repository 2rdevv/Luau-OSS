local RunService = game:GetService("RunService")

local holdService = {}
holdService.__index = holdService

local function kill(instance)
	if instance and instance.Parent then
		instance:Destroy()
	end
end

local function clearOld(root)
	local names = {
		holdAttach = true,
		holdPosition = true,
		holdRotation = true,
		noOwnerCollision = true,
	}

	for _, thing in root:GetChildren() do
		if names[thing.Name] then
			thing:Destroy()
		end
	end
end

function holdService.new(states, collisions, physics, resolver, names, stateRemote)
	local self = setmetatable({}, holdService)
	self.states = states
	self.collisions = collisions
	self.physics = physics
	self.resolver = resolver
	self.names = names
	self.stateRemote = stateRemote
	self.watchTime = 0
	return self
end

function holdService:grab(player, item, root)
	if self.states:get(player) or self.states:owner(item) then
		return false
	end

	clearOld(root)

	for _, part in self.resolver.parts(item) do
		part.Anchored = false
	end

	pcall(function()
		root:SetNetworkOwner(player)
	end)

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local rootAttach = Instance.new("Attachment")
	rootAttach.Name = "holdAttach"
	rootAttach.Parent = root

	local mover = Instance.new("AlignPosition")
	mover.Name = "holdPosition"
	mover.Mode = Enum.PositionAlignmentMode.OneAttachment
	mover.Attachment0 = rootAttach
	mover.Position = root.Position
	mover.ApplyAtCenterOfMass = true
	mover.MaxForce = self.physics.maxForce
	mover.MaxVelocity = self.physics.maxSpeed
	mover.Responsiveness = self.physics.positionResponse
	mover.RigidityEnabled = false
	mover.Parent = root

	local turner = Instance.new("AlignOrientation")
	turner.Name = "holdRotation"
	turner.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turner.Attachment0 = rootAttach
	turner.CFrame = root.CFrame - root.Position
	turner.MaxTorque = self.physics.maxTorque
	turner.MaxAngularVelocity = self.physics.maxTurnSpeed
	turner.Responsiveness = self.physics.rotationResponse
	turner.RigidityEnabled = false
	turner.Parent = root

	local noOwnerHit = self.collisions:stopCharacterHits(item, player.Character, root)
	local data = {
		item = item,
		root = root,
		rootAttach = rootAttach,
		mover = mover,
		turner = turner,
		noOwnerHit = noOwnerHit,
		chargeAt = nil,
	}

	if not self.states:add(player, data) then
		kill(mover)
		kill(turner)
		kill(rootAttach)
		kill(noOwnerHit)
		return false
	end

	self.stateRemote:FireClient(player, self.names.grabbed, item)
	return true
end

function holdService:setTarget(player, cf)
	local data = self.states:get(player)
	if data and data.mover and data.mover.Parent and data.turner and data.turner.Parent then
		data.mover.Position = cf.Position
		data.turner.CFrame = cf - cf.Position
	end
end

function holdService:release(player, reason, velocity, quiet)
	local data = self.states:remove(player)
	if not data then
		return false
	end

	kill(data.mover)
	kill(data.turner)
	kill(data.rootAttach)
	kill(data.noOwnerHit)

	local root = data.root
	if root and root.Parent then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)

		if velocity then
			root.AssemblyLinearVelocity = velocity
			root.AssemblyAngularVelocity = Vector3.zero
		else
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end

		task.delay(self.physics.ownerDelay, function()
			if root.Parent and not self.states:owner(data.item) then
				pcall(function()
					root:SetNetworkOwnershipAuto()
				end)
			end
		end)
	end

	if not quiet then
		self.stateRemote:FireClient(player, reason or self.names.released, data.item)
	end

	return true
end

function holdService:startWatching()
	RunService.Heartbeat:Connect(function(dt)
		self.watchTime += dt
		if self.watchTime < 0.25 then
			return
		end

		self.watchTime = 0
		local broken = {}

		for player, data in self.states:all() do
			local character = player.Character
			local bodyRoot = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local bad = not bodyRoot or not humanoid or humanoid.Health <= 0

			if not data.item or data.item.Parent ~= self.resolver.folder() then
				bad = true
			elseif not data.root or not data.root.Parent or not data.mover or not data.mover.Parent then
				bad = true
			elseif (data.root.Position - bodyRoot.Position).Magnitude > self.physics.breakDistance then
				bad = true
			end

			if bad then
				table.insert(broken, player)
			end
		end

		for _, player in broken do
			self:release(player, self.names.broken)
		end
	end)
end

return holdService
