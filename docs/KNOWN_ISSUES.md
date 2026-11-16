# Known issues and upstream review

Reviewed against OpenXP 1.3.64 on November 16, 2026.

| Report | Evidence and disposition | Player test |
| --- | --- | --- |
| [#6 performance](https://github.com/mjared123/OpenXP/issues/6) | Upstream 1.3.36 spread path work over frames, and 1.3.48 cut minimap redraws and added `/oxp perf`. The reporter’s original problem needs a current test. | **UNVERIFIED**. Record frame behavior with the map open and closed while walking a difficult route. Capture `/oxp perf`. |
| [#25 Tarrel Rockweaver](https://github.com/mjared123/OpenXP/issues/25) | The reported position was in Loch Modan. OpenXP points to Menethil Harbor at 11.50, 52.17, which agrees with a current Forever player observation. The guide now names the harbor at both encounters. [Observed record](https://guildloot.de/en/quest/forever/305-in-search-of-the-excavation-team/) | **UNVERIFIED** on this fork. Confirm the NPC in Menethil Harbor with the exact quest ID and log state, then capture `/oxp step` if the arrow disagrees. |
| [#29 Grimtotem Spying](https://github.com/mjared123/OpenXP/issues/29) | Note #2 before Highperch is deliberate. The three notes are independent completion objectives. The guide now names the Document Chest and the westbound leg. [Quest record](https://db.icy-veins.com/wow-forever/quests/5064) | **UNVERIFIED**. Record how you reach the #2 chest and whether it can be opened before #1, then follow the return leg for #1 and #3. |
| [#42 Hillsbrad chain](https://github.com/mjared123/OpenXP/issues/42) | The reporter completed the chain. Upstream 1.3.64 added catch-up for Battle of Hillsbrad part 2 (528) before part 3 (529). | **UNVERIFIED** on this fork. Test holding 528 at the 27–28 section and verify it leads to 529. |
| [PR #23 quest-log API](https://github.com/mjared123/OpenXP/pull/23) | The upstream PR author verified modern quest-log enumeration in Forever. The fork now reads the modern rows, retains its classic fallback, and leaves incomplete snapshots indeterminate. | **SIMULATED** on this fork. Test expanded, collapsed, and empty logs. |
| [PR #39 data providers](https://github.com/mjared123/OpenXP/pull/39) | Open upstream approach for optional data providers and provenance. The fork’s first release reads no new bundled database. | Review the upstream outcome before implementing a second runtime integration. |

## Fork coverage gaps

- The two Shen’dralas chapters cover the first valley objectives after each clan’s breadcrumb. Their earlier clan quests and later zone routes still need playthroughs.
- Custom zone terrain, group costs, contested routes, class combat profiles, and economic estimates are incomplete.
- The draft builder can use Classic-era XP curves and older quest rows when given raw QuestieDB. Follow the published player guide for testing. Use draft exports as comparison material.
