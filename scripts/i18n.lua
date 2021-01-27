local mod = mod_loader.mods[modApi.currentMod]
local scriptPath = mod.scriptPath

local this = {
    LocalizedText = {}
}

local _IsLocalizedText = IsLocalizedText
function IsLocalizedText(id)
    for k, v in pairs(this.LocalizedText) do
        if k == id then
            return true
        end
    end
    return _IsLocalizedText(id)
end

local _GetLocalizedText = GetLocalizedText
function GetLocalizedText(id)
    for k, v in pairs(this.LocalizedText) do
        if k == id then
            return v
        end
    end
    return _GetLocalizedText(id)
end

local _modApi_loadLanguage = modApi.loadLanguage
function modApi:loadLanguage(languageIndex, ...)
    -- 尽管首次加载语言时会重复在 Init() 中执行的代码，但这里必须得重复执行，否则其他 MOD 也采用这种方式加载文本时会出错
    this:LoadText(languageIndex)
    local ret = _modApi_loadLanguage(self, languageIndex, ...)
    this:SetText()
    return ret
end

function this:LoadText(language)
    language = language or modApi:getLanguageIndex()
    local langPath = nil
    if language == Languages.Chinese_Simplified then
        langPath = scriptPath .. "localization/chinese/"
    else
        langPath = scriptPath .. "localization/english/"
    end
    RndMod_Texts = require(langPath .. "RndMod_Texts")
    RndWeapon_Texts = require(langPath .. "RndWeapon_Texts")
    Rnd_Texts = require(scriptPath .. "localization/Rnd_Texts")
end

function this:SetText()
    for id, text in pairs(RndWeapon_Texts) do
        modApi:setText(id, text)
    end
    for id, text in pairs(Rnd_Texts) do
        modApi:setText(id, text)
    end

    -- for MOD Loader Weapon Deck
    for _, weapon in ipairs(RND_GLOBAL.weaponNames) do
        local name = weapon .. "_Name"
        local desc = weapon .. "_Description"
        self:SetLocalizedText(name, RndWeapon_Texts[name])
        self:SetLocalizedText(desc, RndWeapon_Texts[desc])
    end
end

function this:SetLocalizedText(id, text)
    self.LocalizedText[id] = text
end

function this:Init()
    self:LoadText()
end

function this:Load()
    -- nothing to do
end

return this
