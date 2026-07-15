local HttpService = game:GetService("HttpService")
local Object = require(script.Parent.ObjectConsturctor)

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

	return HttpService:JSONEncode({
		{ (cfi * TFC):GetComponents() },
		self.X,
		self.Y,
	})
end

function Sawmill:FromSerialise(ID, data, Player, Plot)
	local SerialTable = HttpService:JSONDecode(data)

	local relativeCF = CFrame.new(unpack(SerialTable[1]))
	local worldCF = Plot.PrimaryPart.CFrame * relativeCF

	return self.new(ID, worldCF, Player, Plot, SerialTable[2], SerialTable[3])
end

return Sawmill

--note to self add clean up functionlater i can not be botherrre
-- actualy put it in superclass object constructor