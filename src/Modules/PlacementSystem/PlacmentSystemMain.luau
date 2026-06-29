-- CREATED BY TAVEPLE --
-- OFFICIALLY PUBLISHED 2023/03/25 --

--[[
	This code needs a lot of work, I had written this a long time ago, you can change it however you like. However,
	
	IF YOU ARE TO USE THIS PLACEMENT SYSTEM OR PULL CODE FROM IT, INCLUDE ME IN THE CREDITS OF YOUR GAME.
	
	This is all I ask, I choose to make this open sourced for people to use for free. Enjoy.
]]

local Placement = {}

local Calculations = require(script.Parent.SharedCalculations)
local KeybindToFunction = require(script.Parent:WaitForChild("KeybindToFunctions"))
--local UI = require(script.UI)

local RS = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local isServer = RS:IsServer()

local Objects = ReplicatedStorage:WaitForChild("Objects")
local LooseObjects = ReplicatedStorage:WaitForChild("LooseObjects")
local XYZGizmo = ReplicatedStorage:WaitForChild("XYZGizmo")
local RotationGizmo = ReplicatedStorage:WaitForChild("RotationGizmo")

local PlacementRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("PlacementRemotes")
local ObjectsFolder = ReplicatedStorage:WaitForChild("Objects")

local CBPlacement = PlacementRemotes:WaitForChild("CBPlacement")
local DSPlacement = PlacementRemotes:WaitForChild("DSPlacement")
local InitPlacement = PlacementRemotes:WaitForChild("InitPlacement")
local ConstructPlot = PlacementRemotes:WaitForChild("ConstructPlot")

local Mouse
local Camera

if not isServer then
	Mouse = Players.LocalPlayer:GetMouse()
	Camera = workspace.CurrentCamera
end

local GridSizes = { 1, 0.5, 0.25 } -- Constants
local Keybinds = {}

local InpBegan

Placement.Properties = {
	Plot = nil,

	GridSizeSlot = 1, -- Setting it to be the first slot of the gridsizes table

	GridSize = 0.5,
	MaxBuildHeight = 20,

	Rotation = CFrame.Angles(0, 0, 0),
	RotationAngles = Vector3.new(0, 0, 0),

	BuildModeActive = false,
	AutomaticallyPlacing = false,
	DeleteMode = false,
	EditMode = false,

	CanPlace = false,
	ForceUpright = true,

	FollowMouse = true,
	ManualAxis = false,
	ManualRotation = false,
}

Placement.Constants = {
	RotationIncrement = math.pi / 2, -- 90 degrees
}

Placement.IgnoreList = {}

local function GetObject(ObjectName)
	local Object = ObjectsFolder:FindFirstChild(ObjectName)
	if not Object then
		return
	end

	local ObjectClone = Object:Clone()
	ObjectClone.Parent = workspace.Terrain

	local GizmoClone = XYZGizmo:Clone()
	local RotationGizmoClone = RotationGizmo:Clone()

	GizmoClone.Parent = ObjectClone
	RotationGizmoClone.Parent = ObjectClone

	local function GetObjectCFrame()
		if ObjectClone:IsA("Model") then
			return ObjectClone:GetPivot()
		else
			return ObjectClone.CFrame
		end
	end

	local function UpdateGizmo()
		if not ObjectClone or not ObjectClone.Parent then
			return
		end
		if not GizmoClone or not GizmoClone.Parent then
			return
		end
		if not RotationGizmoClone or not RotationGizmoClone.Parent then
			return
		end

		local objectCF = GetObjectCFrame()

		GizmoClone:PivotTo(objectCF)
		RotationGizmoClone:PivotTo(objectCF)

		local Camera = workspace.CurrentCamera
		if Camera then
			local distance = (Camera.CFrame.Position - objectCF.Position).Magnitude

			local scale = distance * 0.1
			scale = math.clamp(scale, 0.5, 8)

			GizmoClone:ScaleTo(scale)
			RotationGizmoClone:ScaleTo(scale)
		end
	end

	UpdateGizmo()

	local beat = RS.Heartbeat:Connect(function()
		if ObjectClone and ObjectClone.Parent then
			UpdateGizmo()
		else
			beat:Disconnect()
		end
	end)

	ObjectClone.AncestryChanged:Connect(function(_, parent)
		if not parent then
			beat:Disconnect()
		end
	end)

	return ObjectClone
end

function Placement:ActivateBuildMode(ObjectName)
	Placement.Properties.BuildModeActive = true
	--UI:ObjectListState("Close")
	print("active")
	local Object = GetObject(ObjectName)
	if not Object then
		warn("Unable to start placement!")
		Placement:CancelPlacing()
		return
	end

	Placement.Properties.Object = Object
	Placement.Mouse.TargetFilter = Object
	Placement.IgnoreList =
		{ Object, Placement.Character, workspace.Terrain, Placement.Properties.Plot:FindFirstChild("PlotBoundries") }

	Calculations:Setup()

	Placement.Beat = RS.Heartbeat:Connect(function()
		if not Placement.Properties.BuildModeActive then
			return
		end

		Calculations:Raycast()
	end)

	print("Activating placement")
end

function Placement:ChangeMode(Input)
	if Placement.Properties.BuildModeActive then
		if Input.KeyCode == Enum.KeyCode.V then
			Calculations:ManualAxis()
		elseif Input.KeyCode == Enum.KeyCode.B then
			Calculations:FollowMouse()
		elseif Input.KeyCode == Enum.KeyCode.N then
			Calculations:ManualRotation()
		end
	end
