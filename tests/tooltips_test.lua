-- Tests for quest tooltips (OpenXPTooltips.lua): bag items needed for quests
-- you have or that the guide saves for later, and mob progress for kill and
-- item-drop objectives. Runs without Questie.
local ROOT = ...
unpack = unpack or table.unpack
tinsert = table.insert
strsplit = function(sep, s)
    local out = {}
    for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%-", "%%-")) do tinsert(out, part) end
    return unpack(out)
end
local function Region()
    return setmetatable({
        Show = function(self) self.visible = true end,
        Hide = function(self) self.visible = false end,
        SetShown = function(self, visible) self.visible = visible end,
        SetTexture = function(self, asset) self.asset = asset end,
        SetText = function(self, label) self.label = label end,
        SetPoint = function(self, _, relative) self.relative = relative end,
    }, {__index = function() return function() end end})
end
local frames = {}
CreateFrame = function(_, _, parent)
    local f = Region()
    f.parent = parent
    f.events, f.scripts = {}, {}
    f.RegisterEvent = function(self, event) self.events[event] = true end
    f.SetScript = function(self, event, fn) self.scripts[event] = fn end
    f.CreateTexture, f.CreateFontString = Region, Region
    frames[#frames + 1] = f
    return f
end
GameTooltip = {HookScript = function() end}

-- One quest in the log: Kill 3/8 Kobold Vermin, and 2/6 Gooey Spider Legs
local log = {
    {title = "Kobold Camp Cleanup", id = 7, objectives = {{"Kobold Vermin slain: 3/8", "monster", false}}},
    {title = "Spider Legs", id = 93, objectives = {{"Gooey Spider Legs: 2/6", "item", false}}},
}
GetNumQuestLogEntries = function() return #log end
GetQuestLogTitle = function(i) local q = log[i]; return q.title, 1, nil, false, nil, nil, nil, q.id end
GetNumQuestLeaderBoards = function(i) return #log[i].objectives end
GetQuestLogLeaderBoard = function(j, i) return unpack(log[i].objectives[j]) end
local items = {[2251] = "Gooey Spider Legs", [1475] = "Small Venom Sac", [5000] = "Something Else"}
GetItemInfo = function(id) return items[id] end
local bags = {[2251] = 2, [1475] = 0}
GetItemCount = function(id) return bags[id] or 0 end
IsQuestFlaggedCompleted = function() return false end
GetItemIcon = function(id) return id + 1 end

local cvars = {autoLootDefault = "1", SoftTargetInteract = "1", SoftTargetIconInteract = "0",
               SoftTargetIconGameObject = "0", SoftTargetNameplateInteract = "0", cameraDistanceMaxZoomFactor = "1.9"}
C_CVar = {
    GetCVar = function(name) return cvars[name] end,
    SetCVar = function(name, value) assert(cvars[name]); cvars[name] = value end,
    GetCVarDefault = function() return "1.9" end,
}
Enum = {SoftTargetEnableFlags = {Any = 3}}

local addon = {
    locale = {Get = function(s) return s end},
    settings = {profile = {}},
    GetGuideProgress = function() return 2 end,
    GetQuestName = function(id) return id == 2359 and "Elixir of Agony" or nil end,
    currentGuide = {steps = {
        {elements = {{tag = "collect", id = 5000, qty = 1, questId = 1}}}, -- already behind you
        {elements = {
            {tag = "collect", id = 1475, qty = 1, questId = 2359},
            {tag = "collect", id = 2251, qty = 6, questId = 93},
            {mobs = {"Venom Web Spider"}},
        }},
    }},
}
-- Questie stand-in: Wildthorn Stalkers (3819) drop Gooey Spider Legs
addon.card = {QGet = function(kind, id)
    if kind == "Item" and id == 2251 then return {name = "Gooey Spider Legs", npcDrops = {3819}} end
end}
assert(loadfile(ROOT .. "/OpenXPTooltips.lua"))("OpenXP", addon)
local T = addon.openxpTooltips
local fails = 0
local function try(label, fn)
    local ok, err = pcall(fn)
    if ok then print("ok   " .. label) else fails = fails + 1; print("FAIL " .. label .. ": " .. tostring(err)) end
end

try("item for a quest you have shows its count", function()
    local lines = T.ItemLines(2251, "Gooey Spider Legs")
    assert(#lines == 1, "lines " .. #lines)
    assert(lines[1].title == "Spider Legs" and lines[1].have == 2 and lines[1].need == 6)
end)
try("item the guide saves for a later quest", function()
    local lines = T.ItemLines(1475, "Small Venom Sac")
    assert(#lines == 1, "lines " .. #lines)
    assert(lines[1].title == "Elixir of Agony" and lines[1].later == 2 and lines[1].need == 1)
end)
try("items for steps you're past show nothing", function()
    assert(#T.ItemLines(5000, "Something Else") == 0)
end)
try("tooltip gets the don't-sell header", function()
    local added = {}
    local tt = {AddLine = function(_, t) tinsert(added, t) end,
                AddDoubleLine = function(_, a, b) tinsert(added, a .. " " .. b) end, Show = function() end}
    T.AddItemLines(tt, 2251, "Gooey Spider Legs")
    assert(#added == 3 and added[2]:find("DON'T SELL"), table.concat(added, " | "))
end)
try("mob: kill objective", function()
    local lines = T.QuestLines("Kobold Vermin", 6)
    assert(#lines == 1 and lines[1].have == 3 and lines[1].need == 8)
end)
try("mob: items it drops (from the guide's .mob lines), incl. ones saved for later", function()
    local lines = T.QuestLines("Venom Web Spider", 217)
    assert(#lines == 2, "lines " .. #lines)
    local by = {}
    for _, l in ipairs(lines) do by[l.what] = l end
    assert(by["Gooey Spider Legs"].have == 2 and by["Gooey Spider Legs"].need == 6)
    assert(by["Small Venom Sac"].later == 2)
end)
try("mob: item it drops (from Questie's drop list)", function()
    local lines = T.MobItemLines("Wildthorn Stalker", 3819)
    assert(#lines == 1 and lines[1].itemId == 2251, "lines " .. #lines)
end)
try("bag marker only on needed items", function()
    assert(T.IsNeeded(2251) and T.IsNeeded(1475) and not T.IsNeeded(5000))
end)
try("mob that drops nothing you need", function()
    assert(#T.QuestLines("Forest Wolf", 69) == 0)
end)

try("Auto Loot and ground cues use the game's settings", function()
    local extras = addon.openxpExtras
    assert(extras.AutoLootEnabled(), "read the user's existing Auto Loot setting")
    extras.SetMaxCamera(true)
    assert(cvars.autoLootDefault == "1", "camera options must not alter loot settings")
    extras.SetAutoLoot(false)
    assert(cvars.autoLootDefault == "0")
    extras.SetAutoLoot(true)
    extras.SetObjectCues(true)
    assert(extras.ObjectCuesEnabled() and cvars.SoftTargetInteract == "3" and cvars.SoftTargetIconInteract == "1")
    extras.SetObjectCues(false)
    assert(not extras.ObjectCuesEnabled() and cvars.autoLootDefault == "1" and cvars.SoftTargetInteract == "3")
end)

try("Forever quest progress marks the Ammo Crate and clears it after looting", function()
    local objective = {text = "Rumbleshot's Ammo: 0/1", type = "item", numFulfilled = 0, numRequired = 1}
    C_QuestLog = {
        GetNumQuestLogEntries = function() return 1 end,
        GetInfo = function() return {questID = 5541, title = "Ammo for Rumbleshot"} end,
        IsOnQuest = function(qid) return qid == 5541 end,
        GetQuestObjectives = function(qid) if qid == 5541 then return {objective} end end,
    }
    local read = T.LogQuests()[1]
    assert(read.id == 5541 and read.objectives[1].name == "Rumbleshot's Ammo")
    local plate = {}
    local guid = "GameObject-0-100-200-300-176785-1234"
    UnitIsGameObject = function(unit) return unit == "softinteract" end
    UnitGUID = function() return guid end
    UnitName = function() return "Ammo Crate" end
    C_NamePlate = {GetNamePlateForUnit = function() return plate end}
    local watcher = frames[1]
    assert(watcher.events.PLAYER_SOFT_INTERACT_CHANGED)
    watcher.scripts.OnEvent(watcher, "PLAYER_SOFT_INTERACT_CHANGED")
    local marker = frames[#frames]
    assert(marker.parent == plate and marker.relative == plate and marker.visible)
    assert(marker.icon.asset == 13851 and marker.text.label == "0/1")
    guid = "GameObject-0-100-200-300-9999-1234"
    watcher.scripts.OnEvent(watcher, "PLAYER_SOFT_INTERACT_CHANGED")
    assert(not marker.visible, "an unrelated object must not inherit a quest icon")
    guid = "GameObject-0-100-200-300-176785-1234"
    watcher.scripts.OnEvent(watcher, "PLAYER_SOFT_INTERACT_CHANGED")
    assert(marker.visible)
    objective.numFulfilled, objective.finished = 1, true
    watcher.scripts.OnEvent(watcher, "QUEST_LOG_UPDATE")
    assert(not marker.visible)
    C_QuestLog = nil
end)

try("the active guide can name a ground quest object without Questie", function()
    addon.RXPFrame = {activeSteps = {{elements = {{
        textReplaced = {"Click the |cRXP_PICK_Unguarded Thunder Ale Barrel|r"},
    }}}}}
    assert(T.ObjectInfo(270, "Unguarded Thunder Ale Barrel").label == "Quest object")
    assert(T.ObjectInfo(999, "Ordinary Barrel") == nil)
    addon.RXPFrame.activeSteps[1].completed = true
    assert(T.ObjectInfo(270, "Unguarded Thunder Ale Barrel") == nil)
end)
print(fails == 0 and "tooltip tests passed" or (fails .. " failed"))
return fails
