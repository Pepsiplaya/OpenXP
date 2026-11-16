"""Validate reviewed quest facts and standalone zone quest progression."""

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUIDES = ROOT / "Guides"
sys.path.insert(0, str(ROOT / "tools"))
from validate_quest_steps import GUIDE, load_evidence, validate


EVIDENCE = load_evidence()
SHENDRALAS = GUIDES / "openxp" / "Extras-Shendralas.lua"


def source(path):
    return path.read_text(encoding="utf-8")


class QuestEvidenceTests(unittest.TestCase):
    def test_finish_requires_an_objective_after_pickup(self):
        body = "step\n    .accept 92743\n    .turnin 92743\n"
        self.assertEqual(list(validate(body, EVIDENCE)),
                         ["step 1, quest 92743: turn-in before objectives [1]"])
        body = "step\n    .complete 92743,1\n" + body
        self.assertTrue(list(validate(body, EVIDENCE)))

    def test_instant_turnin_needs_verified_exception(self):
        body = "step\n    .accept 999999\n    .turnin 999999\n"
        fact = {"source": "unit test"}
        self.assertTrue(list(validate(body, {999999: fact}, strict=True)))
        self.assertFalse(list(validate(body, {999999: {**fact, "instant": True}}, strict=True)))

    def test_reviewed_quests_in_bundled_guides(self):
        files = [*GUIDES.glob("forever/*.lua"), *GUIDES.glob("openxp/*.lua")]
        for path in files:
            for body in GUIDE.findall(source(path)):
                name = re.search(r"^#name (.*)$", body, re.M)
                with self.subTest(file=path.name, guide=name[1] if name else "?"):
                    self.assertEqual(list(validate(body, EVIDENCE)), [])

    def test_valley_of_bones_has_two_standalone_branches(self):
        manifest = source(GUIDES / "GuideList-forever.xml")
        self.assertIn('file="Guides/openxp/Extras-Shendralas.lua"', manifest)
        magram, gelkis = GUIDE.findall(source(SHENDRALAS))
        for body, handoff, quests, position in (
            (magram, 92841, [92844, 92846], (35.71, 12.66)),
            (gelkis, 93034, [93035, 93037], (20.93, 22.68)),
        ):
            with self.subTest(handoff=handoff):
                self.assertEqual(list(validate(body, EVIDENCE, strict=True)), [])
                self.assertEqual(set(map(int, re.findall(r"\.accept (\d+)\b", body))), set(quests))
                self.assertIn(f".isOnQuest {handoff}\n", body)
                self.assertIn(f".turnin {handoff} ", body)
                self.assertIn(f".isQuestTurnedIn {handoff}\n", body)
                self.assertIn(f".goto 2652,{position[0]:.2f},{position[1]:.2f}", body)
                for qid in quests:
                    self.assertRegex(body, rf"(?m)^\s*\.isOnQuest {qid}\s*$")
                    self.assertIn(f".turnin -{qid} ", body)
                points = re.findall(r"\.goto (\d+),([\d.]+),([\d.]+)", body)
                self.assertEqual(len(points), 5)
                self.assertTrue(all(m == "2652" and 0 < float(x) < 100 and 0 < float(y) < 100
                                    for m, x, y in points))

    def test_shared_route_bypasses_the_optional_clans(self):
        for path in GUIDES.glob("openxp/*-??-??.lua"):
            self.assertNotRegex(source(path), r"\.(accept|turnin)\s+-?(92743|92841|92844|92846|93034|93035|93037)\b")
        alliance_start = source(GUIDES / "openxp" / "Alliance-30-40.lua")
        alliance_next = source(GUIDES / "openxp" / "Alliance-40-50.lua")
        self.assertIn("#name 39-40 Desolace\n#next 40-41 Ironforge\n", alliance_start)
        self.assertIn("#name 40-41 Ironforge\n", alliance_next)
