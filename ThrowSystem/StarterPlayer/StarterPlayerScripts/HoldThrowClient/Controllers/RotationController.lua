local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local rotation = {}
rotation.__index = rotation

function rotation.new(config, cleaner)
	local self = setmetatable({}, rotation)
	self.config = config
	self.cleaner = cleaner
	self.active = false
	self.turning = false
	self.value = CFrame.new()
	self.oldMouse = nil
	self.lockedCamera = nil
	self.oldCameraType = nil
	self.cameraBound = false

	self.cleaner:add(UserInputService.InputChanged:Connect(function(input)
		if not self.active or not self.turning then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local dx = input.Delta.X * self.config.turnSpeed
		local dy = input.Delta.Y * self.config.turnSpeed
		self.value = CFrame.Angles(0, -dx, 0) * self.value * CFrame.Angles(-dy, 0, 0)
	end))

	self.cleaner:add(UserInputService.WindowFocusReleased:Connect(function()
		self:stopTurning()
	end))

	return self
end

function rotation:enable(rootCf)
	self:disable()
	self.active = true
	self.value = rootCf - rootCf.Position

	ContextActionService:BindActionAtPriority(
		"turnHeldThing",
		function(_, state)
			if state == Enum.UserInputState.Begin then
				self:stopTurning()
				self.turning = true
				player:SetAttribute("HoldCameraLocked", true)
				self.oldMouse = UserInputService.MouseBehavior
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
				self:lockCamera()
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				self:stopTurning()
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		3000,
		self.config.turn
	)
end

function rotation:disable()
	if not self.active then
		return
	end

	ContextActionService:UnbindAction("turnHeldThing")
	self:stopTurning()
	self.active = false
	self.turning = false

	if self.oldMouse then
		UserInputService.MouseBehavior = self.oldMouse
	end

	self.oldMouse = nil
end

function rotation:stopTurning()
	self.turning = false
	self:unlockCamera()
	player:SetAttribute("HoldCameraLocked", false)

	if self.oldMouse then
		UserInputService.MouseBehavior = self.oldMouse
	end

	self.oldMouse = nil
end

function rotation:lockCamera()
	self:unlockCamera()

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	self.lockedCamera = camera
	self.oldCameraType = camera.CameraType
	self.cameraCf = camera.CFrame
	self.cameraFocus = camera.Focus
	camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep("holdCameraStill", Enum.RenderPriority.Camera.Value + 10, function()
		if self.lockedCamera then
			self.lockedCamera.CFrame = self.cameraCf
			self.lockedCamera.Focus = self.cameraFocus
		end
	end)
	self.cameraBound = true
end

function rotation:unlockCamera()
	if self.cameraBound then
		RunService:UnbindFromRenderStep("holdCameraStill")
		self.cameraBound = false
	end

	if self.lockedCamera and self.lockedCamera.Parent and self.oldCameraType then
		self.lockedCamera.CameraType = self.oldCameraType
	end

	self.lockedCamera = nil
	self.oldCameraType = nil
	self.cameraCf = nil
	self.cameraFocus = nil
end

function rotation:get()
	return self.value
end

return rotation
