# Route optimization

## Reproduce a preview

Use Python 3.12 with `lupa` and a separate QuestieDB checkout. The November 16 benchmark used QuestieDB 1.1.2 at `e1652ce62113c152da682baf2d6fb85f1396bcfb`. QuestieDB’s own offline export combines the Forever baseline with updated static records. [Exporter documentation](https://github.com/Questie/QuestieDB/blob/e1652ce62113c152da682baf2d6fb85f1396bcfb/tools/export/README.md)

Run this in the QuestieDB checkout on Windows.

```powershell
.\tools\lua-binary\lua.exe tools/export-forever.lua --include-authored
```

Run this in OpenXP. Create the directory for the summary and decisions files before running. Use `tools/routes/horde.py` for the Horde comparison.

```powershell
python tools/build_route.py --questiedb PATH\QuestieDB\src\corrections\Forever\combined --output-dir PATH\preview --benchmark PATH\summary.json --log PATH\decisions.json tools/routes/alliance.py
```

Passing the QuestieDB checkout root uses its raw tables. A current, external `/oxp questdump` and separate reward facts can supplement either input. The benchmark records the input type and flags these additional sources. Keep the database and player files out of OpenXP commits and release archives.

## What the planner counts

The hub planner compares nearby and subsequent visits using estimated XP per minute. It tracks quest and kill XP, quests carried into other zones, inter-zone travel, walking within each visit, and the time budget for grinding. The exported route replays pickups, objectives, and turn-ins against the quest log. A pending final grind is written into the draft when the model relies on it to reach the next level.

The Forever cap is 40. Quests outside the current zone consume slots. Turn-ins free slots for subsequent visits during lookahead. The Classic planner keeps its existing cap of 20. The retained drafts report peak quest slots after removing pickups that never get finished.

The travel clock now includes flights, boats, and hub approaches. This gives the Hearthstone cooldown and total-time calculation the same clock used to compare visits. Within-zone walk estimates precede the final local reorder. Spawn walks, combat, recovery, and NPC interactions still share a work estimate where the source cannot separate them. XP curves and work estimates need Forever player calibration. Group formation, PvP exposure, deaths, repairs, class budgets, and gear effects are pending.

## November 16 baseline comparison

**SIMULATED** from the raw Forever tables in QuestieDB 1.1.2, using 4,244 quest records. Both Alliance runs use the same updated planner, with only `OXP_SET=QUEST_LOG_LIMIT=20` different in the control. The lower capacity reduced the set of quests available during planning even though the emitted paths prune unused pickups. The difference in total time is smaller than the uncertainty of the current model.

| Draft and cap | Levels | Reported turn-ins | Peak quest slots | Travel | Objective and interaction work | Grinding | Total |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Alliance 20 | 21–60 | 358 | 17 | 24.5 h | 44.5 h | 49.8 h | 118.7 h |
| Alliance 40 | 21–60 | 457 | 18 | 31.4 h | 56.4 h | 30.6 h | 118.3 h |
| Horde 40 | 22–60 | 393 | 30 | 27.3 h | 64.7 h | 31.6 h | 123.6 h |

**SIMULATED** using the merged export, with 5,922 quest records and authored static corrections. Both drafts at the Forever cap reached 60 in the model. The 20-slot Alliance control exhausted the planner’s fallback grind budget around level 46.3.

| Draft and cap | Levels reached | Reported turn-ins | Peak quest slots | Travel | Objective and interaction work | Grinding | Total |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Alliance 20 | 21–46.3 | 222 | 15 | 12.8 h | 20.4 h | 21.5 h | 54.7 h |
| Alliance 40 | 21–60 | 550 | 27 | 32.6 h | 66.5 h | 17.0 h | 116.1 h |
| Horde 40 | 22–60 | 446 | 32 | 30.7 h | 74.8 h | 19.6 h | 125.1 h |

With fuller quest records, the model replaces some grinding with quests on both factions. Candidate route quality still depends on current objective data, in-game travel and clear times, and the initial character’s actual quest log. These drafts are separate from the playable beta guides.

The reviewed quest evidence validator finds five objective-less turn-ins in upstream OpenXP 1.3.64 and zero in 1.3.65-beta. This comparison covers the recorded quests. It does not estimate the number of issues across the entire guide.

## Calibration

Record game build, guide and step range, character level and class, XP before and after, time on travel legs, combat time, recovery time, group formation time, gold spent, deaths, waypoint errors, and skipped steps. Capture the same segment in the upstream build and this beta. Start with [Valley of Bones and Zephras Isle](PLAYER_TESTING.md).

Polestar’s separate trial replay, versioned references, and timed route comparison are useful design references. For OpenXP, keep measured leg data local and compare a matched character, route segment, and client build. [Polestar project](https://github.com/fitzforge/polestar)
