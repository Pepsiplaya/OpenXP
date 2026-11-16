-- Optional class quests for Forever. See docs/CLASS_RESEARCH.md for source records.
local L = GetLocale() if L and RXP.enabledLocale[L] then return end

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Class Quests
#name Research Access
<< Alliance Mage

step
    .isQuestAvailable 97286
    .goto Westfall,52.70,53.80
    .collect 208860,1,79093 >>Loot the |cRXP_PICK_Gnomish Tome|r at Sentinel Hill. The same book is upstairs in the inn at Thelsamar if you pass there first.
step
    .isQuestAvailable 97286
    .itemcount 208860,1
    .goto Stormwind City,48.94,86.54
    >>Show the book to |cRXP_FRIENDLY_Garion Wendell::211033|r in the Mage Tower.
    .turnin 79093 >>Turn in Rumi of Gnomeregan: The Collected Works
    .target Garion Wendell::211033
step
    .isQuestTurnedIn 79093
    .goto Stormwind City,48.94,86.54
    .accept 97286 >>Accept Research Access from |cRXP_FRIENDLY_Garion Wendell::211033|r
    .turnin 97286 >>Turn in Research Access to unlock Study.
    .target Garion Wendell::211033
]])

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
#name Arcane Refreshment
<< Mage

step
    .xp 60 >>Reach level 60 before starting this quest.
step << Mage
    >>Form a Dire Maul group. Visit the Athenaeum library and speak with Lorekeeper Lydros before entering the east wing for Hydrospawn.
    .accept 7463 >>Accept Arcane Refreshment
    .target Lorekeeper Lydros::14368
step << Mage
    .isOnQuest 7463
    >>Enter the Warpwood Quarter in Dire Maul East. Defeat Hydrospawn with your group and take the essence.
    .complete 7463,1 --Hydrospawn Essence
    .mob Hydrospawn::13280
step << Mage
    .isOnQuest 7463
    >>Return to Lorekeeper Lydros in the Athenaeum to learn Conjure Water rank 7.
    .turnin 7463 >>Turn in Arcane Refreshment
    .target Lorekeeper Lydros::14368
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

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Class Quests
#name The Tempest's Weapons (Horde)
<< Horde Orc Shaman/Horde Troll Shaman/Horde Tauren Shaman

step
    .xp 30 >>Reach level 30.
step
    .isQuestAvailable 79360
    +Finish Elemental Aid in the Horde 33–34 Dustwallow Marsh guide. Return after handing the note to Rau.
step
    .isQuestTurnedIn 79360
    .goto Thousand Needles,46.14,51.71
    .accept 79364 >>Accept Eyes on the Sky from |cRXP_FRIENDLY_Rau Cliffrunner::4722|r
    .target Rau Cliffrunner::4722
step
    .isOnQuest 79364
    .goto Thousand Needles,53.54,42.65
    .turnin 79364 >>Turn in Eyes on the Sky to |cRXP_FRIENDLY_Prate Cloudseer::5905|r
    .target Prate Cloudseer::5905
step
    .isQuestTurnedIn 79364
    .goto Thousand Needles,53.54,42.65
    >>The four kinds of totems can be collected in any order. Plan for enemies around levels 34–40 and bring help for the ritual afterward.
    .accept 79361 >>Accept Storm, Earth, and Fire
    .target Prate Cloudseer::5905
step
    .isOnQuest 79361
    .goto Desolace,32.17,55.50
    >>Loot five |cRXP_LOOT_Twisted Air Totems|r from the Maraudine in the western valley of Desolace.
    .complete 79361,4 --Twisted Air Totem
    .mob Maraudine Mauler::4656
    .mob Maraudine Windchaser::4657
    .mob Maraudine Wrangler::4655
step
    .isOnQuest 79361
    .goto Dustwallow Marsh,59.60,9.20
    >>On the northern coast, loot five |cRXP_LOOT_Twisted Water Totems|r from |cRXP_ENEMY_Mirefin Warriors|r and |cRXP_ENEMY_Mirefin Oracles|r.
    .complete 79361,1 --Twisted Water Totem
    .mob Mirefin Warrior::4360
    .mob Mirefin Oracle::4363
step
    .isOnQuest 79361
    .goto Swamp of Sorrows,50.16,34.18
    >>Look for Lost Ones in the northern swamp and loot five |cRXP_LOOT_Twisted Earth Totems|r.
    .complete 79361,2 --Twisted Earth Totem
    .mob Lost One Mudlurker::755
    .mob Lost One Fisherman::757
    .mob Lost One Hunter::759
step
    .isOnQuest 79361
    .goto Badlands,66.33,22.05
    >>Loot five |cRXP_LOOT_Twisted Fire Totems|r from the |cRXP_ENEMY_Dustbelcher Warriors|r and |cRXP_ENEMY_Dustbelcher Mystics|r in northeastern Badlands.
    .complete 79361,3 --Twisted Fire Totem
    .mob Dustbelcher Warrior::2906
    .mob Dustbelcher Mystic::2907
step
    .isOnQuest 79361
    .goto Thousand Needles,53.54,42.65
    .turnin 79361 >>Turn in Storm, Earth, and Fire to |cRXP_FRIENDLY_Prate Cloudseer::5905|r
    .target Prate Cloudseer::5905
step
    .isQuestTurnedIn 79361
    .goto Thousand Needles,53.54,42.65
    .accept 79366 >>Accept Heed My Call
    .target Prate Cloudseer::5905
