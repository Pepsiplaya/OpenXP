#!/usr/bin/env python3
"""Summarize an OpenXP Recorder session and optionally compare a planner estimate."""
import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path

import savedvars


MAX_FILE_SIZE = 16 * 1024 * 1024
MAX_SAMPLE_GAP_MS = 10_000
STATES = ("combat", "moving", "taxi", "stationary", "afk", "dead", "loading", "unknown")
END_REASONS = ("stopped", "logout", "limit")


def table_array(values, limit):
    if not isinstance(values, dict) or len(values) > limit:
        raise ValueError("Invalid array in recorder data")
    if any(type(index) is not int or not 1 <= index <= len(values) for index in values):
        raise ValueError("Invalid array indices in recorder data")
    return [values[index] for index in range(1, len(values) + 1)]


def load_sessions(path):
    if path.stat().st_size > MAX_FILE_SIZE:
        raise ValueError("Recording exceeds the supported file size")
    try:
        data = savedvars.load(path, only="OpenXPRecorderData").get("OpenXPRecorderData")
    except (AssertionError, IndexError, KeyError, RecursionError, TypeError, ValueError):
        raise ValueError("Invalid Recorder SavedVariables syntax") from None
    if not isinstance(data, dict) or data.get("schema") != 1:
        raise ValueError("Expected Recorder SavedVariables using schema 1")
    return table_array(data.get("sessions"), 4)


def integer(row, field, *, minimum=0, maximum=2**53, optional=False):
    value = row.get(field)
    if optional and value is None:
        return None
    if type(value) not in (int, float) or not minimum <= value <= maximum or value != int(value):
        raise ValueError(f"Invalid {field} in recorder data")
    return int(value)


def level_progress(point):
    level, xp, xp_max = point
    return level + (xp / xp_max if xp_max else 0)


def xp_since(previous, current):
    level, xp, xp_max = previous
    next_level, next_xp, _ = current
    if next_level == level and next_xp >= xp:
        return next_xp - xp
    if next_level == level + 1 and xp_max > 0:
        return xp_max - xp + next_xp
    return None


