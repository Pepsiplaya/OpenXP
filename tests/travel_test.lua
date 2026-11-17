-- Getting to another zone (Travel.lua): flight paths you know, boats, the
-- tram, your Hearthstone and walking through zone borders.
local ROOT = ...
unpack = unpack or table.unpack
bit = bit or require("bit")

-- A made-up world: every zone is a 1000 x 1000 yard block. HereBeDragons
-- world x, y = block corner + zone x, y (0-1) * 1000.
local BLOCKS = {
    -- Eastern Kingdoms
    [1437] = {1, 0, 0}, [1432] = {2, 1, 0}, [1426] = {1, 1, 0}, [1455] = {0, 1, 0},
    [1453] = {-1, 2, 0}, [1429] = {0, 2, 0}, [1431] = {0, 3, 0}, [1436] = {-1, 3, 0},
    [1433] = {1, 3, 0}, [1434] = {0, 4, 0},
    -- Kalimdor
    [1439] = {0, 0, 1}, [1440] = {0, 1, 1}, [1442] = {-1, 1, 1}, [1438] = {0, -1, 1},
}
local function ZoneToWorld(x, y, map)
    local b = BLOCKS[map]
    if not b then return end
    return b[1] * 1000 + x * 1000, b[2] * 1000 + y * 1000, b[3]
end

local player = {x = 0, y = 0, inst = 0, map = 1431}
local function at(map, x, y)
    player.map = map
    player.x, player.y, player.inst = ZoneToWorld(x / 100, y / 100, map)
end

local now = 0
GetTime = function() now = now + 5; return now end
UnitLevel = function() return 25 end
UnitFactionGroup = function() return "Alliance" end
UnitOnTaxi = function() return false end
local hearth = {count = 0, cd = 0, bind = nil}
GetItemCount = function() return hearth.count end
GetItemCooldown = function() return hearth.cd, hearth.cd > 0 and 3600 or 0 end
GetBindLocation = function() return hearth.bind end
C_Map = {GetMapInfo = function(m)
    local names = {[1442] = "Stonetalon Mountains", [1437] = "Wetlands", [1455] = "Ironforge", [1440] = "Ashenvale"}
    return names[m] and {name = names[m]}
end}
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
OXPCData = {flightPaths = {}}

local HBD = {
    GetPlayerWorldPosition = function() return player.x, player.y, player.inst end,
    GetPlayerZonePosition = function()
        local b = BLOCKS[player.map]
        return (player.x - b[1] * 1000) / 1000, (player.y - b[2] * 1000) / 1000, player.map
    end,
    GetWorldCoordinatesFromZone = function(_, x, y, map)
        if map == 1414 then return 0, 0, 1 end
        if map == 1415 then return 0, 0, 0 end
        return ZoneToWorld(x, y, map)
    end,
    GetZoneCoordinatesFromWorld = function(_, wx, wy, map)
        if map == 1414 or map == 1415 then return wx / 5000 + 0.3, wy / 6000 + 0.2 end
        local b = BLOCKS[map]
        if not b then return end
        return (wx - b[1] * 1000) / 1000, (wy - b[2] * 1000) / 1000
    end,
}
LibStub = function() return HBD end

local addon = {locale = {Get = function(s) return s end}, settings = {profile = {}}}

-- Flight masters: taxiPos is stored in UnitPosition order (y, x)
local function Fp(map, x, y)
    local wx, wy, inst = ZoneToWorld(x / 100, y / 100, map)
    return {wx = wy, wy = wx, flag = 3}, inst
end
local FPS = {
    [12] = {"Darkshire, Duskwood", 1431, 77.5, 44.3},
    [2] = {"Stormwind, Elwynn", 1453, 66.3, 62.1},
    [6] = {"Ironforge, Dun Morogh", 1455, 55.5, 47.8},
    [7] = {"Menethil Harbor, Wetlands", 1437, 9.5, 59.7},
    [26] = {"Auberdine, Darkshore", 1439, 36.3, 45.6},
    [28] = {"Astranaar, Ashenvale", 1440, 34.4, 48.0},
    [80] = {"Far Camp, Darkshore", 1439, 92.0, 45.6}, -- same-zone fixture
}
addon.taxiPos = {[0] = {}, [1] = {}}
addon.FPDB = {Alliance = {}}
for id, f in pairs(FPS) do
    local t, inst = Fp(f[2], f[3], f[4])
    addon.taxiPos[inst][id] = t
    addon.FPDB.Alliance[id] = {name = f[1]}
