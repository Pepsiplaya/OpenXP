# Player testing for OpenXP Ultimate 1.3.68-beta

## Install the test build

1. Close WoW Forever. Use a separate Forever installation or test profile if available.
2. For a swap in your existing installation, move your existing `OpenXP` addon folder outside `Interface\AddOns`. Back up its `OpenXP.lua` and `OpenXP.lua.bak` files from the account and character `SavedVariables` directories, where present.
3. Extract the test ZIP. Copy the extracted `OpenXP` folder into `World of Warcraft\_forever_\Interface\AddOns`. The file should be at `AddOns\OpenXP\OpenXP.toc`. Disable RestedXP Guides in the character selection AddOns menu while testing OpenXP.
4. Log in and run `/oxp news`. Confirm the version is `1.3.68-beta`. To restore the original build, exit the game, move the test folder out, and restore the original folder and backed-up OpenXP SavedVariables.

## Fresh Alliance Mage

Start at level 1. A Human starts in Northshire, a Gnome in Coldridge Valley, and a High-Order Skyborne on Zephras Isle.

| When | What to check |
| --- | --- |
| First login | Smart Start selects the racial chapter. The guide menu shows **Mage leveling**. The panel identifies your starter route, current guide, and first spell milestones. |
| First trainer and level 4 | Follow the waypoint and talk to the named trainer. Check Frostbolt and Conjure Water, then reopen the panel after training. The questing steps keep the Hearthstone for a Human or Gnome Mage. |
| Levels 6–13 | Check Conjure Food at 6 and Polymorph at 8. A Skyborne sees the two trainer NPCs in the correct locations and the wand reward notes. Compare your first wand with the options in the panel. |
| Westfall, Darkshore, and Ashenvale | Try the Sentinel Hill book and see if Garion offers Research Access. For the Kerlonian escort, record whether the Horn arrives on acceptance, where the log changes to ready, and the remaining time when you reach Maestra's Post. |
| Level 20 onward | Check the Stormwind and Ironforge teleport offers and the rune requirement. Run one quest loop and one comparable dungeon or grinding segment. Keep elapsed time through travel, drinking, and group formation. |
| Optional group quests | Blackfathom Deeps should lead to Argent Guard Thaelrid inside and Dawnwatcher Selgorm for Gravestone Scepter. At 60, Arcane Refreshment sends you from Lorekeeper Lydros to Hydrospawn in Dire Maul East and back. |

For an optional timed sample, use the separate [Recorder beta](RECORDER.md) with `/oxprec start` and `/oxprec stop`, then log out or reload. The Mage guide and the recorder can be tested independently.

## Other regression checks

