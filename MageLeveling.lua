-- Alliance Mage guidance for Forever. See docs/MAGE_LEVELING.md for sources.
local _, addon = ...
local L = addon.locale.Get
local fmt = string.format
local mage = {}
addon.mageLeveling = mage

local training = {
    {name = "Frostbolt", ranks = {{4, 116}, {8, 205}, {14, 837}, {20, 7322}, {26, 8406},
                                {32, 8407}, {38, 8408}, {44, 10179}, {50, 10180}, {56, 10181}}, book = 25304},
    {name = "Conjure Water", ranks = {{4, 5504}, {10, 5505}, {20, 5506}, {30, 6127}, {40, 10138}, {50, 10139}},
     book = 10140},
    {name = "Conjure Food", ranks = {{6, 587}, {12, 597}, {22, 990}, {32, 6129}, {42, 10144}, {52, 10145}},
     book = 28612},
    {name = "Comprehend Scroll", ranks = {{6, 1296017}}},
    {name = "Polymorph", ranks = {{8, 118}, {20, 12824}, {40, 12825}, {60, 12826}}},
    {name = "Frost Nova", ranks = {{10, 122}, {26, 865}, {40, 6131}, {54, 10230}}},
    {name = "Blink", ranks = {{20, 1953}}},
    {name = "Evocation", ranks = {{20, 12051}}},
    {name = "Blizzard", ranks = {{20, 10}, {28, 6141}, {36, 8427}, {44, 10185}, {52, 10186}, {60, 10187}}},
    {name = "Counterspell", ranks = {{24, 2139}}},
    {name = "Cone of Cold", ranks = {{26, 120}, {34, 8492}, {42, 10159}, {50, 10160}, {58, 10161}}},
    {name = "Conjure Mana Agate", ranks = {{28, 759}}},
    {name = "Ice Armor", ranks = {{30, 7302}, {40, 7320}, {50, 10219}, {60, 10220}}},
    {name = "Mage Armor", ranks = {{34, 6117}, {46, 22782}, {58, 22783}}},
    {name = "Frostfire Bolt", ranks = {{40, 401502}, {50, 1237312}, {60, 1237313}}},
}

local travel = {
    {20, 3561, "Teleport: Stormwind", "Larimaine Purdue"},
    {20, 3562, "Teleport: Ironforge", "Milstaff Stormeye"},
    {30, 3565, "Teleport: Darnassus", "Elissa Dumas"},
    {40, 10059, "Portal: Stormwind", "Larimaine Purdue"},
    {40, 11416, "Portal: Ironforge", "Milstaff Stormeye"},
    {50, 11419, "Portal: Darnassus", "Elissa Dumas"},
}

local starters = {
    Human = "Northshire → Elwynn Forest → Loch Modan",
    Gnome = "Coldridge Valley → Dun Morogh → Elwynn → Loch Modan",
    Skyborne = "Zephras Isle → Westfall",
}

function mage.IsAvailable()
    local p = addon.player
    return addon.game == "FOREVER" and p and p.faction == "Alliance" and p.class == "MAGE"
end

-- Highest trainable rank in each group. Book and quest upgrades stay out of
-- the trainer checklist even when their item is available at level 60.
function mage.Training(level, knows)
    local missing, nextLevel = {}, nil
    for _, track in ipairs(training) do
        local best, rank
        for i, spell in ipairs(track.ranks) do
            if spell[1] > level then
                nextLevel = math.min(nextLevel or spell[1], spell[1])
                break
            end
            best, rank = spell, i
        end
        if best and not knows(best[2]) and not (track.book and knows(track.book)) then
            missing[#missing + 1] = {name = track.name, level = best[1], spell = best[2],
                                    rank = #track.ranks > 1 and rank or nil}
        end
    end
    return missing, nextLevel
end

local function Name(id, fallback)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) or L(fallback) end
    return L(fallback)
end

local function Known(id)
    return addon.IsPlayerSpell and addon.IsPlayerSpell(id) or false
end

