local Calculations = {}
local Base = {}

local RayParams = RaycastParams.new()

local FaceCenterParams = RaycastParams.new()

local FakeHitboxCFrame, GridCFrame, FakeHitboxRot

local Properties

local Mouse

local Object
local ObjectMovePart

local HoverAxis = nil
local DraggingAxis = nil
local ObjectOriginalCFrame = nil
local StartPlanePoint = nil
local PlaneNormal = nil

local Gizmo
local GizmoParts
local RotationGizmo
local RotationGizmoParts

local function UpdatedCornerCFrames(ModelCFrame, Size) -- or get the model cframe * the new
	return {
		Corner1 = ModelCFrame * CFrame.new(-Size.X, -Size.Y, -Size.Z),
		Corner2 = ModelCFrame * CFrame.new(Size.X, -Size.Y, Size.Z),
		Corner3 = ModelCFrame * CFrame.new(-Size.X, Size.Y, -Size.Z),
		Corner4 = ModelCFrame * CFrame.new(Size.X, Size.Y, Size.Z),
		Corner5 = ModelCFrame * CFrame.new(-Size.X, -Size.Y, Size.Z),
		Corner6 = ModelCFrame * CFrame.new(Size.X, -Size.Y, -Size.Z),
		Corner7 = ModelCFrame * CFrame.new(-Size.X, Size.Y, Size.Z),
		Corner8 = ModelCFrame * CFrame.new(Size.X, Size.Y, -Size.Z),
	}
end

local function GetRotatedSize(Rotation, Size) -- Gets rotated size of model
	local OrientedSize = Rotation * CFrame.new(Size)
	return Vector3.new(
		math.abs(math.round(OrientedSize.X)),
		math.abs(math.round(OrientedSize.Y)),
		math.abs(math.round(OrientedSize.Z))
	)
end

local function SnapToGrid(Position, GridSize) -- Snaps object to worldspace grid
	return CFrame.new(
		math.floor(Position.X / GridSize + 0.5) * GridSize,
		math.floor(Position.Y / GridSize + 0.5) * GridSize,
		math.floor(Position.Z / GridSize + 0.5) * GridSize
	) -- ntoe to self fix this, i need to go take a dump
end

local function RoundPosition(Position) -- Rounding position of object in plot object space
	return math.abs(math.round(Position))
end

local function FixEvenOdd(Size, HitRotation, HitSize) -- fix even odd
	local HitRotationSize = GetRotatedSize(HitRotation, HitSize)
	local X, Y, Z = 0, 0, 0
	local FixIncrement = 0.5

	local SizeX = math.abs(math.round(Size.X))
	local SizeY = math.abs(math.round(Size.Y))
	local SizeZ = math.abs(math.round(Size.Z))

	local XValid = SizeX % 2 == 0
	local YValid = SizeY % 2 == 0
	local ZValid = SizeZ % 2 == 0

	if not XValid then
		X += FixIncrement
	end

	if not YValid then
		Y -= FixIncrement
	end

	if not ZValid then
		Z += FixIncrement
	end

	return X, Y, Z
end

local function NearestAxis(Direction) -- Finds which axis is the closest to the cframe
	local Axis = math.max(math.abs(Direction.X), math.abs(Direction.Y), math.abs(Direction.Z))

	if Axis == Direction.X then
		return Enum.Axis.X
	elseif Axis == Direction.Y then
		return Enum.Axis.Y
	end

	return Enum.Axis.Z
end

function Calculations:CheckCollision(Hitbox, TargetObject) -- Checks collision of hitbox
	for _, FoundObject in pairs(workspace:GetPartsInPart(Hitbox)) do
		if FoundObject:IsDescendantOf(workspace.Plot.PlacedObjects) and FoundObject ~= TargetObject then
			Base.Colliding = true
		end
	end
end

