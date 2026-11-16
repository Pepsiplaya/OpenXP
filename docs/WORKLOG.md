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

### 1.3.66-beta

- Checked upstream again. The branch head still pointed to 1.3.64 when this cycle began. The Valley of Bones playthrough and route comparison are awaiting player observations.
- Added a read-only audit for every Forever guide in the load manifest. It checks quest and endpoint records, objective indices, prerequisites, level discrepancies, and quests caught by the seasonal heuristic. The pinned merged export contains 5,922 quests. The first pass exposed two NPC mismatches at the same Valanaar handoff. Part 2 of The Missing Scholar now ends with Fillion 253285 and Fillion's Mission starts there. Part 2 still begins with Fillion 253284 at the den.
- Redesigned the guide card, waypoint dial, step list, and welcome window with a shared OpenXP Ultimate palette and compass mark. The card shows guide progress and level XP separately, distinguishes quest interactions and hand-ins, and has a compact header for narrow widths. Simulated the 200-pixel card, 20-point text, expansion, step list, and level-cap XP state.
- Corrected Get the Scoop to use `/beckon` with Plucky and added an optional Mage's Wand chapter for both factions. The generator now resolves dungeon-object objectives to the entrance and emits the verified Plucky interaction. The Mage chapter groups the Arathi and Scarlet Monastery tasks before returning to Tabetha. It waits for her ritual after both hand-ins.
- Added the optional Horde Warrior route for The Islander and The Affray. The route gives a shoreline approach before pointing to Klannoc and puts the grate before Big Will. The minimum-level offer and the approach still need a fork playthrough.
- Fixed the Horde Shaman Elemental Aid pickup and added Eyes on the Sky and the Windshaper Call of Air variant. Both Heed My Call variants now explain the Corrupted Totems ritual. The Horde guide requires the Eye before turning in, and an optional Tempest's Weapons chapter covers the four totems and the weapon delivery for Orc, Troll, and Tauren Shamans.
- Kept the Prompt Potion Runner objective and verified its two Undercity NPCs. Improved the timed delivery instructions. Recorded the export's missing objective and ambiguous Shaman capstone requirements for future audits.
- Compared the 1.3.65-beta source and this build against the expanded evidence. The Plucky, Heed My Call, and Fillion checks went from nine diagnostics to zero. The full Windows suite passed 270 Smart Start assertions, 34 Python tests, all other Lua tests, and the coordinate, label, and frozen-route checks.

### 1.3.67-beta

- Packaged 1.3.66-beta and verified its archive and Lua load order. The [fork's Linux checks](https://github.com/Pepsiplaya/OpenXP/actions/runs/43953876213) passed.
- Audited the Verigan's Fist preview. The item export listed Bailor and Thundris as drops for their own quest rewards. Both planners now filter those NPCs out of combat sources. Added regression coverage for genuine drops and recorded vendors.
- Added the missing 1654 pickup to the Alliance Paladin leveling steps and a complete optional materials chapter. The validator requires the Bailor and Thundris rewards before their parent objectives and a separate forge turn-in. The optional guide uses the dungeon entrance waypoints and keeps the Shadowfang hammer objective inside the instance.
- The refreshed Alliance preview cleared both invalid combat instructions. The Windows suite passed 270 Smart Start assertions, 36 Python tests, the other Lua tests, and the coordinate, label, and shared-route checks. The merged export audit still has 20 records and guide steps to review, with no remaining single-NPC handoff mismatch.
- Packaged and verified the 1.3.67-beta archive from `ab88a08`. The [fork's Linux checks](https://github.com/Pepsiplaya/OpenXP/actions/runs/43955107035) passed. Reviewed the next Wolfsbane handoffs and documented the unresolved 95036 objective order and ingot waypoint evidence.
