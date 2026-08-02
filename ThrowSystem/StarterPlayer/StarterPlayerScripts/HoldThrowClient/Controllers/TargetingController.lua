local Players = game:GetService("Players")

local player = Players.LocalPlayer

local targeter = {}
targeter.__index = targeter

function targeter.new(interaction, resolver, rayUtil)
	local self = setmetatable({}, targeter)
	self.interaction = interaction
	self.resolver = resolver
	self.rayUtil = rayUtil
	return self
end

function targeter:get()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local ignore = {}
	local rayLength = self.interaction.grabDistance

	if player.Character then
		table.insert(ignore, player.Character)
		local head = player.Character:FindFirstChild("Head")
		if head then
			rayLength += (camera.CFrame.Position - head.Position).Magnitude + 1
		end
	end

	local hit = self.rayUtil.centerRay(camera, rayLength, ignore)
	if not hit then
		return nil
	end

	local item = self.resolver.fromPart(hit.Instance)
	if item and self.resolver.root(item) then
		return item
	end

	return nil
end

return targeter