| Test | Starting conditions | Expected result |
| --- | --- | --- |
| Guide card and welcome | Open `/oxp news`. Open the guide card at its normal size, then resize to 200 pixels and try the 20-point font and one-line mode. | The header and step counter remain usable, the counter opens the step list, and the XP line shows the correct level and percentage. Confirm max-level hides the XP line. Expand the card, then check both waypoint directions and the green arrival check. |
| Mage's Wand | Mage at level 30 or higher. Select OpenXP Extras → Class Quests → Mage's Wand. Try a fresh chain and one with a prior quest in the log. | `/beckon` and speak to Plucky. Gather Jade and the bramble, collect the book in Scarlet Monastery Library, hand in both quests, and wait for Tabetha's ritual. Record dungeon entry and objective tracking if you load the chapter inside. |
| Verigan's Fist | Alliance Paladin, level 20 or higher, with The Tome of Valor (1652) turned in. Select Verigan's Fist under OpenXP Extras → Class Quests. | Jordan offers 1654. Bailor and Thundris's hand-ins supply the refined ore and gem, the dungeon steps track lumber and hammer, and the last quest rewards the mace after the forge event. Check the stables and whether the gem drops around the Blackfathom entrance. |
| Horde Warrior | Level 30 or 31. Select The Islander and The Affray in OpenXP Extras → Class Quests. Test from Ratchet and with The Islander already handed in. | The shoreline directions lead to Fray Island. The grate activates the event, Big Will gives credit, and Klannoc hands out the stance and Intercept. Record the level of each offer. |
| Shaman Call of Air and Heed My Call | Level 30 Windshaper Shaman for 96136. Use an Orc, Troll, or Tauren Shaman with Elemental Aid done to try The Tempest's Weapons in OpenXP Extras. | Alaana starts the Windshaper delivery to Prate. In the weapon chapter each totem increments the correct objective. Corrupted Totems start the ritual, and Rau turns in the Eye before Bath'rah's delivery. Confirm the Alliance ritual also awards the Eye. |
| Valanaar handoff | Alliance Skyborne with The Missing Scholar Part 2 (92850). | Pick it up at the Shriekling Den. Return to Valanaar with the head, hand it to Fillion (253285), and pick up Fillion's Mission. |
| Gelkis Valley of Bones | Level 35 or above, Honored Gelkis, quest 93034 active or already turned in. Select OpenXP Extras → Shen’dralas → Valley of Bones (Gelkis). | Hand 93034 to Nerlokh if active. Accept 93035 and 93037, then see separate kill and loot steps before the turn-ins. Check the southern Desolace approach and the eastbound waypoints. |
| Magram Valley of Bones | Level 35 or above, Honored Magram, quest 92841 active or already turned in. Select the Magram chapter. | Orgrul offers 92844 and 92846 after the breadcrumb. Check the terrain approach, six Outcast kills, and the 426-bone objective. Note which piles and kills produce bones and how long the loop takes. |
| Alliance main route | Finish 39–40 Desolace in the OpenXP 21–60 guide. | The next guide is 40–41 Ironforge. If you were playing the removed 40–41 Shen’dralas section, use `/oxp where` to resume the main guide or choose your clan chapter from OpenXP Extras. |
| Plaguelands tower captures | Level 55 or above. Open the faction's tower quest under OpenXP Extras → World PvP. | Capture all four named towers. Record credit with the active quest and the layer's tower control. The shared 58–59 chapters continue through the other Eastern Plaguelands quests. |
| Skyborne Herbalism | Accept 97968 with Herbalism trained. Check before and after reaching Herbalism 20 while still on Zephras Isle. | The step appears once turn-in is ready and leads to Halassa Fernbreeze in Shen’dar Village (43.01, 43.55). Check both faction routes if you have characters available. |
| Alliance Priest | Gnome or Dwarf Priest at level 20 or above, around the Ironforge class stop in 22–23 Wetlands. | Mims offers or finishes Contingency Plan for a Gnome. Rohan offers Chastise for a Dwarf. Check that neither appears for the other race. If you already have 94819 or 94820, Mims can finish it. |
| Alliance Warrior | The Affray (1719) from Klannoc on Fray Island. | The grate comes first. Defeat the challengers and Big Will, then return to Klannoc within the quest timer. |
| Quest-log recovery | Open your quest log and expand its headers. Run `/oxp step` on an active guide quest, then collapse the relevant header and run it again. | Expanded log diagnostics show the correct active IDs. A collapsed log can be reported as unreadable. Reopen it and confirm the result refreshes. |

Test one clan per character to preserve reputation. If you are short of Honored or lack the Valley of Bones breadcrumb, record the current standing and quest dialog so the prerequisite can be checked. The optional chapters begin at the breadcrumb hand-in and end after the first pair of objectives.

## Report a result

Copy this into your reply and fill the fields you observed. Use `/oxp step` for a stuck quest, `/oxp perf` for a performance problem, and a screenshot of the waypoint or objective counter when available. Trim any names or unrelated chat from screenshots and diagnostics.

```text
OpenXP version / Forever build:
Faction, race, class, level:
Guide name / step / quest ID:
Zone, coordinates, and clan standing if relevant:
Quest log objective counters:
Expected and actual result:
Travel / fighting / recovery minutes, XP gained, deaths, gold spent:
Relevant /oxp step or /oxp perf lines:
```

No fork playthrough has been recorded yet. Add confirmed observations with the game build and conditions to the corresponding research file.
