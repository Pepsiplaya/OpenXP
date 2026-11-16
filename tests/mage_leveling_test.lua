-- Alliance Mage trainer progression and the in-game panel entry point.
local ROOT = ...
local level, known = 1, {}
local addon = {
    game = "FOREVER",
    player = {class = "MAGE", faction = "Alliance", race = "Human"},
    locale = {Get = function(text) return text end},
    IsPlayerSpell = function(id) return known[id] == true end,
}
assert(loadfile(ROOT .. "/MageLeveling.lua"))("OpenXP", addon)
local mage = addon.mageLeveling
local function contains(text, phrase)
    return text:find(phrase, 1, true) ~= nil
end

local function ranks(at)
    local missing, nextLevel = mage.Training(at, addon.IsPlayerSpell)
    local spells = {}
    for _, spell in ipairs(missing) do spells[spell.spell] = spell.rank or true end
    return spells, nextLevel
end
local spells, nextLevel = ranks(1)
assert(nextLevel == 4 and not next(spells))
spells = ranks(4)
assert(spells[116] == 1 and spells[5504] == 1 and not spells[587])
spells = ranks(8)
assert(spells[205] == 2 and not spells[116] and spells[587] == 1 and spells[118])
spells = ranks(20)
assert(spells[7322] == 4 and spells[5506] == 3 and spells[10] == 1 and spells[1953])
spells = ranks(60)
assert(spells[10181] == 10 and spells[10139] == 6 and spells[10145] == 6 and spells[1237313] == 3)
assert(not spells[10140] and not spells[28612] and not spells[25304])
known = {[10140] = true, [28612] = true, [25304] = true}
spells = ranks(60)
assert(not spells[10139] and not spells[10145] and not spells[10181])

assert(contains(mage.Readout(1, "Human", addon.IsPlayerSpell), "Northshire"))
assert(contains(mage.Readout(1, "Gnome", addon.IsPlayerSpell), "Coldridge Valley"))
assert(contains(mage.Readout(1, "Skyborne", addon.IsPlayerSpell), "Dowsing Rod"))
assert(contains(mage.Readout(10, "Gnome", addon.IsPlayerSpell), "Mage-tastic Gizmonitor"))
assert(not contains(mage.Readout(10, "Skyborne", addon.IsPlayerSpell), "Mage-tastic Gizmonitor"))
assert(contains(mage.Readout(15, "Human", addon.IsPlayerSpell), "Manaweave Robe"))
assert(not contains(mage.Readout(15, "Skyborne", addon.IsPlayerSpell), "Manaweave Robe"))
known = {[3561] = true}
local readout = mage.Readout(20, "Human", addon.IsPlayerSpell, "19-20 Redridge")
assert(contains(readout, "19-20 Redridge") and contains(readout, "Teleport: Ironforge"))
assert(not contains(readout, "Teleport: Stormwind") and not contains(readout, "Teleport: Darnassus"))
assert(contains(readout, "Research Access"))
assert(contains(mage.Readout(60, "Human", addon.IsPlayerSpell), "Arcane Refreshment"))
known[1302508] = true
assert(not contains(mage.Readout(20, "Human", addon.IsPlayerSpell), "Research Access"))
print("ok   Alliance Mage ranks, starter guidance, quest rewards, and teleport availability")

assert(mage.IsAvailable())
addon.player.class = "PRIEST"
assert(not mage.IsAvailable())
addon.player.class, addon.player.faction = "MAGE", "Horde"
assert(not mage.IsAvailable())
addon.player.faction, addon.game = "Alliance", "CLASSIC"
assert(not mage.IsAvailable())
local message
addon.comms = {PrettyPrint = function(text) message = text end}
mage.Show()
assert(contains(message, "WoW Forever"))
addon.game = "FOREVER"

local methods = {
    SetWidth = function(self, width) self.width = width end,
    SetHeight = function(self, height) self.height = height end,
    SetSize = function(self, width, height) self.width, self.height = width, height end,
    GetWidth = function(self) return self.width end,
    GetHeight = function(self) return self.height end,
    GetStringHeight = function(self) return 120 end,
    SetText = function(self, text) self.text = text end,
    SetScript = function(self, script, handler) self[script] = handler end,
    RegisterEvent = function(self, event) self.events[event] = true end,
    UnregisterAllEvents = function(self) self.events = {} end,
    Show = function(self) if self.OnShow then self:OnShow() end end,
    Hide = function(self) if self.OnHide then self:OnHide() end end,
}
for _, name in ipairs({"SetPoint", "SetAllPoints", "SetFrameStrata", "SetClampedToScreen", "EnableMouse",
                      "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetColorTexture",
                      "SetTexture", "SetVertexColor", "SetTextColor", "SetScrollChild", "SetJustifyH",
                      "SetSpacing", "SetVerticalScroll"}) do
    methods[name] = function() end
end
local function widget()
    return setmetatable({events = {}}, {__index = methods})
end
methods.CreateTexture = widget
local texts = {}
methods.CreateFontString = function()
    local label = widget()
    texts[#texts + 1] = label
    return label
end
UIParent = widget()
UIParent:SetSize(480, 460)
UISpecialFrames = {}
CreateFrame = function(_, name)
    local frame = widget()
    if name then _G[name] = frame end
    return frame
end
UnitLevel = function() return level end
assert(loadfile(ROOT .. "/OpenXPStyle.lua"))("OpenXP", addon)
mage.Show()
local frame, body = OpenXPMageLeveling, texts[3]
assert(frame.width == 448 and frame.height == 428)
assert(body.width == 392 and contains(body.text, "Northshire"))
assert(frame.events.SPELLS_CHANGED and frame.events.PLAYER_LEVEL_UP)
level = 4
frame:OnEvent("PLAYER_LEVEL_UP")
assert(contains(body.text, "Frostbolt (Rank 1)"))
known[116] = true
frame:OnEvent("SPELLS_CHANGED")
assert(not contains(body.text, "Frostbolt (Rank 1)"))
assert(UISpecialFrames[1] == "OpenXPMageLeveling")
frame:Hide()
assert(not next(frame.events))
print("ok   Mage panel fits a smaller viewport and refreshes on training and level-up")
return 0
