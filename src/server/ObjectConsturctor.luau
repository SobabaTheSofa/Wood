local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptSerivce = game:GetService("ServerScriptService")

local FurnitureDictionary = require(script.Parent:WaitForChild("FurnitureDictionary"))
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Objectsloose = ReplicatedStorage:WaitForChild("LooseObjects")
local ObjectRegistry = ServerScriptSerivce.Server.ObjectPlayerPlotRegistry

local Object = {}
Object.__index = Object

local function SerachObject(looseornot, instancepart, Owner)
	if looseornot then
		-- search work space
		return
	else
		local objects = ObjectRegistry[Owner]
		if not objects then
			return nil
		end

		for index, object in ipairs(objects) do
			if object == instancepart then
				return index
			end
		end
	end
end

function Object.new(ID, cframe, Player, Plot)
	local self = setmetatable({}, Object)

	self.ID = ID
	self.Object = nil
	self.Owner = Player
	self.Plot = Plot

	if FurnitureDictionary[ID][1] then
		self.Object = Objects:WaitForChild(FurnitureDictionary[ID][3]):Clone()

		if self.Object:IsA("Part") then
			self.Object.CFrame = cframe
			self.Object.Anchored = true
		else
			self.Object:PivotTo(cframe)
			self.Object.PrimaryPart.Anchored = true
		end

		self.Object.Parent = Plot.PlacedObjects
	else
		self.Object = Objectsloose:WaitForChild(FurnitureDictionary[ID][3]):Clone()

		if self.Object:IsA("Part") then
			self.Object.CFrame = cframe
		else
			self.Object:PivotTo(cframe)
		end

		self.Object.Anchored = false
		self.Object.Parent = workspace
	end

	--cleanup
	self.Object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			local index = SerachObject(FurnitureDictionary[self.ID][1], self.object, self.Owner)

			index = nil
		end
	end)

	return self
end

return Object
