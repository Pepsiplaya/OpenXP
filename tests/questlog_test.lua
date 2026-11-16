-- Exercise the actual quest-log compatibility and IsOnQuest code.
local ROOT = ...
UnitClass = function() return "Priest", "PRIEST" end
GetBuildInfo = function() return "1.60.1", "70938", "", 16001 end
GetTime = function() return 10 end
C_DateAndTime = {}
C_GossipInfo = {}
QUEST_MONSTERS_KILLED = "%s slain: %d/%d"
QUEST_ITEMS_NEEDED = "%s: %d/%d"
CreateVector2D = function(x, y) return {x = x, y = y} end
LibStub = function() return {} end
strupper = string.upper
StaticPopupDialogs = {}

local rows, rowsShown, totalQuests, onEvent
local readCount = 0
CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, fn) onEvent = fn end,
    }
end

local function loadFunctions(modern)
    C_QuestLog = { IsOnQuest = function() return true end }
    local function counts() return rowsShown, totalQuests end
    if modern then
        C_QuestLog.GetNumQuestLogEntries = counts
        C_QuestLog.GetInfo = function(i)
            readCount = readCount + 1
            return rows[i]
        end
        GetNumQuestLogEntries, GetQuestLogTitle = nil, nil
    else
        GetNumQuestLogEntries = counts
        GetQuestLogTitle = function(i)
            local row = rows[i]
            if row then return row.title, nil, nil, row.isHeader, row.isCollapsed, nil, nil, row.questID end
        end
    end
    local addon = {
        functions = {}, separators = {}, gameVersion = 16001,
        locale = {Get = function(x) return x end},
    }
    assert(loadfile(ROOT .. "/functions.lua"))("OpenXP", addon)
    return addon
end

local function setRows(shown, total, entries)
    rowsShown, totalQuests, rows = shown, total, entries
    onEvent(nil, "QUEST_LOG_UPDATE")
end

local addon = loadFunctions(true)
setRows(2, 1, {{title = "Darkshore", isHeader = true}, {title = "Mathystra Relics", questID = 951}})
assert(addon.QuestLogIDs()[951] == "Mathystra Relics")
assert(addon.IsOnQuest(951) and not addon.IsOnQuest(950), "use the visible log to reject false positives")
assert(readCount == 2, "use the cached log until an event invalidates it")
setRows(0, 0, {})
assert(next(addon.QuestLogIDs()) == nil and not addon.IsOnQuest(951))
setRows(1, 1, {{title = "Darkshore", isHeader = true, isCollapsed = true}})
assert(addon.QuestLogIDs() == nil and addon.IsOnQuest(951), "collapsed log cannot disprove the API")
setRows(2, 1, {{title = "Darkshore", isHeader = true}})
assert(addon.QuestLogIDs() == nil, "a missing row invalidates the snapshot")
setRows(1, 2, {{title = "Mathystra Relics", questID = 951}})
assert(addon.QuestLogIDs() == nil, "a partial snapshot cannot disprove the API")
setRows(1, 0, {{title = "Darkshore", isHeader = true, isCollapsed = true}})
assert(addon.QuestLogIDs() == nil)

addon = loadFunctions(false)
setRows(2, 1, {{title = "Darkshore", isHeader = true}, {title = "Mathystra Relics", questID = 951}})
assert(addon.QuestLogIDs()[951] == "Mathystra Relics", "legacy tuple API remains supported")
setRows(1, 1, {{title = "Darkshore", isHeader = true, isCollapsed = true}})
assert(addon.QuestLogIDs() == nil)
print("quest log compatibility tests passed")
