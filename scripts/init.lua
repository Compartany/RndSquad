local mod = {
    id = "RndSquad",
    name = "True Random Squad",
    version = "1.0.2.20211111",
    requirements = {"kf_ModUtils"},
    modApiVersion = "2.6.3",
    icon = "img/icon.png",
    author = "Compartany",
    description = "These Mechs have mastered the laws of randomness, and they can always find the most useful weapons from randomness."
}
print(mod.version) -- for package and release

function mod:init()
    -- 简化操作的全局变量，仅适用于临时传递
    -- 某些状态需要退出游戏后固化到本地，可以存在 Mission 上
    local profileKey = "MOD_RndSquad"
    local data = modApi:readProfileData(profileKey)
    if not data or not data.tip then
        data = {
            tip = {}
        }
        modApi:writeProfileData(profileKey, data)
    end
    RND_GLOBAL = {
        profileKey = profileKey,
        data = data,
        weaponNames = {
            "RndWeaponReroll", "RndWeaponPrime", "RndWeaponBrute", "RndWeaponRanged", "RndWeaponScience",
            "RndWeaponAny", "RndWeaponTechnoVek"
        }
    }

    self:initLibs()
    self:initResources()
    self:initScripts()
    self:initOptions()
end

-- 改变设置、继续游戏都会重新加载
function mod:load(options, version)
    self.lib.modApiExt:load(self, options, version)
    self.lib.shop:load(options)
    self:loadScripts()
    modApi:addSquad({RndMod_Texts.squad_prs_name, "RndMechPrime", "RndMechRanged", "RndMechScience"},
        RndMod_Texts.squad_prs_name, RndMod_Texts.squad_description, self.resourcePath .. "img/icon.png")
    modApi:addSquad({RndMod_Texts.squad_pbr_name, "RndMechPrime", "RndMechBrute", "RndMechRanged"},
        RndMod_Texts.squad_pbr_name, RndMod_Texts.squad_description, self.resourcePath .. "img/icon.png")
    modApi:addSquad({RndMod_Texts.squad_pbs_name, "RndMechPrime", "RndMechBrute", "RndMechScience"},
        RndMod_Texts.squad_pbs_name, RndMod_Texts.squad_description, self.resourcePath .. "img/icon.png")

    if options.opt_resetTips.enabled then
        RND_GLOBAL.data.tip = {}
        modApi:writeProfileData(RND_GLOBAL.profileKey, RND_GLOBAL.data)
        options.opt_resetTips.enabled = false
    end
end

function mod:loadScripts()
    self.i18n:Load()
    self.tool:Load()
    self.pawns:Load()
    self.mechs:Load()
    self.weapons:Load()
end

function mod:initLibs()
    rnd_modApiExt = require(self.scriptPath .. "modApiExt/modApiExt")
    rnd_modApiExt:init()
    self.lib = {}
    self.lib.modApiExt = rnd_modApiExt
    self.lib.palettes = require(self.scriptPath .. "libs/customPalettes")
    self.lib.shop = require(self.scriptPath .. "libs/shop")
end

function mod:initScripts()
    -- 加载的顺序很重要，不要乱调
    self.i18n = require(self.scriptPath .. "i18n")
    self.i18n:Init()
    self.tool = require(self.scriptPath .. "tool")
    self.pawns = require(self.scriptPath .. "pawns")
    self.mechs = require(self.scriptPath .. "mechs")
    self.weapons = require(self.scriptPath .. "weapons")
    self.weapons:Init()
end

function mod:initOptions()
    local disabled = {
        RndWeaponReroll = true,
        RndWeaponTechnoVek = true
    }
    for _, weapon in ipairs(RND_GLOBAL.weaponNames) do
        local name = RndWeapon_Texts[weapon .. "_Name"]
        self.lib.shop:addWeapon({
            id = weapon,
            name = name,
            desc = string.format(RndMod_Texts.addToShop, name),
            default = disabled[weapon] and {
                enabled = false
            } or nil
        })
    end

    modApi:addGenerationOption("opt_resetTips", RndMod_Texts.resetTips_title, RndMod_Texts.resetTips_text, {
        enabled = false
    })
end

function mod:initResources()
    for _, weapon in ipairs(RND_GLOBAL.weaponNames) do
        local wpImg = weapon .. ".png"
        modApi:appendAsset("img/weapons/" .. wpImg, self.resourcePath .. "img/weapons/" .. wpImg)
    end

    self.lib.palettes.addPalette({
        ID = "rndSquad_palette",
        Name = "True Random Squad",
        PlateHighlight = {228, 228, 228}, -- 高光   rgb(228, 228, 228)
        PlateLight = {0, 0, 0}, -- 主色             rgb(0, 0, 0)
        PlateMid = {0, 0, 0}, -- 主色阴影           rgb(0, 0, 0)
        PlateDark = {0, 0, 0}, -- 主色暗部          rgb(0, 0, 0)
        PlateOutline = {0, 0, 0}, -- 线条           rgb(0, 0, 0)
        PlateShadow = {228, 228, 228}, -- 副色暗部  rgb(228, 228, 228)
        BodyColor = {228, 228, 228}, -- 副色阴影    rgb(228, 228, 228)
        BodyHighlight = {228, 228, 228} -- 副色     rgb(228, 228, 228)
    })

    local baseMechAnimTime = 1.2 -- 时间要错开，不然贼僵硬
    require(self.scriptPath .. "libs/sprites").addMechs({
        Name = "RndMechPrime",
        Default = {
            PosX = -17,
            PosY = -1
        },
        Animated = {
            PosX = -21,
            PosY = -9,
            NumFrames = 7,
            Time = baseMechAnimTime - 0.1
        },
        Submerged = {
            PosX = -17,
            PosY = 8
        },
        Broken = {
            PosX = -15,
            PosY = -2
        },
        SubmergedBroken = {
            PosX = -17,
            PosY = 13
        },
        Icon = {}
    }, {
        Name = "RndMechBrute",
        Default = {
            PosX = -16,
            PosY = 8
        },
        Animated = {
            PosX = -19,
            PosY = 0,
            NumFrames = 6,
            Time = baseMechAnimTime + 0
        },
        Submerged = {
            PosX = -16,
            PosY = 12
        },
        Broken = {
            PosX = -16,
            PosY = 8
        },
        SubmergedBroken = {
            PosX = -16,
            PosY = 12
        },
        Icon = {}
    }, {
        Name = "RndMechRanged",
        Default = {
            PosX = -17,
            PosY = 0
        },
        Animated = {
            PosX = -18,
            PosY = -4,
            NumFrames = 6,
            Time = baseMechAnimTime + 0.1
        },
        Submerged = {
            PosX = -19,
            PosY = 10
        },
        Broken = {
            PosX = -17,
            PosY = 0
        },
        SubmergedBroken = {
            PosX = -19,
            PosY = 13
        },
        Icon = {}
    }, {
        Name = "RndMechScience",
        Default = {
            PosX = -12,
            PosY = -6
        },
        Animated = {
            PosX = -24,
            PosY = -6,
            NumFrames = 5,
            Time = baseMechAnimTime + 0.2
        },
        Broken = {
            PosX = -12,
            PosY = -6
        },
        SubmergedBroken = {
            PosX = -12,
            PosY = -4
        },
        Icon = {}
    })
end

return mod
