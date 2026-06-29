local ZoneLibary = require(script.Parent:WaitForChild("ZoneDictionary"))
local TreeConstructor

local ZoneConstructor = {}
ZoneConstructor.__index = ZoneConstructor

function ZoneConstructor.new(Part, Zone: string)
	local self = setmetatable({}, ZoneConstructor)
	self.TreeRegistry = {}

	self.Parts = Part
	self.Running = true

	self.Zone = ZoneLibary[Zone]

	local RNG = Random.new()

	local function CountTable(tbl)
		local amount = 0

		for _ in pairs(tbl) do
			amount += 1
		end

		return amount
	end

	task.spawn(function()
		while self.Running and CountTable(self.TreeRegistry) < self.Zone.TreeLimit do
			local toSpawn

			if typeof(self.Parts) == "Instance" then
				toSpawn = self.Parts
			elseif type(self.Parts) == "table" then
				local weightedParts = {}

				for _, part in ipairs(self.Parts) do
					table.insert(weightedParts, {
						Part = part,
						SurfaceArea = part.Size.X * part.Size.Z,
					})
				end

				local totalWeight = 0

				for _, data in ipairs(weightedParts) do
					totalWeight += data.SurfaceArea
				end

				local randomNumber = RNG:NextNumber(0, totalWeight)
				local counter = 0

				for _, data in ipairs(weightedParts) do
					counter += data.SurfaceArea

					if randomNumber <= counter then
						toSpawn = data.Part
						break
					end
				end
			end

			if toSpawn then
				local Position = self:GetPosition(toSpawn, self.Zone.MinimumSpawnDistance, self.TreeRegistry)

				if Position then
					local Tree = TreeConstructor.new("Oak", CFrame.new(Position))
					self.TreeRegistry[Tree] = {
						Tree = Tree,
						Position = Position,
					}

					task.spawn(function()
						for i = 1, 1000 do
							Tree:Grow()
							task.wait(0.1)
						end
					end)
				end
			end

			task.wait(0.1)
		end
	end)

	return self
end

function ZoneConstructor:GetPosition(Part: BasePart, MinSpawnDis: number, TreeRegistry)
	local RNG = Random.new()
	local startTime = os.clock()
	local timeOut = 5

	local toSpawnPosition

	repeat
		local localPosition = Vector3.new(
			RNG:NextNumber(-Part.Size.X / 2 + MinSpawnDis, Part.Size.X / 2 - MinSpawnDis),
			Part.Size.Y / 2,
			RNG:NextNumber(-Part.Size.Z / 2 + MinSpawnDis, Part.Size.Z / 2 - MinSpawnDis)
		)

		local position = Part.CFrame:PointToWorldSpace(localPosition)

		local canSpawn = true

		for _, tree in pairs(TreeRegistry) do
			if (tree.Position - position).Magnitude < MinSpawnDis then
				canSpawn = false
				break
			end
		end

		if canSpawn then
			toSpawnPosition = position
		end
		task.wait()
	until toSpawnPosition ~= nil or os.clock() - startTime > timeOut

	return toSpawnPosition
end

function ZoneConstructor:Init(BaseEnv)
	TreeConstructor = BaseEnv

	return self
end

return ZoneConstructor
