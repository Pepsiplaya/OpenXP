# OpenXP Recorder beta

OpenXP Recorder is an optional companion for WoW Forever. It uses the game's public API and its own per-character SavedVariables. It can run alongside OpenXP Ultimate, RestedXP, or by itself. Everything stays local. It samples the player unit and listens for XP, quest, map, and death events.

## Record a session

1. Extract the separate recorder ZIP into the `Interface/AddOns` directory for your Forever test installation. Check for `Interface/AddOns/OpenXPRecorder/OpenXPRecorder.toc` and enable **OpenXP Recorder** in the AddOns list.
2. Run `/oxprec start` immediately before the segment you want to measure. Use `/oxprec start positions` if route reconstruction needs samples of your position on the current map. The default collects map IDs only.
3. Play the segment. `/oxprec status` reports the session ID and event count.
4. Run `/oxprec stop` at the end, then log out or `/reload` so WoW writes SavedVariables. Logout and reload each end an active session. Start a new recording when you resume.

The recorder stores the client build, class, faction, level and XP snapshots, activity and instance flags, and quest IDs with times relative to the session. Optional positions are rounded to one tenth of one percent of the map. It retains four sessions per character and stops a session at 8,192 events. Copy sessions you want to keep before rotation. The file contents use session IDs, and the path WoW gives the file includes account and character directories.

## Summarize a session

Read the character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/OpenXPRecorder.lua` from the Forever game folder. Keep the source file local. The analyzer accepts a literal SavedVariables table and emits aggregate results.

```powershell
python tools/analyze_recording.py 'PATH\OpenXPRecorder.lua'
python tools/analyze_recording.py 'PATH\OpenXPRecorder.lua' --session 1 --json
python tools/analyze_recording.py 'PATH\OpenXPRecorder.lua' --benchmark 'PATH\summary.json'
python tools/analyze_recording.py 'PATH\OpenXPRecorder.lua' --benchmark 'PATH\mage-visits.json' --hub wetlands
```

Use a `tools/build_route.py --benchmark` summary for a whole route or select one hub from `tools/compare_mage_routes.py` output. The hub defaults to ordinary travel. Pass `--transport teleport` when the model includes the teleport duration. Measured and simulated XP rates appear separately. The analyzer reports a time difference when faction and level range match, XP is observed at both boundaries, there are no detected XP gaps, and the session ends normally. A hub comparison also checks Mage class, the exact starting XP, and the modeled hand-ins. Record matched routes from the same position, quest log, talents, gear, rest state, and travel unlocks. Record any serious interruptions or group formation separately.

| Measurement | Interpretation |
| --- | --- |
| XP and gross XP per hour | Derived from observed XP and level changes over elapsed session time. The analyzer flags jumps of multiple levels or inconsistent snapshots. Turn-in rewards are reported separately from XP gained. |
| Quest activity | Counts acceptance and hand-in events and measures time between matched events in the same session. The elapsed span can include other work. |
| Activity seconds | Estimates combat, movement, flight paths, stationary time, AFK, death, and loading time using five-second samples and transition events. Intervals without adequate samples are unknown. Stationary time can include eating, reading, group formation, and other activities. |
| Map summaries | Assigns sampled time to each observed map and assigns XP to a map when adjacent XP snapshots agree on it within the sampling window. Map changes and any position samples reflect what the client exposed. |
| Dungeon and group time | Counts sampled intervals marked as a party instance and intervals during which the player was grouped. These durations can overlap with the activity buckets. |

## Build and validation

The recorder is a separate addon folder. To build the optional ZIP from a committed revision, run this from the repository after creating `dist`.

```powershell
git archive --format=zip --prefix=OpenXPRecorder/ --output=dist/OpenXPRecorder-0.1.0-beta.zip HEAD:companion/OpenXPRecorder
```

**VERIFIED BY GAME DATA** from the generated API documentation for Forever 1.60.1.70938, reviewed November 16, 2026. Use the one-argument quest acceptance event, the quest hand-in event with XP, and the public player XP and map snapshots. [Quest log](https://github.com/reckhou/WoWBlzCode/blob/21ec933bce345f004617343c112a1169710be14a/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L1239), [Map API](https://github.com/reckhou/WoWBlzCode/blob/21ec933bce345f004617343c112a1169710be14a/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua#L411), [XP and event index](https://github.com/reckhou/WoWBlzCode/tree/21ec933bce345f004617343c112a1169710be14a/index/Forever)

**SIMULATED**. Tests cover explicit opt-in, snapshot rollover, restricted values, session limits, loading, matched quests, and the literal-only importer. **UNVERIFIED**. Check timing and event order near level-up, indoor maps, dungeon changes, and alongside each guide addon in a live Forever sample.
