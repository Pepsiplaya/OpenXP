# Compare Alliance Mage routes

`tools/compare_mage_routes.py` compares a local quest visit with trips to other Alliance hubs from the same modeled Mage position, level, quest state, and travel unlocks. It uses the existing quest dependency checks, objective clustering, walking costs, and flight and boat network. Each alternative starts with a fresh copy of the same quest state. The report lists estimated quest XP, mob XP, hub walking time, transit time, turn-ins, and whether the visit reaches the next level.

## Reproduce a comparison

Use the same separate QuestieDB checkout as the [route optimization benchmarks](ROUTE_OPTIMIZATION.md). Save the checkpoint JSON outside the repository. `hub` names the starting pin of that hub in `tools/routes/alliance.py`. Use the completed and held quest IDs from the character when available. A ready quest must also be active. `ready_hearthstone` names a known network town and is optional. The tool covers the shared hub planner's level 21 to 60 range.

```json
{
  "race": "Human",
  "hub": "ashenvale",
  "level": 21,
  "xp_in_level": 0,
  "completed_quests": [],
  "active_quests": [],
  "ready_quests": [],
  "known_flight_paths": ["Astranaar", "Auberdine", "Menethil Harbor", "Ironforge", "Stormwind", "Lakeshire", "Darkshire", "Thelsamar", "Sentinel Hill"],
  "ready_hearthstone": "Astranaar",
  "learned_teleports": [3561, 3562],
  "teleport_runes": 1
}
```

```powershell
python tools/compare_mage_routes.py --questiedb PATH\QuestieDB\src\corrections\Forever\combined --checkpoint PATH\state-21.json --hub duskwood --hub wetlands --hub redridge --out PATH\comparison.json
```

The local hub is always included. Omit `--hub` for all known hubs. An absent ordinary travel time means the shared network could not find a route from the supplied state. `ordinary_xp_per_hour` includes transit and time inside the hub. Compare it to a measured local grinding session with equivalent level, rest, travel, loot, drinking, and recovery. A visit stops taking new quests after leveling up and finishes quests it already holds. The model estimates unfinished objectives in full and credits the turn-in for any supplied ready quest. Judge a trip's XP per hour together with `end_level` and the turn-ins, so a short chain of high-rate errands does not stand in for a full level.

## Teleport model

**VERIFIED BY GAME DATA**, reviewed November 16, 2026. Teleport: Stormwind (3561) and Ironforge (3562) require level 20. Darnassus (3565) requires 30. All three teleport the caster, consume one Rune of Teleportation (17031), and have a 10-second cast. They require the character to have learned the spell. Alliance Mage character creation supports Human, Gnome, and High-Order Skyborne. The merged quest row for Welcome to Azeroth (94947) identifies the Alliance Skyborne race mask. [Stormwind spell](https://www.wowhead.com/forever/spell=3561/teleport-stormwind), [Ironforge spell](https://www.wowhead.com/forever/spell=3562/teleport-ironforge), [Darnassus spell](https://www.wowhead.com/forever/spell=3565/teleport-darnassus), [Rune of Teleportation](https://www.wowhead.com/forever/item=17031/rune-of-teleportation), [Blizzard character creation matrix](https://news.blizzard.com/en-us/article/24304075/create-the-hero-you-want-to-be-in-world-of-warcraft-forever).

The comparator models a single optional Teleport before the visit. It uses the stated learned spells and rune count and shares the same onward flight restrictions as ordinary travel. `teleport_travel.minutes` adds the verified cast to estimated onward network travel. Loading and the walk from the spell's arrival point to the city anchor remain separate. The break-even overhead is the time those parts can take before the estimate loses its advantage. A negative threshold means the other choice has the better rate even at zero additional overhead. `teleport_break_even_overhead_seconds` compares two trips to the same destination. `teleport_vs_stay_overhead_seconds` compares quest XP per hour with staying. Supply `teleport_overhead_seconds` only with an observed or otherwise documented value. At an unknown overhead, the comparator reports thresholds and ranks alternatives using the ordinary travel estimate.

## November 16 runs

**SIMULATED** from the pinned merged QuestieDB 1.1.2 export at `e1652ce62113c152da682baf2d6fb85f1396bcfb`, with 5,922 quest rows. The test checkpoints have empty quest logs at the start of an exact level, purposely hold flight paths fixed within each comparison, and omit teleport overhead. The modeled rates use the existing Classic-derived XP and work estimates. A matched in-game run can test these rankings.

| Modeled start | Visit | Estimated minutes | Estimated XP/hour | End level | Teleport overhead to match ordinary travel |
| --- | --- | ---: | ---: | ---: | ---: |
| Level 21, Astranaar | Stay in Ashenvale | 68.8 | 16,264 | 21.74 | — |
| Level 21, Astranaar | Duskwood | 83.4 | 16,610 | 21.92 | 438 seconds |
| Level 21, Astranaar | Wetlands | 93.4 | 15,234 | 21.94 | 374 seconds |
| Level 21, Astranaar | Redridge | 146.6 | 14,359 | 22.36 | 438 seconds |
| Level 36, Theramore | Stay in Dustwallow Marsh | 32.2 | 76,960 | 36.58 | — |
| Level 36, Theramore | Wetlands | 17.2 | 49,948 | 36.20 | 181 seconds |
| Level 53, Marshal's Refuge | Stay in Un'Goro | 299.2 | 35,124 | 54.05 | — |
| Level 53, Marshal's Refuge | Ironforge errands | 34.7 | 56,343 | 53.20 | 676 seconds |

The Duskwood trip was about 2.1% ahead of staying at 21 under ordinary travel. With a learned Stormwind Teleport and a rune, its modeled advantage over staying allows about 9 minutes of additional teleport overhead. The level 36 model favors the short visit at Theramore. At 53, the Ironforge errands are faster per point of XP, while Un'Goro reaches 54 in one visit. Test a Duskwood or Theramore visit with the actual open quests, measure teleport loading and city travel, and include the elapsed time before and after the visit.

For the level 36 input, use `Gnome`, `dustwallow`, `Theramore` as ready hearth, spells `[3561, 3562, 3565]`, and flight paths Theramore, Astranaar, Auberdine, Menethil Harbor, Ironforge, Stormwind, Southshore, Refuge Pointe, Darkshire, Lakeshire, Booty Bay, Rut'theran Village, and Nijel's Point. For level 53, use `Skyborne`, `ungoro`, `Marshal's Refuge` as ready hearth, the same spells, and flight paths Marshal's Refuge, Gadgetzan, Theramore, Auberdine, Menethil Harbor, Ironforge, Stormwind, Southshore, Chillwind Camp, Thorium Point, Rut'theran Village, Talonbranch Glade, Everlook, and Aerie Peak.

**UNVERIFIED** for the fork. Dungeon wait, clear time, class damage by gear or talent, mana recovery, player competition, and PvP interruptions need a real run. The network model switches to mounted speed at level 40, so record the actual riding purchase when testing later travel. Separate single-target pulls and AoE pulls into different samples and include failed pulls and drinks. Blizzard's November 13 hotfix makes Blizzard damage break Frost Nova and removes dungeon kill XP for the entire group if the enemy is trivial to any member. Use the current build and party level range for any such comparison. [Blizzard hotfixes](https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-13-2026).
