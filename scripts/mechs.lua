local mod = mod_loader.mods[modApi.currentMod]
local palettes = mod.lib.palettes
local colorOffset = palettes.getOffset("rndSquad_palette")

RndMechPrime = PunchMech:new{
    Image = "RndMechPrime",
    ImageOffset = colorOffset,
    SkillList = {"RndWeaponPrime", "RndWeaponReroll"}
}

RndMechBrute = TankMech:new{
    Image = "RndMechBrute",
    ImageOffset = colorOffset,
    SkillList = {"RndWeaponBrute"}
}

RndMechRanged = ArtiMech:new{
    Image = "RndMechRanged",
    ImageOffset = colorOffset,
    SkillList = {"RndWeaponRanged"}
}

RndMechScience = ScienceMech:new{
    Image = "RndMechScience",
    ImageOffset = colorOffset,
    SkillList = {"RndWeaponScience"}
}

local this = {}

function this:Load()
    -- nothing to do
end

return this
