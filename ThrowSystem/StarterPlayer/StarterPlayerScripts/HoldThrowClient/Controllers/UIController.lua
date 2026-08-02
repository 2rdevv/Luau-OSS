local Players = game:GetService("Players")

local ui = {}
ui.__index = ui

local function getMultiplierColor(multiplier)
	local t = math.clamp((multiplier - 0.5) / (2 - 0.5), 0, 1)
	local red = Color3.fromRGB(255, 136, 0)
	local yellow = Color3.fromRGB(253, 253, 184)
	local green = Color3.fromRGB(80, 255, 80)

	if t < 0.5 then
		return red:Lerp(yellow, t * 2)
	end

	return yellow:Lerp(green, (t - 0.5) * 2)
end

function ui.new()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = playerGui:WaitForChild("HoldThrowUI")

	local self = setmetatable({}, ui)
	self.screen = screen
	self.cross = screen:WaitForChild("Crosshiar")
	self.chargeBox = nil
	self.fill = nil
	self:charge(false, 0)
	return self
end

function ui:findCharge()
	if self.chargeBox and self.chargeBox.Parent and self.fill and self.fill.Parent then
		return true
	end

	local charge = self.screen:FindFirstChild("ThrowCharge")
	if not charge or not charge:IsA("GuiObject") then
		return false
	end

	local fill = charge:FindFirstChild("Fill")
	if not fill or not fill:IsA("Frame") then
		return false
	end

	self.chargeBox = charge
	self.fill = fill
	return true
end

function ui:charge(show, amount)
	if not self:findCharge() then
		return
	end

	amount = math.clamp(amount or 0, 0, 1)
	self.chargeBox.Visible = show

	local width = math.floor(self.chargeBox.AbsoluteSize.X * amount + 0.5)
	local height = self.chargeBox.AbsoluteSize.Y
	local multiplier = 0.5 + amount * 1.5

	self.fill.Size = UDim2.fromOffset(width, height)
	self.fill.BackgroundColor3 = getMultiplierColor(multiplier)
end

return ui
