local highlighter = {}
highlighter.__index = highlighter

function highlighter.new()
	local self = setmetatable({}, highlighter)
	self.looked = nil
	self.held = nil

	local light = Instance.new("Highlight")
	light.Name = "itemLight"
	light.DepthMode = Enum.HighlightDepthMode.Occluded
	light.FillColor = Color3.fromRGB(255, 255, 255)
	light.OutlineColor = Color3.fromRGB(255, 255, 255)
	light.FillTransparency = 0.82
	light.OutlineTransparency = 0
	light.Enabled = false
	light.Parent = workspace
	self.light = light

	return self
end

function highlighter:refresh()
	if self.held and not self.held.Parent then
		self.held = nil
	end

	if self.looked and not self.looked.Parent then
		self.looked = nil
	end

	local item = self.held or self.looked
	self.light.Adornee = item
	self.light.Enabled = item ~= nil
end

function highlighter:setLooked(item)
	self.looked = item
	self:refresh()
end

function highlighter:setHeld(item)
	self.held = item
	self:refresh()
end

function highlighter:getLooked()
	return self.looked
end

return highlighter
