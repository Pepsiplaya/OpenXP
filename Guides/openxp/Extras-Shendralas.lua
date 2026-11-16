-- Optional quests for players already aligned with one Desolace clan.
-- Sources and current coverage are in docs/ZONE_RESEARCH.md.
local L = GetLocale() if L and RXP.enabledLocale[L] then return end

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Shen'dralas
#name Valley of Bones (Magram)

step
    .xp 35 >>Reach level 35 before starting this route.
step
    .reputation 93,Honored >>Reach Honored with the Magram Clan Centaur before following their Valley of Bones route.
step
    #completewith next
    +Start with the Magram version of Valley of Bones from Warug in Desolace. If you already handed it in, continue with Orgrul.
    >>Enter Shen'dralas from southern Desolace through the Valley of Bones. Watch for elite Corpsefeeders on patrol.
step
    .isOnQuest 92841
    .goto 2652,35.71,12.66
    .turnin 92841 >>Turn in Valley of Bones to |cRXP_FRIENDLY_Orgrul::253136|r
    .target Orgrul::253136
step
    .isQuestTurnedIn 92841
    .reputation 93,Honored,<0,skip
    .goto 2652,35.71,12.66
    .accept 92844 >>Accept Mountain of Bones from |cRXP_FRIENDLY_Orgrul::253136|r
    .accept 92846 >>Accept Outcast Necromancers
    .target Orgrul::253136
step
    .isOnQuest 92846
    .goto 2652,34.20,15.50
    >>Head south into the valley. Kill 6 |cRXP_ENEMY_Outcast Necromancers|r and collect any bone piles you pass.
    .complete 92846,1 --Outcast Necromancers
    .mob Outcast Necromancer::11559
step
    .isOnQuest 92844
    .goto 2652,35.50,19.60
    >>Gather 426 |cRXP_LOOT_Gently Cursed Bones|r. Check the bone piles on the valley floor and loot nearby |cRXP_ENEMY_Undead Ravagers|r.
    .complete 92844,1 --Mountain of Bones
    .mob Undead Ravager::11561
step
    .isOnQuest 92844,92846
    .goto 2652,35.71,12.66
    >>Return north to |cRXP_FRIENDLY_Orgrul::253136|r while still Honored with the Magram.
    .turnin -92844 >>Turn in Mountain of Bones
    .turnin -92846 >>Turn in Outcast Necromancers
    .target Orgrul::253136
]])

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Shen'dralas
#name Valley of Bones (Gelkis)

step
    .xp 35 >>Reach level 35 before starting this route.
step
    .reputation 92,Honored >>Reach Honored with the Gelkis Clan Centaur before following their Valley of Bones route.
step
    #completewith next
    +Start with the Gelkis version of Valley of Bones from Uthek the Wise in Desolace. If you already handed it in, continue with Nerlokh.
    >>Enter Shen'dralas from southern Desolace through the Valley of Bones. Watch for elite Corpsefeeders on patrol.
step
    .isOnQuest 93034
    .goto 2652,20.93,22.68
    .turnin 93034 >>Turn in Valley of Bones to |cRXP_FRIENDLY_Nerlokh::253177|r
    .target Nerlokh::253177
step
    .isQuestTurnedIn 93034
    .reputation 92,Honored,<0,skip
    .goto 2652,20.93,22.68
    .accept 93035 >>Accept Ravaging Ravagers from |cRXP_FRIENDLY_Nerlokh::253177|r
    .accept 93037 >>Accept Outing Outcasts
    .target Nerlokh::253177
step
    .isOnQuest 93035
    .goto 2652,22.60,23.70
    >>Head east into the valley and kill 6 |cRXP_ENEMY_Undead Ravagers|r.
    .complete 93035,1 --Ravaging Ravagers
    .mob Undead Ravager::11561
step
    .isOnQuest 93037
    .goto 2652,23.90,23.50
    >>Kill |cRXP_ENEMY_Outcast Necromancers|r near the edge of the valley until one drops the |cRXP_LOOT_Necromantic Garb|r.
    .complete 93037,1 --Outing Outcasts
    .mob Outcast Necromancer::11559
step
    .isOnQuest 93035,93037
    .goto 2652,20.93,22.68
    >>Return west to |cRXP_FRIENDLY_Nerlokh::253177|r while still Honored with the Gelkis.
    .turnin -93035 >>Turn in Ravaging Ravagers
    .turnin -93037 >>Turn in Outing Outcasts
    .target Nerlokh::253177
]])
