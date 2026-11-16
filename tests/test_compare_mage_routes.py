"""Validate the Mage comparison against small independent checkpoints."""

import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import build_route as route
from compare_mage_routes import compare, mage_quest, read_checkpoint, score, travel_options


def hub(key, area):
    return dict(key=key, area=area, zone=key, town=key, has_fp=True, start=(30.0, 40.0))


class Network:
    towns = {"local", "remote", "stormwind", "ironforge", "darnassus"}
    pos = dict.fromkeys(towns, (0, 0.0, 0.0))

    def route(self, start, end, known, level):
        if start == end:
            return 0, []
        if start not in known or end not in known:
            return None, None
        return (3 if start == "stormwind" else 15), [("fly", start, end)]


HUBS = {key: hub(key, i) for i, key in enumerate(sorted(Network.towns), 1)}
CHECKPOINT = dict(race="Human", hub="local", level=21, learned_teleports=[3561, 3565],
                  known_flight_paths=["local", "remote", "stormwind", "darnassus"], teleport_runes=1)


class MageComparisonTests(unittest.TestCase):
    def test_quest_eligibility_checks_mage_and_alliance_skyborne(self):
        welcome = route.Quest(94947, {1: "Welcome to Azeroth", 6: 1 << 32})
        self.assertTrue(mage_quest(welcome, "Skyborne"))
        self.assertFalse(mage_quest(welcome, "Gnome"))
        cont = route.Quest(94819, {1: "Contingency Plan"})
        self.assertFalse(mage_quest(cont, "Gnome"))
        rogue = route.Quest(15, {1: "Class quest", 7: route.CLASS_BITS["Rogue"]})
        self.assertFalse(mage_quest(rogue, "Human"))

    def test_checkpoint_validates_quest_state_and_transport(self):
        for changes in (
            {"active_quests": [1], "completed_quests": [1]},
            {"ready_quests": [1]},
            {"active_quests": list(range(1, 42))},
            {"teleport_runes": True},
            {"teleport_overhead_seconds": float("nan")},
            {"known_flight_paths": ["unknown"]},
        ):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                read_checkpoint(dict(CHECKPOINT, **changes), HUBS, Network())

    def test_only_eligible_teleports_are_offered(self):
        checkpoint = read_checkpoint(CHECKPOINT, HUBS, Network())
        ordinary, teleport = travel_options(Network(), HUBS, checkpoint, HUBS["remote"])
        self.assertEqual(ordinary["minutes"], 15)
        self.assertEqual(teleport["spell_id"], 3561)
        self.assertAlmostEqual(teleport["minutes"], 3 + 10 / 60)
        for changes in ({"teleport_runes": 0}, {"learned_teleports": {3565}},
                        {"known_flight_paths": {"local", "remote"}}):
            moved = dict(checkpoint, **changes)
            _, teleport = travel_options(Network(), HUBS, moved, HUBS["remote"])
            self.assertIsNone(teleport)

    def test_score_leaves_missing_overhead_explicit(self):
        regular, teleport = {"minutes": 5.0}, {"minutes": 2.0}
        row = {"xp": 1500, "minutes_in_hub": 10.0}
        result = score(dict(row), regular, teleport, None)
        self.assertEqual(result["teleport_break_even_overhead_seconds"], 180.0)
        self.assertNotIn("teleport_total_minutes", result)
        measured = score(dict(row), regular, teleport, 180)
        self.assertEqual(measured["ordinary_xp_per_hour"], measured["teleport_xp_per_hour"])

    def test_earlier_comparison_never_unlocks_quests_in_another_candidate(self):
        checkpoint = read_checkpoint(CHECKPOINT, HUBS, Network())
        db = {"q": {
            101: {1: "Local task", 2: [[1]], 3: [[1]], 4: 21, 5: 21},
            102: {1: "Follow-up", 2: [[2]], 3: [[2]], 4: 21, 5: 21, 12: [101]},
        }, "n": {
            1: {1: "Local NPC", 7: {HUBS["local"]["area"]: [(30, 40)]}},
            2: {1: "Remote NPC", 7: {HUBS["remote"]["area"]: [(30, 40)]}},
        }, "i": {}, "o": {}}
        with patch.dict(os.environ, {"OXP_NO_TERRAIN": "1"}):
            first = compare(db, HUBS, ["local", "remote"], Network(), checkpoint)
            second = compare(db, HUBS, ["remote", "local"], Network(), checkpoint)
            db["q"][102].pop(12)
            independent = compare(db, HUBS, ["local", "remote"], Network(), checkpoint)
        self.assertEqual(first, second)
        self.assertEqual(first[0]["turnin_ids"], [101])
        self.assertEqual(first[1]["turnin_ids"], [])
        self.assertEqual(independent[1]["teleport_vs_stay_overhead_seconds"], -190.0)
