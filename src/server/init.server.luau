local Constructor, TCSS = require(script:WaitForChild("TreeConstructor")):Init()
local ZoneConstructor = require(script:WaitForChild("ZoneConStructor")):Init(Constructor)

game:GetService("ReplicatedStorage"):WaitForChild("A1").OnServerEvent:Connect(function(player, hitData, Notch)
	if hitData then
		local result = {
			Instance = hitData.Instance,
			Position = hitData.Position,
			Normal = hitData.Normal,
			Material = hitData.Material,
			Distance = hitData.Distance,
			Power = 1,
		}
		TCSS:AttemptIntersection(result)
	end

	if Notch then
		TCSS:IntersectFromNotch(Notch)
	end
end)

local Zone = ZoneConstructor.new({
	workspace.aaa,
	--workspace.bbb,
	workspace.ccc,
}, "TestZone1")