function mage.Readout(level, race, knows, guideName)
    local lines = {}
    local humanOrGnome = race == "Human" or race == "Gnome"
    local function add(text) lines[#lines + 1] = text end
    local function heading(text)
        if #lines > 0 then add("") end
        add("|cFF7DE6C9" .. L(text) .. "|r")
    end
    heading("Leveling route")
    if level < 14 and starters[race] then add(L(starters[race])) end
    if guideName then add(guideName) end
    if level < 21 then
        add(L("Follow the Alliance chapters through Westfall, Darkshore and Ashenvale. Use /oxp where to find your place after a detour."))
    else
        add(L("Continue with the Alliance leveling chapters. Choose a dungeon from the guide picker when you have a group and quests for that run."))
    end

    heading("Mage trainers")
    local missing, nextLevel = mage.Training(level, knows)
    if #missing > 0 then
        local names = {}
        for i, spell in ipairs(missing) do
            local name = Name(spell.spell, spell.name)
            names[i] = spell.rank and fmt(L("%s (Rank %d)"), name, spell.rank) or name
        end
        add(table.concat(names, ", "))
        add(L("Train your main damage spell and water first if coin is tight. Learn the control and utility spells you use."))
    elseif nextLevel then
        add(fmt(L("Next listed training unlocks at level %d."), nextLevel))
    end
    if level == 60 then
        if not knows(10140) then add(L("Open Arcane Refreshment in the class guides for Conjure Water rank 7.")) end
        if not knows(28612) then add(L("Archivist Galford can drop the Conjure Food rank 7 tome in Stratholme.")) end
    end

    heading("Wands and class quests")
    if level < 13 then
        if race == "Skyborne" then add(L("A Magical Affront offers Dowsing Rod. Boughs in the Wind offers Windbough Wand at level 10.")) end
        add(L("Lesser Magic Wand is a crafted upgrade you can use at level 5. Compare the price, weapon DPS and level requirement before buying."))
    elseif level < 22 then
        add(L("Greater Magic Wand is a crafted option at level 13. Smoldering Wand is a vendor fallback at level 15. Compare them with your own wand."))
    elseif level < 30 then
        add(L("Ormer's Revenge in the Wetlands offers Excavation Rod. A Blackfathom Deeps group can earn Gravestone Scepter through Blackfathom Villainy."))
    else
        add(L("Mage's Wand is under OpenXP Extras → Class Quests. Collect both Arathi materials and the Scarlet Monastery Library book before returning to Tabetha."))
    end
    if level >= 10 and level < 20 then
        add(L("Open Mirror Lake under Class Quests for a staff or off-hand reward from Stormwind."))
        if humanOrGnome then add(L("If you're near Ironforge, choose Mage-tastic Gizmonitor instead.")) end
    end
    if level >= 15 and level < 23 and humanOrGnome then
        add(L("The Manaweave Robe chapter starts at the Stormwind Mage Tower. It includes a trip to the Silver Stream Mine in Loch Modan."))
    end
    if level >= 6 and not knows(1302508) then
        add(L("To learn Study, open Research Access under OpenXP Extras → Class Quests. Bring a library book to Garion Wendell during a Stormwind visit."))
    end

    heading("Leveling choices")
    if level < 20 then
        add(L("Start with Fireball, then pull with Frostbolt from range once learned. Finish weak enemies with a wand and drink in a clear spot. Polymorph a second enemy when it is susceptible."))
        if level >= 10 then add(L("Put early Frost points into Improved Frostbolt for single-target casting. Choose control or damage talents based on the fights you take.")) end
    else
        add(L("Solo Frost works well for scattered quest targets. For AoE, test small melee packs with Blizzard and control talents, with a clear retreat. Blizzard and proc damage can break Frost Nova."))
        add(L("Fire favors damage and critical strikes. With Arcane Blast, use its buff on another spell before the stacking mana cost slows your next pull."))
        if level >= 40 then add(L("Try Frostfire Bolt with a Fire or Frost build and compare kills per drink on the enemies you are fighting.")) end
        add(L("Count travel, mana breaks and deaths when comparing a grind or dungeon to questing. Dungeon kills give the party zero XP when a mob is trivial to any member."))
    end

    heading("Travel")
    if level < 20 then
        add(L("Keep your Hearthstone and learn flight paths as you pass them. Stormwind and Ironforge teleports open at level 20."))
    else
        local unlearned = {}
        for _, spell in ipairs(travel) do
            if level >= spell[1] and not knows(spell[2]) then
                unlearned[#unlearned + 1] = fmt("%s (%s)", Name(spell[2], spell[3]), spell[4])
            end
        end
        if #unlearned > 0 then add(table.concat(unlearned, "\n")) end
        add(L("Carry Runes of Teleportation for your own trips and Runes of Portals for party portals. Bind your Hearthstone near your current quest circuit when you can teleport back to a city."))
    end
    return table.concat(lines, "\n")
end

local frame, subtitle, body, content

local function RefreshPanel()
    local level = UnitLevel("player")
    local guide = addon.currentGuide
    local title = guide and (guide.displayname or guide.name)
    subtitle:SetText(fmt(L("Level %d • Alliance"), level))
    body:SetText(mage.Readout(level, addon.player.race, Known, title))
    content:SetHeight(math.max(body:GetStringHeight(), 1))
end

local function CreatePanel()
    local c = addon.openxpStyle.colors
    local white = "Interface/Buttons/WHITE8X8"
    frame = CreateFrame("Frame", "OpenXPMageLeveling", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({bgFile = white, edgeFile = white, edgeSize = 1})
    frame:SetBackdropColor(unpack(c.bg))
    frame:SetBackdropBorderColor(unpack(c.border))
    table.insert(UISpecialFrames, "OpenXPMageLeveling")

    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(62)
    header:SetColorTexture(unpack(c.header))
    local mark = addon.openxpStyle.Mark(frame, 28)
    mark:SetPoint("TOPLEFT", 18, -16)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mark, "TOPRIGHT", 10, 3)
    title:SetTextColor(unpack(c.text))
    title:SetText(L("Mage leveling"))
    subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetTextColor(unpack(c.dim))
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -76)
    scroll:SetPoint("BOTTOMRIGHT", -36, 18)
    content = CreateFrame("Frame", nil, scroll)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT")
    body:SetJustifyH("LEFT")
    body:SetSpacing(4)
    body:SetTextColor(unpack(c.text))
    frame.scroll = scroll
    frame:Hide()
    frame:SetScript("OnShow", function(self)
        self:RegisterEvent("SPELLS_CHANGED")
        self:RegisterEvent("PLAYER_LEVEL_UP")
    end)
    frame:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
    frame:SetScript("OnEvent", RefreshPanel)
end

function mage.Show()
    if not mage.IsAvailable() then
        addon.comms.PrettyPrint(L("Mage leveling is available on Alliance Mages in WoW Forever."))
        return
    end
    if not frame then CreatePanel() end
    local width = math.min(550, UIParent:GetWidth() - 32)
    local height = math.min(560, UIParent:GetHeight() - 32)
    frame:SetSize(width, height)
    content:SetWidth(width - 56)
    body:SetWidth(width - 56)
    RefreshPanel()
    frame.scroll:SetVerticalScroll(0)
    frame:Show()
end