def summarize(session):
    if not isinstance(session, dict):
        raise ValueError("Invalid recorder session")
    session_id = integer(session, "id", minimum=1)
    elapsed = integer(session, "elapsed_ms")
    rows = table_array(session.get("events"), 8192)
    duration = Counter({state: 0 for state in STATES})
    counts = Counter()
    acceptance = {}
    quest_spans = []
    turnin_ids = []
    by_map = defaultdict(lambda: {"observed_ms": 0, "observed_xp": 0})
    rewarded_xp = xp = xp_gaps = dungeon_ms = grouped_ms = position_samples = map_changes = 0
    previous_sample = previous_point = last_point = first_point = last_map = None
    first_point_at = last_point_at = None
    last_at = 0

    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("Invalid recorder event")
        at = integer(row, "at_ms", minimum=last_at, maximum=elapsed)
        kind = row.get("kind")
        last_at = at
        if kind in ("accept", "turnin"):
            quest_id = integer(row, "quest_id", minimum=1)
            counts[kind] += 1
            if kind == "accept":
                acceptance[quest_id] = at
            else:
                turnin_ids.append(quest_id)
                rewarded_xp += integer(row, "reward_xp", optional=True) or 0
                if quest_id in acceptance:
                    quest_spans.append(at - acceptance.pop(quest_id))
        elif kind == "death":
            counts[kind] += 1
        elif kind == "sample":
            counts[kind] += 1
            state = row.get("state")
            if state not in STATES:
                raise ValueError("Invalid activity in recorder data")
            map_id = integer(row, "map_id", minimum=1, optional=True)
            if map_id is not None:
                if last_map is not None and map_id != last_map:
                    map_changes += 1
                last_map = map_id
                by_map[map_id]  # Include maps observed only once at a boundary.
            x = integer(row, "x", maximum=1000, optional=True)
            y = integer(row, "y", maximum=1000, optional=True)
            position_samples += int(map_id is not None and x is not None and y is not None)

            if previous_sample:
                previous_at, previous_state, previous_map, instance, grouped = previous_sample
                delta = at - previous_at
                if delta <= MAX_SAMPLE_GAP_MS or previous_state == "loading":
                    duration[previous_state] += delta
                    if previous_map is not None:
                        by_map[previous_map]["observed_ms"] += delta
                    if instance == "party":
                        dungeon_ms += delta
                    if grouped:
                        grouped_ms += delta
                else:
                    duration["unknown"] += delta
            else:
                duration["unknown"] += at
            previous_sample = (at, state, map_id, row.get("instance"), row.get("grouped") is True)

            level = integer(row, "level", minimum=1, optional=True)
            current_xp = integer(row, "xp", optional=True)
            needed_xp = integer(row, "xp_max", optional=True)
            if level is not None and current_xp is not None and needed_xp is not None:
                if current_xp > needed_xp:
                    xp_gaps += 1
                    continue
                point = (level, current_xp, needed_xp)
                last_point, last_point_at = point, at
                if not first_point:
                    first_point, first_point_at = point, at
                if previous_point:
                    before, before_map, before_at = previous_point
                    gained = xp_since(before, point)
                    if gained is None:
                        xp_gaps += 1
                        # Retain the high-water mark if the same level's XP momentarily drops.
                        if before[0] == level:
                            continue
                    else:
                        xp += gained
                        if map_id is not None and map_id == before_map and at - before_at <= MAX_SAMPLE_GAP_MS:
                            by_map[map_id]["observed_xp"] += gained
                previous_point = (point, map_id, at)
        else:
            raise ValueError("Unknown event in recorder data")

    duration["unknown"] += elapsed - (previous_sample[0] if previous_sample else 0)
    player_class = session.get("class")
    if not isinstance(player_class, str) or not player_class.isascii() or not player_class.isalpha() or not player_class.isupper():
        player_class = None
    faction = session.get("faction")
    return {
        "status": "RECORDED",
        "session": session_id,
        "build": integer(session, "build", minimum=1, optional=True),
        "class": player_class,
        "faction": faction if faction in ("Alliance", "Horde", "Neutral") else None,
        "end_reason": session.get("end_reason") if session.get("end_reason") in END_REASONS else "interrupted",
        "elapsed_seconds": elapsed / 1000,
        "start_level": round(level_progress(first_point), 4) if first_point else None,
        "start_character_level": first_point[0] if first_point else None,
        "start_xp_in_level": first_point[1] if first_point else None,
        "end_level": round(level_progress(last_point), 4) if last_point else None,
        "xp_gained": xp if first_point else None,
        "xp_observation_gaps": xp_gaps,
        "xp_endpoints_observed": first_point_at == 0 and last_point_at == elapsed,
        "gross_xp_per_hour": round(xp * 3_600_000 / elapsed) if first_point and elapsed else None,
        "quests_accepted": counts["accept"],
        "quests_turned_in": counts["turnin"],
        "turnin_ids": turnin_ids,
        "reported_turnin_xp": rewarded_xp,
        "matched_quest_spans": len(quest_spans),
        "mean_quest_span_seconds": round(sum(quest_spans) / len(quest_spans) / 1000, 1) if quest_spans else None,
        "deaths": counts["death"],
        "map_changes": map_changes,
        "position_samples": position_samples,
        "activity_seconds": {state: round(ms / 1000, 3) for state, ms in duration.items()},
        "party_instance_seconds": dungeon_ms / 1000,
        "grouped_seconds": grouped_ms / 1000,
        "maps": {key: {"sampled_seconds": row["observed_ms"] / 1000,
                       "observed_xp": row["observed_xp"]} for key, row in sorted(by_map.items())},
    }


def comparison(recorded, estimate, *, hub=None, transport="ordinary"):
    if not isinstance(estimate, dict) or estimate.get("status") != "SIMULATED" or estimate.get("game") != "Forever":
        raise ValueError("Expected a simulated Forever route benchmark")
    if estimate.get("faction") not in ("Alliance", "Horde"):
        raise ValueError("Expected an Alliance or Horde route benchmark")

    def number(row, key):
        value = row.get(key) if isinstance(row, dict) else None
        if type(value) not in (int, float) or not 0 <= value <= 2**53:
            raise ValueError(f"Invalid benchmark {key}")
        return value

    expected_class = estimate.get("class")
    expected_turnins = None
    start_xp = None
    if hub is None:
        start, end = number(estimate, "start_level"), number(estimate, "end_level")
        seconds = number(estimate.get("minutes"), "total") * 60
        rate = number(estimate, "estimated_xp_per_hour") if estimate.get("estimated_xp_per_hour") is not None else None
    else:
        visits = estimate.get("visits")
        if estimate.get("class_name") != "Mage" or not isinstance(visits, list):
            raise ValueError("The --hub option requires output from compare_mage_routes.py")
        chosen = next((row for row in visits if isinstance(row, dict) and row.get("hub") == hub), None)
        if chosen is None or f"{transport}_total_minutes" not in chosen:
            raise ValueError("The selected hub and transportation have no estimated duration")
        start = number(estimate.get("checkpoint"), "level")
        start_xp = number(estimate.get("checkpoint"), "xp_in_level")
        end = number(chosen, "end_level")
        seconds = number(chosen, f"{transport}_total_minutes") * 60
        rate_key = f"{transport}_xp_per_hour"
        rate = number(chosen, rate_key) if chosen.get(rate_key) is not None else None
        expected_class = "MAGE"
        expected_turnins = chosen.get("turnin_ids")
        if not isinstance(expected_turnins, list) or any(type(id_) is not int or id_ <= 0 for id_ in expected_turnins):
            raise ValueError("Invalid benchmark turn-in IDs")

    reasons = []
    if recorded["faction"] is None or recorded["faction"] != estimate.get("faction"):
        reasons.append("factions differ or are unavailable")
    if expected_class and recorded["class"] != expected_class:
        reasons.append("class differs from the benchmark")
    recorded_start, recorded_end = recorded["start_level"], recorded["end_level"]
    if start_xp is None:
        starts_alike = recorded_start is not None and abs(recorded_start - start) <= 0.01
    else:
        starts_alike = (recorded["start_character_level"] == start
                        and recorded["start_xp_in_level"] == start_xp)
    if not starts_alike or recorded_end is None or abs(recorded_end - end) > 0.01:
        reasons.append("level ranges differ or are unavailable")
    if expected_turnins is not None and Counter(expected_turnins) != Counter(recorded["turnin_ids"]):
        reasons.append("handed-in quests differ from the modeled visit")
    if (recorded["xp_observation_gaps"] or not recorded["xp_endpoints_observed"]
            or recorded["end_reason"] not in ("stopped", "logout")):
        reasons.append("recording has gaps or ended early")
    return {
        "status": "SIMULATED", "faction": estimate.get("faction"),
        "hub": hub, "transport": transport if hub is not None else None,
        "start_level": start, "start_xp_in_level": start_xp, "end_level": end, "estimated_seconds": seconds,
        "estimated_xp_per_hour": rate, "alignment_notes": reasons,
        "elapsed_minus_estimated_seconds": round(recorded["elapsed_seconds"] - seconds, 1) if not reasons else None,
    }