local function NormalOffset(NormalCFrame, Normal, FakeCFrame)
	FakeHitboxRot = GetRotatedSize(Properties.Rotation, ObjectMovePart.Size)
	local FilterAxis = Vector3.FromAxis(NearestAxis(FakeCFrame:VectorToObjectSpace(Normal)))
	local RelativeOffset = (FakeHitboxRot * FilterAxis).Magnitude * 0.5

	return NormalCFrame + (Normal * RelativeOffset)
end

local function FlipGrid(HitNormal, Offset)
	local Forward = (HitNormal.Position - Offset.Position).Unit
	local UpVector = HitNormal.UpVector
	local RightVector = Forward:Cross(UpVector).Unit
	local upVector2 = RightVector:Cross(Forward).Unit
	return CFrame.fromMatrix(HitNormal.Position, RightVector, upVector2) * CFrame.Angles(math.rad(90), 0, 0)
end

local function GetCenterFace(HitCF, RotatedCF, Hit)
	local Offset = RotatedCF * CFrame.new(0, 40, 0)
	local BackRay = CFrame.new(Offset.Position, HitCF.Position)

	FaceCenterParams.FilterDescendantsInstances = { Hit }
	FaceCenterParams.FilterType = Enum.RaycastFilterType.Include

	local RayResult = workspace:Raycast(Offset.Position, BackRay.LookVector * 50, FaceCenterParams)

	if RayResult then
		return RayResult.Position
	end
end

local function CheckAllPlots(CornerPosition)
	for _, Plot in pairs(workspace.Plot.Plots:GetChildren()) do
		local Position = Plot.CFrame:PointToObjectSpace(CornerPosition)

		local boundX = Plot.Size.X / 2
		local boundZ = Plot.Size.Z / 2

		local withinX = Position.X >= -boundX and Position.X <= boundX
		local withinZ = Position.Z >= -boundZ and Position.Z <= boundZ

		local plotBottomY = Plot.Position.Y - Plot.Size.Y / 2
		local plotTopY = Plot.Position.Y + Plot.Size.Y / 2
		local maxBuildY = plotTopY + Properties.MaxBuildHeight

		local withinY = CornerPosition.Y >= plotBottomY and CornerPosition.Y <= maxBuildY

		if withinX and withinY and withinZ then
			return true
		end
	end

	return false
end

function Calculations:CheckBounds(ModelSize)
	local CornerTable = UpdatedCornerCFrames(ObjectMovePart.CFrame, ObjectMovePart.Size / 2)

	-- do not detect new corner table every frame. detect for a new face then update the table
	for i, Corner in pairs(CornerTable) do
		--local DummyPart = workspace.Terrain.Parts[i]
		--
		--DummyPart.CFrame = Corner

		if CheckAllPlots(Corner.Position, ModelSize) then
			Base.OutsideBounds = false
		else
			Base.OutsideBounds = true
			break
		end
	end
end

function Calculations:Main(HitNormal, Normal, HitCFrame, Target)
	local TargetPosition = HitCFrame.Position
	local FinalGrid
	Base.Colliding = false

	if not FakeHitboxCFrame then
		FakeHitboxCFrame = CFrame.new(ObjectMovePart.Position)
	end

	local RelativeOffset = NormalOffset(HitNormal, Normal, FakeHitboxCFrame)

	if Properties.ForceUpright then
		FinalGrid = CFrame.new(HitNormal.Position)
	else
		FinalGrid = FlipGrid(HitNormal, HitNormal * CFrame.new(0, 0, -5))
	end

	local CornerPos =
		GetCenterFace(HitCFrame, CFrame.new(TargetPosition) * CFrame.Angles(FinalGrid:ToEulerAnglesXYZ()), Target)
	if not CornerPos then
		return
	end

	self:CheckBounds(FakeHitboxRot)
	self:CheckCollision(ObjectMovePart, Target)

	local Offset = CFrame.new(CornerPos)

	local X, Y, Z = FixEvenOdd(FakeHitboxRot, Target.CFrame, Target.Size)

	GridCFrame = Offset * CFrame.Angles(FinalGrid:ToEulerAnglesXYZ()) * CFrame.new(X, Y, Z)

	local mouseHitRelative = GridCFrame:ToObjectSpace(RelativeOffset)
	local mouseHitWorldSnapped = GridCFrame * SnapToGrid(mouseHitRelative, Properties.GridSize)

	FakeHitboxCFrame = mouseHitWorldSnapped

	local FinalCFrame = mouseHitWorldSnapped * Properties.Rotation

	if Object:IsA("Model") then
		Object:PivotTo(FinalCFrame)
	else
		Object.CFrame = FinalCFrame
	end
