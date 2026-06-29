local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = game:GetService("Players").LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()

local PlacementSystem = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementSystem"):WaitForChild("PlacmentSystemMain")
)
local DragSystem = require(script:WaitForChild("DragSystemClient"))

PlacementSystem:Init(Player, Character)
DragSystem:Init(Player, Character)
require(script:WaitForChild("TreeChoppingSystemClient")):Enable()
