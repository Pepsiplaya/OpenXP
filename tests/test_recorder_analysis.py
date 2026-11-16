"""Check XP rollover, sampled activity, and safe Recorder file imports."""
import json
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import analyze_recording as recorder


def sample(at, level, xp, needed, state, map_id=1429, **extra):
    return {"kind": "sample", "at_ms": at, "level": level, "xp": xp, "xp_max": needed,
            "state": state, "map_id": map_id, **extra}


def session(*rows, elapsed=None, end_reason="stopped"):
    return {"id": 1, "class": "MAGE", "faction": "Alliance", "build": 70938,
            "elapsed_ms": rows[-1]["at_ms"] if elapsed is None else elapsed,
            "end_reason": end_reason, "events": dict(enumerate(rows, start=1))}


def benchmark(start, end, faction="Alliance"):
    return {"status": "SIMULATED", "game": "Forever", "faction": faction,
            "start_level": start, "end_level": end, "minutes": {"total": 1.5},
            "estimated_xp_per_hour": 10000}


class RecorderTests(unittest.TestCase):
    def test_rollover_total_and_quest_rewards_are_separate(self):
        result = recorder.summarize(session(
            sample(0, 1, 75, 100, "stationary"),
            {"kind": "accept", "at_ms": 1_000, "quest_id": 25},
            {"kind": "turnin", "at_ms": 6_000, "quest_id": 25, "reward_xp": 50},
            sample(6_000, 2, 25, 200, "moving"),
            sample(10_000, 2, 50, 200, "combat", x=123, y=456),
        ))
        self.assertEqual(result["xp_gained"], 75)
        self.assertEqual(result["reported_turnin_xp"], 50)
        self.assertEqual(result["gross_xp_per_hour"], 27000)
        self.assertEqual(result["maps"][1429], {"sampled_seconds": 10, "observed_xp": 75})
        self.assertEqual(result["position_samples"], 1)
        self.assertEqual(result["mean_quest_span_seconds"], 5)
        self.assertEqual(result["end_level"], 2.25)
        self.assertEqual(result["activity_seconds"]["stationary"], 6)
        self.assertEqual(result["activity_seconds"]["moving"], 4)

    def test_loading_dungeon_and_unobserved_gaps(self):
        result = recorder.summarize(session(
            sample(0, 19, 10, 2000, "moving"),
            {"kind": "sample", "at_ms": 5_000, "state": "loading"},
            sample(30_000, 19, 10, 2000, "combat", map_id=291, instance="party", grouped=True),
            {"kind": "death", "at_ms": 32_000},
            sample(33_000, 19, 10, 2000, "dead", map_id=291, instance="party", grouped=True),
            sample(48_000, 19, 10, 2000, "stationary", map_id=291),
            elapsed=49_000,
        ))
        self.assertEqual(result["map_changes"], 1)
        self.assertEqual(result["deaths"], 1)
        self.assertEqual(result["activity_seconds"]["loading"], 25)
        self.assertEqual(result["activity_seconds"]["unknown"], 16)
        self.assertEqual(result["party_instance_seconds"], 3)
        self.assertEqual(result["grouped_seconds"], 3)
        self.assertEqual(sum(result["activity_seconds"].values()), result["elapsed_seconds"])
        self.assertFalse(result["xp_endpoints_observed"])

    def test_level_jumps_and_transient_resets_report_gaps(self):
        result = recorder.summarize(session(
            sample(0, 1, 70, 100, "stationary"),
            sample(1_000, 1, 10, 100, "stationary"),
            sample(2_000, 1, 80, 100, "stationary"),
            sample(3_000, 3, 20, 300, "stationary"),
            sample(4_000, 3, 35, 300, "stationary"),
        ))
        self.assertEqual(result["xp_gained"], 25)
        self.assertEqual(result["xp_observation_gaps"], 2)

    def test_benchmark_aligns_range_faction_and_complete_measurements(self):
        result = recorder.summarize(session(
            sample(0, 1, 0, 100, "stationary"),
            sample(90_000, 2, 0, 200, "moving"),
        ))
        compared = recorder.comparison(result, benchmark(1, 2))
        self.assertEqual(compared["status"], "SIMULATED")
        self.assertEqual(compared["elapsed_minus_estimated_seconds"], 0)
        mismatched = recorder.comparison(result, benchmark(21, 60, "Horde"))
        self.assertEqual(len(mismatched["alignment_notes"]), 2)
        self.assertIsNone(mismatched["elapsed_minus_estimated_seconds"])
        result["end_reason"] = "limit"
        self.assertIsNone(recorder.comparison(result, benchmark(1, 2))["elapsed_minus_estimated_seconds"])

    def test_mage_visit_checks_starting_xp_and_modeled_quests(self):
        result = recorder.summarize(session(
            sample(0, 21, 200, 1000, "stationary"),
            {"kind": "turnin", "at_ms": 70_000, "quest_id": 100, "reward_xp": 800},
            sample(72_000, 22, 0, 2000, "moving"),
        ))
        row = {"hub": "wetlands", "end_level": 22, "ordinary_total_minutes": 1.5,
               "ordinary_xp_per_hour": 32000, "turnin_ids": [100]}
        model = {"status": "SIMULATED", "game": "Forever", "faction": "Alliance", "class_name": "Mage",
                 "checkpoint": {"level": 21, "xp_in_level": 200}, "visits": [row]}
        compared = recorder.comparison(result, model, hub="wetlands")
        self.assertEqual(compared["elapsed_minus_estimated_seconds"], -18)
        self.assertEqual(compared["transport"], "ordinary")
        row["turnin_ids"] = [101]
        result["start_xp_in_level"] = 100
        compared = recorder.comparison(result, model, hub="wetlands")
        self.assertEqual(len(compared["alignment_notes"]), 2)
        self.assertIsNone(compared["elapsed_minus_estimated_seconds"])
        with self.assertRaisesRegex(ValueError, "no estimated duration"):
            recorder.comparison(result, model, hub="wetlands", transport="teleport")

    def test_literal_wow_file_can_be_read_by_cli(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "OpenXPRecorder.lua"
            path.write_text('''
OpenXPRecorderData = {
    ["schema"] = 1,
    ["sessions"] = {
        {id = 1, class = "MAGE", faction = "Alliance", build = 70938,
         elapsed_ms = 5000, end_reason = "stopped", events = {
            {kind = "sample", at_ms = 0, level = 1, xp = 0, xp_max = 400, state = "moving"},
            {kind = "sample", at_ms = 5000, level = 1, xp = 10, xp_max = 400, state = "moving"},
         }},
    },
}
''', encoding="utf-8")
            output = subprocess.check_output([sys.executable, str(ROOT / "tools" / "analyze_recording.py"),
                                              str(path), "--json"], text=True)
        result = json.loads(output)
        self.assertEqual(result["xp_gained"], 10)
        self.assertEqual(result["activity_seconds"]["moving"], 5)

    def test_executable_lua_is_rejected_without_evaluation(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "OpenXPRecorder.lua"
            path.write_text('OpenXPRecorderData = {value = (function() return 0 end)()}\n', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "SavedVariables syntax"):
                recorder.load_sessions(path)


if __name__ == "__main__":
    unittest.main()
