local collision = {}
collision.__index = collision

function collision.new(resolver)
	return setmetatable({resolver = resolver}, collision)
end

function collision:stopCharacterHits(item, character, parent)
	local folder = Instance.new("Folder")
	folder.Name = "noOwnerCollision"
	folder.Parent = parent

	local itemParts = self.resolver.parts(item)
	local characterParts = {}

	for _, thing in character:GetDescendants() do
		if thing:IsA("BasePart") then
			table.insert(characterParts, thing)
		end
	end

	for _, itemPart in itemParts do
		for _, bodyPart in characterParts do
			local noHit = Instance.new("NoCollisionConstraint")
			noHit.Part0 = itemPart
			noHit.Part1 = bodyPart
			noHit.Parent = folder
		end
	end

	return folder
end

return collision
