local mod = mod_loader.mods[modApi.currentMod]
local tool = mod.tool

local this = {}

RndWeaponReroll = Skill:new{
    Icon = "weapons/RndWeaponReroll.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 3},
    Limited = 2,
    LaunchSound = "/weapons/swap",
    TipImage = {
        Unit = Point(2, 2),
        Friendly = Point(1, 2),
        Target = Point(1, 2),
        CustomPawn = "RndMechPrime"
    }
}
RndWeaponReroll_A = RndWeaponReroll:new{
    Limited = 3
}
RndWeaponReroll_B = RndWeaponReroll:new{
    Limited = 4
}
RndWeaponReroll_AB = RndWeaponReroll:new{
    Limited = 5
}

function RndWeaponReroll:GetTargetArea(point)
    local ret = PointList()
    if Board:IsTipImage() then
        ret:push_back(Point(1, 2))
    else
        local pawns = extract_table(Board:GetPawns(TEAM_MECH))
        for _, id in ipairs(pawns) do
            local pawn = Board:GetPawn(id)
            if pawn and pawn:IsActive() then
                local weaponIds = rnd_modApiExt.pawn:getWeapons(id)
                for _, weaponId in ipairs(weaponIds) do
                    local weapon = _G[weaponId]
                    if weapon and weapon.IsRandomWeapon then
                        ret:push_back(pawn:GetSpace())
                    end
                end
            end
        end
    end
    return ret
end

function RndWeaponReroll:GetSkillEffect(p1, p2)
    return Board:IsTipImage() and self:GetSkillEffect_TipImage() or self:GetSkillEffect_Inner(p1, p2)
end

function RndWeaponReroll:GetSkillEffect_Inner(p1, p2)
    local ret = SkillEffect()
    local target = Board:GetPawn(p2)
    if target then
        ret:AddScript(string.format([[
            local weaponIds = rnd_modApiExt.pawn:getWeapons(%d)
            for _, weaponId in ipairs(weaponIds) do
                local weapon = _G[weaponId]
                if weapon and weapon.IsRandomWeapon then
                    weapon:NextWeapon()
                end
            end
        ]], target:GetId()))
        ret:AddScript(string.format([[
            local pawn = Board:GetPawn(%d)
            if pawn then
                local Weapons = mod_loader.mods.RndSquad.weapons
                local text = Weapons:GetPawnWeaponName(pawn)
                if text then
                    local p2 = %s
                    Board:Ping(p2, GL_Color(255, 255, 255, 0))
                    Board:AddAlert(p2, text)
                end
            end
        ]], target:GetId(), p2:GetString()))
        ret:AddDelay(0.2)

        -- special thanks to Lemonymous for the code below
        ret:AddScript(string.format([[
            local pawn = Board:GetPawn(%d)
            if pawn then
                modApi:conditionalHook(
                    function() return not Board:IsBusy() end,
                    function()
                        local origin = pawn:GetSpace()
                        pawn:SetActive(true)
                        Game:TriggerSound("/enemy/shared/robot_power_on")
                        Board:Ping(origin, GL_Color(255, 255, 255, 0))
                        pawn:SetSpace(Point(-1, -1))
                        modApi:conditionalHook(
                            function() return pawn:GetSpace() ~= origin end,
                            function()
                                pawn:SetSpace(origin)
                            end
                        )
                    end
                )
            end
        ]], Pawn:GetId()))
    end
    return ret
end

function RndWeaponReroll:GetSkillEffect_TipImage()
    local ret = SkillEffect()
    ret:AddScript([[
        local p2 = Point(1, 2)
        local pawn = Board:GetPawn(p2)
        local class = _G[pawn:GetType()].Class
        local Weapons = mod_loader.mods.RndSquad.weapons
        local text = random_element(Weapons.Weapons[class]).name
        Board:Ping(p2, GL_Color(255, 255, 255, 0))
        Board:AddAlert(p2, text)
    ]])
    ret:AddDelay(1)
    ret:AddScript([[
        local p1 = Point(2, 2)
        local pawn = Board:GetPawn(p1)
        pawn:SetActive(true)
        Game:TriggerSound("/enemy/shared/robot_power_on")
        Board:Ping(p1, GL_Color(255, 255, 255, 0))
    ]])
    return ret
end

