#!/usr/bin/env python3
"""Compare Alliance Mage hub visits from one checkpoint with the Forever planner."""

import argparse
import json
import math
from pathlib import Path

import build_route as route


# Forever character masks. Quest 94947 uses the Alliance Skyborne bit alone.
RACE_MASKS = {"Human": 1, "Gnome": 64, "Skyborne": 1 << 32}
# Spell ID -> Alliance hub key, required level. Each spell casts for 10 seconds
# and consumes one Rune of Teleportation. See docs/MAGE_ROUTE_COMPARISON.md.
TELEPORTS = {3561: ("stormwind", 20), 3562: ("ironforge", 20), 3565: ("darnassus", 30)}
TELEPORT_CAST_SECONDS = 10


def mage_quest(quest, race):
    tag = quest.evidence.get("tag")
    tokens = {"Alliance", "Mage", race}
    return (
        (not quest.races or quest.races & RACE_MASKS[race])
        and (not quest.classes or quest.classes & route.CLASS_BITS["Mage"])
        and (not tag or any(set(part.split()) <= tokens for part in tag.split("/")))
    )


def nonnegative(data, key, default, *, integer=False):
    value = data.get(key, default)
    if (type(value) not in (int, float) or (integer and type(value) is not int)
            or not math.isfinite(value) or value < 0):
        unit = "integer" if integer else "number"
        raise ValueError(f"{key} must be a nonnegative {unit}")
    return value


def id_set(data, key):
    values = data.get(key, [])
    if not isinstance(values, list) or any(type(value) is not int or value <= 0 for value in values):
        raise ValueError(f"{key} must be a list of positive numeric IDs")
    return set(values)


def read_checkpoint(data, hubs, network):
    if not isinstance(data, dict):
        raise ValueError("checkpoint must be an object")
    race, hub = data.get("race"), data.get("hub")
    if race not in tuple(RACE_MASKS) or hub not in tuple(hubs):
        raise ValueError("checkpoint requires a supported Alliance Mage race and hub key")
    level = nonnegative(data, "level", 0, integer=True)
    if not 21 <= level < route.MAX_LEVEL:
        raise ValueError("the Alliance hub planner covers levels 21 through 59")
    xp = nonnegative(data, "xp_in_level", 0, integer=True)
    if xp >= route.XP_TO_NEXT[level]:
        raise ValueError("xp_in_level must be below the planner's XP for the level")
    active = id_set(data, "active_quests")
    completed = id_set(data, "completed_quests")
    ready = id_set(data, "ready_quests")
    if ready - active or active & completed or len(active) > route.QUEST_LOG_LIMITS["Forever"]:
        raise ValueError("ready quests must be active, and active quests must fit the log and be unfinished")
    flight_paths = data.get("known_flight_paths", [])
    if not isinstance(flight_paths, list) or any(
            not isinstance(town, str) or town not in network.towns for town in flight_paths):
        raise ValueError("known_flight_paths must list Alliance towns named in the OpenXP flight network")
    hearth = data.get("ready_hearthstone")
    if hearth is not None and hearth not in tuple(network.pos):
        raise ValueError("ready_hearthstone must name a town with a known network position")
    spells = id_set(data, "learned_teleports")
    if spells - TELEPORTS.keys():
        raise ValueError("learned_teleports must contain only Stormwind, Ironforge or Darnassus Teleport IDs")
    runes = nonnegative(data, "teleport_runes", 0, integer=True)
    overhead = data.get("teleport_overhead_seconds")
    if overhead is not None:
        overhead = nonnegative(data, "teleport_overhead_seconds", 0)
    return dict(race=race, hub=hub, level=level, xp_in_level=xp,
                active_quests=active, completed_quests=completed, ready_quests=ready,
                known_flight_paths=set(flight_paths), ready_hearthstone=hearth,
                learned_teleports=spells, teleport_runes=runes, teleport_overhead_seconds=overhead)


def shortest_leg(network, starts, destination, known, level, method):
    """Only score trips for which the shared travel graph has a route."""
    town = route.fp_town(destination["town"])
    first = town not in known
    stops = route.hub_anchors(destination, first)
    best = None
    for departure, departure_minutes in starts:
        for arrival, arrival_minutes in stops:
            minutes, legs = network.route(departure, arrival, known, level)
            if minutes is None:
                continue
            total = departure_minutes + minutes + arrival_minutes
            if destination.get("city"):
                total += route.MINUTES_CITY_INSIDE
            if best is None or best["minutes"] > total:
                best = dict(method=method, from_town=departure, to_town=arrival,
                            minutes=total, legs=legs)
    return best


def travel_options(network, hubs, checkpoint, destination):
    from_hub = hubs[checkpoint["hub"]]
    if from_hub["key"] == destination["key"]:
        return {"method": "stay", "minutes": 0.0, "legs": []}, None
    known, level = checkpoint["known_flight_paths"], checkpoint["level"]
    regular = shortest_leg(network, route.hub_anchors(from_hub), destination, known, level, "network")
    home = checkpoint["ready_hearthstone"]
    if home is not None:
        hearth = shortest_leg(network, [(home, route.MINUTES_HEARTH)], destination, known, level, "hearthstone")
        if hearth and (regular is None or hearth["minutes"] < regular["minutes"]):
            regular = hearth
    teleport = None
    if checkpoint["teleport_runes"]:
        for spell in sorted(checkpoint["learned_teleports"]):
            capital, minimum = TELEPORTS[spell]
            if level < minimum:
                continue
            starts = [(town, walk + TELEPORT_CAST_SECONDS / 60) for town, walk in route.hub_anchors(hubs[capital])]
            candidate = shortest_leg(network, starts, destination, known, level, "teleport")
            if candidate and (teleport is None or candidate["minutes"] < teleport["minutes"]):
                teleport = dict(candidate, spell_id=spell, capital=capital)
    return regular, teleport