def print_summary(result):
    def label(value):
        return value if value is not None else "unavailable"

    print(f"Session {result['session']} | {label(result['class'])} | {label(result['faction'])} | "
          f"build {label(result['build'])}")
    print(f"Recorded level {label(result['start_level'])} to {label(result['end_level'])} "
          f"in {result['elapsed_seconds'] / 60:.1f} minutes ({result['end_reason']}).")
    print(f"Observed XP {label(result['xp_gained'])} | gross XP/hour {label(result['gross_xp_per_hour'])} "
          f"| XP observation gaps {result['xp_observation_gaps']}")
    print(f"Quests accepted {result['quests_accepted']} | handed in {result['quests_turned_in']} | "
          f"reported turn-in XP {result['reported_turnin_xp']} | deaths {result['deaths']}")
    print("Sampled minutes | " + " | ".join(f"{state} {seconds / 60:.1f}"
                                             for state, seconds in result["activity_seconds"].items()))
    if "benchmark" in result:
        compared = result["benchmark"]
        visit_name = f"{compared['hub']} ({compared['transport']}) | " if compared["hub"] else ""
        initial_xp = f" plus {compared['start_xp_in_level']} XP" if compared["hub"] else ""
        print(f"Simulated reference | {visit_name}level {compared['start_level']}{initial_xp} to {compared['end_level']} | "
              f"{compared['estimated_seconds'] / 60:.1f} minutes | "
              f"XP/hour {label(compared['estimated_xp_per_hour'])}")
        if compared["alignment_notes"]:
            print("Reference only | " + ", ".join(compared["alignment_notes"]))
        else:
            print(f"Recorded minus estimated minutes {compared['elapsed_minus_estimated_seconds'] / 60:+.1f}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recording", type=Path, help="OpenXPRecorder.lua from SavedVariables")
    parser.add_argument("--session", type=int, help="Select a session ID. The latest is the default.")
    parser.add_argument("--benchmark", type=Path, help="Optional route or Mage visit estimate in JSON")
    parser.add_argument("--hub", help="Visit hub key from compare_mage_routes.py JSON")
    parser.add_argument("--transport", choices=("ordinary", "teleport"), help="Visit transportation estimate")
    parser.add_argument("--json", action="store_true", help="Output the aggregate summary as JSON")
    args = parser.parse_args(argv)
    if (args.hub and not args.benchmark) or (args.transport and not args.hub):
        parser.error("--hub requires --benchmark and --transport requires --hub")
    try:
        sessions = load_sessions(args.recording)
        if args.session is not None:
            sessions = [row for row in sessions if isinstance(row, dict) and row.get("id") == args.session]
        if not sessions:
            raise ValueError("No matching recorder session")
        result = summarize(sessions[-1])
        if args.benchmark:
            if args.benchmark.stat().st_size > MAX_FILE_SIZE:
                raise ValueError("Benchmark exceeds the supported file size")
            with args.benchmark.open(encoding="utf-8") as file:
                result["benchmark"] = comparison(result, json.load(file), hub=args.hub,
                                                 transport=args.transport or "ordinary")
    except OSError as error:
        parser.error(error.strerror or "Could not read the file")
    except (ValueError, RecursionError) as error:
        parser.error(str(error))
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_summary(result)


if __name__ == "__main__":
    main()
