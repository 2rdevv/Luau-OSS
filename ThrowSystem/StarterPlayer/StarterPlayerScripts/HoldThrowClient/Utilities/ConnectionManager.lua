local manager = {}
manager.__index = manager

function manager.new()
	return setmetatable({stuff = {}}, manager)
end

function manager:add(thing)
	table.insert(self.stuff, thing)
	return thing
end

function manager:clear()
	for i = #self.stuff, 1, -1 do
		local thing = self.stuff[i]

		if typeof(thing) == "RBXScriptConnection" then
			thing:Disconnect()
		elseif typeof(thing) == "Instance" then
			thing:Destroy()
		elseif type(thing) == "function" then
			thing()
		end

		self.stuff[i] = nil
	end
end

return manager
