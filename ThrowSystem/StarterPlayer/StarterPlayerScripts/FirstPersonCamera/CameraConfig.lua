local config = {}

config.fov = 75
config.sensitivity = 0.00225
config.mouseSmooth = 24
config.pitchLimit = math.rad(86)
config.eyeLift = 0.08

config.walkRate = 7.5
config.walkSpeedRate = 0.2
config.bobX = 0.055
config.bobY = 0.065
config.bobPitch = math.rad(0.35)
config.bobSmooth = 11

config.breathRate = 1.35
config.breathAmount = 0.012
config.moveTilt = math.rad(1.4)
config.mouseTilt = 0.00045
config.maxMouseTilt = math.rad(1.1)
config.tiltSmooth = 10

config.jumpKick = 0.025
config.landMax = 0.13
config.landRecover = 12

return config
