"""Validate reviewed quest facts and standalone zone quest progression."""

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUIDES = ROOT / "Guides"
sys.path.insert(0, str(ROOT / "tools"))
from validate_quest_steps import GUIDE, STEP, load_evidence, validate


EVIDENCE = load_evidence()
SHENDRALAS = GUIDES / "openxp" / "Extras-Shendralas.lua"
CLASS_QUESTS = GUIDES / "openxp" / "Extras-ClassQuests.lua"


def source(path):
    return path.read_text(encoding="utf-8")


def class_quest(name):
    body, = (body for body in GUIDE.findall(source(CLASS_QUESTS))
             if f"\n#name {name}\n" in body)
    return body


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

    def test_event_quest_needs_its_own_turnin_step(self):
        facts = {999999: {"wait_for_event": "Wait for the ritual."}}
        accept, turnin = "step\n    .accept 999999\n", "    .turnin 999999\n"
        self.assertTrue(list(validate(accept + turnin, facts, strict=True)))
        self.assertFalse(list(validate(accept + "step\n    >>Wait for the ritual.\n" + turnin, facts, strict=True)))

    def test_mage_wand_routes_each_faction_through_both_prerequisites(self):
        manifest = source(GUIDES / "GuideList-forever.xml")
        self.assertIn('file="Guides/openxp/Extras-ClassQuests.lua"', manifest)
        mage = class_quest("Mage's Wand")
        self.assertIn("\n<< Mage\n", mage)
        for faction in ("Alliance", "Horde"):
            self.assertEqual(list(validate(mage, EVIDENCE, strict=True, faction=faction)), [])
        for phase in (".complete 1948,1", ".complete 1948,2", ".complete 1951,1",
                      ".turnin -1948", ".turnin -1951"):
            self.assertLess(mage.index(phase), mage.index(".accept 1952"))
        steps = STEP.split(mage)
        library_index, = (i for i, step in enumerate(steps) if ".complete 1951,1" in step)
        self.assertIn("#completewith next", steps[library_index - 1])
        self.assertIn(".goto Tirisfal Glades,82.60,33.80,35", steps[library_index - 1])
        self.assertNotIn(".goto ", steps[library_index])
        altered = mage.replace("/beckon", "kill the chicken")
        self.assertTrue(any("/beckon with NPC 6626" in error for error in validate(altered, EVIDENCE)))

    def test_horde_warrior_route_reaches_fray_island_before_arena_targets(self):
        horde = class_quest("The Islander and The Affray")
        self.assertIn("\n<< Horde Warrior\n", horde)
        self.assertEqual(list(validate(horde, EVIDENCE, strict=True, faction="Horde")), [])
        self.assertLess(horde.index(".subzone 720"), horde.index(".goto The Barrens,68.62,49.16"))
        self.assertLess(horde.index(".complete 1719,2"), horde.index(".complete 1719,1"))
        self.assertIn(".mob Big Will::6238", horde)

    def test_horde_shaman_summons_and_loots_tempest_before_turnin(self):
        horde = source(GUIDES / "openxp" / "Horde-30-40.lua")
        phase, = (body for body in GUIDE.findall(horde) if ".accept 79366" in body)
        self.assertLess(phase.index(".complete 79366,1"), phase.index(".turnin 79366"))
        self.assertFalse(list(validate(phase, EVIDENCE)))
        no_gate = phase.replace(".isQuestTurnedIn 79361", "")
        self.assertTrue(any("prerequisite" in error for error in validate(no_gate, EVIDENCE)))
        no_use = phase.replace(".use 268582", "")
        self.assertTrue(any("needs quest item 268582" in error for error in validate(no_use, EVIDENCE)))

    def test_tempest_chapter_collects_the_four_totems_before_returning_to_prate(self):
        shaman = class_quest("The Tempest's Weapons (Horde)")
        self.assertEqual(list(validate(shaman, EVIDENCE, strict=True, faction="Horde")), [])
        steps = STEP.split(shaman)
        collection = [(re.search(r"\.goto ([^,]+)", step)[1], int(index)) for step in steps
                      if (index := next(iter(re.findall(r"\.complete 79361,(\d+)", step)), None))]
        self.assertEqual(collection, [("Desolace", 4), ("Dustwallow Marsh", 1),
                                      ("Swamp of Sorrows", 2), ("Badlands", 3)])
        self.assertLess(shaman.index(".turnin 79361"), shaman.index(".accept 79366"))
        self.assertLess(shaman.index(".turnin 79366"), shaman.index(".accept 79442"))

    def test_skyborne_scholar_moves_from_shriekling_den_to_valanaar(self):
        text = source(GUIDES / "forever" / "RestedXP-Skyborne.lua")
        steps = [step for body in GUIDE.findall(text) for step in STEP.split(body)[1:]]
        cave, = (step for step in steps if ".accept 92850" in step)
        valanaar, = (step for step in steps if ".turnin 92850" in step)
        self.assertIn(".goto 2521,52.064,69.396", cave)
        self.assertIn(".target Fillion Flamebreeze::253284", cave)
        self.assertIn(".goto 2521,66.21,79.94", valanaar)
        self.assertIn(".target Fillion Flamebreeze::253285", valanaar)
        self.assertIn(".accept 99260", valanaar)

    def test_verigans_fist_gets_the_two_rewards_before_registering_materials(self):
        paladin = class_quest("Verigan's Fist")
        self.assertIn("\n<< Alliance Paladin\n", paladin)
        self.assertEqual(list(validate(paladin, EVIDENCE, strict=True, faction="Alliance")), [])
        self.assertLess(paladin.index(".accept 1654"), paladin.index(".accept 1655"))
        for reward, index in ((1655, 2), (1442, 4)):
            self.assertLess(paladin.index(f".turnin {reward}"), paladin.index(f".complete 1654,{index}"))
        self.assertLess(paladin.index(".complete 1654,3"), paladin.index(".turnin 1654"))
        misplaced = paladin.replace(".complete 1654,2", "").replace(
            ".accept 1655", ".complete 1654,2\n    .accept 1655")
        self.assertTrue(any("needs the reward from quest 1655" in error for error in validate(misplaced, EVIDENCE)))

    def test_arcane_refreshment_is_a_level_60_mage_chapter(self):
        self.assertEqual(list(validate(class_quest("Arcane Refreshment"), EVIDENCE, strict=True)), [])

    def test_research_access_follows_the_first_library_book_hand_in(self):
        body = class_quest("Research Access")
        self.assertIn("\n<< Alliance Mage\n", body)
        self.assertFalse(list(validate(body, EVIDENCE, strict=True)))
        self.assertLess(body.index(".collect 208860,1,79093"), body.index(".turnin 79093"))
        self.assertLess(body.index(".turnin 79093"), body.index(".accept 97286"))
        self.assertIn(".isQuestTurnedIn 79093", body)

    def test_sleeper_escort_waits_for_the_quest_log_using_the_provided_horn(self):
        text = source(GUIDES / "forever" / "Alliance-11-20.lua")
        self.assertNotIn("Kerlonian's Chest", text)
        self.assertNotRegex(text, r"\.complete 5321,[1-9]")
        self.assertEqual(text.count(".complete 5321,0"), 2)
        for body in GUIDE.findall(text):
            for step in STEP.split(body)[1:]:
                if ".complete 5321,0" in step:
                    self.assertIn(".isOnQuest 5321", step)
                    self.assertIn(".goto 1440/1,128.01,3305.31", step)
                    self.assertIn(".use 13536", step)

    def test_plaguelands_captures_are_optional_for_both_factions(self):
        filename = "Guides/openxp/Extras-Plaguelands.lua"
        self.assertIn(filename, source(GUIDES / "GuideList-forever.xml"))
        alliance, horde = GUIDE.findall(source(ROOT / filename))
        towers = ["Crownguard", "Eastwall", "Northpass", "Plaguewood"]
        for faction, quest, body in (("Alliance", 9664, alliance), ("Horde", 9665, horde)):
            with self.subTest(faction=faction):
                self.assertFalse(list(validate(body, EVIDENCE, strict=True, faction=faction)))
                self.assertIn(f"\n<< {faction}\n", body)
                self.assertNotIn(".mob ", body)
                for index, tower in enumerate(towers, 1):
                    self.assertIn(f".complete {quest},{index} >>Capture {tower} Tower", body)
                shared = source(GUIDES / "openxp" / f"{faction}-50-60.lua")
                self.assertNotRegex(shared, rf"\.(accept|complete|turnin)\s+-?{quest}\b")

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

    def test_skyborne_herbalism_turnin_stays_in_shendar_village(self):
        skyborne = source(GUIDES / "forever" / "RestedXP-Skyborne.lua")
        part_one, part_two = GUIDE.findall(skyborne)[:2]
        for part in (part_one, part_two):
            handoffs = [step for step in re.split(r"(?m)^step\b", part)
                        if re.search(r"(?m)^\s*\.turnin 97968\b", step)]
            self.assertEqual(len(handoffs), 1)
            self.assertIn(".isQuestComplete 97968", handoffs[0])
            self.assertIn(".goto 2521,43.01,43.55", handoffs[0])
            self.assertIn(".target Halassa Fernbreeze::257021", handoffs[0])
            self.assertNotIn("<<", handoffs[0], "both factions use the new turn-in")
        self.assertIn(".subzoneskip 16624,1", handoffs[0])
        self.assertLess(part_two.index(".turnin 97968"), part_two.index(".goto 2521,49.4,58.76"))
