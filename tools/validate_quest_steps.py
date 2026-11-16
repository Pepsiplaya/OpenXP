"""Replay quest actions against independently verified Forever quest requirements.

Coverage is limited to quests with records in quest_evidence.json. Use strict
mode for new, self-contained guides whose every quest has been researched.
"""

import json
import re
from pathlib import Path


GUIDE = re.compile(r"RegisterGuide\(\s*\[\[(.*?)\]\]", re.S)
STEP = re.compile(r"^step\b", re.M)
ACTION = re.compile(r"^\.(accept|complete|turnin)\s+(-?\d+)\b(?:\s*,\s*(\d+))?")


def load_evidence():
    path = Path(__file__).with_name("quest_evidence.json")
    return {int(qid): fact for qid, fact in json.loads(path.read_text(encoding="utf-8")).items()}


def validate(body, evidence, *, strict=False):
    """Yield errors for known quest actions in one guide, in guide order."""
    steps = STEP.split(body)
    accepted, turned = {}, set()
    minimum, standings = 0, set()
    for number, step in enumerate(steps[1:], 1):
        lines = [line.strip() for line in step.splitlines()]
        for line in lines:
            level = re.match(r"^\.xp (\d+)\b", line)
            reputation = re.match(r"^\.reputation (\d+),Honored\s*>>", line)
            if level:
                minimum = max(minimum, int(level[1]))
            if reputation:
                standings.add(int(reputation[1]))
            action = ACTION.match(line)
            if not action:
                continue
            kind, signed, index = action.groups()
            qid = abs(int(signed))
            fact = evidence.get(qid)
            context = f"step {number}, quest {qid}"
            if fact is None:
                if strict:
                    yield f"{context}: missing quest evidence"
                continue
            npc = fact.get(f"{kind}_npc")
            if npc and not any(line.startswith(".target ") and line.endswith(f"::{npc}") for line in lines):
                yield f"{context}: {kind} needs NPC {npc}"
            if kind == "accept":
                if not set(fact.get("requires", ())) <= turned:
                    yield f"{context}: prerequisite turn-in missing before pickup"
                if fact.get("level", 0) > minimum:
                    yield f"{context}: minimum level gate missing"
                if fact.get("reputation") and fact["reputation"] not in standings:
                    yield f"{context}: Honored reputation gate missing"
                accepted[qid] = []
            elif kind == "complete":
                if strict and qid not in accepted:
                    yield f"{context}: objective before pickup"
                if qid in accepted:
                    accepted[qid].append(int(index) if index else None)
            else:
                if qid in accepted:
                    progress = accepted.pop(qid)
                    required = fact.get("objectives", ())
                    guarded = fact.get("optional_skill") and any(
                        re.match(rf"^\.isQuestComplete {qid}\b", line) for line in lines)
                    missing = set(required).difference(progress)
                    if missing and not guarded:
                        yield f"{context}: turn-in before objectives {sorted(missing)}"
                    elif fact.get("ordered") and progress != required:
                        yield f"{context}: expected objective order {required}, got {progress}"
                    elif not (required or fact.get("instant") or fact.get("delivery")):
                        yield f"{context}: immediate turn-in needs a verified exception"
                turned.add(qid)
    if strict:
        for qid in accepted:
            yield f"quest {qid}: missing turn-in"
