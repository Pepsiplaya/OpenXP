# Player testing for OpenXP 1.3.65-beta

## Install the test build

1. Close WoW Forever. Use a separate Forever installation or test profile if available.
2. For a swap in your existing installation, move your existing `OpenXP` addon folder outside `Interface\AddOns`. Back up its `OpenXP.lua` and `OpenXP.lua.bak` files from the account and character `SavedVariables` directories, where present.
3. Extract the test ZIP. Copy the extracted `OpenXP` folder into `World of Warcraft\_forever_\Interface\AddOns`. The file should be at `AddOns\OpenXP\OpenXP.toc`. Disable RestedXP Guides in the character selection AddOns menu while testing OpenXP.
4. Log in and run `/oxp news`. Confirm the version is `1.3.65-beta`. To restore the original build, exit the game, move the test folder out, and restore the original folder and backed-up OpenXP SavedVariables.

## What to test first

| Test | Starting conditions | Expected result |
| --- | --- | --- |
| Gelkis Valley of Bones | Level 35 or above, Honored Gelkis, quest 93034 active or already turned in. Select OpenXP Extras → Shen’dralas → Valley of Bones (Gelkis). | Hand 93034 to Nerlokh if active. Accept 93035 and 93037, then see separate kill and loot steps before the turn-ins. Check the southern Desolace approach and the eastbound waypoints. |
| Magram Valley of Bones | Level 35 or above, Honored Magram, quest 92841 active or already turned in. Select the Magram chapter. | Orgrul offers 92844 and 92846 after the breadcrumb. Check the terrain approach, six Outcast kills, and the 426-bone objective. Note which piles and kills produce bones and how long the loop takes. |
| Alliance main route | Finish 39–40 Desolace in the OpenXP 21–60 guide. | The next guide is 40–41 Ironforge. If you were playing the removed 40–41 Shen’dralas section, use `/oxp where` to resume the main guide or choose your clan chapter from OpenXP Extras. |
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
