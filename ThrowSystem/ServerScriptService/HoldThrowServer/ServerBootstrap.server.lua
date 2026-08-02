local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverFolder = script.Parent
local serviceFolder = serverFolder:WaitForChild("Services")
local securityFolder = serverFolder:WaitForChild("Security")

local system = ReplicatedStorage:WaitForChild("HoldThrowSystem")
local remoteFolder = system:WaitForChild("Remotes")
local shared = system:WaitForChild("Shared")
local configs = shared:WaitForChild("Config")

local remotes = {
	GrabRequest = remoteFolder:WaitForChild("GrabRequest"),
	HoldUpdate = remoteFolder:WaitForChild("HoldUpdate"),
	ReleaseRequest = remoteFolder:WaitForChild("ReleaseRequest"),
	ChargeRequest = remoteFolder:WaitForChild("ChargeRequest"),
	ThrowRequest = remoteFolder:WaitForChild("ThrowRequest"),
	StateChanged = remoteFolder:WaitForChild("StateChanged"),
}

local interaction = require(configs:WaitForChild("InteractionConfig"))
local physics = require(configs:WaitForChild("PhysicsConfig"))
local throwConfig = require(configs:WaitForChild("ThrowConfig"))
local names = require(shared:WaitForChild("Types"))
local resolver = require(shared:WaitForChild("ItemResolver"))

local PlayerStateService = require(serviceFolder:WaitForChild("PlayerStateService"))
local CollisionService = require(serviceFolder:WaitForChild("CollisionService"))
local HoldService = require(serviceFolder:WaitForChild("HoldService"))
local GrabService = require(serviceFolder:WaitForChild("GrabService"))
local RotationService = require(serviceFolder:WaitForChild("RotationService"))
local ThrowService = require(serviceFolder:WaitForChild("ThrowService"))
local RequestValidator = require(securityFolder:WaitForChild("RequestValidator"))
local RateLimiter = require(securityFolder:WaitForChild("RateLimiter"))

local states = PlayerStateService.new()
local limiter = RateLimiter.new()
local validator = RequestValidator.new(interaction, physics, resolver)
local collisions = CollisionService.new(resolver)
local hold = HoldService.new(states, collisions, physics, resolver, names, remotes.StateChanged)
local grab = GrabService.new(states, hold, validator, limiter, names, remotes.StateChanged)
local rotation = RotationService.new(states, hold, validator, limiter)
local thrower = ThrowService.new(states, hold, validator, limiter, throwConfig, names)

remotes.GrabRequest.OnServerEvent:Connect(function(player, item)
	grab:request(player, item)
end)

remotes.HoldUpdate.OnServerEvent:Connect(function(player, cf)
	rotation:update(player, cf)
end)

remotes.ReleaseRequest.OnServerEvent:Connect(function(player)
	if limiter:allow(player, "release", 0.06) then
		hold:release(player, names.dropped)
	end
end)

remotes.ChargeRequest.OnServerEvent:Connect(function(player, started)
	thrower:charge(player, started)
end)

remotes.ThrowRequest.OnServerEvent:Connect(function(player, direction)
	thrower:throw(player, direction)
end)

local function hookPlayer(player)
	player.CharacterRemoving:Connect(function()
		hold:release(player, names.released)
	end)
end

for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

Players.PlayerAdded:Connect(hookPlayer)

Players.PlayerRemoving:Connect(function(player)
	hold:release(player, names.released, nil, true)
	limiter:clear(player)
end)

hold:startWatching()
