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

### 1.3.68-beta

- Checked upstream at the start of the cycle. It was still at 1.3.64. Confirmed all three legal Alliance Mage starts, retained their Hearthstone, and repaired Skyborne steps that used Dorii's target at Shenaan's location. Added a level-aware Mage panel in the OpenXP style and checked it opens at a smaller viewport and refreshes as spells are learned.
- Repaired the Sleeper escort using the November 6 hotfix and the quest-log readiness API. Both escort paths lead through southern Darkshore to Maestra's Post. The Plaguelands tower steps now track captures in two optional faction chapters, leaving the solo leveling routes free of the PvP detour.
- Added the Blackfathom wand quest, the optional Stormwind library book and Study handoff, and Arcane Refreshment at 60. Added guidance for accessible early wands and scoped the Andromath breadcrumb using its Human and Gnome mask. See [Mage leveling](MAGE_LEVELING.md) for the spells, travel choices, leveling bands, and live test gaps.
- Compared local and remote hubs from matched Mage checkpoints at 21, 36, and 53. The level-21 estimate was too close to justify changing the default. Fixed a stale breadcrumb cache between hub visits and reproduced the comparison on the same export.
- Added the opt-in standalone recorder, SavedVariables importer, and analysis of measured sessions against route and hub estimates. Its own archive contains no guide dependency. Live and indoor event behavior remain pending. [Recorder documentation](RECORDER.md)
- The pinned audit covers 5,922 quests and 23 bundled files and now flags 16 items for review. Verified three library quests previously flagged as seasonal. Windows validation passed 55 Python tests, 270 Smart Start assertions, all Lua smoke tests, and the coordinate, label, and frozen-route checks. The three fresh Mage paths reach the level-cap handoff in simulation.
- Packaged OpenXP 1.3.68-beta and OpenXP Recorder 0.1.0-beta from `a78f763`. Both archives passed integrity and layout checks. The 17 changed addon Lua files and the recorder passed Lua 5.1 compilation from the ZIPs. The [fork's Linux checks](https://github.com/Pepsiplaya/OpenXP/actions/runs/43963508238) passed.

### 1.3.69-beta

- Added optional Mirror Lake and Mage-tastic Gizmonitor chapters for the level-10 staff and off-hand rewards. They check for the alternate quest and let the player choose the reward. The Mirror Lake chapter uses the waterfall and flask records. The Ironforge chapter directs Human and Gnome Mages to Bink's Toolbox. Logged the difference between the Skyborne eligibility record and the older introductory quest.
- Added Manaweave Robe for Human and Gnome Mages. The guide tracks the two quest tools, three filled coffers, the Silver Stream Mine approach and gem objectives, and Wynne's final reward. All three additions stay in OpenXP Extras.
- The 5,922-quest audit still has 16 findings and none for these three chapters. Added strict tests for the early weapon alternatives and the robe's objective and hand-in order.
- Windows validation passed 57 Python tests, 270 Smart Start assertions, all Lua suites, and the coordinate, label, and frozen-route checks. Live quest offers, alley and mine navigation, and the ritual sequence remain on the player test list.

### 1.3.70-beta

- A live Gnome Mage reached the Nori pickup before level 4. The game records confirm level 4 and a five-minute timer for Scalding Mornbrew Delivery. The Stolen Journal lists 550 XP at Grelin.
- Reordered the Mage branch to collect the journal, leave the cave, and hand the quest in before starting the timer. A level-4 checkpoint points to verified whelp spawns only when XP is needed. The guide then takes the brew to Durnan and brings the empty mug back to Nori.
- Windows validation passed 58 Python tests, 270 Smart Start checks, all Lua suites, and the map, label, and frozen-route checks. The new test verifies both normal and Hardcore Mage guide order. A Lua simulation verified the level-3 redirect and level-4 advance.

### 1.3.71-beta

- A live screenshot showed only an icon on the active journal step. The installed OpenXP files were 1.3.69-beta and both guide addons were present on disk. Which addon supplied the visible window remains unverified.
- Reproduced the icon-only objective in Lua by supplying an item objective with an empty description. The guide now keeps its own instruction visible until the game provides usable objective text. A missing description without a guide instruction shows a loading message. Progress and completion still use the quest data.
- Put Grik'nir's name and the journal loot instruction directly on The Stolen Journal objective. The quest log regression covers missing and empty rows, later progress, and stale fallback data.
- Windows validation passed the Lua suites, 58 Python tests, 270 Smart Start checks, and the coordinate, label, and frozen-route checks.

### 1.3.72-beta

- A player screenshot showed the Spirit Healer shortcut above Eric's quest pickup, along with a blank hand-in and icon-only objectives. In both modes the Mage route now walks to Kharanos in its own step. For the other normal-mode routes the shortcut clears on arrival.
- Verified the supply bundle delivery, Eric's quest endpoints, and the campfire pin in the Forever data. The guide shows the bundle hand-in if held, the pickup, the campfire, and the return separately. The campfire step waits for quest credit. Record the time to credit during the next live run.
- Windows validation passed 59 Python tests, 270 Smart Start checks, all Lua suites, and the coordinate, label, and frozen-route checks. Compared the line-based saved step IDs after Eric against the prior build. The pinned audit found nothing to review for these three quests and kept the overall total at 16 findings.

### 1.3.73-beta

- A player reached the base of Tundra MacGrann's ridge with the pickup active and needed the climb directions. Forever players identify the wooden platform and banner near 36.3, 52.4. The two approach waypoints already in the guide lead northwest from there toward the NPC.
- Added a trailhead step with a visible landmark and put both approach waypoints on the pickup and hand-in. The trailhead step skips once the quest is in the log or turned in. Check arrow switching and the return climb in the live client.
- Windows validation passed 60 Python tests, 270 Smart Start checks, all Lua suites, and the coordinate, label, and frozen-route checks. The guide keeps the step count and saved step IDs after the hand-in. The pinned audit kept 16 findings across 5,922 quests and recorded none for quest 312.
