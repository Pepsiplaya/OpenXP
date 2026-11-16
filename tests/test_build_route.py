"""Route builder tests with small deterministic visits."""

import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import build_route as route
import class_steps
from validate_quest_steps import validate


SECTION = {"zone": "Example", "area": 1}
START = (0, 0)


class StraightTerrain(route._Straight):
    kx = ky = 1


def candidate(qid, *, carried=False, finish=None):
    return {
        "q": route.Quest(qid, [f"Quest {qid}", None, None, 20, 20]),
        "start": None if carried else ("npc", "Giver", START),
        "finish": None if finish is None else ("npc", "Finisher", finish),
        "sites": [],
        "carried": carried,
        "obj_later": None if finish is not None else 2,
        "finish_later": None,
    }


def builder(carried=()):
    visit = route.Builder({}, (), carried)
    visit.xp = route.xp_at_level(20)
    return visit


def simulate(visit, candidates, terrain):
    if terrain:
        return visit.simulate_terrain(SECTION, candidates, START, StraightTerrain())
    with patch.dict("os.environ", {"OXP_NO_TERRAIN": "1"}):
        return visit.simulate(SECTION, candidates, START)


class QuestLogTests(unittest.TestCase):
    def test_game_capacity(self):
        self.assertEqual(route.QUEST_LOG_LIMITS, {"Forever": 40, "Classic": 20})

    def test_accepts_up_to_forty_quests_in_both_planners(self):
        for terrain in (False, True):
            with self.subTest(terrain=terrain):
                visit = builder()
                candidates = {qid: candidate(qid) for qid in range(1, 42)}
                actions, _ = simulate(visit, candidates, terrain)
                self.assertEqual(len(actions), 40)
                self.assertEqual(len(visit.accepted_before), 40)

    def test_other_zones_reserve_slots_in_both_planners(self):
        for terrain in (False, True):
            for held in (39, 40):
                with self.subTest(terrain=terrain, held=held):
                    visit = builder(range(100, 100 + held))
                    actions, _ = simulate(visit, {1: candidate(1), 2: candidate(2)}, terrain)
                    self.assertEqual(len(actions), 40 - held)
                    self.assertEqual(len(visit.accepted_before), 40)

    def test_turn_in_frees_a_slot_without_reordering_the_pickup_ahead(self):
        candidates = {1: candidate(1, carried=True, finish=(50, 0)),
                      2: candidate(2, finish=(1, 0))}
        expected = [("turnin", 1, (50, 0)), ("accept", 2, START), ("turnin", 2, (1, 0))]
        for terrain in (False, True):
            with self.subTest(terrain=terrain):
                visit = builder([1, *range(100, 139)])
                visit.rollouts = True
                actions, done = simulate(visit, candidates, terrain)
                self.assertEqual(actions, expected)
                self.assertEqual(done, {1, 2})
                self.assertEqual(visit.accepted_before, set(range(100, 139)))

    def test_classic_limit_is_respected_by_both_planners(self):
        with patch.object(route, "QUEST_LOG_LIMIT", route.QUEST_LOG_LIMITS["Classic"]):
            for terrain in (False, True):
                with self.subTest(terrain=terrain):
                    visit = builder(range(100, 120))
                    actions, _ = simulate(visit, {1: candidate(1)}, terrain)
                    self.assertEqual(actions, [])

    def test_off_zone_carry_does_not_join_local_objectives(self):
        visit = builder({100})
        quest = candidate(1, finish=START)
        quest["sites"] = [(1, "kill", "Target", ["Target"], (10, 0), None)]
        actions, done = simulate(visit, {1: quest}, terrain=True)
        self.assertEqual(actions, [("accept", 1, START), ("obj", (1, 1), (10, 0)), ("turnin", 1, START)])
        self.assertEqual(done, {1})
        self.assertEqual(visit.accepted_before, {100})
        self.assertGreater(visit.travel_minutes, 0)

    def test_draft_replay_rejects_overfilling_the_log(self):
        plan = [{"actions": [("accept", 1, START)]}]
        self.assertEqual(route.replay_quest_log(plan, range(100, 139)), 40)
        with self.assertRaisesRegex(ValueError, "overfill"):
            route.replay_quest_log(plan, range(100, 140))
        plan[0]["actions"] = [("turnin", 1, START)]
        with self.assertRaisesRegex(ValueError, "before pickup"):
            route.replay_quest_log(plan, ())


