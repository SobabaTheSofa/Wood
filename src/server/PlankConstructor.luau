local PlankConstructor = {}
PlankConstructor.__index = PlankConstructor

PlankConstructor.PlankRegistry = nil
PlankConstructor.GrowthAmmountPerIntervel = 1
--get libary

local function GetBranchFromPart(part)
	if not part then
		return nil
	end

	return PlankConstructor.PlankRegistry[part]
end

function PlankConstructor.New(volume, cframe, witdh, hieght, length) --length is to be implemented
    local self = setmetatable({}, PlankConstructor)

    local p, remainingVolume = self:PrintPlank(volume, witdh, hieght, cframe)

    self.PlankRegistry[p] = self

    p.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self.PlankRegistry[p] = nil
        end
	end)


    return self
end

function PlankConstructor:PrintPlank(Volume, width, hieght, cframe)
    local length = Volume / (width * hieght)

    local p = instance.new("Part")
    p.Size = Vector3.new(width, 1, hieght)
    p.CFrame = nil -- to be implemented

    local growthAmmount = math.ceil(length / PlankConstructor.GrowthAmmountPerIntervel)
    local remainingVolume = (growthAmmount - (length / PlankConstructor.GrowthAmmountPerIntervel)) * PlankConstructor.GrowthAmmountPerIntervel

    local randomtablename = {p}
    local Params = OverlapParams.new() -- it will be much better to create tag for furniture and only include that
   

    for _,player in ipairs(game.Players:GetPlayers()) do
        local character = player.Character
        table.insert(randomtablename, character)
    end
    --params.IncludeInstances = {p}
    params.ExcludeInstances = randomtablename

    --task.spawn(function()
    --    
    --end)

    for i = 1, growthAmmount do
             if i == (growthAmmount -1) then
                if self:CheckCollision(width, hieght, p.CFrame:ToWorldSpace(CFrame.new(0, PlankConstructor.GrowthAmmountPerIntervel/2 + p.size.Y/2, 0)), Params) then
                    p.Size = Vector3.new(width, p.Size.Y + PlankConstructor.GrowthAmmountPerIntervel, hieght)
                    task.wait(0.5)
                else
                    return p, ((PlankConstructor.GrowthAmmountPerIntervel * (growthAmmount - i)) + remainingVolume)
                    break
                end 
             else
            p.Size = Vector3.new(width, p.Size.Y + remainingVolume, hieght)
            return p, 0
        end
    end
end

function PlankConstructor:CheckCollision(width, hieght, cframe, params)
    if #(workspace:GetPartBoundsInBox(cframe, Vector3.new(width, self.GrowthAmmountPerIntervel, hieght, params))) == 0 then
        return true
    else
        return false
    end
end

function PlankConstructor:Init(BaseEnv)
    self.PlankRegistry = BaseEnv
end

return PlankConstructor