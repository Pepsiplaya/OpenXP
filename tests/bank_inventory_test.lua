-- Exercise the bank events and a guide collection step with real stack counts.
local ROOT = ...
local itemID, otherID = 723, 159
local bags = {[itemID] = 1}
local nativeBank = {[itemID] = 2}
local bank = {
    [6] = {{itemID = itemID, stackCount = 2}},
    [7] = {{itemID = itemID, stackCount = 3}, {itemID = otherID, stackCount = 12}},
    [12] = {{itemID = itemID, stackCount = 50}}, -- Account bank.
}
local slots = {[6] = 2, [7] = 2, [12] = 2}
local canView = false
local frames, timers = {}, {}

OXPCData = {}
Enum = {BankType = {Character = 0, Account = 2}}
C_Bank = {
    CanViewBank = function(bankType) return canView and bankType == Enum.BankType.Character end,
    FetchPurchasedBankTabIDs = function(bankType)
        assert(bankType == Enum.BankType.Character)
        return {6, 7}
    end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return slots[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot) return bank[bag] and bank[bag][slot] end,
}
C_Item = {GetItemCount = function(id, includeBank)
    return (bags[id] or 0) + (includeBank and (nativeBank[id] or 0) or 0)
end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
CreateFrame = function()
    local frame = {
        events = {},
        RegisterEvent = function(self, event) self.events[event] = true end,
        SetScript = function(self, _, handler) self.handler = handler end,
    }
    frames[#frames + 1] = frame
    return frame
end
tContains = function(list, item)
    for _, entry in ipairs(list) do if entry == item then return true end end
    return false
end

local addon = {functions = {}, separators = {}, gameVersion = 16001, locale = {Get = function(text) return text end}}
local function loadBank()
    assert(loadfile(ROOT .. "/BankInventory.lua"))("OpenXP", addon)
    local frame = frames[#frames]
    return function(event, bag)
        assert(frame.events[event], event)
        frame.handler(frame, event, bag)
    end
end

local emit = loadBank()
assert(addon.GetBankItemCount(itemID) == 2, "use bank data the client already holds")
nativeBank = {}
assert(addon.GetBankItemCount(itemID) == 0)
emit("BANKFRAME_OPENED")
assert(OXPCData.bankItemCounts == nil, "wait for readable bank data")
canView = true
timers[1]()
assert(addon.GetBankItemCount(itemID) == 5 and addon.GetBankItemCount(otherID) == 12,
       "read items banked before the addon loaded and sum personal tabs")

UnitClass = function() return "Mage", "MAGE" end
GetBuildInfo = function() return "1.60.1", "70938", "", 16001 end
GetTime = function() return 10 end
C_DateAndTime, C_GossipInfo, C_QuestLog = {}, {}, {}
QUEST_MONSTERS_KILLED, QUEST_ITEMS_NEEDED = "%s slain: %d/%d", "%s: %d/%d"
CreateVector2D = function(x, y) return {x = x, y = y} end
LibStub = function() return {} end
strupper, strlower = string.upper, string.lower
StaticPopupDialogs = {}
INVSLOT_LAST_EQUIPPED = 19
GetInventoryItemID = function() end
assert(loadfile(ROOT .. "/functions.lua"))("OpenXP", addon)

addon.settings = {profile = {}}
addon.icons = {collect = ""}
addon.GetItemName = function() return "Goretusk Liver" end
addon.GetGuideProgress = function() return 1 end
addon.comms = {AnnounceStepEvent = function() end}
addon.UpdateMap = function() end
addon.lastStepUpdate = GetTime()
addon.IsOnTurnInGuide = function() end
local repaints = 0
addon.UpdateStepText = function() repaints = repaints + 1 end

local step = {active = true, index = 1, elements = {}}
local element = addon.functions.collect(".collect 723,8", nil, "723", "8")
element.step, element.tag = step, "collect"
element.frame = {element = element, step = step}
step.elements[1] = element
addon.RXPFrame = {activeSteps = {step}}
addon.ActiveStepElementEventHandler = function(frame, event) addon.functions[frame.element.tag](frame, event) end

addon.functions.collect(element.frame)
assert(not element.completed and element.count == 1)
assert(element.text == "Goretusk Liver: 1/8\nWithdraw 5 from your bank, then get 2 more.")
local initialRepaints = repaints
bank[7][1].stackCount = 7
emit("BAG_UPDATE", 7)
assert(repaints > initialRepaints and element.count == 1, "a bank-only count change refreshes the step")
assert(element.text == "Goretusk Liver: 1/8\nWithdraw 7 from your bank.")
assert(not element.completed, "banked items do not complete a standard collection step")

slots[7] = 0
emit("BAG_UPDATE_DELAYED")
assert(addon.GetBankItemCount(itemID) == 9, "a partial bank read keeps the previous counts")
slots[7] = 2
bags[itemID] = 8
bank[6][1], bank[7][1].stackCount = nil, 2
emit("BAG_UPDATE", 6)
assert(element.completed and element.text == "Goretusk Liver: 8/8", "withdrawal completes the step")

bags[itemID], bank[7][1].stackCount = 6, 4
emit("BAG_UPDATE", 7)
assert(not element.completed and not element.skip, "depositing required items reopens an active objective")
assert(element.text == "Goretusk Liver: 6/8\nWithdraw 2 from your bank.")
emit("BANKFRAME_CLOSED")
local saved = OXPCData
canView = false
bank[7][1] = nil
emit("BAG_UPDATE_DELAYED")
assert(addon.GetBankItemCount(itemID) == 4, "a closed bank preserves the last count")
emit = loadBank()
assert(addon.GetBankItemCount(itemID) == 4, "the count survives a reload")
OXPCData = {}
assert(addon.GetBankItemCount(itemID) == 0, "another character has its own snapshot")
OXPCData = saved
canView = true
emit("BANKFRAME_OPENED")
assert(addon.GetBankItemCount(itemID) == 0 and element.text == "Goretusk Liver: 6/8",
       "the next visit clears items removed from storage")

local explicitBank = addon.functions.collect(".collect 723,8,0,0,8", nil, "723", "8", nil, "0", "8")
explicitBank.step, explicitBank.tag = step, "collect"
nativeBank[itemID] = 2
addon.functions.collect({element = explicitBank, step = step})
assert(explicitBank.completed and explicitBank.text == "Goretusk Liver: 8/8", "keep explicit bank-counting flags")

-- Classic Era bank storage has a main container and optional equipped bank bags.
C_Bank = nil
BANK_CONTAINER, NUM_BAG_SLOTS, NUM_BANKBAGSLOTS = -1, 4, 2
bank = {[-1] = {{itemID = itemID, stackCount = 3}}, [5] = {{itemID = itemID, stackCount = 6}}}
slots = {[-1] = 2, [5] = 1}
emit = loadBank()
emit("BANKFRAME_OPENED")
assert(addon.GetBankItemCount(itemID) == 9)
bank[-1][1] = nil
emit("PLAYERBANKSLOTS_CHANGED")
assert(addon.GetBankItemCount(itemID) == 6)

print("bank inventory and guide collection tests passed")
