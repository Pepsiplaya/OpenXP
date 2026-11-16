"""Validate the external guide-data audit without requiring third-party files."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from audit_guide_data import audit, guide_actions, objective_count


def guide(body):
    return 'RXPGuides.RegisterGuide([[\n#name Example\n' + body + '\n]])'


class GuideDataAuditTests(unittest.TestCase):
    def test_reader_keeps_line_numbers_and_filters_inactive_actions(self):
        text = guide(
            "step << SoD Mage/skip\n"
            "    .accept 1\n"
            "step << !SoD\n"
            "    -- .turnin 2\n"
            "    .accept 2 << SoD\n"
            "    .accept 3 << SoD/Mage\n"
            "    .turnin -4,2\n"
            "    .target Guide NPC::10\n"
            "    .target Unavailable NPC::11 << SoD\n"
            "step\n"
            "    .complete 5,2"
        )
        steps = list(guide_actions(text))
        self.assertEqual(steps, [
            ("Example", 8, "accept", 3, None, {10}),
            ("Example", 9, "turnin", 4, None, {10}),
            ("Example", 13, "complete", 5, 2, set()),
        ])

    def test_objective_count_uses_sparse_slots_and_single_reputation_requirement(self):
        row = {9: ["Explore"], 10: {1: [[3], [4]], 4: [10, 200], 6: [[8]]}, 29: [[1], [2]]}
        self.assertEqual(objective_count(row), 5)

    def test_reviewed_objectives_and_endpoints_take_precedence_in_the_guide(self):
        db = {"q": {10: {1: "Example", 2: [[11]], 3: [[12]], 4: 30, 13: [3, 4]}},
              "n": {11: [], 12: [], 13: []}}
        facts = {10: {"objectives": [1], "turnin_npc": 13, "requires": [3, 4], "level": 35,
                      "source": "https://example.com/game-data"}}
        src = guide("step\n    .accept 10\nstep\n    .complete 10,1\n"
                    "step\n    .turnin 10\n    .target Corrected NPC::13")
        report = audit(db, [("Guide.lua", src)], facts)
        self.assertEqual({row["code"] for row in report}, {
            "reviewed_objectives_missing", "reviewed_endpoint_discrepancy",
            "level_discrepancy", "reviewed_prerequisites_missing",
        })
        self.assertTrue(all(row["line"] == 4 and row["reviewed_source"] == facts[10]["source"]
                            for row in report))

    def test_reports_missing_quests_and_unconfirmed_objective_indices(self):
        db = {"q": {76001: {1: "Old event", 2: [[1]], 3: [[2]], 10: {2: [[31]]}}}, "n": {}}
        src = guide("step\n    .complete 76001,2\n    .accept 9\n    .turnin 9")
        result = audit(db, [("Guide.lua", src)], {})
        self.assertEqual([row["code"] for row in result],
                         ["objective_unconfirmed", "quest_unrecorded", "seasonal_review"])
        self.assertEqual(audit(db, [], {}, quests=[9]),
                         [{"quest": 9, "code": "quest_unrecorded", "detail": "Export has no quest record."}])

    def test_endpoint_mismatch_with_single_target_and_npc_only_source(self):
        db = {"q": {10: {2: [[11]], 3: [[12]]}}, "n": {}}
        src = guide("step\n    .accept 10\n    .target Other NPC::13")
        report = audit(db, [("Guide.lua", src)], {})
        self.assertEqual([row["code"] for row in report], ["step_target_discrepancy"])
        db["q"][10][2] = [[11], [21]]
        self.assertEqual(audit(db, [("Guide.lua", src)], {}), [])