end

local function GetAxisFromPart(part)
	local name = part.Name

	if
		name == "Red1"
		or name == "Red2"
		or name == "RBar1"
		or name == "RBar2"
		or name == "BlueRing"
		or name == "BBall1"
		or name == "BBall2"
	then
		return "X"
	elseif
		name == "Green1"
		or name == "Green2"
		or name == "GBar1"
		or name == "GBar2"
		or name == "GreenRing"
		or name == "GBall1"
		or name == "GBall2"
	then
		return "Y"
	elseif
		name == "Blue1"
		or name == "Blue2"
		or name == "BBar1"
		or name == "BBar2"
		or name == "RedRing"
		or name == "RBall1"
		or name == "RBall2"
	then
		return "Z"
	end

	return nil
end

local function SetGizmo(Value)
	for _, part in ipairs(Gizmo:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = math.clamp(Value, 0, 1) or 0
		end
	end
end

local function SetRotationGizmo(Value)
	for _, part in ipairs(RotationGizmo:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = math.clamp(Value, 0, 1) or 0
		end
	end
end

local function SafeSetTransparency(part, value)
	if part and part:IsA("BasePart") then
		part.Transparency = value
	end
end

local function HighlightAxis(axis)
	SetGizmo(0.5)

	if axis == "X" then
		SafeSetTransparency(GizmoParts.Red1, 0)
		SafeSetTransparency(GizmoParts.Red2, 0)
		SafeSetTransparency(GizmoParts.RBar1, 0)
		SafeSetTransparency(GizmoParts.RBar2, 0)
	elseif axis == "Y" then
		SafeSetTransparency(GizmoParts.Green1, 0)
		SafeSetTransparency(GizmoParts.Green2, 0)
		SafeSetTransparency(GizmoParts.GBar1, 0)
		SafeSetTransparency(GizmoParts.GBar2, 0)
	elseif axis == "Z" then
		SafeSetTransparency(GizmoParts.Blue1, 0)
		SafeSetTransparency(GizmoParts.Blue2, 0)
		SafeSetTransparency(GizmoParts.BBar1, 0)
		SafeSetTransparency(GizmoParts.BBar2, 0)
	end
end

local function HightlightRotation(axis)
	if axis == "X" then
		SafeSetTransparency(RotationGizmoParts.BlueRing, 0)
		SafeSetTransparency(RotationGizmoParts.BBall1, 0)
		SafeSetTransparency(RotationGizmoParts.BBall2, 0)
	elseif axis == "Y" then
		SafeSetTransparency(RotationGizmoParts.GreenRing, 0)
		SafeSetTransparency(RotationGizmoParts.GBall1, 0)
		SafeSetTransparency(RotationGizmoParts.GBall2, 0)
	elseif axis == "Z" then
		SafeSetTransparency(RotationGizmoParts.RedRing, 0)
		SafeSetTransparency(RotationGizmoParts.RBall1, 0)
		SafeSetTransparency(RotationGizmoParts.RBall2, 0)
	end
end

function Calculations:Raycast()
	local MRay = Mouse.UnitRay

	if Properties.FollowMouse then
		local RayResult = workspace:Raycast(MRay.Origin, MRay.Direction.unit * 500, RayParams)

		if RayResult then
			--if RayResult.Instance.Name == "Plot" then Base.Plot = RayResult.Instance end
			Base.TargetObject = RayResult.Instance
			local EndPos = CFrame.new(RayResult.Position, RayResult.Position + RayResult.Normal)
			self:Main(EndPos, RayResult.Normal, RayResult.Instance.CFrame, RayResult.Instance)
		end
	end

	if (Properties.ManualAxis or Properties.ManualRotation) and not DraggingAxis then
		local unitRay = Mouse.UnitRay

		local rayCast = workspace:Raycast(unitRay.Origin, unitRay.Direction.Unit * 500, RayParams)

		HoverAxis = nil
		if
			rayCast
			and rayCast.Instance
			and (rayCast.Instance:IsDescendantOf(RotationGizmo) or rayCast.Instance:IsDescendantOf(Gizmo))
		then
			local axis = GetAxisFromPart(rayCast.Instance)

			if axis then
				HoverAxis = axis

				if Properties.ManualAxis then
					HighlightAxis(axis)
				else
					HightlightRotation(axis)
				end
			else
				if Properties.ManualAxis then
					SetGizmo(0.5)
				else
					SetRotationGizmo(0.5)
				end
			end
		else
			if Properties.ManualAxis then
				SetGizmo(0.5)
			else
				SetRotationGizmo(0.5)
			end
		end
	end

	if DraggingAxis and ObjectOriginalCFrame and StartPlanePoint and PlaneNormal then
		if Properties.ManualAxis then
			Calculations:MoveAxis()
		end
		if Properties.ManualRotation then
			Calculations:RotateAxis()
		end
	end

	if not Base.Colliding and not Base.OutsideBounds then
		ObjectMovePart.Color = Color3.new(1, 1, 1)
	else
		ObjectMovePart.BrickColor = BrickColor.new("Really red")
	end
end

function Calculations:RayPlaneIntersection(rayOrigin, rayDirection, planePoint, planeNormal)
	local denominator = rayDirection:Dot(planeNormal)

	if math.abs(denominator) < 0.0001 then
		return nil
	end

	local distance = (planePoint - rayOrigin):Dot(planeNormal) / denominator

	if distance < 0 then
		return nil
	end

	return rayOrigin + rayDirection * distance
end

function Calculations:GetAxisVector(axis, objectCF)
	if axis == "Y" then
		return objectCF.RightVector
	elseif axis == "X" then
		return objectCF.UpVector
	elseif axis == "Z" then
		return objectCF.LookVector
	end
end

function Calculations:GetPlaneNormalForAxis(axis, objectCF, cameraCF)
	local axisVector = self:GetAxisVector(axis, objectCF)
	if not axisVector then
		return nil
	end

	local cameraLook = cameraCF.LookVector

	-- Project camera direction onto a direction perpendicular to the axis.
	-- This makes a plane that contains the movement axis.
	local planeNormal = cameraLook - axisVector * cameraLook:Dot(axisVector)

	if planeNormal.Magnitude < 0.001 then
		-- fallback if camera is looking almost exactly along the axis
		if axis == "X" then
			planeNormal = objectCF.UpVector
		elseif axis == "Y" then
			planeNormal = objectCF.LookVector
		elseif axis == "Z" then
			planeNormal = objectCF.UpVector
		end
	end

	return planeNormal.Unit
end

function Calculations:MoveAxis()
	local unitRay = Mouse.UnitRay

	local currentPlanePoint = Calculations:RayPlaneIntersection(
		unitRay.Origin,
		unitRay.Direction.Unit,
		ObjectOriginalCFrame.Position,
		PlaneNormal
	)

	if currentPlanePoint then
		local mouseMovement = currentPlanePoint - StartPlanePoint

		local axisVector = Calculations:GetAxisVector(DraggingAxis, ObjectOriginalCFrame)

		if axisVector then
			local distanceOnAxis = mouseMovement:Dot(axisVector)
			local finalMovement = axisVector * distanceOnAxis
			local newCFrame = ObjectOriginalCFrame + finalMovement

			local finalCFrame = (SnapToGrid(newCFrame.Position, Properties.GridSize)) * newCFrame.Rotation

			if Object:IsA("Model") then
				Object:PivotTo(finalCFrame)
			else
				Object.CFrame = finalCFrame
			end

			self:CheckBounds(FakeHitboxRot)
			self:CheckCollision(ObjectMovePart, Object)
		end
	end
end

function Calculations:RotateAxis()
	local unitRay = Mouse.UnitRay

	local currentPlanePoint = Calculations:RayPlaneIntersection(
		unitRay.Origin,
		unitRay.Direction.Unit,
		ObjectOriginalCFrame.Position,
		PlaneNormal
	)

	if not currentPlanePoint then
		return
	end

	local startVector = StartPlanePoint - ObjectOriginalCFrame.Position
	local currentVector = currentPlanePoint - ObjectOriginalCFrame.Position

	if startVector.Magnitude < 0.001 then
		return
	end
	if currentVector.Magnitude < 0.001 then
		return
	end

	startVector = startVector.Unit
	currentVector = currentVector.Unit

	local angle = math.atan2(
		startVector:Cross(currentVector):Dot(Calculations:GetAxisVector(DraggingAxis, ObjectOriginalCFrame)),
		startVector:Dot(currentVector)
	)

	local SnapAngle = math.rad(90)

	angle = math.floor(angle / SnapAngle + 0.5) * SnapAngle

	local axisVector = Calculations:GetAxisVector(DraggingAxis, ObjectOriginalCFrame)

	local rotation = CFrame.fromAxisAngle(axisVector, angle)

	local positionOnly = CFrame.new(ObjectOriginalCFrame.Position)
	local originalRotationOnly = ObjectOriginalCFrame - ObjectOriginalCFrame.Position

	local NewCFrame = positionOnly * rotation * originalRotationOnly

	Properties.Rotation = rotation * originalRotationOnly

	if Object:IsA("Model") then
		Object:PivotTo(NewCFrame)
	else
		Object.CFrame = NewCFrame
	end

	self:CheckBounds(FakeHitboxRot)
	self:CheckCollision(ObjectMovePart, Object)
end

function Calculations:MouseDown()
	if HoverAxis then
		local unitRay = Mouse.UnitRay

		if Properties.ManualAxis then
			DraggingAxis = HoverAxis

			ObjectOriginalCFrame = ObjectMovePart.CFrame
			local planePoint = ObjectOriginalCFrame.Position

			PlaneNormal =
				Calculations:GetPlaneNormalForAxis(DraggingAxis, ObjectOriginalCFrame, workspace.CurrentCamera.CFrame)

			if not PlaneNormal then
				warn("cant find it the planenormal", DraggingAxis)
				DraggingAxis = nil
				ObjectOriginalCFrame = nil
			end

			StartPlanePoint =
				Calculations:RayPlaneIntersection(unitRay.Origin, unitRay.Direction.Unit, planePoint, PlaneNormal)

			if not StartPlanePoint then
				warn("Could not get start plane point")
				DraggingAxis = nil
				ObjectOriginalCFrame = nil
				PlaneNormal = nil
				return
			end
		elseif Properties.ManualRotation then
			DraggingAxis = HoverAxis

			ObjectOriginalCFrame = ObjectMovePart.CFrame
			local planePoint = ObjectOriginalCFrame.Position

			PlaneNormal = Calculations:GetAxisVector(DraggingAxis, ObjectOriginalCFrame)

			if not PlaneNormal then
				warn("Could not get rotation axis:", DraggingAxis)
				DraggingAxis = nil
				ObjectOriginalCFrame = nil
				return
			end

			StartPlanePoint =
				Calculations:RayPlaneIntersection(unitRay.Origin, unitRay.Direction.Unit, planePoint, PlaneNormal)

			if not StartPlanePoint then
				warn("Could not get start rotate plane point")
				DraggingAxis = nil
				ObjectOriginalCFrame = nil
				PlaneNormal = nil
				return
			end

			print("Started rotating:", DraggingAxis)
		end
	end
end

function Calculations:MouseUp()
	if DraggingAxis then
		print("Stopped dragging:", DraggingAxis)
	end

	DraggingAxis = nil
	ObjectOriginalCFrame = nil
	StartPlanePoint = nil
	PlaneNormal = nil
end

function Calculations:ManualAxis()
	RayParams.FilterType = Enum.RaycastFilterType.Include
	print(Gizmo)
	RayParams.FilterDescendantsInstances = { Gizmo }

	Properties.ManualAxis = true
	Properties.FollowMouse = false
	Properties.ManualRotation = false

	SetRotationGizmo(1)
	SetGizmo(0.5)
end

function Calculations:FollowMouse()
	RayParams.FilterDescendantsInstances = Base.IgnoreList
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	Properties.ManualAxis = false
	Properties.FollowMouse = true
	Properties.ManualRotation = false

	SetRotationGizmo(1)
	SetGizmo(1)
end

function Calculations:ManualRotation()
	RayParams.FilterType = Enum.RaycastFilterType.Include
	RayParams.FilterDescendantsInstances = { RotationGizmo }

	Properties.ManualAxis = false
	Properties.FollowMouse = false
	Properties.ManualRotation = true

	SetRotationGizmo(0.5)
	SetGizmo(1)
end

function Calculations:Setup()
	RayParams.FilterDescendantsInstances = Base.IgnoreList
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	Properties = Base.Properties
	Object = Properties.Object

	Gizmo = Object:FindFirstChild("XYZGizmo")

	RotationGizmo = Object:FindFirstChild("RotationGizmo")

	RotationGizmoParts = {
		BlueRing = RotationGizmo:FindFirstChild("BlueRing"),
		GreenRing = RotationGizmo:FindFirstChild("GreenRing"),
		RedRing = RotationGizmo:FindFirstChild("RedRing"),

		RBall1 = RotationGizmo:FindFirstChild("RBall1"),
		RBall2 = RotationGizmo:FindFirstChild("RBall2"),

		GBall1 = RotationGizmo:FindFirstChild("GBall1"),
		GBall2 = RotationGizmo:FindFirstChild("GBall2"),

		BBall1 = RotationGizmo:FindFirstChild("BBall1"),
		BBall2 = RotationGizmo:FindFirstChild("BBall2"),
	}

	GizmoParts = {
		Red1 = Gizmo:FindFirstChild("Red1"),
		Red2 = Gizmo:FindFirstChild("Red2"),
		RBar1 = Gizmo:FindFirstChild("RBar1"),
		RBar2 = Gizmo:FindFirstChild("RBar2"),

		Green1 = Gizmo:FindFirstChild("Green1"),
		Green2 = Gizmo:FindFirstChild("Green2"),
		GBar1 = Gizmo:FindFirstChild("GBar1"),
		GBar2 = Gizmo:FindFirstChild("GBar2"),

		Blue1 = Gizmo:FindFirstChild("Blue1"),
		Blue2 = Gizmo:FindFirstChild("Blue2"),
		BBar1 = Gizmo:FindFirstChild("BBar1"),
		BBar2 = Gizmo:FindFirstChild("BBar2"),
	}

	if Object:IsA("Model") then
		ObjectMovePart = Object.PrimaryPart
	else
		ObjectMovePart = Object
	end
end

function Calculations:Init(BaseEnv)
	Base = BaseEnv

	Mouse = BaseEnv.Mouse
end

return Calculations
