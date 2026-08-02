local rayUtil = {}

function rayUtil.centerRay(camera, length, ignore)
	local size = camera.ViewportSize
	local ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
	local params = RaycastParams.new()

	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true

	return workspace:Raycast(ray.Origin, ray.Direction * length, params)
end

return rayUtil
