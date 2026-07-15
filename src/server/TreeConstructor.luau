--NOTE TO SELF stuf to be implemented:
--bending i like it bendy
--check for collision when growing branches

local ServerScriptSerivce = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local TCSS = require(script.Parent:WaitForChild("TreeChoppingSystemServer"))
local TreeDictionary = require(script.Parent:WaitForChild("TreeDictionary"))

local TreeConc = {}
TreeConc.__index = TreeConc

TreeConc.TreeRegistry = require(script.Parent:WaitForChild("TreeRegistry"))

setmetatable(self, TCSS)

local function GetBranchFromPart(part)
	if not part then
		return nil
	end

	return TreeConc.TreeRegistry[part]
end

local function CreateMark(part, topOrBottom)
	local Log = GetBranchFromPart(part)
	if not Log then
		return
	end

	local newMark = Instance.new("Part")

	newMark.Color = Log.PlankColour
	newMark.Material = Log.PlankMaterial
	newMark.Transparency = 0
	newMark.Size = Vector3.new(part.Size.X * 0.95, 0.02, part.Size.Z * 0.95)
	newMark.CFrame = part.CFrame * CFrame.new(0, (part.Size.Y / 2) * topOrBottom, 0)
	newMark.Parent = part
	newMark.CanCollide = false
	newMark.Anchored = false

	local newWeld = Instance.new("WeldConstraint")

	if topOrBottom > 0 then
		newMark.Name = "Top"
		newWeld.Name = "TopWeld"
	else
		newMark.Name = "Bottom"
		newWeld.Name = "BottomWeld"
	end

	newWeld.Part0 = part
	newWeld.Part1 = newMark
	newWeld.Parent = part

	return newMark
end

local function RefreshMark(part, topOrBottom)
	if not part then
		return
	end

	if topOrBottom > 0 then
		local oldTop = part:FindFirstChild("Top")
		local oldWeld = part:FindFirstChild("TopWeld")

		if oldWeld then
			oldWeld:Destroy()
		end

		if oldTop then
			oldTop:Destroy()
		end

		CreateMark(part, 1)
	else
		local oldBottom = part:FindFirstChild("Bottom")
		local oldWeld = part:FindFirstChild("BottomWeld")

		if oldWeld then
			oldWeld:Destroy()
		end

		if oldBottom then
			oldBottom:Destroy()
		end

		CreateMark(part, -1)
	end
end

local function RemoveBranchWeldBetween(partA, partB)
	if not partA or not partB then
		return
	end

	for _, object in ipairs(partA:GetChildren()) do
		if object:IsA("WeldConstraint") and object.Name == "BranchWeldConstraint" then
			if object.Part0 == partB or object.Part1 == partB then
				object:Destroy()
			end
		end
	end

	for _, object in ipairs(partB:GetChildren()) do
		if object:IsA("WeldConstraint") and object.Name == "BranchWeldConstraint" then
			if object.Part0 == partA or object.Part1 == partA then
				object:Destroy()
			end
		end
	end
end

local function RotateAssembly(Part, Aseembly)

end

function TreeConc:CalculateTargetLength(mode)
	if mode == "Exponential" then
		return math.floor(self.MaxLength * (self.LengthMultiplier ^ self.N) * 5 + 0.5) / 5
	end
end

function TreeConc:CalculateMaxChildren(mode)
	if mode == "Exponential" then
		return math.clamp(math.round((self.N + 1) ^ 2), 0, self.ChildrenLimit)
	end
end


