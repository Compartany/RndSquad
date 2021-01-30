local this = {}

-- 提取武器名称与升级
function this:ExtractWeapon(weapon)
    local upgrade = "Z"
    if modApi:stringEndsWith(weapon, "_A") then
        upgrade = "A"
    elseif modApi:stringEndsWith(weapon, "_B") then
        upgrade = "B"
    elseif modApi:stringEndsWith(weapon, "_AB") then
        upgrade = "AB"
    end
    local name = weapon
    if upgrade ~= "Z" then
        local s = string.find(weapon, "_" .. upgrade .. "$")
        if s > 1 then
            name = string.sub(weapon, 1, s - 1)
        else
            name = ""
        end
    end
    return name, upgrade
end

-- 判断单位是否有指定装备（可判断升级情况）
function this:HasWeapon(pawn, name, upgradeCheck)
    upgradeCheck = upgradeCheck or false
    if pawn then
        local weapons = env_modApiExt.pawn:getWeapons(pawn:GetId())
        for _, weapon in ipairs(weapons) do
            local wp = upgradeCheck and weapon or self:ExtractWeapon(weapon)
            if wp == name then
                return true
            end
        end
    end
    return false
end

function this:Load()
    -- nothing to do
end

RND_GLOBAL.tool = this
return this
