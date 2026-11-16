"""Route builder tests with small deterministic visits."""

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import build_route as route
import class_steps


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

    def test_classic_limit_is_respected_by_both_planners(self):
        with patch.object(route, "QUEST_LOG_LIMIT", route.QUEST_LOG_LIMITS["Classic"]):
            for terrain in (False, True):
                with self.subTest(terrain=terrain):
                    visit = builder(range(100, 120))
                    actions, _ = simulate(visit, {1: candidate(1)}, terrain)
                    self.assertEqual(actions, [])


class ClassObjectiveTests(unittest.TestCase):
    def test_affray_exploration_precedes_the_kill(self):
        quest = route.Quest(1719, {
            1: "The Affray", 9: ["Step on the grate", {17: [[68.60, 48.72]]}],
            10: [[[123, "Big Will"]]],
        })
        db = {"n": {123: {1: "Big Will", 7: {17: [[68.61, 48.72]]}}}, "o": {}, "i": {}}
        sites = class_steps.objectives(db, quest)
        self.assertEqual([(index, kind) for index, kind, *_ in sites], [(2, "explore"), (1, "kill")])
