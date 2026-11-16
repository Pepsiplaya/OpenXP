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


class MageRouteTests(unittest.TestCase):
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
