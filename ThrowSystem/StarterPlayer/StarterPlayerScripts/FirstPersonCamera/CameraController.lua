local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local cameraControl = {}
cameraControl.__index = cameraControl

local function yawFrom(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

function cameraControl.new(config, cameraMotion)
	local self = setmetatable({}, cameraControl)
	self.config = config
	self.motion = cameraMotion
	self.character = nil
	self.humanoid = nil
	self.root = nil
	self.head = nil
	self.eyeHeight = 1.5
	self.yaw = 0
	self.pitch = 0
	self.wantYaw = 0
	self.wantPitch = 0
	self.hide = {}
	self.bodyAdded = nil
	self.charNumber = 0
	return self
end

function cameraControl:addBodyPart(thing)
	if not thing:IsA("BasePart") then
		return
	end

	table.insert(self.hide, thing)
end

function cameraControl:hookChar(character)
	self.charNumber += 1
	local thisChar = self.charNumber
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")

	if player.Character ~= character or thisChar ~= self.charNumber then
		return
	end

	if self.bodyAdded then
		self.bodyAdded:Disconnect()
	end

	self.character = character
	self.humanoid = humanoid
	self.root = root
	self.head = head
	self.eyeHeight = head.Position.Y - root.Position.Y + self.config.eyeLift
	self.hide = {}
	self.motion:reset()

	for _, thing in character:GetDescendants() do
		self:addBodyPart(thing)
	end

	self.bodyAdded = character.DescendantAdded:Connect(function(thing)
		if character == self.character then
			self:addBodyPart(thing)
		end
	end)
end

function cameraControl:body()
	for i = #self.hide, 1, -1 do
		local part = self.hide[i]
		if part.Parent then
			part.LocalTransparencyModifier = 1
		else
			table.remove(self.hide, i)
		end
	end

end

function cameraControl:frame(dt)
	local camera = workspace.CurrentCamera
	local root = self.root
	local humanoid = self.humanoid

	if not camera or not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
		return
	end

	self:body()

	if player:GetAttribute("HoldCameraLocked") then
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = self.config.fov

	local mouse = UserInputService:GetMouseDelta()
	self.wantYaw -= mouse.X * self.config.sensitivity
	self.wantPitch = math.clamp(
		self.wantPitch - mouse.Y * self.config.sensitivity,
		-self.config.pitchLimit,
		self.config.pitchLimit
	)

	local smooth = 1 - math.exp(-self.config.mouseSmooth * dt)
	self.yaw += (self.wantYaw - self.yaw) * smooth
	self.pitch += (self.wantPitch - self.pitch) * smooth

	local move, extraPitch, roll = self.motion:step(dt, humanoid, root, mouse)
	local eye = root.Position + Vector3.new(0, self.eyeHeight, 0)
	local cf = CFrame.new(eye)
		* CFrame.Angles(0, self.yaw, 0)
		* CFrame.Angles(self.pitch + extraPitch, 0, roll)
		* CFrame.new(move)

	camera.CFrame = cf
	camera.Focus = cf * CFrame.new(0, 0, -12)
end

function cameraControl:start()
	while not workspace.CurrentCamera do
		workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	end

	local camera = workspace.CurrentCamera
	self.yaw = yawFrom(camera.CFrame)
	self.wantYaw = self.yaw
	self.pitch = 0
	self.wantPitch = 0

	player.CameraMode = Enum.CameraMode.LockFirstPerson
	if player:GetAttribute("HoldCameraLocked") == nil then
		player:SetAttribute("HoldCameraLocked", false)
	end

	local startingCharacter = player.Character
	if startingCharacter then
		task.spawn(function()
			self:hookChar(startingCharacter)
		end)
	end

	player.CharacterAdded:Connect(function(character)
		self:hookChar(character)
	end)

	RunService:BindToRenderStep("firstPersonCamera", Enum.RenderPriority.Camera.Value, function(dt)
		self:frame(dt)
	end)
end

return cameraControl
