local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleDictionaries = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleDictionaries")
local FurnitureDictionary = require(ModuleDictionaries:WaitForChild("FurnitureDictionary"))

local FurnitureConstructor = {}
FurnitureConstructor.__index = FurnitureConstructor

function FurnitureConstructor.new(furnitureID, cframe, parent) end

function FurnitureConstructor:SetCFrame(Object, cframe, Anchored) end

return FurnitureConstructor
