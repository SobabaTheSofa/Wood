local ServerScriptSerivce = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local TCSS = {}
local Base = nil

local TreeRegistry = {}

local function GetBranchFromPart(part)
	if not part then
		return nil
	end

	return TreeRegistry[part]
end

local function GetWoodLogsFromBranch(part)
	local branch = GetBranchFromPart(part)
	local logs = {}

	if not branch then
		return logs
	end

	table.insert(logs, branch.Tree)

	local currentBranch = branch

	while currentBranch.ParentingBranch do
		local parentBranch = GetBranchFromPart(currentBranch.ParentingBranch)

		if not parentBranch then
			break
		end

		table.insert(logs, parentBranch.Tree)
		currentBranch = parentBranch
	end

	local function AddChildren(parentBranch)
		for _, childBranch in ipairs(parentBranch.Children or {}) do
			table.insert(logs, childBranch.Tree)
			AddChildren(childBranch)
		end
	end

	AddChildren(branch)

	return logs
end

local function SavePartAnchorState(anchorStates, part)
	if not part then
		return
	end

	if not part:IsA("BasePart") then
		return
	end

	if anchorStates[part] == nil then
		anchorStates[part] = part.Anchored
	end

	part.Anchored = true
end

local function SaveBranchOnlyAnchorStates(branch, anchorStates)
	if not branch then
		return
	end

	SavePartAnchorState(anchorStates, branch.Tree)
	SavePartAnchorState(anchorStates, branch.Leaf)

	if branch.Tree then
		for _, object in ipairs(branch.Tree:GetDescendants()) do
			if object:IsA("BasePart") then
				SavePartAnchorState(anchorStates, object)
			end
		end
	end
end

local function SaveBranchTreeAnchorStates(branch, anchorStates)
	if not branch then
		return
	end

	SaveBranchOnlyAnchorStates(branch, anchorStates)

	for _, childBranch in ipairs(branch.Children or {}) do
		SaveBranchTreeAnchorStates(childBranch, anchorStates)
	end
end

local function IgnoreBranchFromRestore(branch, ignoreRestore)
	if not branch then
		return
	end

	if branch.Tree then
		ignoreRestore[branch.Tree] = true

		for _, object in ipairs(branch.Tree:GetDescendants()) do
			if object:IsA("BasePart") then
				ignoreRestore[object] = true
			end
		end
	end

	if branch.Leaf then
		ignoreRestore[branch.Leaf] = true
	end

	for _, childBranch in ipairs(branch.Children or {}) do
		IgnoreBranchFromRestore(childBranch, ignoreRestore)
	end
end

local function RestoreAnchorStates(anchorStates, ignoreRestore)
	for part, wasAnchored in pairs(anchorStates) do
		if part and part.Parent and not ignoreRestore[part] then
			part.Anchored = wasAnchored
		end
	end
end

local function DestroyLeaf(branch)
	if not branch then
		return
	end

	if branch.Leaf then
		branch.Leaf:Destroy()
		branch.Leaf = nil
	end

	if branch.Tree then
		local leafWeld = branch.Tree:FindFirstChild("LeafWeldConstraint")
		if leafWeld then
			leafWeld:Destroy()
		end
	end
end

local function RemoveBranchWelds(part)
	if not part then
		return
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("WeldConstraint") and child.Name == "BranchWeldConstraint" then
			child:Destroy()
		end
	end
end

local function RemoveAllBranchWeldsFromPart(part)
	if not part then
		return
	end

	for _, object in ipairs(part:GetDescendants()) do
		if object:IsA("WeldConstraint") and object.Name == "BranchWeldConstraint" then
			object:Destroy()
		end
	end
end

local function RemoveAllBranchWeldsFromBranchTree(branch)
	if not branch then
		return
	end

	RemoveAllBranchWeldsFromPart(branch.Tree)

	for _, childBranch in ipairs(branch.Children or {}) do
		RemoveAllBranchWeldsFromBranchTree(childBranch)
	end
end

local function CreateBranchWeld(parentPart, childPart)
	if not parentPart or not childPart then
		return
	end

	local wc = Instance.new("WeldConstraint")
	wc.Name = "BranchWeldConstraint"
	wc.Part0 = parentPart
	wc.Part1 = childPart
	wc.Parent = parentPart

	return wc
end

