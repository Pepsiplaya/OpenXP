"""Check fresh level-one Alliance Mage handoffs at the default XP rate."""

import re
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from validate_quest_steps import GUIDE, STEP

GROUP = "RestedXP Forever Guide (A)"
END = "59-60 Stormwind City"


def applies(tag, player):
    return not tag.strip() or any(
        all((token[1:] not in player) if token.startswith("!") else (token in player)
            for token in option.split())
        for option in tag.split("/")
    )


def mage_chapters(race):
    player = {"Alliance", "Mage", race}
    loaded = {}
    manifest = ET.parse(ROOT / "Guides" / "GuideList-forever.xml")
    for script in manifest.findall("{*}Script"):
        for body in GUIDE.findall((ROOT / script.attrib["file"]).read_text(encoding="utf-8")):
            header = STEP.split(body, maxsplit=1)[0]
            if any(not applies(line[2:], player) for line in header.splitlines() if line.startswith("<<")):
                continue
            fields = {}
            for line in header.splitlines():
                value, _, tag = line.partition("<<")
                key, _, content = value.strip().partition(" ")
                if key.startswith("#") and applies(tag, player):
                    fields[key] = content
            if fields.get("#group") == GROUP and "#internal" not in fields:
                # The Gnome side chapters use this header gate.
                if fields.get("#xprate") in (None, "<1.5"):
                    name = fields["#name"]
                    if name in loaded:
                        raise AssertionError(f"duplicate chapter {name}")
                    loaded[name] = (fields.get("#next"), body)
    return loaded


def playable_steps(body, player, hardcore):
    excluded = "#softcore" if hardcore else "#hardcore"
    for step in STEP.split(body)[1:]:
        header, _, content = step.partition("\n")
        if not applies(header.partition("<<")[2], player):
            continue
        lines = []
        for row in content.splitlines():
            value, _, tag = row.partition("<<")
            if applies(tag, player):
                lines.append(value.strip())
        if excluded not in lines:
            yield lines


class MageRouteTests(unittest.TestCase):
    def step_for(self, active, command):
        matches = [i for i, step in enumerate(active)
                   if any(line.startswith(command) for line in step)]
        self.assertEqual(len(matches), 1, command)
        return matches[0]

    def test_gnome_mage_hands_in_the_journal_before_the_level_four_delivery(self):
        _, body = mage_chapters("Gnome")["1-5 Coldridge Valley"]
        player = {"Alliance", "Mage", "Gnome"}
        for hardcore in (False, True):
            with self.subTest(hardcore=hardcore):
                active = list(playable_steps(body, player, hardcore))
                cave = self.step_for(active, ".complete 218,1 ")
                journal = self.step_for(active, ".turnin 218 ")
                level = self.step_for(active, ".xp 4 ")
                brew = self.step_for(active, ".accept 3364 ")
                delivery = self.step_for(active, ".turnin 3364 ")
                mug = self.step_for(active, ".turnin 3365 ")
                self.assertEqual([cave, journal, level, brew, delivery, mug],
                                 sorted({cave, journal, level, brew, delivery, mug}))
                self.assertIn(".mob Frostmane Troll Whelp::706", active[level])
                self.assertIn(".isQuestTurnedIn 218", active[brew])
                self.assertIn(".xp <4,1,ColdridgeMornbrewLevel", active[brew])
                self.assertTrue(any(line.startswith(".accept 3365 ") for line in active[delivery]))
                self.assertFalse(any(line.startswith(".deathskip ")
                                     for step in active[cave:brew] for line in step))

    def test_gnome_mage_walks_to_kharanos_and_finishes_the_campfire_quest(self):
        _, body = mage_chapters("Gnome")["5-11 Dun Morogh"]
        player = {"Alliance", "Mage", "Gnome"}
        for hardcore in (False, True):
            with self.subTest(hardcore=hardcore):
                active = list(playable_steps(body, player, hardcore))
                bundle = self.step_for(active, ".turnin -96628 ")
                road = self.step_for(active[:bundle], ".subzone 131 ")
                offer = self.step_for(active, ".accept 96608 ")
                campfire = self.step_for(active, ".complete 96608,0 ")
                handoff = self.step_for(active, ".turnin 96608 ")
                self.assertEqual([road, bundle, offer, campfire, handoff],
                                 sorted({road, bundle, offer, campfire, handoff}))
                self.assertIn(".goto Dun Morogh,46.68,53.84", active[campfire])
                self.assertIn(".isOnQuest 96608", active[campfire])
                self.assertRegex("\n".join(active[campfire]), r"\.complete 96608,0 >>.*?/sit.*Boosted Rest")
                self.assertEqual(handoff, self.step_for(active, ".accept 96629 "))
                self.assertFalse(any(line.startswith(".deathskip ")
                                     for step in active[:handoff] for line in step))

        active = list(playable_steps(body, {"Alliance", "Warrior", "Dwarf"}, hardcore=False))
        offer = self.step_for(active, ".accept 96608 ")
        shortcut = self.step_for(active[:offer], ".deathskip ")
        self.assertIn(".subzoneskip 131", active[shortcut])

    def test_fresh_starters_reach_the_shared_level_cap_chapter(self):
        starts = {
            "Human": ("1-6 Northshire", "6-11 Elwynn Forest", "11-13 Loch Modan"),
            "Gnome": ("1-5 Coldridge Valley", "5-11 Dun Morogh", "11-12 Elwynn (Dwarf/Gnome)",
                      "12-14 Loch Modan (Dwarf/Gnome)"),
            "Skyborne": ("1-9 Zephras Isle", "9-13 Zephras Isle"),
        }
        for race, start in starts.items():
            with self.subTest(race=race):
                chapters = mage_chapters(race)
                path, current = [], start[0]
                while current:
                    self.assertNotIn(current, path, "guide handoff cycles")
                    path.append(current)
                    link, _ = chapters[current]
                    current = None
                    if link:
                        for candidate in link.split(";"):
                            group, _, name = candidate.strip().rpartition("\\")
                            if group in ("", GROUP) and name in chapters:
                                current = name
                                break
                        self.assertIsNotNone(current, f"{path[-1]} has no playable successor: {link}")
                self.assertEqual(tuple(path[:len(start)]), start)
                self.assertEqual(path[len(start)], "13-15 Westfall")
                self.assertIn("21-22 Ashenvale", path)
                self.assertEqual(path[-1], END)
                self.assertRegex(chapters[END][1], r"step << Mage\n\s*\.xp 60\b")

    def test_skyborne_trainer_steps_pair_the_two_npcs_with_the_right_pins(self):
        path = ROOT / "Guides" / "forever" / "RestedXP-Skyborne.lua"
        checked = set()
        for body in GUIDE.findall(path.read_text(encoding="utf-8")):
            for step in STEP.split(body)[1:]:
                if not re.match(r" << (Alliance )?Mage\n", step):
                    continue
                for pin, trainer in ((r"45\.1[0]?,45\.8[67]", "Shenaan Spellwind::254086"),
                                     (r"41\.55,23\.67", "Dorii Brightwhisper::251379")):
                    if re.search(rf"\.goto 2521,{pin}\b", step) and (".train" in step or ".target" in step):
                        self.assertIn(f".target {trainer}", step)
                        checked.add(trainer)
        self.assertEqual(len(checked), 2)