step
    .isOnQuest 79366
    .goto Thousand Needles,36.68,39.08
    >>Bring help to the steam pools west of Freewind Post. Use the |cRXP_LOOT_Corrupted Totems|r at the ritual circle.
    >>Defeat the waves and loot the |cRXP_LOOT_Eye of the Tempest|r from |cRXP_ENEMY_Ravaging Tempest::216474|r.
    .complete 79366,1 --Heed My Call
    .use 268582
    .mob Ravaging Tempest::216474
step
    .isOnQuest 79366
    .goto Thousand Needles,46.14,51.71
    .turnin 79366 >>Turn in Heed My Call to |cRXP_FRIENDLY_Rau Cliffrunner::4722|r
    .target Rau Cliffrunner::4722
step
    .isQuestTurnedIn 79366
    .goto Thousand Needles,46.14,51.71
    .accept 79442 >>Accept The Tempest's Weapons
    .target Rau Cliffrunner::4722
step
    .isOnQuest 79442
    .goto Alterac Mountains,80.50,66.92
    .turnin 79442 >>Deliver the Eye to |cRXP_FRIENDLY_Bath'rah the Windwatcher::6176|r and choose a weapon.
    .target Bath'rah the Windwatcher::6176
]])

RXPGuides.RegisterGuide([[
#forever
#version 1
#group OpenXP Extras
#subgroup Class Quests
#name Verigan's Fist
<< Alliance Paladin

step
    .xp 20 >>Reach level 20.
step
    .isQuestAvailable 1652
    +Finish The Tome of Valor with Duthorian Rall in Stormwind. The Alliance leveling guides cover Daphne's defense in Westfall.
step
    .isQuestTurnedIn 1652
    .goto Stormwind City,50.48,47.49
    .accept 1653 >>Accept The Test of Righteousness from |cRXP_FRIENDLY_Duthorian Rall::6171|r
    .target Duthorian Rall::6171
step
    .isOnQuest 1653
    .goto Dun Morogh,52.49,36.92
    .turnin 1653 >>Turn in The Test of Righteousness to |cRXP_FRIENDLY_Jordan Stilwell::6181|r near the Gates of Ironforge.
    .target Jordan Stilwell::6181
step
    .isQuestTurnedIn 1653
    .goto Dun Morogh,52.49,36.92
    .accept 1654 >>Accept The Test of Righteousness and keep Jordan's Weapon Notes for the four materials.
    .target Jordan Stilwell::6181
step
    .isOnQuest 1654
    .goto Loch Modan,35.95,44.91
    .accept 1655 >>Accept Bailor's Ore Shipment from |cRXP_FRIENDLY_Bailor Stonehand::6241|r in Thelsamar.
    .target Bailor Stonehand::6241
step
    .isOnQuest 1655
    .goto Loch Modan,71.60,21.61
    >>Look among the ogres northeast of the loch for |cRXP_PICK_Bailor's Ore|r and recover the shipment.
    .complete 1655,1 --Jordan's Ore Shipment
step
    .isOnQuest 1655
    .goto Loch Modan,35.95,44.91
    .turnin 1655 >>Turn in Bailor's Ore Shipment to receive the refined ore.
    .complete 1654,2 --Jordan's Refined Ore Shipment
    .target Bailor Stonehand::6241
step
    #completewith next
    .isOnQuest 1654
    .goto Westfall,42.60,71.70,35 >>Meet your group at Moonbrook, then take the mine tunnels into the Deadmines.
step
    .isOnQuest 1654
    >>Inside the Deadmines, loot |cRXP_LOOT_Whitestone Oak Lumber|r from a |cRXP_ENEMY_Goblin Woodcarver::641|r.
    .complete 1654,1 --Whitestone Oak Lumber
    .mob Goblin Woodcarver::641
step
    #completewith next
    .isOnQuest 1654
    .goto Silverpine Forest,44.80,67.80,35 >>Meet your group at Shadowfang Keep in Silverpine Forest.
step
    .isOnQuest 1654
    >>Once inside Shadowfang Keep, check the stables off the courtyard and take |cRXP_PICK_Jordan's Hammer|r.
    .complete 1654,3 --Jordan's Smithing Hammer
step
    .isOnQuest 1654
    .goto Darkshore,37.40,40.13
    .accept 1442 >>Accept Seeking the Kor Gem from |cRXP_FRIENDLY_Thundris Windweaver::3649|r in Auberdine.
    .target Thundris Windweaver::3649
step
    .isOnQuest 1442
    .goto Darkshore,31.80,92.44
    >>Bring help to the Blackfathom Deeps approach. Loot a |cRXP_LOOT_Corrupted Kor Gem|r from the naga around the ruins or inside the dungeon.
    .complete 1442,1 --Corrupted Kor Gem
    .mob Blackfathom Oracle::4803
    .mob Blackfathom Tide Priestess::4802
    .mob Blackfathom Sea Witch::4805
step
    .isOnQuest 1442
    .goto Darkshore,37.40,40.13
    .turnin 1442 >>Turn in Seeking the Kor Gem to receive the purified gem.
    .complete 1654,4 --Purified Kor Gem
    .target Thundris Windweaver::3649
step
    .isOnQuest 1654
    .goto Dun Morogh,52.49,36.92
    .turnin 1654 >>Return all four materials to Jordan Stilwell.
    .target Jordan Stilwell::6181
step
    .isQuestTurnedIn 1654
    .goto Dun Morogh,52.49,36.92
    .accept 1806 >>Accept the final Test of Righteousness.
    .target Jordan Stilwell::6181
step
    .isOnQuest 1806
    .goto Dun Morogh,52.49,36.92
    >>Wait by the forge while Jordan makes the weapon. Speak with him again for Verigan's Fist.
    .turnin 1806 >>Turn in The Test of Righteousness
    .target Jordan Stilwell::6181
]])
