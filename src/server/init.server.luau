local TreeRegistry = require(script:WaitForChild("TreeRegistry"))
local Constructor = require(script:WaitForChild("TreeConstructor")):Init(TreeRegistry)
local ZoneConstructor = require(script:WaitForChild("ZoneConStructor")):Init(Constructor)

local TCSS = require(script:WaitForChild("TreeChoppingSystemServer"))

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

--ahfafoefaief

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Libaries
local Libaries = script:WaitForChild("ServerLibaries")

-- ProfileStore
local ProfileStore = require(Libaries:WaitForChild("ProfileStore"))

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local DataManager = require(script.DataManager)
local PlotManager = require(script.PlotManager)
local Template = require(Libaries.GeneralPlayerDataTemplate)

-- Access profile store
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

local PlacementClass = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementSystem"):WaitForChild("PlacmentSystemMain")
)
local PlayersPlots = {}

local Plot = ReplicatedStorage:WaitForChild("Plot"):WaitForChild("Plot")
local Objects = ReplicatedStorage:WaitForChild("Objects")

--  Remotes
local PlacementRemotes = ReplicatedStorage:WaitForChild("PlacementRemotes")
local CBPlacement = PlacementRemotes:WaitForChild("CBPlacement")
local DSPlacement = PlacementRemotes:WaitForChild("DSPlacement")
local InitPlacement = PlacementRemotes:WaitForChild("InitPlacement")
local ConstructPlot = PlacementRemotes:WaitForChild("ConstructPlot")
local DragReuqest = PlacementRemotes:WaitForChild("DragRequest")

-- Add leaderstats and synchronize player data
local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync())) end

-- Creates and stores a profile
local function PlayerAdded(player: Player)
	-- Start a new profile session
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Sanity check to ensure profile exists
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing data variables from template

		-- Handles session-locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data error occured. Please rejoin.")
		end)

		-- Save profile for later use
		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)
		else
			profile:EndSession()
		end
	else
		-- Server shuts down while player is joining
		player:Kick("Data error occured. Please rejoin.")
	end
end

-- Early joiners
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

DSPlacement.OnServerEvent:Connect(function(player, func, ...)
	if PlacementClass[func] then
		PlacementClass[func](nil, ...)
	end
end)

CBPlacement.OnServerEvent:Connect(function(player, func, ...)
	if PlacementClass[func] then
		PlacementClass[func](nil, ...)
	end
end)

--// Plot construction
ConstructPlot.OnServerInvoke = function(player, plotNumber)
	return PlotManager:Load(player, plotNumber)
end

--// Player leaving (save)
Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	--profile.Data.Plot.Furniture = PlotManager:SerialiseFurniture(player)
	--profile.Data.Plot.LooseObjects = PlotManager:SerialiseLoose(player)

	profile:EndSession()
	DataManager.Profiles[player] = nil
	PlotManager:Unload(player)
end)

DragReuqest.OnServerInvoke = function(player, object, requestionPickup)
	if not object or not object.Parent then
		return
	end

	if requestionPickup and not object:GetAttribute("DraggedBy") then
		object:SetAttribute("DraggedBy", player.UserId)
		object:SetNetworkOwner(player)
		return true
	elseif not requestionPickup and object:GetAttribute("DraggedBy") == player.UserId then
		object:SetAttribute("DraggedBy", nil)
		object:SetNetworkOwner(nil)
		return true
	end

	return false
end
