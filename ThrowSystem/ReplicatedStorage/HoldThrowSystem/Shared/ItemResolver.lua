local itemFolder = workspace:WaitForChild("HoldableItems")

local resolver = {}

function resolver.fromPart(part)
	local at = part

	while at and at ~= itemFolder do
		if at.Parent == itemFolder and at:IsA("Model") then
			return at
		end

		at = at.Parent
	end

	return nil
end

function resolver.root(item)
	if typeof(item) ~= "Instance" or not item:IsA("Model") then
		return nil
	end

	if item.Parent ~= itemFolder then
		return nil
	end

	local root = item:FindFirstChild("Root")
	if root and root:IsA("MeshPart") then
		return root
	end

	for _, child in item:GetChildren() do
		if child:IsA("MeshPart") then
			return child
		end
	end

	return nil
end

function resolver.parts(item)
	local list = {}

	for _, thing in item:GetDescendants() do
		if thing:IsA("BasePart") then
			table.insert(list, thing)
		end
	end

	return list
end

function resolver.folder()
	return itemFolder
end

return resolver