function TreeConc.new(Class: string, cframe: CFrame, parentingBranch, n: IntValue, lVolume, setSize)
	local self = setmetatable({}, TreeConc)

	local class

	if typeof(Class) == "string" then
		class = TreeDictionary[Class]
	end

	self.TreeClass = class.Name
	-- experimental to be removed if not optimised
	self.isGrowing = true
	self.hasBended = false
	self.BranchBendingLimit = class.BranchBendingLimit

	self.MaxLength = class.MaxLength
	self.MaxTrunkRadius = class.MaxTrunkRadius
	self.MaxLeafLength = class.MaxLeafLength
	self.MaxLeafRadius = class.MaxLeafRadius

	self.LeafMultiplier = class.LeafMultiplier
	self.LengthMultiplier = class.LengthMultiplier
	self.TrunkRadiusMultiplier = class.TrunkRadiusMultiplier

	self.LeafMaterial = class.LeafMaterial
	self.LeafColour = class.LeafColour
	self.LeafTransparency = class.LeafTransparency

	self.BarkMaterial = class.BarkMaterial
	self.BarkColour = class.BarkColour

	self.PlankMaterial = class.PlankMaterial
	self.PlankColour = class.PlankColour

	self.MaxSubBranches = class.MaxSubBranches
	self.ChildrenLimit = class.ChildrenLimit

	self.N = n or 0
	self.Children = {}
	self.Notch = {}
	self.Leaf = nil
	self.ParentingBranch = parentingBranch

	self.TargetLeafLength = self.MaxLeafLength * (self.LeafMultiplier ^ self.N)
	self.TargetLeafRadius = self.MaxLeafRadius * (self.LeafMultiplier ^ self.N)

	self.TargetLength = self:CalculateTargetLength("Exponential")

	self.TargetRadius = self.MaxTrunkRadius * (self.TrunkRadiusMultiplier ^ self.N)

	local leafVolume = lVolume or 0.1

	local p = Instance.new("Part")
	p.Size = setSize or Vector3.new(0.2, 0.2, 0.2)
	p.Anchored = true
	p.Color = self.BarkColour
	p.Material = self.BarkMaterial
	p.CFrame = cframe
	p.Name = self.TreeClass
	p.Parent = workspace

	p:SetAttribute("TreeClass", self.TreeClass)
	CollectionService:AddTag(p, "Cuttable")

	self.Tree = p
	self.TreeRegistry[p] = self

	p.AncestryChanged:Connect(function(_, parent)
		if not parent then
			local thisBranch = self.TreeRegistry[p]

			if thisBranch then
				if thisBranch.ParentingBranch then
					local parentPart = thisBranch.ParentingBranch
					local parentBranch = self.TreeRegistry[parentPart]

					RemoveBranchWeldBetween(parentPart, thisBranch.Tree)

					local hadTopMark = parentBranch.Tree:FindFirstChild("Top") ~= nil

					if hadTopMark then
						RefreshMark(parentBranch.Tree, 1)
					else
						CreateMark(parentBranch.Tree, 1)
					end

					if parentBranch and parentBranch.Children then
						for i = #parentBranch.Children, 1, -1 do
							if parentBranch.Children[i] == thisBranch then
								table.remove(parentBranch.Children, i)
								break
							end
						end
					end
				end

				if thisBranch.Notch then
					for _, notchData in ipairs(thisBranch.Notch) do
						if notchData.Part then
							notchData.Part:Destroy()
						end

						if notchData.WC then
							notchData.WC:Destroy()
						end
					end
				end

				table.clear(thisBranch.Notch)
				thisBranch.Notch = nil

				for _, childBranch in ipairs(thisBranch.Children or {}) do
					RemoveBranchWeldBetween(thisBranch.Tree, childBranch.Tree)

					local hadBottomMark = childBranch.Tree:FindFirstChild("Bottom") ~= nil

					if hadBottomMark then
						RefreshMark(childBranch.Tree, -1)
					else
						CreateMark(childBranch.Tree, -1)
					end

					childBranch.ParentingBranch = nil
				end

				thisBranch.ParentingBranch = nil
				thisBranch.Children = {}
			end

			self.TreeRegistry[p] = nil
		end
	end)

	if leafVolume > 0 then
		local scale = (leafVolume / (self.TargetLeafLength * (self.TargetLeafRadius ^ 2))) ^ (1 / 3)

		local leafWidth = scale * self.TargetLeafRadius
		local leafHeight = scale * self.TargetLeafLength
		local leafSize = Vector3.new(leafWidth, leafHeight, leafWidth)

		local l = Instance.new("Part")
		l.Anchored = true
		l.Color = self.LeafColour
		l.Material = self.LeafMaterial
		l.Name = "Leaf"
		l.Size = leafSize
		l.CFrame = p.CFrame * CFrame.new(0, p.Size.Y / 2 + l.Size.Y / 2, 0)
		l.Parent = workspace

		self.Leaf = l
	end

	return self
end

function TreeConc:SpawnBranchAtTip() -- collision detection is to be implemented
	local LV = 3

	if self.Leaf then
		LV = self.Leaf.Size.X * self.Leaf.Size.Y * self.Leaf.Size.Z

		self.Leaf:Destroy()
		self.Leaf = nil

		if self.Tree:FindFirstChild("LeafWeldConstraint") then
			self.Tree:FindFirstChild("LeafWeldConstraint"):Destroy()
		end
	end

	local tip = self.Tree.CFrame:ToWorldSpace(CFrame.new(0, self.Tree.Size.Y / 2, 0)).Position

	local toSpawn = self:CalculateMaxChildren("Exponential")
	local baseAngle = math.random() * math.pi * 2

	for i = 1, toSpawn do
		local angleStep = (2 * math.pi) / toSpawn
		local angle = baseAngle + i * angleStep

		local jitter = (math.random() - 0.5) * math.rad(12)
		angle += jitter

		local radius = 2
		local radiusJitter = (math.random() - 0.5) * 0.4
		radius += radiusJitter

		local x = math.cos(angle)
		local z = math.sin(angle)
		local y = math.random(35, 65) / 100

		local localDir = Vector3.new(x, y, z).Unit
		local worldDir = self.Tree.CFrame:VectorToWorldSpace(localDir).Unit

		local targetPos = tip + worldDir * radius
		local branchCFrame = CFrame.lookAt(tip, targetPos)

		local childBranch = self.new(self.TreeClass, branchCFrame, self.Tree, self.N + 1, LV / toSpawn)

		table.insert(self.Children, childBranch)
	end
