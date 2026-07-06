local Object = require(script.Parent:WaitForChild("ObjectConstructor"))

local Sawmill = {}
Sawmill.__index = Sawmill

setmetatable(Sawmill, { __index = Object })

function Sawmill.new(ID, cframe, Player, Plot, X, Y)
	local self = Object.new(ID, cframe, Player, Plot)

	setmetatable(self, Sawmill)

	self.X = X or 1
	self.Y = Y or 1

	return self
end

function Sawmill:Serialise()
	local cfi = self.Plot.PrimaryPart.CFrame:Inverse()
	local TFC

	if self.Object:IsA("Model") and self.Object.PrimaryPart then
		TFC = self.Object.PrimaryPart.CFrame
	elseif self.Object:IsA("BasePart") then
		TFC = self.Object.CFrame
	else
		return
	end

	local serial = {
		tostring(cfi * TFC),
		self.X,
		self.Y,
	}

	return serial
end

function Sawmill:FromSerialise(ID, SerialTable, Player, Plot)
	local components = {}
	for num in string.gmatch(SerialTable[1], "[^%s,]+") do
		components[#components + 1] = tonumber(num)
	end

	local newCF = Plot.CFrame * CFrame.new(unpack(components))

	self.new(ID, newCF, Player, Plot, SerialTable[2], SerialTable[3])
end
