local this = {}

function BoardPawn:IsRndActive()
    if self:IsAbility("Shifty") and self:GetMoveSpeed() == 1 then
        return false
    end
    return self:IsActive()
end

function BoardPawn:SetRndReactivated(reactive)
    local mission = GetCurrentMission()
    if mission and mission.RndReactivated then
        mission.RndReactivated[self:GetId()] = reactive or false
        return true
    end
    return false
end

function BoardPawn:IsRndReactivated()
    local mission = GetCurrentMission()
    if mission and mission.RndReactivated then
        return mission.RndReactivated[self:GetId()] or false
    end
    return false
end

local _Move_GetTargetArea = Move.GetTargetArea
function Move:GetTargetArea(point, ...)
    if Pawn:IsRndReactivated() and Pawn:IsAbility("Shifty") then
        local ret = PointList()
        ret:push_back(Pawn:GetSpace())
        return ret
    end
    return _Move_GetTargetArea(self, point, ...)
end
local _Move_GetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
    local ret = _Move_GetSkillEffect(self, p1, p2, ...)
    -- 保险起见还是处理一下 Post_Move
    if Pawn:IsRndReactivated() and (Pawn:IsAbility("Shifty") or Pawn:IsAbility("Post_Move")) then
        ret:AddDelay(0.2)
        ret:AddScript(string.format([[
            Board:GetPawn(%d):SetActive(true)
        ]], Pawn:GetId()))
    end
    return ret
end

function this:Load()
    modApi:addNextTurnHook(function(mission)
        if Game:GetTeamTurn() == TEAM_PLAYER then
            mission.RndReactivated = {}
        end
    end)
    modApi:addTestMechEnteredHook(function(mission)
        mission.RndReactivated = {}
    end)
end

return this
