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
TARGET_ID = re.compile(r"::(\d+)\b")


def load_evidence():
    path = Path(__file__).with_name("quest_evidence.json")
    return {int(qid): fact for qid, fact in json.loads(path.read_text(encoding="utf-8")).items()}


def quest_npcs(fact, action):
    """Reviewed NPC options for a single pickup or turn-in."""
    npc = fact.get(f"{action}_npc")
    return {npc} if npc else set(fact.get(f"{action}_npcs", ()))


def validate(body, evidence, *, strict=False, faction=None):
    """Yield errors for known quest actions in one guide, in guide order."""
    steps = STEP.split(body)
    opposing = {"Alliance": "Horde", "Horde": "Alliance"}.get(faction)

    def other_faction(tag):
        return opposing and all(opposing in part.split() for part in tag.split("/"))

    header_tag = re.search(r"^<<\s+(.+)$", steps[0], re.M)
    if header_tag and other_faction(header_tag[1]):
        return
    accepted, turned = {}, set()
    minimum, standings = 0, set()
    for number, step in enumerate(steps[1:], 1):
        lines = [line.strip() for line in step.splitlines()]
        tag = step.partition("\n")[0].strip().removeprefix("<<").strip()
        if other_faction(tag):
            continue
        targets = {int(npc) for line in lines if line.startswith(".target ")
                   for npc in TARGET_ID.findall(line.split("--", 1)[0].split("<<", 1)[0])}
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
            if fact.get("tag") and tag != fact["tag"]:
                yield f"{context}: needs step tag {fact['tag']}"
            npcs = quest_npcs(fact, kind)
            if npcs and not targets.intersection(npcs):
                options = ", ".join(map(str, sorted(npcs)))
                yield f"{context}: {kind} needs NPC {options}"
            if kind == "accept":
                # A prior chapter may supply a prerequisite. Require the
                # explicit single-quest gate in that case (multiple IDs are OR).
                external = {int(match[1]) for row in lines if
                            (match := re.fullmatch(r"\.isQuestTurnedIn\s+(\d+)(?:\s*--.*)?", row))}
                if not set(fact.get("requires", ())) <= turned | external:
                    yield f"{context}: prerequisite turn-in missing before pickup"
                if fact.get("level", 0) > minimum:
                    yield f"{context}: minimum level gate missing"
                if fact.get("reputation") and fact["reputation"] not in standings:
                    yield f"{context}: Honored reputation gate missing"
                accepted[qid] = (number, [])
            elif kind == "complete":
                if strict and qid not in accepted:
                    yield f"{context}: objective before pickup"
                interaction = fact.get("interactions", {}).get(index)
                if interaction and (interaction["target_npc"] not in targets
                                    or interaction["required_text"] not in step
                                    or any(row.startswith(".mob ") for row in lines)):
                    yield f"{context}: objective {index} needs {interaction['required_text']} with NPC {interaction['target_npc']}"
                use = fact.get("objective_use", {}).get(index)
                if use and not any(re.match(rf"^\.use {use['item']}\b", row) for row in lines):
                    yield f"{context}: objective {index} needs quest item {use['item']}"
                if qid in accepted:
                    accepted[qid][1].append(int(index) if index else None)
            else:
                if qid in accepted:
                    pickup, progress = accepted.pop(qid)
                    required = fact.get("objectives", ())
                    guarded = fact.get("optional_skill") and any(
                        re.match(rf"^\.isQuestComplete {qid}\b", line) for line in lines)
                    missing = set(required).difference(progress)
                    if missing and not guarded:
                        yield f"{context}: turn-in before objectives {sorted(missing)}"
                    elif fact.get("ordered") and progress != required:
                        yield f"{context}: expected objective order {required}, got {progress}"
                    elif not (required or fact.get("instant") or fact.get("delivery")
                              or (fact.get("wait_for_event") and pickup < number)):
                        yield f"{context}: immediate turn-in needs a verified exception"
                elif strict and not fact.get("delivery"):
                    yield f"{context}: turn-in before pickup"
                turned.add(qid)
    if strict:
        for qid in accepted:
            yield f"quest {qid}: missing turn-in"