class BenchmarkTests(unittest.TestCase):
    def test_travel_counts_once_for_committed_hops(self):
        def hub(key, area):
            return {"key": key, "zone": key, "area": area, "continent": "Kalimdor",
                    "start": START, "first": [], "again": []}

        visit = builder()
        visit.known_fps, visit.home = set(), None
        visit.xp = route.xp_at_level(21) - 8000
        config = SimpleNamespace(FIRST="First", HUBS=[hub("First", 1), hub("Second", 2)])

        def candidates(section, *_args, **_kwargs):
            first = section["area"] * 10
            return {qid: candidate(qid, finish=START) for qid in range(first, first + 4)
                    if qid not in visit.done}

        with (patch.object(visit, "candidates", candidates),
              patch.object(route, "MAX_LEVEL", 21),
              patch.object(route, "DECISIONS", []),
              patch.object(route.travel_graph, "Network", return_value=SimpleNamespace(pos={})),
              patch.dict("os.environ", {"OXP_NO_TERRAIN": "1"})):
            plan, _ = route.plan_hubs(visit, config)

        self.assertEqual(len(plan), 2)
        self.assertEqual(visit.travel_minutes, route.MINUTES_HOP)
        self.assertAlmostEqual(visit.minutes, route.MINUTES_HOP + 16 * route.MINUTES_TALK)
        self.assertEqual(visit.grind_minutes, 0)

    def test_last_grind_is_written_as_a_guide_step(self):
        visit = builder()
        visit.known_fps, visit.home = set(), None
        hub = {"key": "First", "zone": "First", "area": 1, "continent": "Kalimdor",
               "start": START, "first": [], "again": []}
        config = SimpleNamespace(FIRST="First", HUBS=[hub])
        quest = candidate(1, finish=START)

        with (patch.object(visit, "candidates", return_value={1: quest}),
              patch.object(route, "MAX_LEVEL", 21),
              patch.object(route, "DECISIONS", []),
              patch.object(route.travel_graph, "Network", return_value=SimpleNamespace(pos={})),
              patch.dict("os.environ", {"OXP_NO_TERRAIN": "1"})):
            plan, _ = route.plan_hubs(visit, config)
            self.assertEqual(visit.level(), 21)

        self.assertGreater(visit.grind_minutes, 0)
        self.assertEqual(plan[-1]["end"], 21)
        section = route.render_section(visit, plan[-1]["section"], {}, [], "Test", None)
        self.assertIn(".xp 21 >>Kill level-appropriate mobs", section)


