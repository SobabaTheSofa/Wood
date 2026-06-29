local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local PlacementRemotes = ReplicatedStorage:WaitForChild("PlacementRemotes")
local DragRemote = PlacementRemotes:WaitForChild("DragRequest")

local Terrain = workspace:WaitForChild("Terrain")
local DragTarget = Instance.new("Attachment")
DragTarget.Parent = Terrain

local DragSystem = {}

DragSystem.Properties = {
	Character = nil,
	Target = nil,
	grabbedObject = nil,
	CoolDown = false,
	loacalhit = nil,
	GrabbedOrientation = nil,
	ConfirmationTemp = false,
}

function DragSystem:Highlight(object, uiEnabled)
	local ui = script:WaitForChild("BillboardGui")
	local highlight = script:WaitForChild("ObjectHighlight")

	highlight.Adornee = object
	if object then
		ui.Text.Text = object.Name
	end

	ui.Enabled = uiEnabled
	ui.Adornee = object
end

function DragSystem:DropObject()
	if not self.Properties.grabbedObject then
		return
	end

	DragRemote:InvokeServer(self.Properties.Target, false)
	--self.Properties.grabbedObject.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	self.Properties.grabbedObject = nil

	DragSystem.Properties.Character.AlignPosition.Attachment0 = nil
	DragSystem.Properties.Character.AlignOrientation.Attachment0 = nil
	self.Properties.ConfirmationTemp = false
	self.Properties.CoolDown = true
	task.delay(0.5, function()
		self.Properties.CoolDown = false
	end)
end

function DragSystem:Init(Player: Player, Character)
	Character.AlignPosition.Attachment1 = DragTarget
	Character.AlignOrientation.Attachment1 = DragTarget

	DragSystem.Properties.Character = Character
	-- InputBegan
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or self.Properties.CoolDown then
			return
		end
		if self.Properties.Target and not self.Properties.grabbedObject then
			self.Properties.grabbedObject = self.Properties.Target
			if DragRemote:InvokeServer(self.Properties.Target, true) then
				local mousePosition = Player:GetMouse().Hit.Position
				local cameraCF = workspace.CurrentCamera.CFrame

				print(self.Properties.grabbedObject.CFrame - self.Properties.grabbedObject.Position)
				self.Properties.GrabbedOrientation = cameraCF:ToObjectSpace(
					self.Properties.grabbedObject.CFrame - self.Properties.grabbedObject.Position
				)
				self.Properties.loacalhit = self.Properties.grabbedObject.CFrame:PointToObjectSpace(mousePosition)

				self.Properties.ConfirmationTemp = true
			end
		else
			self:DropObject()
		end
	end)

	-- InputEnded
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:DropObject()
		end
	end)

	-- Main loop
	RunService.Heartbeat:Connect(function()
		local mousePosition = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = Character:GetDescendants()

		local result = workspace:Raycast(ray.Origin, ray.Direction * 40, raycastParams)

		if self.Properties.grabbedObject and self.Properties.ConfirmationTemp then
			local grabbed = self.Properties.grabbedObject
			local dragAttachment = grabbed:FindFirstChild("DragAttachment") or Instance.new("Attachment")
			dragAttachment.Name = "DragAttachment"
			dragAttachment.Parent = grabbed
			dragAttachment.Position = self.Properties.loacalhit

			local targetCF = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -5)

			if self.Properties.GrabbedOrientation then
				targetCF = targetCF * self.Properties.GrabbedOrientation
			end

			DragTarget.WorldCFrame = targetCF

			Character.AlignPosition.Attachment0 = dragAttachment
			Character.AlignOrientation.Attachment0 = dragAttachment

			--DragTarget.Position = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 15
			DragTarget.Position = ray.Origin + ray.Direction * 20

			grabbed.CollisionGroup = "PickedUpObject"
			self:Highlight(grabbed, false)
		else
			if result and result.Instance and result.Instance:HasTag("Draggable") then
				self.Properties.Target = result.Instance
				self:Highlight(self.Properties.Target, true)
			else
				self.Properties.Target = nil
				self:Highlight(nil, false)
			end
		end
	end)
end

return DragSystem

-- NOTE TO SEELF MAKE IT SO INIT CRETE NW DRAG TARGET FOR EACH PERSON PLAYER RENEMBER????? poopy head
