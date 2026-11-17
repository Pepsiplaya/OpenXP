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
strlower = string.lower
StaticPopupDialogs = {}

local rows, rowsShown, totalQuests, onEvent
local ready, turnedIn
local readCount = 0
CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, fn) onEvent = fn end,
    }
end

local function loadFunctions(modern)
    C_QuestLog = {
        IsOnQuest = function() return true end,
        IsComplete = function() return ready end,
        IsQuestFlaggedCompleted = function() return turnedIn end,
    }
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

addon.settings = {profile = {}}
addon.icons = {complete = ""}
addon.GetQuestName = function() return "Escort" end
addon.GetQuestObjectives = function() error("whole-quest completion does not request objective rows") end
addon.UpdateStepText = function() end
addon.SetElementIncomplete = function(widget) widget.element.completed = false end
addon.SetElementComplete = function(widget) widget.element.completed = true end
local escort = {element = {tag = "complete", questId = 5321, obj = 0, flags = 0,
                           rawtext = "Finish the escort", step = {active = true, index = 1}}}
ready = -1
addon.UpdateQuestCompletionData(escort)
assert(not escort.element.completed and escort.element.text == "Finish the escort")
ready = true
escort.element.step.active = false -- only active steps announce completion
addon.UpdateQuestCompletionData(escort)
assert(escort.element.completed, "ready state completes a whole-quest objective")
ready, turnedIn = nil, true
addon.UpdateQuestCompletionData(escort)
assert(escort.element.completed, "a turned-in quest stays complete without objective rows")
ready, turnedIn = nil, nil
print("whole-quest completion tests passed")

local instruction = "Kill Grik'nir the Cold and loot Grelin's journal."
local journal = addon.functions.complete(".complete 218,1", instruction, "218", "1")
journal.tag = "complete"
journal.step = {active = true, index = 17}
local widget = {element = journal}
assert(journal.text == instruction, "show the instruction while fetching objective data")

local objectives
addon.icons.collect = "[loot]"
addon.GetQuestName = function() return "The Stolen Journal" end
addon.GetQuestObjectives = function(_, _, useCache)
    if useCache then return {{text = "Stale journal count", finished = true}} end
    return objectives
end
addon.UpdateQuestCompletionData(widget)
assert(not journal.completed and journal.requestFromServer and journal.text == instruction,
       "missing rows retain the instruction and do not complete from fallback data")

objectives = {{text = "", type = "item", numFulfilled = 0, numRequired = 1, finished = false}}
addon.UpdateQuestCompletionData(widget)
assert(journal.text == instruction and journal.requestFromServer and journal.icon == "[loot]",
       "an empty loot objective still shows the authored instruction")

journal.rawtext = nil
addon.UpdateQuestCompletionData(widget)
assert(journal.text == "Retrieving quest data..." and journal.requestFromServer,
       "an unauthored empty objective has a visible loading state")

journal.rawtext = "Collect the journal (%d/%d)"
objectives = nil
addon.UpdateQuestCompletionData(widget)
assert(journal.text == "Retrieving quest data...", "wait for counts before formatting progress")
objectives = {{text = "Grelin's journal: 1/1", type = "item",
               numFulfilled = 1, numRequired = 1, finished = true}}
journal.step.active = false
addon.UpdateQuestCompletionData(widget)
assert(journal.text == "Collect the journal (1/1)" and journal.completed and not journal.requestFromServer,
       "loaded objectives still show real counts and complete normally")
print("objective loading text tests passed")

local standing
C_Reputation = {GetFactionDataByID = function(id)
    assert(id == 93)
    if standing then
        local threshold = standing >= 6 and 9000 or 0
        return {reaction = standing, currentReactionThreshold = threshold,
                nextReactionThreshold = threshold + 3000, currentStanding = threshold}
    end
end}
addon.repStandingID = {honored = 6}
addon.settings = {profile = {}}
local gate = addon.functions.reputation("parse", nil, "93", "Honored", "<0", "skip")
gate.step = {active = true}
addon.functions.reputation({element = gate})
assert(not gate.step.completed, "unknown reputation leaves the step intact")
standing = 6
addon.functions.reputation({element = gate})
assert(not gate.step.completed, "Honored satisfies the pickup gate")
standing = 4
addon.functions.reputation({element = gate})
assert(gate.step.completed, "Neutral skips the clan pickup")
print("reputation gate tests passed")