def visit(builder, hub, checkpoint):
    saved = builder.snapshot()
    before_xp, before_minutes, before_travel = builder.xp, builder.minutes, builder.travel_minutes
    before_quest_xp, before_mob_xp = builder.xp_from["quests"], builder.xp_from["kills"]
    section = dict(hub, until=checkpoint["level"] + 1)
    candidates = builder.candidates(section, carry_ahead=0)
    actions, turned = builder.simulate(section, candidates, section["start"])
    peak = route.replay_quest_log([{"actions": actions}], checkpoint["active_quests"])
    result = dict(hub=hub["key"], zone=hub["zone"], turnins=len(turned),
                  turnin_ids=[ref for kind, ref, _ in actions if kind == "turnin"],
                  peak_quests_held=peak, end_level=round(builder.level(), 3),
                  reaches_next_level=builder.level() >= checkpoint["level"] + 1,
                  xp=round(builder.xp - before_xp),
                  quest_xp=round(builder.xp_from["quests"] - before_quest_xp),
                  mob_xp=round(builder.xp_from["kills"] - before_mob_xp),
                  minutes_in_hub=round(builder.minutes - before_minutes, 3),
                  minutes_walking_in_hub=round(builder.travel_minutes - before_travel, 3))
    builder.restore(saved)
    return result


def score(row, regular, teleport, overhead):
    if regular:
        row["ordinary_travel"] = regular
        total = row["minutes_in_hub"] + regular["minutes"]
        row["ordinary_total_minutes"] = round(total, 3)
        if total and row["xp"]:
            row["ordinary_xp_per_hour"] = round(row["xp"] * 60 / total)
    if teleport:
        row["teleport_travel"] = teleport
        if regular:
            row["teleport_break_even_overhead_seconds"] = round((regular["minutes"] - teleport["minutes"]) * 60, 1)
        if overhead is not None:
            total = row["minutes_in_hub"] + teleport["minutes"] + overhead / 60
            row["teleport_total_minutes"] = round(total, 3)
            if total and row["xp"]:
                row["teleport_xp_per_hour"] = round(row["xp"] * 60 / total)
    return row


def compare(db, hubs, destinations, network, checkpoint, skip=()):
    builder = route.Builder(db, checkpoint["completed_quests"], checkpoint["active_quests"],
                            quest_allowed=lambda quest: mage_quest(quest, checkpoint["race"]))
    builder.xp = route.xp_at_level(checkpoint["level"]) + checkpoint["xp_in_level"]
    builder.carried_ready.update(checkpoint["ready_quests"])
    builder.used.update(skip)
    results = []
    for key in destinations:
        hub = hubs[key]
        ordinary, teleport = travel_options(network, hubs, checkpoint, hub)
        row = visit(builder, hub, checkpoint)
        results.append(score(row, ordinary, teleport, checkpoint["teleport_overhead_seconds"]))
    local = next((row for row in results if row["hub"] == checkpoint["hub"]), None)
    if local and local["xp"] and local["minutes_in_hub"]:
        local_rate = local["xp"] / local["minutes_in_hub"]
        for row in results:
            if row.get("teleport_travel") and row["xp"]:
                budget = row["xp"] / local_rate - row["minutes_in_hub"] - row["teleport_travel"]["minutes"]
                row["teleport_vs_stay_overhead_seconds"] = round(60 * budget, 1)
    return sorted(results, key=lambda row: (-max(row.get("ordinary_xp_per_hour", 0),
                                                 row.get("teleport_xp_per_hour", 0)), row["hub"]))


def main():
    alliance = route.load_route(str(Path(__file__).parent / "routes" / "alliance.py"))
    hubs = {hub["key"]: hub for hub in alliance.HUBS}
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questiedb", required=True, help="QuestieDB checkout or merged Forever export")
    parser.add_argument("--checkpoint", type=Path, required=True, help="local character state JSON")
    parser.add_argument("--hub", action="append", choices=sorted(hubs), help="candidate hub key, repeatable")
    parser.add_argument("--out", type=Path, help="write JSON to this file")
    args = parser.parse_args()

    network = route.travel_graph.Network("Alliance")
    try:
        checkpoint = read_checkpoint(json.loads(args.checkpoint.read_text(encoding="utf-8-sig")), hubs, network)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    db = route.load_db(args.questiedb, "Forever")
    destinations = list(dict.fromkeys([checkpoint["hub"], *(args.hub or hubs)]))
    result = dict(status="SIMULATED", game="Forever", faction="Alliance", class_name="Mage",
                  quest_rows=len(db["q"]),
                  quest_db_source="merged_export" if route.inline_export(args.questiedb, "Forever") else "raw_tables",
                  teleport_cast_seconds=TELEPORT_CAST_SECONDS,
                  checkpoint={key: sorted(value) if isinstance(value, set) else value
                              for key, value in checkpoint.items()},
                  visits=compare(db, hubs, destinations, network, checkpoint, alliance.SKIP))
    payload = json.dumps(result, indent=2) + "\n"
    if args.out:
        args.out.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")


if __name__ == "__main__":
    main()
