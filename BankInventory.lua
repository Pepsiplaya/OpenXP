local _, addon = ...

local GetItemCount = C_Item and C_Item.GetItemCount or _G.GetItemCount
local characterBank = Enum and Enum.BankType and Enum.BankType.Character
local bankOpen = false

function addon.GetBankItemCount(itemID)
    local counts = OXPCData and OXPCData.bankItemCounts
    if counts then return counts[itemID] or 0 end
    if not GetItemCount then return 0 end
    return math.max(0, GetItemCount(itemID, true) - GetItemCount(itemID))
end

if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return end

local function GetBankBags()
    if characterBank and C_Bank and C_Bank.FetchPurchasedBankTabIDs then
        if C_Bank.CanViewBank and not C_Bank.CanViewBank(characterBank) then return end
        return C_Bank.FetchPurchasedBankTabIDs(characterBank), true
    end

    local bank = _G.BANK_CONTAINER or (Enum and Enum.BagIndex and Enum.BagIndex.Bank)
    if not bank then return end
    local bags = {bank}
    local numBags = _G.NUM_BAG_SLOTS or 0
    for i = 1, _G.NUM_BANKBAGSLOTS or 0 do
        bags[#bags + 1] = numBags + i
    end
    return bags, false
end

local function RefreshCollectionSteps()
    local steps = addon.RXPFrame and addon.RXPFrame.activeSteps
    if not steps then return end
    for _, step in ipairs(steps) do
        for _, element in ipairs(step.elements) do
            if element.frame and (element.tag == "collect" or element.tag == "collectmultiple") then
                addon.ActiveStepElementEventHandler(element.frame, "BAG_UPDATE_DELAYED")
            end
        end
    end
end

local function ScanBank(changedBag)
    if not bankOpen or not OXPCData then return end
    local bags, tabbed = GetBankBags()
    if not bags or #bags == 0 or (changedBag and not tContains(bags, changedBag)) then return end

    local counts = {}
    for index, bag in ipairs(bags) do
        local slots = C_Container.GetContainerNumSlots(bag)
        -- The main bank and every purchased tab have slots once their data is available.
        if not slots or (slots == 0 and (tabbed or index == 1)) then return end
        for slot = 1, slots do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            if item then
                local id = item.itemID
                counts[id] = (counts[id] or 0) + item.stackCount
            elseif C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot) then
                return -- Keep the last complete count while a slot is still loading.
            end
        end
    end

    OXPCData.bankItemCounts = counts
    RefreshCollectionSteps()
end

local frame = CreateFrame("Frame")
for _, event in ipairs({"BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "BAG_UPDATE", "BAG_UPDATE_DELAYED"}) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", function(_, event, bag)
    if event == "BANKFRAME_CLOSED" then
        bankOpen = false
    elseif event == "BANKFRAME_OPENED" then
        bankOpen = true
        ScanBank()
        C_Timer.After(0, ScanBank)
    elseif event == "BAG_UPDATE" then
        ScanBank(bag)
    else
        ScanBank()
    end
end)
