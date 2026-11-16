-- Optional class quests for Forever. See docs/CLASS_RESEARCH.md for source records.
local L = GetLocale() if L and RXP.enabledLocale[L] then return end

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Class Quests
#name Mage's Wand
<< Mage

step
    .xp 30 >>Reach level 30 to start the wand chain.
step << Alliance
    .goto Stormwind City,49.56,85.80
    >>Pick up the quest from |cRXP_FRIENDLY_Jennea Cannon::5497|r in Stormwind or |cRXP_FRIENDLY_Bink::5144|r in Ironforge.
    .accept 1947 >>Accept Journey to the Marsh
    .target Jennea Cannon::5497
step << Horde
    .goto Orgrimmar,38.45,86.13
    >>Pick up the quest from |cRXP_FRIENDLY_Deino::5885|r in Orgrimmar, |cRXP_FRIENDLY_Anastasia Hartwell::4568|r in Undercity, or |cRXP_FRIENDLY_Ursyn Ghull::3048|r in Thunder Bluff.
    .accept 1947 >>Accept Journey to the Marsh
    .target Deino::5885
step
    .isOnQuest 1947
    .goto Dustwallow Marsh,46.06,57.09
    .turnin 1947 >>Turn in Journey to the Marsh to |cRXP_FRIENDLY_Tabetha::6546|r
    .target Tabetha::6546
step
    .goto Dustwallow Marsh,46.06,57.09
    >>Take both quests from |cRXP_FRIENDLY_Tabetha::6546|r. Get one |cRXP_LOOT_Jade|r from another player or the auction house if you need one.
    .accept 1948 >>Accept Items of Power
    .accept 1949 >>Accept Hidden Secrets
    .target Tabetha::6546
step << Mage
    .goto Thousand Needles,78.29,75.70
    >>Find |cRXP_FRIENDLY_Magus Tirth::6548|r at the Shimmering Flats racetrack.
    .turnin 1949 >>Turn in Hidden Secrets
    .accept 1950 >>Accept Get the Scoop
    .target Magus Tirth::6548
step << Mage
    .isOnQuest 1950
    .goto Thousand Needles,79.61,75.63
    >>Look by the tower across the racetrack. Target the chicken |cRXP_FRIENDLY_"Plucky" Johnson::6626|r and type /beckon. Speak to him in human form to learn the phrase.
    .complete 1950,1 --Get the Scoop
    .target "Plucky" Johnson::6626
step << Mage
    .goto Thousand Needles,78.29,75.70
    >>Return to |cRXP_FRIENDLY_Magus Tirth::6548|r.
    .turnin 1950 >>Turn in Get the Scoop
    .accept 1951 >>Accept Rituals of Power
    .target Magus Tirth::6548
step
    .isOnQuest 1948
    .goto Arathi Highlands,66.02,62.87
    .collect 7273,10,1948,2,4 >>Loot 10 Witherbark Totem Sticks from the trolls around Witherbark Village.
    .mob Witherbark Axe Thrower::2554
step
    .isOnQuest 1948
    .goto Arathi Highlands,52.00,50.80
    >>At the Stone of Outer Binding, use the sticks from your bags and loot the bramble that appears. Bring help for the nearby elementals if needed.
    .complete 1948,2 --Bolt Charged Bramble
    .use 7273
step
    .isOnQuest 1948
    >>Carry one |cRXP_LOOT_Jade|r for Tabetha.
    .complete 1948,1 --Jade
step
    #completewith next
    .isOnQuest 1951
    .isQuestNotComplete 1951
    .goto Tirisfal Glades,82.60,33.80,35 >>Meet your group at Scarlet Monastery and take the Library portal.
step
    .isOnQuest 1951
    >>In Scarlet Monastery Library, look for |cRXP_PICK_Rituals of Power|r on a bookshelf in the Athenaeum before Arcanist Doan's room. Open the book and take it.
    .complete 1951,1 --Rituals of Power
step
    .isOnQuest 1948,1951
    .goto Dustwallow Marsh,46.06,57.09
    >>Return to |cRXP_FRIENDLY_Tabetha::6546|r after collecting the book, Jade, and bramble.
    .turnin -1948 >>Turn in Items of Power
    .turnin -1951 >>Turn in Rituals of Power
    .target Tabetha::6546
step
    .goto Dustwallow Marsh,46.06,57.09
    .accept 1952 >>Accept Mage's Wand from |cRXP_FRIENDLY_Tabetha::6546|r
    .target Tabetha::6546
step
    .isOnQuest 1952
    .goto Dustwallow Marsh,46.06,57.09
    >>Wait for Tabetha's ritual to finish. Speak with her again to choose your wand.
    .turnin 1952 >>Turn in Mage's Wand
    .target Tabetha::6546
]])

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Class Quests
#name The Islander and The Affray
<< Horde Warrior

step
    .xp 30 >>Reach level 30 to start the Warrior chain.
step
    .goto Orgrimmar,80.39,32.38
    >>Start with |cRXP_FRIENDLY_Sorek::3354|r in Orgrimmar, |cRXP_FRIENDLY_Torm Ragetotem::3041|r in Thunder Bluff, or |cRXP_FRIENDLY_Baltus Fowler::4595|r in Undercity.
    .accept 1718 >>Accept The Islander
    .target Sorek::3354
step
    .isQuestAvailable 1719
    .subzone 720 >>Follow Merchant Coast south from Ratchet and look for the shallow crossing out to Fray Island.
step
    .isOnQuest 1718
    .goto The Barrens,68.62,49.16
    .turnin 1718 >>Turn in The Islander to |cRXP_FRIENDLY_Klannoc Macleod::6236|r
    .target Klannoc Macleod::6236
step << Warrior
    .goto The Barrens,68.62,49.16
    >>Get ready to fight before accepting. If Klannoc has no quest after The Islander at level 30, check again at level 31.
    .accept 1719 >>Accept The Affray
    .target Klannoc Macleod::6236
step << Warrior
    .isOnQuest 1719
    .goto The Barrens,68.60,48.72
    >>Step on the grate in the middle of the crowd to start the event.
    .complete 1719,2 --The Affray
step << Warrior
    .isOnQuest 1719
    .goto The Barrens,68.61,48.72
    >>Fight through the challengers until |cRXP_ENEMY_Big Will::6238|r enters the ring. Beat him and return to Klannoc before the 10-minute quest timer ends.
    .complete 1719,1 --The Affray
    .mob Big Will::6238
step << Warrior
    .isOnQuest 1719
    .goto The Barrens,68.62,49.16
    .turnin 1719 >>Turn in The Affray to learn Berserker Stance and Intercept.
    .target Klannoc Macleod::6236
]])
