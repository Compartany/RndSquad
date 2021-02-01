local mod = mod_loader.mods[modApi.currentMod]
local tool = mod.tool
local baseRandomSequenceNum = 3

local this = {
    HintPawnTypes = {},
    PawnNames = {}
}

RndWeaponReroll = Skill:new{
    Icon = "weapons/RndWeaponReroll.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 1},
    RandomSequenceNum = baseRandomSequenceNum,
    LaunchSound = "/weapons/swap",
    TipImage = {
        Unit = Point(2, 2),
        Friendly = Point(1, 2),
        Target = Point(1, 2),
        CustomPawn = "RndMechPrime"
    }
}
RndWeaponReroll_A = RndWeaponReroll:new{
    RandomSequenceNum = baseRandomSequenceNum + 1
}
RndWeaponReroll_B = RndWeaponReroll:new{
    RandomSequenceNum = baseRandomSequenceNum + 1
}
RndWeaponReroll_AB = RndWeaponReroll:new{
    RandomSequenceNum = baseRandomSequenceNum + 2
}

function RndWeaponReroll:GetTargetArea(point)
    local ret = PointList()
    if Board:IsTipImage() then
        ret:push_back(Point(1, 2))
    else
        local mission = GetCurrentMission()
        if mission and mission.RndWeaponReroll_Target then
            local pawn = Board:GetPawn(mission.RndWeaponReroll_Target)
            if pawn and pawn:IsActive() then
                local boardSize = Board:GetSize()
                for x = 0, boardSize.x - 1 do
                    for y = 0, boardSize.y - 1 do
                        ret:push_back(Point(x, y))
                    end
                end
            end
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
    end
    return ret
end

function RndWeaponReroll:GetSkillEffect(p1, p2)
    return Board:IsTipImage() and self:GetSkillEffect_TipImage() or self:GetSkillEffect_Inner(p1, p2)
end

function RndWeaponReroll:GetSkillEffect_Inner(p1, p2)
    local ret = SkillEffect()
    local target = nil
    local mission = GetCurrentMission()
    if mission and mission.RndWeaponReroll_Target then
        target = Board:GetPawn(mission.RndWeaponReroll_Target)
        p2 = target:GetSpace()
    else
        target = Board:GetPawn(p2)
    end
    if target then
        ret:AddScript(string.format([[
            local id = %d
            local mission = GetCurrentMission()
            if mission then
                mission.RndWeaponReroll_Target = id
            end
            local weaponIds = rnd_modApiExt.pawn:getWeapons(id)
            for _, weaponId in ipairs(weaponIds) do
                local weapon = _G[weaponId]
                if weapon and weapon.IsRandomWeapon then
                    weapon:SwitchRandomSequence()
                end
            end
        ]], target:GetId()))
        ret:AddScript(string.format([[
            local pawn = Board:GetPawn(%d)
            if pawn then
                local Weapons = mod_loader.mods.RndSquad.weapons
                local p2 = %s
                local text = Weapons:GetPawnWeaponName(pawn) -- 不要验证 text 是否为空
                Board:Ping(p2, GL_Color(255, 255, 255, 0))
                Weapons:SetHintText(pawn, text)
            end
        ]], target:GetId(), p2:GetString()))
        ret:AddDelay(0.2)
        ret:AddScript(string.format([[
            local pawn = Board:GetPawn(%d)
            if pawn then
                pawn:SetActive(true)
                pawn:SetRndReactivated(true)
            end
        ]], Pawn:GetId()))
    end
    return ret
end

