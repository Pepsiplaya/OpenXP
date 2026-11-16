-- Optional world PvP quests. See docs/RESEARCH_SOURCES.md for the captured quest data.
local L = GetLocale() if L and RXP.enabledLocale[L] then return end

RXPGuides.RegisterGuide([[
#forever
#version 1
<< Alliance
#group OpenXP Extras
#subgroup World PvP
#name Establishing New Outposts

step
    .xp 55 >>Reach level 55 before starting this tower capture quest.
step
    .goto Eastern Plaguelands,71.51,49.66
    >>This quest involves world PvP. Check tower control on your map and wait for capture credit at each tower.
    .accept 9664 >>Accept Establishing New Outposts from |cRXP_FRIENDLY_Emmisary Whitebeard::17069|r
    .target Emmisary Whitebeard::17069
step
    .isOnQuest 9664
    .goto Eastern Plaguelands,34.09,64.10
    .complete 9664,1 >>Capture Crownguard Tower while flagged for PvP.
step
    .isOnQuest 9664
    .goto Eastern Plaguelands,59.04,39.41
    .complete 9664,2 >>Capture Eastwall Tower while flagged for PvP.
step
    .isOnQuest 9664
    .goto Eastern Plaguelands,49.25,18.20
    .complete 9664,3 >>Capture Northpass Tower while flagged for PvP.
step
    .isOnQuest 9664
    .goto Eastern Plaguelands,18.16,25.06
    .complete 9664,4 >>Capture Plaguewood Tower while flagged for PvP.
step
    .isOnQuest 9664
    .goto Eastern Plaguelands,71.51,49.66
    .turnin 9664 >>Turn in Establishing New Outposts to |cRXP_FRIENDLY_Emmisary Whitebeard::17069|r
    .target Emmisary Whitebeard::17069
]])

RXPGuides.RegisterGuide([[
#forever
#version 1
<< Horde
#group OpenXP Extras
#subgroup World PvP
#name Bolstering Our Defenses

step
    .xp 55 >>Reach level 55 before starting this tower capture quest.
step
    .goto Eastern Plaguelands,70.37,47.94
    >>This quest involves world PvP. Check tower control on your map and wait for capture credit at each tower.
    .accept 9665 >>Accept Bolstering Our Defenses from |cRXP_FRIENDLY_Emmisary Gormok::17072|r
    .target Emmisary Gormok::17072
step
    .isOnQuest 9665
    .goto Eastern Plaguelands,34.09,64.10
    .complete 9665,1 >>Capture Crownguard Tower while flagged for PvP.
step
    .isOnQuest 9665
    .goto Eastern Plaguelands,59.04,39.41
    .complete 9665,2 >>Capture Eastwall Tower while flagged for PvP.
step
    .isOnQuest 9665
    .goto Eastern Plaguelands,49.25,18.20
    .complete 9665,3 >>Capture Northpass Tower while flagged for PvP.
step
    .isOnQuest 9665
    .goto Eastern Plaguelands,18.16,25.06
    .complete 9665,4 >>Capture Plaguewood Tower while flagged for PvP.
step
    .isOnQuest 9665
    .goto Eastern Plaguelands,70.37,47.94
    .turnin 9665 >>Turn in Bolstering Our Defenses to |cRXP_FRIENDLY_Emmisary Gormok::17072|r
    .target Emmisary Gormok::17072
]])