end

function Placement:ChangeGridSize()
	local GridSizeSlot = Placement.Properties.GridSizeSlot
	--if GridSizeSlot == #GridSizes then GridSizeSlot = 0 end

	GridSizeSlot = (GridSizeSlot == #GridSizes and 1) or GridSizeSlot + 1

	Placement.Properties.GridSize = GridSizes[GridSizeSlot]
	Placement.Properties.GridSizeSlot = GridSizeSlot

	print("Grid size changed to: " .. Placement.Properties.GridSize)
end

function Placement:RotateObject(Input)
	if Placement.Properties.ManualAxis or Placement.Properties.ManualRotation then
		return
	end
	local amount = Placement.Constants.RotationIncrement
	local currentRotation = Placement.Properties.Rotation

	if Input.KeyCode == Enum.KeyCode.T then
		Placement.Properties.Rotation = CFrame.Angles(amount, 0, 0) * currentRotation
	elseif Input.KeyCode == Enum.KeyCode.R then
		Placement.Properties.Rotation = CFrame.Angles(0, amount, 0) * currentRotation
	elseif Input.KeyCode == Enum.KeyCode.Y then
		Placement.Properties.Rotation = CFrame.Angles(0, 0, amount) * currentRotation
	end
end

function Placement:EditMode(MouseTarget)
	--if MouseTarget then
	--	local ObjectName = (MouseTarget.Parent:IsA("Model") and MouseTarget.Parent.Name) or MouseTarget.Name
	--
	--	Placement:DeleteMode(MouseTarget)
	--	Placement:ActivateBuildMode(ObjectName)
	--end
	--
	--Placement.Properties.EditMode = false
	--
end

function Placement:DeleteMode(MouseTarget)
	if isServer then
		print(MouseTarget)
		if MouseTarget.Parent:IsA("Model") then
			MouseTarget.Parent:Destroy()
		else
			MouseTarget:Destroy()
		end
	else
		if MouseTarget and MouseTarget:IsDescendantOf(workspace.Plot.PlacedObjects) then
			print(MouseTarget)
			DSPlacement:FireServer("DeleteMode", MouseTarget)
		end
	end
end

function Placement:PlaceObject(OBJN, CFRAME, Anchored)
	if isServer then
		local TargetClone

		if Anchored then
			TargetClone = Objects:FindFirstChild(OBJN):Clone()
			TargetClone.Parent = workspace.Plot.PlacedObjects
		else
			TargetClone = LooseObjects:FindFirstChild(OBJN):Clone()
			TargetClone.Parent = workspace
		end

		if TargetClone:IsA("Model") then
			TargetClone:PivotTo(CFRAME)
		else
			TargetClone.CFrame = CFRAME
		end

		if TargetClone:IsA("Model") then
			TargetClone.PrimaryPart.Anchored = Anchored
		else
			TargetClone.Anchored = Anchored
		end
	else
		if Placement.Properties.ManualAxis or Placement.Properties.ManualRotation then
			Calculations:MouseUp()
		end

		Calculations:FollowMouse()
		Placement.Properties.Rotation = CFrame.Angles(0, 0, 0)

		if not Placement.Properties.BuildModeActive or (Placement.Colliding or Placement.OutsideBounds) then
			return
		end
		local Object = Placement.Properties.Object
		local ObjectName = Object.Name
		local CF

		if Object:IsA("Model") then
			CF = Object.PrimaryPart.CFrame
		else
			CF = Object.CFrame
		end

		CBPlacement:FireServer("PlaceObject", ObjectName, CF, true)

		if Placement.Properties.AutomaticallyPlacing then
			Placement:ActivateBuildMode(ObjectName)
		else
			Placement:CancelPlacing()
		end
	end
end

function Placement:CancelPlacing()
	if not Placement.Properties.BuildModeActive then
		return
	end

	--UI:ObjectListState("Open")

	print("Cancelling placement")

	Placement:Cleanup()
end

function Placement:Cleanup()
	if Placement.Beat then
		Placement.Beat:Disconnect()
	end

	Placement.Properties.BuildModeActive = false
	Placement.Properties.AutomaticallyPlacing = false
	Placement.Properties.EditMode = false
	Placement.Properties.DeleteMode = false

	local Object = Placement.Properties.Object

	if Object then
		Object:Destroy()
		Placement.Properties.Object = nil
	end
end

function Placement:Init(Player, Character)
	Placement.Player = Player
	Placement.Character = Character
	Placement.Mouse = Player:GetMouse()

	Placement.Mouse.Button1Up:Connect(function()
		if Placement.Properties.DeleteMode then
			Placement:DeleteMode(Placement.Mouse.Target)
		elseif Placement.Properties.EditMode then
			print("wtffffff")
			print(Placement.Properties.EditMode)
			Placement:EditMode(Placement.Mouse.Target)
		elseif Placement.Properties.ManualAxis or Placement.Properties.ManualRotation then
			print("wwwwww")
			Calculations:MouseUp()
		end
	end)

	Placement.AxisMouseDown = Mouse.Button1Down:Connect(function()
		if Placement.Properties.ManualAxis or Placement.Properties.ManualRotation then
			Calculations:MouseDown()
		end
	end)

	Placement.Properties.Plot = ConstructPlot:InvokeServer()

	KeybindToFunction:Init(Placement)
	Calculations:Init(Placement)
	--UI:Init(Placement)
end

return Placement
