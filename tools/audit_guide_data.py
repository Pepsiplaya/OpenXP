"""Compare loaded Forever guide steps with a local QuestieDB export.

The report identifies records for review. QuestieDB can omit objectives and
carry forward old metadata, so discrepancies don't imply a guide is wrong.
"""

import argparse
import json
import re
from pathlib import Path
from xml.etree import ElementTree

import build_route as route
from validate_quest_steps import ACTION, GUIDE, STEP, TARGET_ID, load_evidence, quest_npcs


ROOT = Path(__file__).resolve().parents[1]
GUIDE_NAME = re.compile(r"^#name\s+([^\n]+)", re.M)


def bundled_guides(root):
    manifest = ElementTree.parse(root / "Guides" / "GuideList-forever.xml")
    return [root / script.attrib["file"] for script in manifest.findall("{*}Script")]


def excluded(line):
    """True when every alternative explicitly requires SoD or 'skip'."""
    _, marker, tags = line.split("--", 1)[0].partition("<<")
    return bool(marker) and all(
        {"sod", "skip"}.intersection(clause.lower().split())
        for clause in tags.split("/")
    )


def guide_actions(text):
    for match in GUIDE.finditer(text):
        header, *steps = STEP.split(match[1])
        match_name = GUIDE_NAME.search(header)
        name = match_name[1].split("<<", 1)[0].strip() if match_name else ""
        if any(excluded(line) for line in header.splitlines() if line.startswith("<<")):
            continue
        line_number = text.count("\n", 0, match.start(1)) + 1 + header.count("\n")
        for step in steps:
            lines = step.splitlines()
            if lines and not excluded(lines[0]):
                targets = {
                    int(npc) for line in lines if line.lstrip().startswith(".target ") and not excluded(line)
                    for npc in TARGET_ID.findall(line.split("--", 1)[0].split("<<", 1)[0])
                }
                for offset, line in enumerate(lines):
                    action = ACTION.match(line.strip())
                    if action and not excluded(line):
                        kind, quest, index = action.groups()
                        yield (name, line_number + offset, kind, abs(int(quest)),
                               int(index) if kind == "complete" and index else None, targets)
            line_number += step.count("\n")


def objective_count(row):
    """Count represented objectives, without treating counts as client indices."""
    objectives = route.li(row, 10)
    lists = sum(len(route.as_list(route.li(objectives, slot))) for slot in (1, 2, 3, 5, 6))
    return lists + bool(route.li(objectives, 4)) + bool(route.li(row, 9))


def endpoint(row, kind):
    return route.li(row, 2 if kind == "accept" else 3)


def review_record(qid, row, fact, npc_ids):
    count = objective_count(row)
    required = [i for i in fact.get("objectives", ()) if i is not None]
    if required and max(required) > count:
        yield "reviewed_objectives_missing", f"Reviewed objective {max(required)} exceeds the {count} represented in the export."
    if fact.get("optional_skill") and route.li(route.li(row, 10), 1):
        yield "skill_record_needs_review", "Reviewed skill objective appears as a creature objective in the export."
    level = route.li(row, 4)
    if fact.get("level") and level != fact["level"]:
        yield "level_discrepancy", f"Export minimum {level} differs from the guide gate of {fact['level']}."
    group = set(route.as_list(route.li(row, 12)))
    alternatives = route.as_list(route.li(row, 13))
    if len(alternatives) == 1:
        group.add(alternatives[0])
    missing = set(fact.get("requires", ())) - group
    if missing:
        yield "reviewed_prerequisites_missing", f"Export lacks required prerequisites {sorted(missing)}."
    for kind in ("accept", "turnin"):
        expected = quest_npcs(fact, kind)
        missing = expected.difference(route.as_list(route.li(endpoint(row, kind), 1)))
        if missing:
            yield "reviewed_endpoint_discrepancy", f"Export omits reviewed {kind} NPCs {sorted(missing)}."
        missing = expected.difference(npc_ids)
        if missing:
            yield "reviewed_npc_missing", f"Export has no NPC records for reviewed {kind} NPCs {sorted(missing)}."
    for kind in ("accept", "turnin"):
        if not endpoint(row, kind):
            yield "endpoint_unrecorded", f"Export does not record a {kind} source."
    if route.season_of_discovery(qid, route.li(row, 1)):
        yield "seasonal_review", "The Forever planner's legacy seasonal filter flags this record."


def audit(db, guides, evidence, quests=()):
    """Return source and step discrepancies with stable locations and codes."""
    findings, references = [], {}
    selected = set(quests)
    for path, text in guides:
        for guide, line, kind, qid, index, targets in guide_actions(text):
            if selected and qid not in selected:
                continue
            ref = {"quest": qid, "file": path, "guide": guide, "line": line}
            references.setdefault(qid, ref)
            row = db["q"].get(qid)
            if row is None:
                continue
            fact = evidence.get(qid, {})
            if kind != "complete":
                finish = endpoint(row, kind)
                npcs = quest_npcs(fact, kind) or set(route.as_list(route.li(finish, 1)))
                other_source = route.li(finish, 2) or route.li(finish, 3)
                if len(targets) == 1 and npcs and not other_source and not targets.intersection(npcs):
                    findings.append(dict(ref, code="step_target_discrepancy", detail=
                        f"Step targets {next(iter(targets))}. Recorded {kind} NPCs are {sorted(npcs)}."))
            elif fact.get("objectives"):
                if index is not None and index not in fact["objectives"]:
                    findings.append(dict(ref, code="reviewed_index_discrepancy", detail=
                        f"Step uses objective {index}. Reviewed indices are {fact['objectives']}."))
            else:
                count = objective_count(row)
                if count == 0 or (index is not None and index > count):
                    findings.append(dict(ref, code="objective_unconfirmed", detail=
                        f"Export represents {count} objectives for this completion step."))

    for qid in sorted(references.keys() | selected):
        ref = references.get(qid, {"quest": qid})
        row = db["q"].get(qid)
        fact = evidence.get(qid, {})
        if row is None:
            findings.append(dict(ref, code="quest_unrecorded", detail="Export has no quest record."))
        else:
            findings.extend(dict(ref, code=code, detail=detail)
                            for code, detail in review_record(qid, row, fact, db["n"]))
    for finding in findings:
        url = evidence.get(finding["quest"], {}).get("source")
        if url:
            finding["reviewed_source"] = url
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questiedb", required=True, help="QuestieDB checkout or merged Forever export")
    parser.add_argument("--guide", type=Path, action="append", help="Guide file to check, repeatable")
    parser.add_argument("--quest", type=int, action="append", default=[], help="Quest ID to check, repeatable")
    parser.add_argument("--out", type=Path, help="Write a JSON audit report")
    args = parser.parse_args()

    paths = args.guide if args.guide else bundled_guides(ROOT)
    files = [(path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path.name,
              path.read_text(encoding="utf-8")) for path in (p.resolve() for p in paths)]
    db = route.load_db(args.questiedb, "Forever")
    findings = audit(db, files, load_evidence(), args.quest)
    result = {
        "game": "Forever",
        "input": "merged_export" if route.inline_export(args.questiedb, "Forever") else "raw_tables",
        "quest_records": len(db["q"]),
        "guide_files": len(files),
        "findings": findings,
    }
    output = json.dumps(result, indent=2) + "\n"
    if args.out:
        args.out.write_text(output, encoding="utf-8")
        print(f"{len(findings)} findings for review in {args.out}")
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
