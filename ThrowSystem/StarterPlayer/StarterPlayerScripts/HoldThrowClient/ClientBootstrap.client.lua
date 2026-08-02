local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local holder = script.Parent
local controllers = holder:WaitForChild("Controllers")
local utilities = holder:WaitForChild("Utilities")

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

local inputConfig = require(configs:WaitForChild("InputConfig"))
local interaction = require(configs:WaitForChild("InteractionConfig"))
local throwConfig = require(configs:WaitForChild("ThrowConfig"))
local names = require(shared:WaitForChild("Types"))
local resolver = require(shared:WaitForChild("ItemResolver"))

local ConnectionManager = require(utilities:WaitForChild("ConnectionManager"))
local RaycastUtility = require(utilities:WaitForChild("RaycastUtility"))
local InputController = require(controllers:WaitForChild("InputController"))
local TargetingController = require(controllers:WaitForChild("TargetingController"))
local HoldController = require(controllers:WaitForChild("HoldController"))
local RotationController = require(controllers:WaitForChild("RotationController"))
local ThrowController = require(controllers:WaitForChild("ThrowController"))
local UIController = require(controllers:WaitForChild("UIController"))
local HighlightController = require(controllers:WaitForChild("HighlightController"))

local cleaner = ConnectionManager.new()
local ui = UIController.new()
local targeting = TargetingController.new(interaction, resolver, RaycastUtility)
local holding = HoldController.new(remotes, interaction, inputConfig.scrollStep)
local turning = RotationController.new(inputConfig, cleaner)
local throwing = ThrowController.new(remotes, throwConfig, holding, ui)
local highlighting = HighlightController.new()
local inputController
local lookClock = 0

local calls = {}

function calls.grabDown()
	if holding:isHolding() then
		return
	end

	local item = targeting:get()
	highlighting:setLooked(item)
	if item then
		holding:ask(item)
	end
end

function calls.grabUp()
	throwing:cancel(true)
	turning:disable()
	holding:drop()
	highlighting:setHeld(nil)
end

function calls.throwDown()
	throwing:start()
end

function calls.throwUp()
	local camera = workspace.CurrentCamera
	if not camera then
		throwing:cancel(true)
		return
	end

	if throwing:finish(camera.CFrame.LookVector) then
		highlighting:setHeld(nil)
	end
end

function calls.wheel(amount)
	holding:changeDistance(amount)
end

inputController = InputController.new(inputConfig, calls, cleaner)
inputController:start()

cleaner:add(remotes.StateChanged.OnClientEvent:Connect(function(state, item)
	if state == names.grabbed then
		local root = resolver.root(item)
		if not root then
			holding:drop()
			return
		end

		holding:accepted(item, root)
		turning:enable(root.CFrame)
		highlighting:setHeld(item)

		if not inputController:isGrabDown() then
			turning:disable()
			holding:drop()
			highlighting:setHeld(nil)
		end
	elseif state == names.denied then
		holding:denied()
	else
		holding:clear()
		turning:disable()
		throwing:cancel(false)
		highlighting:setHeld(nil)
	end
end))

cleaner:add(RunService.RenderStepped:Connect(function(dt)
	throwing:update()

	if not holding:isHolding() then
		lookClock += dt
		if lookClock >= 0.05 then
			lookClock = 0
			highlighting:setLooked(targeting:get())
		end
	end
end))

cleaner:add(RunService.PreSimulation:Connect(function(dt)
	if not holding:isHolding() then
		return
	end

	local character = player.Character
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local cf = holding:target(character, camera, turning:get(), dt)
	holding:update(cf)
end))
