local hold = {}
hold.__index = hold

function hold.new(remotes, config, scrollStep)
	local self = setmetatable({}, hold)
	self.remotes = remotes
	self.config = config
	self.scrollStep = scrollStep
	self.item = nil
	self.root = nil
	self.mover = nil
	self.turner = nil
	self.waiting = false
	self.dropping = false
	self.distance = config.holdStart
	self.lastSend = 0
	self.smoothCf = nil
	self.askNumber = 0
	return self
end

function hold:ask(item)
	if self.item or self.waiting or not item then
		return
	end

	self.waiting = true
	self.askNumber += 1
	local thisAsk = self.askNumber
	self.remotes.GrabRequest:FireServer(item)

	task.delay(1, function()
		if self.waiting and self.askNumber == thisAsk then
			self.waiting = false
		end
	end)
end

function hold:accepted(item, root)
	self.waiting = false
	self.askNumber += 1
	self.dropping = false
	self.item = item
	self.root = root
	self.mover = root:FindFirstChild("holdPosition") or root:WaitForChild("holdPosition", 1)
	self.turner = root:FindFirstChild("holdRotation") or root:WaitForChild("holdRotation", 1)
	self.distance = self.config.holdStart
	self.smoothCf = root.CFrame
end

function hold:denied()
	self.waiting = false
	self.askNumber += 1
	self.dropping = false
end

function hold:drop()
	if not self.item and not self.waiting then
		return
	end

	self.dropping = true
	self.waiting = false
	self.askNumber += 1
	self:stopPulling()
	self.item = nil
	self.root = nil
	self.mover = nil
	self.turner = nil
	self.smoothCf = nil
	self.remotes.ReleaseRequest:FireServer()
end

function hold:clear()
	self.item = nil
	self.root = nil
	self.mover = nil
	self.turner = nil
	self.waiting = false
	self.askNumber += 1
	self.dropping = false
	self.smoothCf = nil
end

function hold:changeDistance(amount)
	if not self.item then
		return
	end

	self.distance = math.clamp(
		self.distance + amount * self.scrollStep,
		self.config.holdMin,
		self.config.holdMax
	)
end

function hold:target(character, camera, rotation, dt)
	if not self.item then
		return nil
	end

	local bodyRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not bodyRoot then
		return nil
	end

	local origin = bodyRoot.Position + Vector3.new(0, 1.5, 0)
	local at = origin + camera.CFrame.LookVector * self.distance
	local wanted = CFrame.new(at) * rotation
	local amount = 1 - math.exp(-self.config.moveSmooth * dt)

	if not self.smoothCf then
		self.smoothCf = wanted
	else
		self.smoothCf = self.smoothCf:Lerp(wanted, amount)
	end

	return self.smoothCf
end

function hold:update(cf)
	if not self.item or not cf or self.dropping then
		return
	end

	if self.mover and self.mover.Parent then
		self.mover.Position = cf.Position
	end

	if self.turner and self.turner.Parent then
		self.turner.CFrame = cf - cf.Position
	end

	local now = os.clock()
	if now - self.lastSend < self.config.sendEvery then
		return
	end

	self.lastSend = now
	self.remotes.HoldUpdate:FireServer(cf)
end

function hold:stopPulling()
	if not self.root then
		return
	end

	local mover = self.mover or self.root:FindFirstChild("holdPosition")
	local turner = self.turner or self.root:FindFirstChild("holdRotation")

	if mover and mover:IsA("AlignPosition") then
		mover.Enabled = false
	end

	if turner and turner:IsA("AlignOrientation") then
		turner.Enabled = false
	end

	self.mover = nil
	self.turner = nil
end

function hold:throwNow(velocity)
	local root = self.root
	self:stopPulling()

	if root and root.Parent then
		root.AssemblyLinearVelocity = velocity
		root.AssemblyAngularVelocity = Vector3.zero
	end

	self.item = nil
	self.root = nil
	self.mover = nil
	self.turner = nil
	self.smoothCf = nil
	self.dropping = true
end

function hold:isHolding()
	return self.item ~= nil
end

return hold
