local root = ...
local frames, callbacks, messages = {}, {}, {}
local time, level, xp, xpMax, map = 0, 1, 75, 100, 1429
local moving, combat, dead, grouped, party = false, false, false, false, false
local positionReads = 0
local secret = {}

function CreateFrame()
    local frame = {events = {}}
    function frame:SetScript(name, fn) self[name] = fn end
    function frame:RegisterEvent(name) self.events[name] = true end
    function frame:UnregisterAllEvents() self.events = {} end
    frames[#frames + 1] = frame
    return frame
end

local timer
C_Timer = {
    After = function(_, callback) callbacks[#callbacks + 1] = callback end,
    NewTicker = function(seconds, callback)
        assert(seconds == 5)
        timer = {tick = callback, Cancel = function(self) self.cancelled = true end}
        return timer
    end,
}

local function signal(event, ...)
    local frame = frames[1]
    if frame.events[event] then frame:OnEvent(event, ...) end
end

local function nextUpdate()
    local ready = callbacks
    callbacks = {}
    for _, callback in ipairs(ready) do callback() end
end

function GetTime() return time end
function GetBuildInfo() return "1.60.1", "70938", "Nov 14 2026", 16001 end
function UnitClass(unit) assert(unit == "player"); return "Mage", "MAGE" end
function UnitFactionGroup(unit) assert(unit == "player"); return "Alliance" end
function UnitLevel(unit) assert(unit == "player"); return level end
function UnitXP(unit) assert(unit == "player"); return xp end
function UnitXPMax(unit) assert(unit == "player"); return xpMax end
function UnitIsDeadOrGhost(unit) assert(unit == "player"); return dead end
function UnitAffectingCombat(unit) assert(unit == "player"); return combat end
function UnitOnTaxi(unit) assert(unit == "player"); return false end
function UnitIsAFK(unit) assert(unit == "player"); return secret end
function GetUnitSpeed(unit) assert(unit == "player"); return moving and 5 or 0 end
function IsInGroup() return grouped end
function IsInInstance() return party, party and "party" or "none" end
function issecretvalue(value) return value == secret end
C_Map = {
    GetBestMapForUnit = function(unit) assert(unit == "player"); return map end,
    GetPlayerMapPosition = function(mapID, unit)
        assert(mapID == map and unit == "player")
        positionReads = positionReads + 1
        return {GetXY = function() return 0.12349, 0.98765 end}
    end,
}

local console = print
print = function(message) messages[#messages + 1] = message end
SlashCmdList = {}
assert(loadfile(root .. "/companion/OpenXPRecorder/Recorder.lua"))()
local command = assert(SlashCmdList.OPENXPRECORDER)
assert(SLASH_OPENXPRECORDER1 == "/oxprec")
signal("QUEST_ACCEPTED", 25)
command("status")
assert(OpenXPRecorderData == nil and timer == nil, "idle recorder must not gather measurements")

command("start")
local first = OpenXPRecorderData.sessions[1]
assert(first.id == 1 and first.build == 70938 and first.class == "MAGE" and first.faction == "Alliance")
assert(first.events[1].xp == 75 and first.events[1].state == "stationary")
assert(first.events[1].x == nil and positionReads == 0)
time = 1
signal("QUEST_ACCEPTED", 25)
time, level, xp, xpMax, moving = 2, 2, 10, 200, true
signal("PLAYER_LEVEL_UP", level)
signal("PLAYER_XP_UPDATE", "player")
signal("QUEST_TURNED_IN", 25, 35, 1234)
assert(#callbacks == 1, "coalesce XP snapshots in a single update")
nextUpdate()
assert(first.events[3].reward_xp == 35 and first.events[3].quest_id == 25)
assert(first.events[4].level == 2 and first.events[4].xp == 10 and first.events[4].at_ms == 2000)
assert(first.events[4].state == "moving")

time = 3
signal("PLAYER_LEAVING_WORLD")
assert(first.events[5].state == "loading" and first.events[5].xp == nil)
timer.tick()
assert(#first.events == 5)
map, time, grouped, party, combat = 42, 6, true, true, true
signal("PLAYER_ENTERING_WORLD")
nextUpdate()
assert(first.events[6].map_id == 42 and first.events[6].state == "combat")
assert(first.events[6].grouped and first.events[6].instance == "party")
time, dead = 7, true
signal("PLAYER_DEAD")
nextUpdate()
assert(first.events[7].kind == "death" and first.events[8].state == "dead")

time = 8
signal("PLAYER_XP_UPDATE", "player")
local firstTicker = timer
command("stop")
assert(first.end_reason == "stopped" and first.elapsed_ms == 8000 and firstTicker.cancelled)
assert(next(frames[1].events) == nil)
map, dead, grouped, party, combat, moving = 1429, false, false, false, false, false
command("start positions")
local second = OpenXPRecorderData.sessions[2]
nextUpdate()
assert(#second.events == 1 and second.positions and positionReads == 1)
assert(second.events[1].x == 123 and second.events[1].y == 988)
time = 10
signal("PLAYER_LOGOUT")
assert(second.end_reason == "logout" and second.elapsed_ms == 2000)
assert(next(frames[1].events) == nil)

for i = 1, 3 do
    command("start")
    command("stop")
end
local sessions = OpenXPRecorderData.sessions
assert(#sessions == 4 and sessions[1].id == 2 and sessions[4].id == 5)
command("start")
for i = 1, 8192 do signal("QUEST_ACCEPTED", i) end
assert(#sessions == 4 and sessions[4].id == 6)
assert(sessions[4].end_reason == "limit" and #sessions[4].events == 8192 and timer.cancelled)
assert(next(frames[1].events) == nil)
console("recorder tests passed")
return 0