local function RebuildBranchWelds(branch)
	if not branch or not branch.Tree then
		return
	end

	for _, childBranch in ipairs(branch.Children or {}) do
		if childBranch and childBranch.Tree and childBranch.Tree.Parent then
			CreateBranchWeld(branch.Tree, childBranch.Tree)
			RebuildBranchWelds(childBranch)
		end
	end
end

local function GetRootBranch(branch)
	local currentBranch = branch

	while currentBranch and currentBranch.ParentingBranch do
		local parentBranch = GetBranchFromPart(currentBranch.ParentingBranch)

		if not parentBranch then
			break
		end

		currentBranch = parentBranch
	end

	return currentBranch
end

local function WeldAndRelease(part)
	local branch = GetBranchFromPart(part)

	if not branch then
		return
	end

	branch.Tree.Anchored = false

	for _, object in ipairs(branch.Tree:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = false
		end
	end

	DestroyLeaf(branch)

	for _, childBranch in ipairs(branch.Children or {}) do
		CreateBranchWeld(branch.Tree, childBranch.Tree)
		WeldAndRelease(childBranch.Tree)
	end
end

local function AnchorAllChildren(part)
	local branch = GetBranchFromPart(part)

	if not branch then
		return
	end

	branch.Tree.Anchored = true
	DestroyLeaf(branch)

	for _, childBranch in ipairs(branch.Children or {}) do
		AnchorAllChildren(childBranch.Tree)
	end
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

local function RemoveChildBranch(parentBranch, childBranch)
	if not parentBranch or not parentBranch.Children then
		return
	end

	for i = #parentBranch.Children, 1, -1 do
		if parentBranch.Children[i] == childBranch then
			table.remove(parentBranch.Children, i)
			break
		end
	end
end

local function TransferChildrenToNewBranch(oldBranch, newBranch)
	local childrenTransfer = oldBranch.Children or {}

	newBranch.Children = childrenTransfer
	oldBranch.Children = {}

	for _, childBranch in ipairs(childrenTransfer) do
		childBranch.ParentingBranch = newBranch.Tree
	end
end

local function GetCutDistanceFromBottom(part, hitPosition)
	local Branch = GetBranchFromPart(part)
	local totalLength = part.Size.Y
	local halfLength = totalLength / 2
	local relativePos = part.CFrame:PointToObjectSpace(hitPosition)

	--local safeMin = math.min(0.2, totalLength)
	--local safeMax = math.max(0.2, totalLength - 0.2)
	local safeMin = 0
	local safeMax = totalLength

	if #Branch.Children == 0 then
		safeMax = math.max(0.2, totalLength - 0.2)
	end

	if Branch.ParentingBranch == nil then
		safeMin = math.min(0.2, totalLength)
	end

	if safeMax < safeMin then
		return nil
	end

	local rawY = math.clamp(relativePos.Y + halfLength, safeMin, safeMax)

	local cutYFromBottom = math.floor(rawY * 5 + 0.5) / 5

	return cutYFromBottom
end

local function FindNotchAtCutY(targetBranch, CutY)
	if not targetBranch.Notch then
		return nil
	end

	for i, notchData in ipairs(targetBranch.Notch) do
		if notchData.Part and notchData.Part.Parent then
			if math.abs(notchData.CutY - CutY) <= 0.05 then
				return notchData, i
			end
		end
	end

	return nil
end

local function GetCutYFromNotchPart(part, notchPart)
	local targetBranch = GetBranchFromPart(part)

	if not targetBranch or not targetBranch.Notch then
		return nil
	end

	for _, notchData in ipairs(targetBranch.Notch) do
		if notchData.Part == notchPart then
			return notchData.CutY
		end
	end

	return nil
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

local function NotchCleanUp(Part)
	local Branch = GetBranchFromPart(Part)

	if not Branch then
		return
	end

	local Notch = Branch.Notch

	if Notch then
		for _, notchData in pairs(Notch) do
			if notchData.Part then
				notchData.Part:Destroy()
			end

			if notchData.WC then
				notchData.WC:Destroy()
			end
		end

		--Branch.Notch = nil
	end

	if Branch.Children then
		for _, Child in ipairs(Branch.Children) do
			NotchCleanUp(Child.Tree)
		end
	end
end

local function Interesct(Part, CutDistanceFromBottom)
	local targetBranch = GetBranchFromPart(Part)

	if targetBranch.ParentingBranch then
		NotchCleanUp(targetBranch.ParentingBranch)
	else
		NotchCleanUp(targetBranch.Tree)
	end

	if not targetBranch then
		return
	end

	local targetPart = targetBranch.Tree

	if not targetPart then
		return
	end

	local originalCFrame = targetPart.CFrame
	local originalSize = targetPart.Size
	local totalLength = originalSize.Y

	if totalLength <= 0.2 then
		warn(("Tree too small to cut (%.2f studs tall)"):format(totalLength))
		return
	end

	--local cutY = GetCutDistanceFromBottom(targetPart, result.Position)
	local cutY = CutDistanceFromBottom

	if not cutY then
		return
	end

	local cutMargin = 0.4
	local bottomHeight = cutY
	local topHeight = totalLength - cutY

	--if bottomHeight <= 0 or topHeight <= 0 then
	--	print("edwadwadwadawd")
	--	return
	--end
	--
	local hadTopMark = targetPart:FindFirstChild("Top") ~= nil
	local hadBottomMark = targetPart:FindFirstChild("Bottom") ~= nil

	local anchorStates = {}
	local ignoreRestore = {}

	local originalRootBranch = GetRootBranch(targetBranch)

	SaveBranchTreeAnchorStates(originalRootBranch, anchorStates)
	RemoveAllBranchWeldsFromBranchTree(originalRootBranch)

	local parentPart = targetBranch.ParentingBranch
	local parentBranch = nil

	if parentPart then
		parentBranch = GetBranchFromPart(parentPart)
	end

	local function FinishIntersection()
		if originalRootBranch then
			RemoveAllBranchWeldsFromBranchTree(originalRootBranch)
			RebuildBranchWelds(originalRootBranch)
		end

		RestoreAnchorStates(anchorStates, ignoreRestore)
	end

	if cutY >= totalLength - cutMargin and #targetBranch.Children > 0 then
		AnchorAllChildren(targetPart)

		for _, childBranch in ipairs(targetBranch.Children) do
			childBranch.ParentingBranch = nil
			IgnoreBranchFromRestore(childBranch, ignoreRestore)

			WeldAndRelease(childBranch.Tree)
			RefreshMark(childBranch.Tree, -1)
		end

		targetBranch.Children = {}

		RefreshMark(targetPart, 1)

		FinishIntersection()
		return
	end

	if cutY <= cutMargin and targetBranch.ParentingBranch then
		IgnoreBranchFromRestore(targetBranch, ignoreRestore)

		AnchorAllChildren(targetPart)

		if parentBranch then
			RefreshMark(parentPart, 1)
			RemoveChildBranch(parentBranch, targetBranch)
		end

		targetBranch.ParentingBranch = nil

		WeldAndRelease(targetPart)
		RefreshMark(targetPart, -1)

		FinishIntersection()
		return
	end

	local topSize = Vector3.new(originalSize.X, topHeight, originalSize.Z)
	local topCFrame = originalCFrame * CFrame.new(0, bottomHeight / 2, 0)

	--if topSize.Y < 0.2 then
	--	return
	--end

	if targetBranch.isPlank then
		local topSize = Vector3.new(originalSize.X, topHeight, originalSize.Z)
		local topCFrame = originalCFrame * CFrame.new(0, bottomHeight / 2, 0)

		if targetBranch.isPlank then
			local topVolume = topSize.X * topSize.Y * topSize.Z

			local topPlank = Base.newPlank(nil, topCFrame, topVolume, originalSize.X, originalSize.Z)

			topPlank.Tree.Anchored = false

			local bottomSize = Vector3.new(originalSize.X, bottomHeight, originalSize.Z)
			local bottomCFrame = originalCFrame * CFrame.new(0, -topHeight / 2, 0)

			targetPart.Anchored = true
			targetPart.Size = bottomSize
			targetPart.CFrame = bottomCFrame

			FinishIntersection()
			return
		else
			local topBranch = Base.new(targetBranch.TreeClass, topCFrame, nil, targetBranch.N, -99, topSize)

			topBranch.Tree.Anchored = true

			RefreshMark(topBranch.Tree, -1)

			if hadTopMark then
				RefreshMark(topBranch.Tree, 1)
			end

			local bottomSize = Vector3.new(originalSize.X, bottomHeight, originalSize.Z)
			local bottomCFrame = originalCFrame * CFrame.new(0, -topHeight / 2, 0)

			targetPart.Anchored = true
			targetPart.Size = bottomSize
			targetPart.CFrame = bottomCFrame

			if hadBottomMark then
				RefreshMark(targetPart, -1)
			end

			RefreshMark(targetPart, 1)

			TransferChildrenToNewBranch(targetBranch, topBranch)

			IgnoreBranchFromRestore(topBranch, ignoreRestore)

			if targetBranch.Leaf then
				targetBranch.Leaf:Destroy()
				targetBranch.Leaf = nil
			end

			WeldAndRelease(topBranch.Tree)

			FinishIntersection()
		end
	else
		local topBranch = Base.new(targetBranch.TreeClass, topCFrame, nil, targetBranch.N, -99, topSize)

		topBranch.Tree.Anchored = true

		RefreshMark(topBranch.Tree, -1)

		if hadTopMark then
			RefreshMark(topBranch.Tree, 1)
		end

		local bottomSize = Vector3.new(originalSize.X, bottomHeight, originalSize.Z)
		local bottomCFrame = originalCFrame * CFrame.new(0, -topHeight / 2, 0)

		targetPart.Anchored = true
		targetPart.Size = bottomSize
		targetPart.CFrame = bottomCFrame

		if hadBottomMark then
			RefreshMark(targetPart, -1)
		end

		RefreshMark(targetPart, 1)

		TransferChildrenToNewBranch(targetBranch, topBranch)

		IgnoreBranchFromRestore(topBranch, ignoreRestore)

		if targetBranch.Leaf then
			targetBranch.Leaf:Destroy()
		end

		WeldAndRelease(topBranch.Tree)

		FinishIntersection()

		--local fallingPart = topBranch.Tree
		--
		--fallingPart.Anchored = false
		--
		--local pushDirection = Vector3.new(
		--	math.random(-100, 100) / 100,
		--	0.4,
		--	math.random(-100, 100) / 100
		--).Unit
		--
		--fallingPart:ApplyImpulse(pushDirection * fallingPart.AssemblyMass * 80)
		--
		--fallingPart.AssemblyAngularVelocity = Vector3.new(
		--	math.random(-4, 4),
		--	math.random(-4, 4),
		--	math.random(-4, 4)
		--)
	end
end

function TCSS:AttemptIntersection(result)
	if not result or not result.Instance then
		return
	end

	if not result.Instance:HasTag("Cuttable") then
		return
	end

	local targetBranch = GetBranchFromPart(result.Instance)

	if targetBranch.Tree.Size.Y <= 0.21 then
		warn(("Tree too small to cut (%.2f studs tall)"):format(targetBranch.Tree.Size.Y))
		return
	end

	local CutY = GetCutDistanceFromBottom(targetBranch.Tree, result.Position)

	if CutY and targetBranch then
		if FindNotchAtCutY(targetBranch, CutY) then
			Interesct(targetBranch.Tree, CutY)
		else
			local Notch = Instance.new("Part")
			Notch.Transparency = 0.5
			Notch.Size = Vector3.new(targetBranch.Tree.Size.X * 1.01, 0.067, targetBranch.Tree.Size.Z * 1.01)
			Notch.CFrame = targetBranch.Tree.CFrame * CFrame.new(0, ((targetBranch.Tree.Size.Y / 2) * -1) + CutY, 0)
			Notch.Parent = targetBranch.Tree
			Notch.CanCollide = false
			Notch.Anchored = false
			Notch.Name = "Notch"
			Notch.Material = Enum.Material.SmoothPlastic
			Notch.Color = Color3.new(1, 1, 1)

			CollectionService:AddTag(Notch, "Notch")

			local wc = Instance.new("WeldConstraint")
			wc.Name = "NotchWeld"
			wc.Part0 = targetBranch.Tree
			wc.Part1 = Notch
			wc.Parent = targetBranch.Tree

			table.insert(targetBranch.Notch, {
				Part = Notch,
				CutY = CutY,
				WC = wc,
			})
		end
	end
end

function TCSS:IntersectFromNotch(part)
	local CutY = GetCutYFromNotchPart(part.Parent, part)
	print(CutY)
	Interesct(part.Parent, CutY)
end

function TCSS:Init(BaseEnv)
	Base = BaseEnv
	TreeRegistry = BaseEnv.TreeRegistry

	return self
end

return TCSS
