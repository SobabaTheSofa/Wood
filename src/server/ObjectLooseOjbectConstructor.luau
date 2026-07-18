local HttpService = game:GetService("HttpService")
local Object = require(script.Parent.ObjectConsturctor)

local loose = {}
loose.__index = loose

function loose.new(ID, cframe, Player, Plot)
    local self = Object.new(ID, cframe, Player, Plot)

    setmetatable(self, loose)

    return self
end

function loose:Serialise()
    local cfi = self.Plot.PrimaryPart.CFrame:Inverse()
    local TFC

    if self.Object:IsA("Model") and self.Object.PrimaryPart then
		TFC = self.Object.PrimaryPart.CFrame
	elseif self.Object:IsA("BasePart") then
		TFC = self.Object.CFrame
	else
		return
	end

    return HttpService:JSONDecode(
		{ (cfi * TFC):GetComponents() })

end

function loose:FromSerialise(ID, data, Player, Plot)
	local SerialTable = HttpService:JSONDecode(data)

	local relativeCF = CFrame.new(unpack(SerialTable[1]))
	local worldCF = Plot.PrimaryPart.CFrame * relativeCF

	return self.new(ID, worldCF, Player, Plot)

return loose