RndWeapon = Skill:new{
    Upgrade = "Z",
    IsRandomWeapon = true,
    TipImage = {
        Unit = Point(2, 3),
        Enemy = Point(2, 2),
        Enemy2 = Point(3, 2),
        Enemy3 = Point(1, 1),
        Friendly = Point(3, 1),
        Mountain = Point(2, 1),
        Target = Point(2, 2)
    }
}

function RndWeapon:GetTargetArea(point)
    local table = self:GetWeaponTable()
    if table then
        if Board:IsTipImage() then
            local ret = PointList()
            ret:push_back(Point(2, 2))
            return ret
        else
            return table:GetTargetArea(point)
        end
    else
        return PointList()
    end
end

function RndWeapon:GetSkillEffect(p1, p2)
    return Board:IsTipImage() and self:GetSkillEffect_TipImage() or self:GetSkillEffect_Inner(p1, p2)
end

function RndWeapon:GetSkillEffect_Inner(p1, p2)
    local table = self:GetWeaponTable()
    if table then
        local fx = table:GetSkillEffect(p1, p2)
        fx:AddScript(string.format([[
            RndWeapon:NextWeapon("%s")
        ]], this:GetWeaponClass(self) or "nil"))
        self.LaunchSound = table.LaunchSound
        self.ImpactSound = table.ImpactSound
        return fx
    else
        return SkillEffect()
    end
end

