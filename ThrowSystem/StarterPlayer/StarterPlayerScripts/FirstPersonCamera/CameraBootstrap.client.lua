local folder = script.Parent

local config = require(folder:WaitForChild("CameraConfig"))
local CameraMotion = require(folder:WaitForChild("CameraMotion"))
local CameraController = require(folder:WaitForChild("CameraController"))

local motion = CameraMotion.new(config)
local camera = CameraController.new(config, motion)

camera:start()
