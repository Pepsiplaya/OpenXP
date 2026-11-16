# OpenXP Ultimate development

- Read `docs/WORKLOG.md` and `docs/NEXT_ACTIONS.md` before picking a task. Check `upstream/main` for new fixes. Commit verified changes locally on the development branch. Preserve the upstream remote and keep release tags local unless publication is explicitly requested.
- Keep OpenXP free under CC BY-NC-SA 4.0 and retain the notices. Use original guide instructions and independently checked game facts. Read external quest databases in place. Keep their bundled data, paid guides, and personal SavedVariables out of the repo and release.
- Use `docs/RESEARCH_SOURCES.md` to record source URLs, review dates, client builds, and the limits of the evidence. Use `VERIFIED BY GAME DATA`, `VERIFIED BY PLAYER TESTING`, `SIMULATED`, or `UNVERIFIED` for findings.
- Prefer targeted repairs to the shared routes. Review every `#next` change and update `tests/route_frozen.json` deliberately after inspecting shared guide changes. Keep ability and class quest steps scoped to the correct class and race.
- Install `lupa` and run `python -u tests/run_tests.py` before packaging. Build from a committed ref using `python tools/package.py <output-directory>`. Use a distinct test version and leave installed addons and player settings alone.
- Keep routes and timings eligible for player validation. Preserve exact quest IDs, objective indices, reputation thresholds, and waypoint provenance. Record player feedback with only the data needed to reproduce it.