function RndWeapon:GetSkillEffect_TipImage()
    local ret = nil
    local table = self:GetWeaponTable()
    if table then
        local p1 = Point(2, 3)
        local choices = {}
        local area = extract_table(table:GetTargetArea(p1))
        for _, space in ipairs(area) do
            if space.y < 3 then
                choices[#choices + 1] = space
            end
        end
        if #choices > 0 then
            local p2 = random_element(choices)
            ret = table:GetSkillEffect(p1, p2)
        end
    end
    return ret
end

function RndWeapon:InitWeapons(reset)
    local class = this:GetWeaponClass(self)
    local mission = GetCurrentMission()
    if not reset and (mission.RndWeapons and mission.RndWeapons[class] and #mission.RndWeapons[class] > 0) then
        return
    end
    if not mission.RndWeapons then
        mission.RndWeapons = {}
    end
    if class then
        local rnds = {}
        if this.Weapons and mission then
            local cWeapons = this.Weapons[class]
            if cWeapons and #cWeapons > 0 then
                local orders = {}
                for i = 1, #cWeapons do
                    orders[i] = i
                end
                while #orders > 0 do
                    rnds[#rnds + 1] = cWeapons[random_removal(orders)]
                end
            end
        end
        mission.RndWeapons[class] = rnds
    end
end

function RndWeapon:GetWeaponTable()
    local table = nil
    local wp = self:GetWeapon()
    if wp and wp.id then
        local upgrade = self.Upgrade or "Z"
        if upgrade == "AB" then
            local id = wp.id .. "_AB"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "A"
            end
        end
        if upgrade == "B" then
            local id = wp.id .. "_B"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "Z"
            end
        end
        if upgrade == "A" then
            local id = wp.id .. "_A"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "Z"
            end
        end
        if upgrade == "Z" then
            table = _G[wp.id]
        end
    end
    return table
end

function RndWeapon:GetWeapon()
    local wp = nil
    local class = this:GetWeaponClass(self)
    if this.Weapons and class then
        local cWeapons = this.Weapons[class]
        if cWeapons and #cWeapons > 0 then
            if Board:IsTipImage() then
                wp = random_element(cWeapons)
            else
                local mission = GetCurrentMission()
                if mission then
                    if not mission.RndWeapons or not mission.RndWeapons[class] or #mission.RndWeapons[class] == 0 then
                        self:InitWeapons()
                    end
                    local crWeapons = mission.RndWeapons[class]
                    if #crWeapons > 0 then
                        wp = crWeapons[#crWeapons]
                    end
                end
            end
        end
    end
    return wp
end

function RndWeapon:NextWeapon(class)
    class = class or this:GetWeaponClass(self)
    if not Board:IsTipImage() and class then
        local mission = GetCurrentMission()
        if mission and mission.RndWeapons and mission.RndWeapons[class] then
            local crWeapons = mission.RndWeapons[class]
            if #crWeapons > 0 then
                table.remove(crWeapons, #crWeapons)
            end
        end
    end
end

----------------------------------------------------------

RndWeaponPrime = RndWeapon:new{
    Class = "Prime",
    Icon = "weapons/RndWeaponPrime.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 2}
}
RndWeaponPrime_A = RndWeaponPrime:new{
    Upgrade = "A"
}
RndWeaponPrime_B = RndWeaponPrime:new{
    Upgrade = "B"
}
RndWeaponPrime_AB = RndWeaponPrime:new{
    Upgrade = "AB"
}

RndWeaponBrute = RndWeapon:new{
    Class = "Brute",
    Icon = "weapons/RndWeaponBrute.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 2}
}
RndWeaponBrute_A = RndWeaponBrute:new{
    Upgrade = "A"
}
RndWeaponBrute_B = RndWeaponBrute:new{
    Upgrade = "B"
}
RndWeaponBrute_AB = RndWeaponBrute:new{
    Upgrade = "AB"
}

RndWeaponRanged = RndWeapon:new{
    Class = "Ranged",
    Icon = "weapons/RndWeaponRanged.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 2}
}
RndWeaponRanged_A = RndWeaponRanged:new{
    Upgrade = "A"
}
RndWeaponRanged_B = RndWeaponRanged:new{
    Upgrade = "B"
}
RndWeaponRanged_AB = RndWeaponRanged:new{
    Upgrade = "AB"
}

RndWeaponScience = RndWeapon:new{
    Class = "Science",
    Icon = "weapons/RndWeaponScience.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 2}
}
RndWeaponScience_A = RndWeaponScience:new{
    Upgrade = "A"
}
RndWeaponScience_B = RndWeaponScience:new{
    Upgrade = "B"
}
RndWeaponScience_AB = RndWeaponScience:new{
    Upgrade = "AB"
}

function this:GetWeaponClass(weapon)
    local class = nil
    if weapon.Passive ~= "" then
        class = "Passive"
    else
        class = weapon:GetClass()
        if class == "" then
            class = "Any"
        end
    end
    return class
end

function this:IsValidWeapon(weapon)
    return weapon and type(weapon) == "table" and (not weapon.GetUnlocked or weapon:GetUnlocked()) and
               not weapon.IsRandomWeapon
end

function this:GetWeaponKey(id, key)
    local textId = id .. "_" .. key
    if IsLocalizedText(textId) then
        return GetLocalizedText(textId)
    end
    return _G[id] and _G[id][key] or id
end

function this:GetPawnWeaponName(pawn)
    local text = nil
    if pawn then
        local weaponIds = rnd_modApiExt.pawn:getWeapons(pawn:GetId())
        for _, weaponId in ipairs(weaponIds) do
            local weapon = _G[weaponId]
            if weapon and weapon.IsRandomWeapon then
                local entry = weapon:GetWeapon()
                if entry then
                    if text then
                        text = text .. " & " .. entry.name
                    else
                        text = entry.name
                    end
                end
            end
        end
    end
    return text
end

function this:Load()
    self.Weapons = {}
    for id, enabled in pairs(modApi.weaponDeck) do
        local weapon = _G[id]
        if enabled and self:IsValidWeapon(weapon) then
            local class = self:GetWeaponClass(weapon)
            if not self.Weapons[class] then
                self.Weapons[class] = {}
            end
            table.insert(self.Weapons[class], {
                id = id,
                name = self:GetWeaponKey(id, "Name")
            })
        end
    end

    modApi:addNextTurnHook(function(mission)
        if not mission.RndWeapons_Init then
            local pawns = extract_table(Board:GetPawns(TEAM_MECH))
            for _, id in ipairs(pawns) do
                local weaponIds = rnd_modApiExt.pawn:getWeapons(id)
                for _, weaponId in ipairs(weaponIds) do
                    local weapon = _G[weaponId]
                    if weapon and weapon.IsRandomWeapon then
                        weapon:InitWeapons()
                    end
                end
                mission.RndWeapons_Init = true
            end
        end

        if Game:GetTeamTurn() == TEAM_PLAYER then
            local pawns = extract_table(Board:GetPawns(TEAM_MECH))
            for _, id in ipairs(pawns) do
                local pawn = Board:GetPawn(id)
                if pawn then
                    local text = self:GetPawnWeaponName(pawn)
                    if text then
                        Board:AddAlert(pawn:GetSpace(), text)
                    end
                end
            end
        end
    end)
end

return this
