local UserInputService = game:GetService("UserInputService")

local inputs = {}
inputs.__index = inputs

function inputs.new(config, calls, cleaner)
	local self = setmetatable({}, inputs)
	self.config = config
	self.calls = calls
	self.cleaner = cleaner
	self.grabHeld = false
	self.throwHeld = false
	return self
end

function inputs:start()
	self.cleaner:add(UserInputService.InputBegan:Connect(function(input, used)
		if used then
			return
		end

		if input.UserInputType == self.config.grab then
			self.grabHeld = true
			self.calls.grabDown()
		elseif input.KeyCode == self.config.throw then
			self.throwHeld = true
			self.calls.throwDown()
		end
	end))

	self.cleaner:add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == self.config.grab and self.grabHeld then
			self.grabHeld = false
			self.calls.grabUp()
		elseif input.KeyCode == self.config.throw and self.throwHeld then
			self.throwHeld = false
			self.calls.throwUp()
		end
	end))

	self.cleaner:add(UserInputService.InputChanged:Connect(function(input, used)
		if used then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self.calls.wheel(input.Position.Z)
		end
	end))

	self.cleaner:add(UserInputService.WindowFocusReleased:Connect(function()
		if self.grabHeld then
			self.grabHeld = false
			self.calls.grabUp()
		end

		if self.throwHeld then
			self.throwHeld = false
			self.calls.throwUp()
		end
	end))
end

function inputs:isGrabDown()
	return self.grabHeld
end

return inputs
