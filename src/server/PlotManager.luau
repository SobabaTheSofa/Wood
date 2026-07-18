-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlacementClass = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementSystem"):WaitForChild("PlacmentSystemMain")
)

local Plot = ReplicatedStorage:WaitForChild("Plot"):WaitForChild("Plot") -- be constructed per person
local Objects = ReplicatedStorage:WaitForChild("Objects")
local LooseObjects = ReplicatedStorage:WaitForChild("LooseObjects")

local DataManager = require(script.Parent.DataManager)
local ObjectSawmillConstructor = require(script.Parent.ObjectSawmillConstructor)

local Labaries = script.Parent:WaitForChild("ServerLibaries")

local ProfileStore = require(Labaries.ProfileStore)
local PlotTemplate = require(Labaries.Template)

local FurnitureDictionary = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleDictionaries"):WaitForChild("FurnitureDictionary")
)

local PlotManager = {}

local FixedPlotPosition = {
	Vector3.new(0, 0, 0),
}

PlotManager.hasTaken = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
}
PlotManager.PlayersPlots = {}
PlotManager.PlayersProfiles = {}

local function GetPlayerPlot(plrname)
	local plotData = PlotManager.PlayersPlots[plrname]
	return plotData.PlotNumber
end

local function LoadObjects(ID, ...)
	local ConstructorID = FurnitureDictionary[ID][2]
	local Constructor = require(script.Parent:WaitForChild("Object" .. ConstructorID .. "Constructor"))

	local Object = Constructor:FromSerialise(ID, ...)

	return Object
end

local function GetStoreName(plotNumber: number)
	if plotNumber == 1 or plotNumber == 2 or plotNumber == 3 then
		return ((RunService:IsStudio() and "Test" or "Live") .. "_Plot_" .. tostring(plotNumber))
	else
		warn("Invalid plot number provided. Defaulting to 'Test_Plot_1'.")
		return ((RunService:IsStudio() and "Test" or "Live") .. "_Plot_1")
	end
end

-- to be remove, object superclass has it own serialisatioin function this is uneeded
function PlotManager:SerialiseFurniture(player)
	local PlayersPlot = self.PlayersPlots[player]
	if not PlayersPlot or not PlayersPlot.PrimaryPart then
		return
	end

	local cfi = PlayersPlot.PrimaryPart.CFrame:Inverse()
	local PlacedObjects = PlayersPlot.PlacedObjects:GetChildren()

	local serial = {}

	for i = 1, #PlacedObjects do
		local obj = PlacedObjects[i]
		local TFC

		if obj:IsA("Model") and obj.PrimaryPart then
			TFC = obj.PrimaryPart.CFrame
		elseif obj:IsA("BasePart") then
			TFC = obj.CFrame
		else
			warn("Skipping object, invalid type:", obj.Name, obj.ClassName)
			continue
		end

		serial[tostring(cfi * TFC)] = obj.Name
	end

	return serial
end

function PlotManager:SerialiseLoose(player)
	local PlayersPlot = self.PlayersPlots[player]
	if not PlayersPlot or not PlayersPlot.PrimaryPart then
		return
	end

	local cfi = PlayersPlot.PrimaryPart.CFrame:Inverse()
	local LooseObjects = game.Workspace:GetPartsInPart(PlayersPlot.PlotBoundries)

	local serial = {}

	for i = 1, #LooseObjects do
		local obj
		local TFC
		if not LooseObjects[i].Anchored then
			obj = LooseObjects[i]
			print(obj.Anchored)
			if obj:IsA("Model") and obj.PrimaryPart then
				TFC = obj.PrimaryPart.CFrame
			elseif obj:IsA("BasePart") then
				TFC = obj.CFrame
			else
				warn("Skipping object, invalid type:", obj.Name, obj.ClassName)
				continue
			end

			serial[tostring(cfi * TFC)] = obj.Name
		else
			continue
		end
	end

	return serial
end

function PlotManager:Serialise(player) end