end

function TreeConc:GrowLeaf()
	local growthRate = 0.2

	if self.Leaf then
		local growY = math.max(0, math.min(growthRate / 5, self.TargetLeafLength - self.Leaf.Size.Y))
		local growX = math.max(0, math.min(growthRate / 5, self.TargetLeafRadius - self.Leaf.Size.X))
		local growZ = math.max(0, math.min(growthRate / 5, self.TargetLeafRadius - self.Leaf.Size.Z))

		if growY > 0 or growX > 0 or growZ > 0 then
			local oldSize = self.Leaf.Size

			local newSize = Vector3.new(oldSize.X + growX, oldSize.Y + growY, oldSize.Z + growZ)

			local newCFrame = self.Leaf.CFrame * CFrame.new(0, growY / 2, 0)

			self.Leaf.Size = newSize
			self.Leaf.CFrame = newCFrame
		end
	end
end

function TreeConc:GrowLength()
	local growthRate = 0.2
	local Branch = self.Tree

	if Branch.Size.Y < self.TargetLength then
		local growAmount = math.min(growthRate, self.TargetLength - Branch.Size.Y)

		Branch.Size = Vector3.new(Branch.Size.X, Branch.Size.Y + growAmount, Branch.Size.Z)

		Branch.CFrame = Branch.CFrame * CFrame.new(0, growAmount / 2, 0)

		if self.Leaf then
			self.Leaf.Position += Branch.CFrame.UpVector * growAmount
		end

		for _, childBranch in ipairs(self.Children or {}) do
			childBranch:MoveBy(Branch.CFrame.UpVector * growAmount)
		end
	end
end

function TreeConc:GrowWidth()
	local Branch = self.Tree
	local growthRate = 0.2

	if Branch.Size.X < self.TargetRadius then
		local growAmount = math.min(growthRate, self.TargetRadius - Branch.Size.X)

		Branch.Size = Vector3.new(Branch.Size.X + growAmount, Branch.Size.Y, Branch.Size.Z + growAmount)
	end
end

function TreeConc:Grow()
	if not self.isGrowing then return end 

	self:GrowLength()
	self:GrowWidth()
	self:GrowLeaf()

	if #self.Children == 0 and self.MaxSubBranches > self.N then
		local maxH = self.TargetLength
		local half = maxH * 0.5

		if self.Tree.Size.Y > half then
			local progress = math.clamp((self.Tree.Size.Y - half) / (maxH - half), 0, 1)

			local chance = progress * 100
			local roll = math.random(1, 100)

			if roll < chance then
				self:SpawnBranchAtTip()
			end
		end
	else
		for _, childBranch in ipairs(self.Children or {}) do
			childBranch:Grow()
		end
	end

	if #self.children > 0 and self.hasBended and self.N >= self.BranchBendingLimit the
		if math.random(1,100) > 67 then -- to be determined

		end
	end	
end

function TreeConc:BendBranch()
	local Ylength = self.Tree.Size.y
	local branchCFrame = self.Tree.CFrame


	self.Tree.Size.y/2 --as of current is now 50/50 split to be randomised
	local CloneP = self.Tree:Clone()

	branchCFrame = self.Tree:ToWorldSpace(CFrame.new(0,-self.Tree.Size.y/2, 0)) -- to be resaerched: use the direction of upvector to simplify and minimalise
	-- apply position changes to clone brnach 


	-- apply rotation to chilldren assembly
end

function TreeConc:MoveBy(offset)
	self.Tree.Position += offset

	if self.Leaf then
		self.Leaf.Position += offset
	end

	for _, childBranch in ipairs(self.Children or {}) do
		childBranch:MoveBy(offset)
	end
end

function TreeConc:Init(BaseEnv) -- unsed requirering is enough, to be remoed if not other init function is neded
	---self.TreeRegistry = BaseEnv

	return self 
end

return TreeConc
