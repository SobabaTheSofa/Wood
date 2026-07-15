local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptSerivce = game:GetService("ServerScriptSerivce")

local FurnitureDictionary = require(script.Parent:WaitForChild("FurnitureDictionary"))
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Objectsloose = ReplicatedStorage:WaitForChild("LooseObjects")
local ObjectRegistry = ServerScriptSerivce.Server.ObjectRegistry

local Object = {}
Object.__index = Object

local function SerachObject(looseornot, instancepart, Owner)
	if looseornot then
		warn("a")
		return 
	else
	
	end
	for i in ipairs(ObjectRegistry[Owner])
		if i == instancepart then
			return i 
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

	--cleanup
	self.object.AncestryChanged:Connect(function(_, parent))
		if not parent then
			local object = SerachObject(FurnitureDictionary[self.ID][1], self.object, self.Owner)

			object = nil
	end


	return self
end


return Object