end
local function Flight(a, b, secs) addon.FPDB.Alliance[a][b] = secs; addon.FPDB.Alliance[b][a] = secs end
Flight(12, 7, 300); Flight(12, 2, 120); Flight(2, 6, 180); Flight(6, 7, 150); Flight(26, 28, 150)
Flight(26, 80, 40)

assert(loadfile(ROOT .. "/DB/travel.lua"))("OpenXP", addon)
assert(loadfile(ROOT .. "/Travel.lua"))("OpenXP", addon)
local tv = addon.travel

local fails = 0
local function try(label, fn)
    tv.Reset()
    OXPCData = {flightPaths = {}}
    hearth.count, hearth.cd, hearth.bind = 0, 0, nil
    now = now + 100
    local ok, err = pcall(fn)
    if ok then print("ok   " .. label) else fails = fails + 1; print("FAIL " .. label .. ": " .. tostring(err)) end
end
local function know(...) for _, id in ipairs({...}) do OXPCData.flightPaths[id] = true end end
local function target(map, x, y, title)
    local wx, wy, inst = ZoneToWorld(x / 100, y / 100, map)
    return {wx = wx, wy = wy, instance = inst, zone = map, title = title or "Talk to someone", step = {}}
end
local function texts(plan)
    local out = {}
    for _, l in ipairs(plan and plan.legs or {}) do out[#out + 1] = l.text end
    return table.concat(out, " | ")
end

local albagorm = target(1442, 37.1, 8.1, "Talk to Keeper Albagorm")

try("Duskwood to Stonetalon: fly, boat, fly, then the Talondeep Path", function()
    -- Forever: Stormwind Harbor has a boat to Auberdine, and Menethil's boat
    -- goes round by Southshore first, so Stormwind's boat is the way
    know(12, 2, 7, 26, 28)
    at(1431, 77.0, 44.0) -- by the Darkshire flight master
    local plan = tv.PlanFor(albagorm)
    local s = texts(plan)
    assert(s:find("Fly to Stormwind", 1, true), s)
    assert(s:find("Take the boat to Auberdine", 1, true), s)
    assert(not s:find("Menethil", 1, true), s)
    assert(s:find("Fly to Astranaar", 1, true), s)
    assert(s:find("Talondeep Path", 1, true), s)
    -- the arrow: the flight master you're standing by, saying where to fly
    local a = tv.ArrowTarget(albagorm)
    assert(a and a.travel and a.title == "Fly to Stormwind", a and a.title)
    assert(a.instance == 0)
    -- and the card lists the legs in order
    local lines = tv.Lines()
    assert(lines[1] == "Fly to Stormwind", lines[1])
end)

try("flight paths you haven't learned aren't used", function()
    know(12, 26, 28) -- no Menethil
    at(1431, 77.0, 44.0)
    local s = texts(tv.PlanFor(albagorm))
    assert(not s:find("Fly to Menethil", 1, true), s)
    assert(s:find("Take the boat to Auberdine", 1, true), s)
end)

try("Stormwind to Ironforge: the Deeprun Tram", function()
    at(1453, 60.0, 40.0)
    local plan = tv.PlanFor(target(1455, 30.0, 60.0))
    local s = texts(plan)
    assert(s:find("Go to the Deeprun Tram", 1, true), s)
    assert(s:find("Take the Deeprun Tram to Ironforge", 1, true), s)
end)

try("Ironforge to the Wetlands on foot: through Dun Morogh, Loch Modan and Dun Algaz", function()
    at(1455, 30.0, 60.0)
    local s = texts(tv.PlanFor(target(1437, 10.0, 60.0)))
    assert(s:find("Dun Algaz", 1, true), s)
end)

try("your Hearthstone when it's ready and takes you closer", function()
    know(26, 28)
    hearth.count, hearth.bind = 1, "Astranaar"
    at(1431, 50.0, 50.0)
    local s = texts(tv.PlanFor(albagorm))
    assert(s:find("Use your Hearthstone (to Astranaar)", 1, true), s)
    hearth.cd = 100 -- on cooldown
    tv.Reset(); now = now + 100
    s = texts(tv.PlanFor(albagorm))
    assert(not s:find("Hearthstone", 1, true), s)
end)

try("same zone: nothing to plan, the arrow goes straight", function()
    at(1442, 70.0, 40.0)
    assert(tv.PlanFor(albagorm) == nil)
    assert(tv.ArrowTarget(albagorm) == nil)
end)

local farCamp = target(1439, 96, 45.6)
try("compares the walks at both ends of a flight in the same zone", function()
    know(26, 80)
    at(1439, 32, 45.6)
    local plan = tv.PlanFor(farCamp)
    assert(plan and #plan.legs == 3, texts(plan))
    assert(plan.legs[1].text == "Go to the Auberdine flight master", texts(plan))
    assert(plan.legs[2].text == "Fly to Far Camp", texts(plan))
    assert(plan.legs[3].text == "Walk the rest of the way", texts(plan))
    assert(plan.seconds > 60, "includes walking to and from the masters")
    addon.arrowFrame = {element = farCamp}
    local estimate = OpenXPGetTravelEstimate()
    assert(estimate.mode == "fly" and estimate.seconds == plan.seconds and estimate.flight_to == 80)
    addon.arrowFrame = nil

    at(1439, 80, 45.6)
    assert(tv.PlanFor(farCamp) == nil and tv.estimate.mode == "walk", "walking wins from closer to the target")
end)

try("learned nodes without a verified flight time do not create a shortcut", function()
    know(26, 80)
    Flight(26, 80, nil)
    at(1439, 36.3, 45.6)
    local plan = tv.PlanFor(farCamp)
    Flight(26, 80, 40)
    assert(plan == nil and tv.estimate.mode == "walk")
end)

try("world map discovery preserves saved nodes and skips locked or hostile stops", function()
    know(12)
    Enum = {FlightPathFaction = {Neutral = 0, Horde = 1, Alliance = 2}}
    C_TaxiMap = {GetTaxiNodesForMap = function(map)
        if map == 1439 then
            return {
                {nodeID = 26, name = "Auberdine", faction = 2, isUndiscovered = false},
                {nodeID = 80, name = "Far Camp", faction = 2, isUndiscovered = true},
                {nodeID = 999, name = "Enemy camp", faction = 1, isUndiscovered = false},
            }
        end
    end}
    tv.SyncFlightPaths()
    C_TaxiMap, Enum = nil, nil
    assert(OXPCData.flightPaths[12] and OXPCData.flightPaths[26] == "Auberdine")
    assert(not OXPCData.flightPaths[80] and not OXPCData.flightPaths[999])
end)

try("boards only the recommended reachable flight from the right master", function()
    know(26, 80)
    at(1439, 32, 45.6)
    local plan = assert(tv.PlanFor(farCamp))
    local taken, shift, reachable
    TakeTaxiNode = function(slot) taken = slot end
    IsShiftKeyDown = function() return shift end
    TaxiNodeGetType = function() return reachable and "REACHABLE" or "DISTANT" end
    addon.settings.profile.enableFPAutomation = true
    addon.arrowFrame = {element = farCamp}
    local slots = {[80] = 3}
    tv.TakeRecommendedFlight({currentFP = 28, slots = slots}, plan)
    assert(not taken)
    local map = {currentFP = 26, slots = slots}
    tv.TakeRecommendedFlight(map, plan)
    assert(not taken)
    reachable, shift = true, true
    tv.TakeRecommendedFlight(map, plan)
    assert(not taken)
    shift = false
    addon.RXPFrame = {activeSteps = {{elements = {{tag = "fly"}}}}}
    tv.TakeRecommendedFlight(map, plan)
    assert(not taken, "authored flights retain their handler")
    addon.RXPFrame = nil
    tv.TakeRecommendedFlight(map, plan)
    assert(taken == 3, "selected the live slot for the planned flight")
    taken = nil
    tv.TakeRecommendedFlight(map, plan)
    assert(not taken, "send a planned flight only once")
    addon.settings.profile.enableFPAutomation = nil
    addon.arrowFrame, TakeTaxiNode, IsShiftKeyDown, TaxiNodeGetType = nil, nil, nil, nil
end)

try("opening the live flight map saves its nodes and selects the planned slot", function()
    know(26, 80)
    at(1439, 36.3, 45.6)
    addon.arrowFrame = {element = farCamp}
    addon.settings.profile.enableFPAutomation = true
    assert(tv.PlanFor(farCamp))
    local taken
    GetTaxiMapID = function() return 1414 end
    TaxiNodePosition = function(slot) return slot / 10, 0.5 end
    TaxiNodeGetType = function() return "REACHABLE" end
    TakeTaxiNode = function(slot) taken = slot end
    Enum = {FlightPathState = {Current = 0, Reachable = 1, Unreachable = 2}}
    C_TaxiMap = {GetAllTaxiNodes = function(map)
        assert(map == 1414, "use the flight map ID")
        return {
            {nodeID = 26, state = 0, slotIndex = 1, name = "Auberdine"},
            {nodeID = 80, state = 1, slotIndex = 5, name = "Far Camp"},
            {nodeID = 28, state = 2, slotIndex = 6, name = "Astranaar"},
            {nodeID = 900, state = 1, slotIndex = 7, isMapLayerTransition = true, name = "Other map"},
        }
    end}
    local noop = function() end
    table.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    CreateFrame = function() return {ClearAllPoints = noop, SetPoint = noop} end
    hooksecurefunc = noop
    addon.RXPFrame = {}
    assert(loadfile(ROOT .. "/Timers.lua"))("OpenXP", addon)
    addon:TAXIMAP_OPENED("TAXIMAP_OPENED")
    assert(taken == 5 and OXPCData.flightPaths[80] == "Far Camp")
    assert(not OXPCData.flightPaths[28] and not OXPCData.flightPaths[900])
    assert(addon.flightInfo.reachable[28] == false and tv.plan.boarding.to.fp == 80)
    addon.settings.profile.enableFPAutomation = nil
    addon.RXPFrame, addon.arrowFrame, addon.flightInfo = nil, nil, nil
    TakeTaxiNode, TaxiNodePosition, TaxiNodeGetType, GetTaxiMapID, C_TaxiMap, Enum = nil, nil, nil, nil, nil, nil
end)

try("the setting turns it off", function()
    know(12, 7, 26, 28)
    at(1431, 77.0, 44.0)
    addon.settings.profile.openxpTravel = false
    local a = tv.ArrowTarget(albagorm)
    addon.settings.profile.openxpTravel = nil
    assert(a == nil)
end)

try("route line: on the continent map, from you to the step", function()
    know(12, 7, 26, 28)
    at(1431, 77.0, 44.0)
    tv.PlanFor(albagorm)
    local ek, kal = tv.Polylines(1415, 20), tv.Polylines(1414, 20)
    assert(ek and #ek >= 1, "the flight and the walk to the dock in the Eastern Kingdoms")
    assert(kal and #kal >= 2, "the rest in Kalimdor")
    for _, l in ipairs(kal) do assert(#l >= 2) end
end)

try("route line: a walk in another zone follows that zone's terrain", function()
    know(12, 7, 26, 28)
    at(1431, 77.0, 44.0)
    tv.PlanFor(albagorm)
    local asked = {}
    addon.terrain = {FindPath = function(map, ax, ay, bx, by)
        asked[map] = true
        return {{(ax + bx) / 2 + 3, (ay + by) / 2}, {bx, by}}
    end}
    local kal = tv.Polylines(1414, 20)
    addon.terrain = nil
    assert(asked[1442], "the walk through Stonetalon is worked out on Stonetalon's map")
    assert(kal and #kal >= 2)
end)

if fails > 0 then print(fails .. " failed") end
return fails
