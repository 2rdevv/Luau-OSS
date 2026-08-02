local validator = {}
validator.__index = validator

local function goodNumber(number)
	return type(number) == "number" and number == number and math.abs(number) < 1000000
end

local function goodCFrame(cf)
	if typeof(cf) ~= "CFrame" then
		return false
	end

	local values = {cf:GetComponents()}
	for _, number in values do
		if not goodNumber(number) then
			return false
		end
	end

	return true
end

local function goodVector(vec)
	return typeof(vec) == "Vector3"
		and goodNumber(vec.X)
		and goodNumber(vec.Y)
		and goodNumber(vec.Z)
end

function validator.new(interaction, physics, resolver)
	local self = setmetatable({}, validator)
	self.interaction = interaction
	self.physics = physics
	self.resolver = resolver
	return self
end

function validator:character(player)
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local bodyRoot = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 or not head or not bodyRoot then
		return nil
	end

	return character, head, bodyRoot
end

function validator:canGrab(player, item)
	local root = self.resolver.root(item)
	if not root then
		return false
	end

	local character, head = self:character(player)
	if not character then
		return false
	end

	local toward = root.Position - head.Position
	if toward.Magnitude > self.interaction.grabDistance then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local result = workspace:Raycast(head.Position, toward, params)
	if not result or not result.Instance:IsDescendantOf(item) then
		return false
	end

	return true, root
end

function validator:target(player, data, cf)
	if not data or not data.root or not data.root.Parent or not goodCFrame(cf) then
		return false
	end

	local character, head = self:character(player)
	if not character then
		return false
	end

	local distance = (cf.Position - head.Position).Magnitude
	if distance < self.interaction.holdMin - 1.5 then
		return false
	end

	if distance > self.interaction.holdMax + 2.5 then
		return false
	end

	return true
end

function validator:direction(direction)
	return goodVector(direction) and direction.Magnitude > 0.5
end

return validator
