local DataManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Store profiles from ProfileStore
DataManager.Profiles = {}
DataManager.GeneralData = {}

function DataManager:WaitForProfile(player, timeout)
	timeout = timeout or 5
	local start = tick()
	while not self.Profiles[player] and tick() - start < timeout do
		task.wait()
	end
	return self.Profiles[player]
end

return DataManager
