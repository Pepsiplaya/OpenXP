# Worklog

## November 16, 2026

- Forked OpenXP into [Pepsiplaya/OpenXP](https://github.com/Pepsiplaya/OpenXP), preserved `upstream`, and based `codex/openxp-ultimate` on upstream 1.3.64 (`9940a0b`). The baseline passed 268 Smart Start assertions, the other Lua suites, the frozen-route check, and coordinate and label validation.
- Confirmed the Forever 40-quest cap from the 1.60.1 client, applied it across visits and to the action reorder, and tested both planner paths and off-zone carry. Added modern quest-log enumeration with cache tests for active, collapsed, and missing rows.
- Reviewed upstream issues #6, #25, #29, and #42. Fixed the separate verified modern quest-log defect. Recorded the live retests in [Known issues](KNOWN_ISSUES.md).
- Replaced the broken shared clan detour with two opt-in Valley of Bones chapters. Removed the premature A Conqueror’s Crown instructions from both faction guides. Added game-fact checks for prerequisite and objective order, endpoints, reputation, and verified immediate turn-ins.
- Updated the post-hotfix Skyborne Herbalism waypoint. Added Ironforge Contingency Plan and Chastise corrections and reordered The Affray. Prepared live test cases for existing and new characters.
- Ran pinned QuestieDB drafts for both factions. Added isolated preview output, quest-state replay, and timing that includes inter-zone travel. OpenXP can read QuestieDB’s merged offline export from a separate folder, including sparse objective rows. See [Route optimization](ROUTE_OPTIMIZATION.md) for estimates and coverage limits.
- Prepared OpenXP 1.3.65-beta using the release packager. Windows validation passed 270 Smart Start assertions, the other Lua suites, and the coordinate, frozen-route, guide-label, and package checks.
- Audited the merged Alliance preview and fixed a generator regression that treated Contingency Plan as a general Priest quest. Generated steps now preserve reviewed class and race tags and record a numeric NPC target. The Python suite includes 19 tests. See [Player testing](PLAYER_TESTING.md) and [Next actions](NEXT_ACTIONS.md) for the next cycle.