function RndWeaponReroll:GetSkillEffect_TipImage()
    local ret = SkillEffect()
    local p2 = Point(1, 2)
    local pawn = Board:GetPawn(p2)
    local globalKey = "RndWeaponReroll_TipImageWeapons" .. self.RandomSequenceNum
    if pawn then
        if not RND_GLOBAL[globalKey] then
            local weapons = {}
            local class = _G[pawn:GetType()].Class
            if #this.Weapons[class] > 0 then
                for i = 1, self.RandomSequenceNum do
                    local id = random_element(this.Weapons[class])
                    weapons[#weapons + 1] = this:GetWeaponKey(id, "Name")
                end
            end
            RND_GLOBAL[globalKey] = weapons
            RND_GLOBAL[globalKey .. "_Index"] = 1
        end
        ret:AddScript(string.format([=[
            local p2 = %s
            local globalKey = "%s"
            local indexKey = globalKey .. "_Index"
            local weapons = RND_GLOBAL[globalKey]
            local weapon = weapons[RND_GLOBAL[indexKey]]
            RND_GLOBAL[indexKey] = RND_GLOBAL[indexKey] %% #weapons + 1
            Board:Ping(p2, GL_Color(255, 255, 255, 0))
            Board:AddAlert(p2, weapon)
        ]=], p2:GetString(), globalKey))
    end
    return ret
end

RndWeapon = Skill:new{
    Upgrade = "Z",
    IsRandomWeapon = true,
    RndId = "RndWeapon", -- 子类必须修改为与 table 名一致
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
        assert(self.RndId ~= "RndWeapon")
        fx:AddScript(self.RndId .. ":NextWeapon()")
        fx:AddScript(string.format([[
            modApi:conditionalHook(
                function()
                    return Board and not Board:IsBusy()
                end,
                function()
                    local pawn = Board:GetPawn(%d)
                    if pawn then
                        local Weapons = mod_loader.mods.RndSquad.weapons
                        local text = pawn:IsActive() and Weapons:GetPawnWeaponName(pawn) or nil
                        Weapons:SetHintText(pawn, text)
                    end
                end
            )
        ]], Pawn:GetId()))
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
            if space == p1 or (space.y < 3 and space.x > 1 and space.x < 4) then
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
    if not reset and
        (mission.RndWeapons and mission.RndWeapons[class] and mission.RndWeapons[class][1] and
            #mission.RndWeapons[class][1] > 0) then
        return
    end
    if not mission.RndWeapons then
        mission.RndWeapons = {}
    end
    if class then
        mission.RndWeapons[class] = {
            SequenceIndex = 1,
            WeaponIndex = 1
        }
        for i = 1, mission.RandomSequenceNum do
            local rnds = {}
            if this.Weapons and mission then
                local cWeapons = this.Weapons[class]
                if cWeapons and #cWeapons > 0 then
                    local orders = {}
                    for j = 1, #cWeapons do
                        orders[j] = j
                    end
                    while #orders > 0 do
                        rnds[#rnds + 1] = cWeapons[random_removal(orders)]
                    end
                end
            end
            mission.RndWeapons[class][i] = rnds
        end
    end
end

function RndWeapon:GetWeaponTable()
    local table = nil
    local wp = self:GetWeapon()
    if wp then
        local upgrade = self.Upgrade or "Z"
        if upgrade == "AB" then
            local id = wp .. "_AB"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "A"
            end
        end
        if upgrade == "B" then
            local id = wp .. "_B"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "Z"
            end
        end
        if upgrade == "A" then
            local id = wp .. "_A"
            if this:IsValidWeapon(_G[id]) then
                table = _G[id]
            else
                upgrade = "Z"
            end
        end
        if upgrade == "Z" then
            table = _G[wp]
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
                    local crWeaponsAll = mission.RndWeapons[class]
                    local crWeapons = crWeaponsAll[crWeaponsAll.SequenceIndex]
                    if crWeapons and #crWeapons > 0 then
                        wp = crWeapons[crWeaponsAll.WeaponIndex]
                    end
                end
            end
        end
    end
    return wp
end

function RndWeapon:NextWeapon()
    local class = this:GetWeaponClass(self)
    if not Board:IsTipImage() and class then
        local mission = GetCurrentMission()
        if mission and mission.RndWeapons and mission.RndWeapons[class] then
            local crWeaponsAll = mission.RndWeapons[class]
            local crWeapons1 = crWeaponsAll[1]
            if crWeapons1 and #crWeapons1 > 1 then -- 只有一件也不用切换了
                crWeaponsAll.WeaponIndex = crWeaponsAll.WeaponIndex % #crWeapons1 + 1
            end
        end
    end
end

function RndWeapon:SwitchRandomSequence()
    local class = this:GetWeaponClass(self)
    if not Board:IsTipImage() and class then
        local mission = GetCurrentMission()
        if mission and mission.RndWeapons and mission.RndWeapons[class] then
            local crWeaponsAll = mission.RndWeapons[class]
            if #crWeaponsAll > 1 then -- 只有一条线就不用切换了
                crWeaponsAll.SequenceIndex = crWeaponsAll.SequenceIndex % #crWeaponsAll + 1
            end
        end
    end
end

----------------------------------------------------------

RndWeaponPrime = RndWeapon:new{
    RndId = "RndWeaponPrime",
    Class = "Prime",
    Icon = "weapons/RndWeaponPrime.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 3}
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
    RndId = "RndWeaponBrute",
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
    RndId = "RndWeaponRanged",
    Class = "Ranged",
    Icon = "weapons/RndWeaponRanged.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 1}
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
    RndId = "RndWeaponScience",
    Class = "Science",
    Icon = "weapons/RndWeaponScience.png",
    PowerCost = 1,
    Upgrades = 1,
    UpgradeCost = {1}
}
RndWeaponScience_A = RndWeaponScience:new{
    Upgrade = "AB"
}

RndWeaponAny = RndWeapon:new{
    RndId = "RndWeaponAny",
    Icon = "weapons/RndWeaponAny.png",
    PowerCost = 1,
    Upgrades = 1,
    UpgradeCost = {1},
    TipImage = {
        Unit = Point(2, 3),
        Enemy = Point(2, 2),
        Enemy2 = Point(3, 2),
        Enemy3 = Point(1, 1),
        Friendly = Point(3, 1),
        Mountain = Point(2, 1),
        Target = Point(2, 2),
        CustomPawn = "RndMechPrime"
    }
}
RndWeaponAny_A = RndWeaponAny:new{
    Upgrade = "AB"
}

RndWeaponTechnoVek = RndWeapon:new{
    RndId = "RndWeaponTechnoVek",
    Class = "TechnoVek",
    Icon = "weapons/RndWeaponTechnoVek.png",
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = {1, 3},
    TipImage = {
        Unit = Point(2, 3),
        Enemy = Point(2, 2),
        Enemy2 = Point(3, 2),
        Enemy3 = Point(1, 1),
        Friendly = Point(3, 1),
        Mountain = Point(2, 1),
        Target = Point(2, 2),
        CustomPawn = "HornetMech"
    }
}
RndWeaponTechnoVek_A = RndWeaponTechnoVek:new{
    Upgrade = "A"
}
RndWeaponTechnoVek_B = RndWeaponTechnoVek:new{
    Upgrade = "B"
}
RndWeaponTechnoVek_AB = RndWeaponTechnoVek:new{
    Upgrade = "AB"
}

----------------------------------------------------------

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
                local id = weapon:GetWeapon()
                if id then
                    if text then
                        text = text .. " & " .. self:GetWeaponKey(id, "Name")
                    else
                        text = self:GetWeaponKey(id, "Name")
                    end
                end
            end
        end
    end
    return text
end

function this:SetHintText(pawn, text)
    if pawn then
        local type = pawn:GetType()
        local name = self.PawnNames[type]
        if text and text ~= "" then
            if not name then
                name = GetText(type)
                self.PawnNames[type] = name
            end
            self.HintPawnTypes[type] = true -- 必须以 type 为 key
            modApi:setText(type, name .. " - " .. text)
            if not RND_GLOBAL.data.tip.HintText then
                Game:AddTip("HintTextTip", pawn:GetSpace())
                RND_GLOBAL.data.tip.HintText = true
                modApi:writeProfileData(RND_GLOBAL.profileKey, RND_GLOBAL.data)
            end
        elseif name then
            modApi:setText(type, name)
        end
    end
end

function this:InitHintText(checkActive)
    local pawns = extract_table(Board:GetPawns(TEAM_MECH))
    for _, id in ipairs(pawns) do
        local pawn = Board:GetPawn(id)
        if pawn and (not checkActive or pawn:IsActive()) then
            local text = self:GetPawnWeaponName(pawn)
            if text then
                self:SetHintText(pawn, text)
            end
        end
    end
end

function this:ResetHintText()
    if self.HintPawnTypes then
        for type, hint in pairs(self.HintPawnTypes) do
            if hint and self.PawnNames[type] then
                modApi:setText(type, self.PawnNames[type])
                self.HintPawnTypes[type] = nil
            end
        end
    end
end

function this:InitRndWeapons(mission)
    mission.RndWeaponReroll_Target = nil
    mission.RandomSequenceNum = baseRandomSequenceNum
    local randomWeapons = {}
    local pawns = extract_table(Board:GetPawns(TEAM_MECH))
    for _, id in ipairs(pawns) do
        local weaponIds = rnd_modApiExt.pawn:getWeapons(id)
        for _, weaponId in ipairs(weaponIds) do
            local weapon = _G[weaponId]
            if weapon then
                if weapon.IsRandomWeapon then
                    randomWeapons[#randomWeapons + 1] = weapon
                elseif weapon.RandomSequenceNum then
                    mission.RandomSequenceNum = mission.RandomSequenceNum + weapon.RandomSequenceNum -
                                                    baseRandomSequenceNum
                end
            end
        end
    end
    for _, randomWeapon in ipairs(randomWeapons) do
        randomWeapon:InitWeapons(true)
    end
end

function this:Init()
    sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
        self:ResetHintText()
    end)
end

function this:Load()
    self.Weapons = {
        TechnoVek = {"Vek_Beetle", "Vek_Hornet", "Vek_Scarab"}
    }
    -- weaponDeck 此时未初始化，而是在在 ModsFirstLoadedHook 中初始化，这里也等到该时点后再初始化
    modApi:addModsFirstLoadedHook(function()
        for id, enabled in pairs(modApi.weaponDeck) do
            local weapon = _G[id]
            if enabled and self:IsValidWeapon(weapon) then
                local class = self:GetWeaponClass(weapon)
                if not self.Weapons[class] then
                    self.Weapons[class] = {}
                end
                table.insert(self.Weapons[class], id)
            end
        end
    end)

    modApi:addNextTurnHook(function(mission)
        if not mission.RndWeapons_Init then
            self:InitRndWeapons(mission)
            mission.RndWeapons_Init = true
        end

        if Game:GetTeamTurn() == TEAM_PLAYER then
            mission.RndWeaponReroll_Target = nil
            self:InitHintText()
        end
    end)
    modApi:addPostLoadGameHook(function()
        modApi:runLater(function(mission)
            if mission.RndWeapons_Init then
                self:InitHintText(true)
            end
        end)
    end)
    modApi:addMissionEndHook(function(mission)
        self:ResetHintText()
    end)

    modApi:addTestMechEnteredHook(function(mission)
        modApi:runLater(function(mission)
            modApi:scheduleHook(250, function()
                self:InitRndWeapons(mission)
                self:InitHintText()
            end)
        end)
    end)
    modApi:addTestMechExitedHook(function(mission)
        self:ResetHintText()
    end)

    -- disable Post_Move temporarily
    local moveBonuses = {}
    rnd_modApiExt:addSkillStartHook(function(mission, pawn, weaponId, p1, p2)
        local reroll = tool:ExtractWeapon(weaponId) == "RndWeaponReroll"
        if reroll and Pawn:IsAbility("Post_Move") then
            local speed = pawn:GetMoveSpeed()
            pawn:SetMoveSpeed(0)
            moveBonuses[pawn:GetId()] = pawn:GetMoveSpeed()
            pawn:SetMoveSpeed(speed)
            pawn:AddMoveBonus(-25)
        end
    end)
    rnd_modApiExt:addSkillEndHook(function(mission, pawn, weaponId, p1, p2)
        local reroll = tool:ExtractWeapon(weaponId) == "RndWeaponReroll"
        if reroll and Pawn:IsAbility("Post_Move") then
            pawn:AddMoveBonus(moveBonuses[pawn:GetId()])
        end
    end)
end

return this
