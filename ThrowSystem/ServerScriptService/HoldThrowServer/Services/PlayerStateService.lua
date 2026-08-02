local playerState = {}
playerState.__index = playerState

function playerState.new()
	local self = setmetatable({}, playerState)
	self.byPlayer = {}
	self.byItem = {}
	return self
end

function playerState:add(player, data)
	if self.byPlayer[player] or self.byItem[data.item] then
		return false
	end

	self.byPlayer[player] = data
	self.byItem[data.item] = player
	return true
end

function playerState:get(player)
	return self.byPlayer[player]
end

function playerState:owner(item)
	return self.byItem[item]
end

function playerState:remove(player)
	local data = self.byPlayer[player]
	if not data then
		return nil
	end

	self.byPlayer[player] = nil
	if self.byItem[data.item] == player then
		self.byItem[data.item] = nil
	end

	return data
end

function playerState:all()
	return self.byPlayer
end

return playerState