class ClassObjectiveTests(unittest.TestCase):
    def test_quest_item_from_dungeon_object_uses_entrance_and_keeps_objective(self):
        quest = route.Quest(1951, {1: "Rituals of Power", 10: {3: [[7274]]}})
        db = {"n": {}, "o": {103664: {1: "Rituals of Power", 4: {796: [[-1, -1]]}}},
              "i": {7274: {1: "Rituals of Power", 3: [103664]}}}
        site, = class_steps.objectives(db, quest)
        self.assertEqual((site[0], site[3:]), (1, ([], 85, (82.6, 33.8), True)))
        text = class_steps.render_obj("step << Mage", quest, *site)
        self.assertIn(".goto Tirisfal Glades,82.60,33.80", text)
        self.assertIn("inside Scarlet Monastery", text)
        self.assertIn(".complete 1951,1", text)
        self.assertNotIn(".mob", text)

        # Keep a real outdoor source when the same item also drops there.
        db["o"][2] = {1: "Outdoor book", 4: {17: [[23, 45]]}}
        db["i"][7274][3].append(2)
        site, = class_steps.objectives(db, quest)
        self.assertEqual(site[1:], ("loot", "Rituals of Power", [], 17, (23, 45), False))

    def test_direct_dungeon_object_uses_entrance(self):
        quest = route.Quest(3, {1: "Read a Plaque", 10: {2: [[4]]}})
        db = {"n": {}, "o": {4: {1: "Plaque", 4: {719: [[-1, -1]]}}}, "i": {}}
        site, = class_steps.objectives(db, quest)
        self.assertEqual(site[:2], (1, "do"))
        self.assertIn("Blackfathom Deeps", site[2])
        self.assertTrue(site[-1])

    def test_follow_reviewed_plucky_interaction_in_class_preview(self):
        quest = route.Quest(1950, {1: "Get the Scoop", 10: [[[6626, None, 3]]]})
        db = {"n": {6626: {1: '"Plucky" Johnson', 7: {400: [[79.61, 75.63]]}}}, "o": {}, "i": {}}
        site, = class_steps.objectives(db, quest)
        self.assertEqual(site[:2], (1, "interact"))
        text = class_steps.render_obj("step << Mage", quest, *site)
        self.assertIn("/beckon", text)
        self.assertIn('.target "Plucky" Johnson::6626', text)
        self.assertNotIn(".mob ", text)
        self.assertIsNone(route.Builder(db, (), ()).objective_sites(quest, 400))

    def test_affray_exploration_precedes_the_kill(self):
        quest = route.Quest(1719, {
            1: "The Affray", 9: ["Step on the grate", {17: [[68.60, 48.72]]}],
            10: [[[123, "Big Will"]]],
        })
        db = {"n": {123: {1: "Big Will", 7: {17: [[68.61, 48.72]]}}}, "o": {}, "i": {}}
        sites = class_steps.objectives(db, quest)
        self.assertEqual([(index, kind) for index, kind, *_ in sites], [(2, "explore"), (1, "kill")])

    def test_preview_keeps_reviewed_race_restriction_at_shared_npc(self):
        visit = route.Builder({"n": {376: ["Laurena"], 258785: ["Mims"]}}, (), ())
        both = {
            1: candidate(1, finish=START),
            94819: candidate(94819, finish=(1, 0)),
        }
        both[1]["q"].classes = route.CLASS_BITS["Priest"]
        both[1]["start"] = ("npc", 376, START)
        both[94819]["start"] = ("npc", 376, START)
        both[94819]["finish"] = ("npc", 258785, (1, 0))
        actions = [("accept", 1, START), ("accept", 94819, START), ("turnin", 94819, (1, 0))]
        zone = {"zone": "Ironforge", "name": "20-21 Ironforge"}
        text = route.render_section(visit, zone, both, actions, "Test", None)
        self.assertIn("step << Priest\n    .goto Ironforge,0.00,0.00\n    >>Talk", text)
        self.assertEqual(text.count("step << Gnome Priest"), 2)
        self.assertIn(".turnin 94819 >>Turn in Contingency Plan\n    .target Mims::258785", text)
        self.assertEqual(list(validate(text, route.FOREVER_QUEST_EVIDENCE)), [])


class QuestDataTests(unittest.TestCase):
    def test_sparse_objective_tuples_keep_their_lua_indices(self):
        db = {"q": {}, "n": {123: {1: "Target", 7: {17: [[12, 34]]}}}, "o": {}, "i": {}}
        quest = route.Quest(1, {1: "Example", 10: [[{1: 123, 3: 2}]]})
        visit = route.Builder(db, (), ())
        sites = visit.objective_sites(quest, 17)
        self.assertEqual([(s[0], s[2], s[4]) for s in sites], [(1, "Target", (12, 34))])
        sites = class_steps.objectives(db, quest)
        self.assertEqual([(s[0], s[2], s[5]) for s in sites], [(1, "Target", (12, 34))])

    def test_load_raw_and_inline_questie_tables(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            raw = root / "data" / "Forever"
            raw.mkdir(parents=True)
            inline = root / "preview"
            inline.mkdir()
            for kind in ("quest", "npc", "object", "item"):
                filename = f"forever{kind.capitalize()}DB.lua"
                (raw / filename).write_text(f'QuestieDB.{kind}Data = [[\n[1] = {{"Raw",nil,1}},\n]]\n',
                                            encoding="utf-8")
                (inline / filename).write_text(f'local {kind} = {{}}\n{kind}[1]={{"Merged",nil,2}}\nreturn {kind}\n',
                                               encoding="utf-8")
            self.assertEqual(route.load_db(root)["q"][1], ["Raw", None, 1])
            self.assertEqual(route.load_db(inline)["q"][1], ["Merged", None, 2])

            # The merged source can change after a rebuild at the same path.
            (inline / "foreverQuestDB.lua").write_text('quest[1]={"Corrected"}\n', encoding="utf-8")
            self.assertEqual(route.load_db(inline)["q"][1], ["Corrected"])