function PlotManager:Load(player, plotNumber)
	if self.PlayersProfiles[player] or self.hasTaken[plotNumber] == true then
		warn("Player already has a plot loaded, or plot has been taken.")
		return
		--return self.PlayersProfiles[player]
		--elseif self.PlayersPlots[plotNumber] then -- add check function later
		--	warn("Plot already taken.")
		--	return
	else
		local PlayerStore = ProfileStore.New(GetStoreName(plotNumber), PlotTemplate)
		local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing data variables from template

			-- Handles session-locking
			profile.OnSessionEnd:Connect(function()
				self.PlayersProfiles[player] = nil
				player:Kick("Data error occured. Please rejoin.")
			end)

			-- Save profile for later use
			if player.Parent == Players then
				self.PlayersProfiles[player] = profile
				--Initialize(player, profile)
			else
				profile:EndSession()
			end
		else
			-- Server shuts down while player is joining
			player:Kick("Data error occured. Please rejoin.")
		end

		-- Load plot
		local ClonedPlot = Plot:Clone()
		ClonedPlot.Parent = workspace
		--print(FixedPlotPosition[1]) --get it down there
		ClonedPlot:PivotTo(CFrame.new(0, 0, 0))

		local MasterPlotCF = ClonedPlot.PrimaryPart.CFrame
		local PlacedObjects = ClonedPlot.PlacedObjects

		self.PlayersPlots[player] = {
			Plot = ClonedPlot,
			PlotNumber = plotNumber,
		}
		print(PlacementClass.PlotRegistry)
		print(player)
		PlacementClass.PlotRegistry[player] = {

			Plot = ClonedPlot,
			Furniture = {},
			LooseObject = {},
			Sawmill = {},

			-- should be handle why loop through furniture dictionaery
		}
		--Load sawmill
		local Profile = self.PlayersProfiles[player]
		print(profile)
		if Profile then
			--for i in ipairs(Profile.DataPlot) do
			--	for STable, ID in pairs(Profile.DataPlot[i] or {}) do
			--		local OBJ = LoadObjects(ID, STable, player, PlacementClass.PlotRegistry[player].Plot)
			--		table.insert(PlacementClass.PlotRegistry[player].tostring(FurnitureDictionary[ID][2]), OBJ)
			--	end
			--end

			for STable, ID in pairs(Profile.Data.Plot.Sawmill or {}) do
				local OBJ = LoadObjects(ID, STable, player, PlacementClass.PlotRegistry[player].Plot)

				table.insert(PlacementClass.PlotRegistry[player].Sawmill, OBJ)
			end
		end

		-- Load furniture from profile
		--local Profile = self.PlayersProfiles[player]
		--if Profile then
		--	local Furniture = Profile.Data.Plot.Furniture or {}
		--	for cf, name in pairs(Furniture) do
		--		local Piece = Objects:FindFirstChild(name)
		--		if Piece then
		--			-- parse string into numbers
		--			local components = {}
		--			for num in string.gmatch(cf, "[^%s,]+") do
		--				components[#components + 1] = tonumber(num)
		--			end
		--
		--			-- reconstruct CFrame
		--			local newCF = MasterPlotCF * CFrame.new(unpack(components))
		--
		--			-- place the object (ensure parenting inside PlacementClass)
		--			PlacementClass:PlaceObject(name, newCF, true)
		--		end
		--	end
		--	print("proced to loose")
		--	print(Profile.Data.Plot.LooseObjects)
		--	local LooseObject = Profile.Data.Plot.LooseObjects or {}
		--	for cf, name in pairs(LooseObject) do
		--		local Piece = LooseObjects:FindFirstChild(name)
		--		if Piece then
		--			-- parse string into numbers
		--			local components = {}
		--			for num in string.gmatch(cf, "[^%s,]+") do
		--				components[#components + 1] = tonumber(num)
		--			end
		--
		--			-- reconstruct CFrame
		--			local newCF = MasterPlotCF * CFrame.new(unpack(components))
		--
		--			-- place the object (ensure parenting inside PlacementClass)
		--			PlacementClass:PlaceObject(name, newCF, false)
		--		end
		--	end
		--end

		return ClonedPlot
	end
end

function PlotManager:Unload(player)
	local profile = self.PlayersProfiles[player]
	if not profile then
		warn("Player does not have a plot loaded.")
		return
	end

	--print(profile.Data.Data)
	--profile.Data.Plot.Furniture = PlotManager:SerialiseFurniture(player)
	--profile.Data.Plot.LooseObjects = PlotManager:SerialiseLoose(player)

	for i, value in pairs(PlacementClass.PlotRegistry[player].Sawmill) do
		print(value)
		profile.Data.Plot.Sawmill[value:Serialise()] = value.ID
	end

	self.PlayersPlots[player].Plot:Destroy()
	self.hasTaken[GetPlayerPlot(player)] = false
	self.PlayersPlots[player] = nil

	profile:EndSession()
	self.PlayersProfiles[player] = nil
end

return PlotManager
