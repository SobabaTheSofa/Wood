-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlacementClass = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementSystem"))

local ServerModules = ServerScriptService:WaitForChild("ServerModules")

local Plot = ReplicatedStorage:WaitForChild("Plot"):WaitForChild("Plot")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local LooseObjects = ReplicatedStorage:WaitForChild("LooseObjects")

local DataManager = require(ServerModules.DataManager)

local PlotManager = {}

PlotManager.PlayersPlots = {}

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

function PlotManager:Load(player)
	local ClonedPlot = Plot:Clone()
	ClonedPlot.Parent = workspace
	ClonedPlot:PivotTo(CFrame.new(0, -0.1, 0))

	local MasterPlotCF = ClonedPlot.PrimaryPart.CFrame
	local PlacedObjects = ClonedPlot.PlacedObjects

	self.PlayersPlots[player] = ClonedPlot

	-- Load furniture from profile
	local Profile = DataManager:WaitForProfile(player)
	if Profile then
		local Furniture = Profile.Data.Plot.Furniture or {}
		for cf, name in pairs(Furniture) do
			local Piece = Objects:FindFirstChild(name)
			if Piece then
				-- parse string into numbers
				local components = {}
				for num in string.gmatch(cf, "[^%s,]+") do
					components[#components + 1] = tonumber(num)
				end

				-- reconstruct CFrame
				local newCF = MasterPlotCF * CFrame.new(unpack(components))

				-- place the object (ensure parenting inside PlacementClass)
				PlacementClass:PlaceObject(name, newCF, true)
			end
		end
		print("proced to loose")
		print(Profile.Data.Plot.LooseObjects)
		local LooseObject = Profile.Data.Plot.LooseObjects or {}
		for cf, name in pairs(LooseObject) do
			local Piece = LooseObjects:FindFirstChild(name)
			if Piece then
				-- parse string into numbers
				local components = {}
				for num in string.gmatch(cf, "[^%s,]+") do
					components[#components + 1] = tonumber(num)
				end

				-- reconstruct CFrame
				local newCF = MasterPlotCF * CFrame.new(unpack(components))

				-- place the object (ensure parenting inside PlacementClass)
				PlacementClass:PlaceObject(name, newCF, false)
			end
		end
	end

	return ClonedPlot
end

return PlotManager
