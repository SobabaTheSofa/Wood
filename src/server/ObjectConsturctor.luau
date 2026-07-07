local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnitureDictionary = require(script.Parent:WaitForChild("FurnitureDictionary"))
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Objectsloose = ReplicatedStorage:WaitForChild("LooseObjects")

local Object = {}
Object.__index = Object

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

		self.Object.Parent = Plot
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

	return self
end

return Object
