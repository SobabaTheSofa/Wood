local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Split = ReplicatedStorage:WaitForChild("A1")

local cutter = {}

cutter.Properties = {
	CoolDown = false,
	Connection = nil,
}

function cutter:Enable(character)
	self.Properties.Connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if self.Properties.CoolDown then
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local mousePosition = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }

		local result = Workspace:Raycast(ray.Origin, ray.Direction * 40, raycastParams)

		if result and result.Instance and CollectionService:HasTag(result.Instance, "Cuttable") then
			self.Properties.CoolDown = true

			task.delay(0.5, function()
				self.Properties.CoolDown = false
			end)

			Split:FireServer({
				Instance = result.Instance,
				Position = result.Position,
				Normal = result.Normal,
				Material = result.Material,
				Distance = result.Distance,
			})
		end

		if result and result.Instance and CollectionService:HasTag(result.Instance, "Notch") then
			self.Properties.CoolDown = true

			task.delay(0.5, function()
				self.Properties.CoolDown = false
			end)
			Split:FireServer(nil, result.Instance)
		end
	end)
end

function cutter:Disable()
	if self.Properties.Connection then
		self.Properties.Connection:Disconnect()
		self.Properties.Connection = nil
	end
end

return cutter
