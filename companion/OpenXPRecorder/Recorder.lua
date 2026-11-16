-- Opt-in measurements from the player unit and public Forever events.
local SCHEMA = 1
local SAMPLE_SECONDS = 5
local MAX_EVENTS = 8192
local MAX_SESSIONS = 4

local frame = CreateFrame("Frame")
local session, started, ticker, pending, loading

local function Say(message)
    print("OpenXP Recorder: " .. message)
end

local function Public(value)
    if not issecretvalue or not issecretvalue(value) then
        return value
    end
end

local function Nonnegative(value)
    value = Public(value)
    if type(value) == "number" and value >= 0 and value < math.huge then
        return value
    end
end

local function Positive(value)
    value = Nonnegative(value)
    if value and value > 0 then return value end
end

local function Activity()
    if Public(UnitIsDeadOrGhost("player")) then return "dead" end
    if Public(UnitAffectingCombat("player")) then return "combat" end
    if Public(UnitOnTaxi("player")) then return "taxi" end
    if Public(UnitIsAFK("player")) then return "afk" end
    local speed = Nonnegative(GetUnitSpeed("player"))
    if not speed then return "unknown" end
    return speed > 0 and "moving" or "stationary"
end

local function Finish(reason)
    session.end_reason = reason
    session, pending, loading = nil, nil, nil
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    frame:UnregisterAllEvents()
    if reason == "limit" then
        Say("Stopped at the event limit. Log out or reload to save the session.")
    elseif reason == "stopped" then
        Say("Stopped. Log out or reload to save the session.")
    end
end

local function Record(event, at)
    local elapsed = at or math.max(session.elapsed_ms, math.floor((GetTime() - started) * 1000 + 0.5))
    event.at_ms = elapsed
    session.elapsed_ms = elapsed
    local events = session.events
    events[#events + 1] = event
    if #events == MAX_EVENTS then Finish("limit") end
end

local function Sample(at)
    local row = {kind = "sample", state = "loading"}
    if not loading then
        row.state = Activity()
        row.level = Positive(UnitLevel("player"))
        row.xp = Nonnegative(UnitXP("player"))
        row.xp_max = Nonnegative(UnitXPMax("player"))
        row.map_id = Positive(C_Map.GetBestMapForUnit("player"))
        row.instance = Public(select(2, IsInInstance()))
        row.grouped = Public(IsInGroup())
        if session.positions and row.map_id then
            local position = Public(C_Map.GetPlayerMapPosition(row.map_id, "player"))
            if position then
                local x, y = position:GetXY()
                x, y = Nonnegative(x), Nonnegative(y)
                if x and y and x <= 1 and y <= 1 and (x > 0 or y > 0) then
                    row.x = math.floor(x * 1000 + 0.5)
                    row.y = math.floor(y * 1000 + 0.5)
                end
            end
        end
    end
    Record(row, at)
end

local function QueueSample()
    if loading or pending then return end
    local active = session
    pending = true
    -- The level and XP events can arrive in the same update. Read the player
    -- after that update so a transient rollover is less likely to be sampled.
    C_Timer.After(0, function()
        if session ~= active then return end
        pending = nil
        if not loading then Sample() end
    end)
end

local events = {
    "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "QUEST_ACCEPTED", "QUEST_TURNED_IN",
    "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "PLAYER_MAP_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT",
}

frame:SetScript("OnEvent", function(_, event, value, xpReward)
    if not session then return end
    if event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
        local id = Positive(value)
        if id then
            Record({kind = event == "QUEST_ACCEPTED" and "accept" or "turnin", quest_id = id,
                reward_xp = event == "QUEST_TURNED_IN" and Nonnegative(xpReward) or nil})
        end
    elseif event == "PLAYER_DEAD" then
        Record({kind = "death"})
        if session then QueueSample() end
    elseif event == "PLAYER_LEAVING_WORLD" then
        loading = true
        Sample()
    elseif event == "PLAYER_ENTERING_WORLD" then
        loading = nil
        QueueSample()
    elseif event == "PLAYER_LOGOUT" then
        if not loading then Sample() end
        if session then Finish("logout") end
    elseif event ~= "PLAYER_XP_UPDATE" or value == "player" then
        QueueSample()
    end
end)

local function Start(positions)
    if session then
        Say("A session is already recording. Use /oxprec stop to finish it.")
        return
    end
    local data = OpenXPRecorderData
    if data == nil then
        data = {schema = SCHEMA, sessions = {}}
        OpenXPRecorderData = data
    end
    if type(data) ~= "table" or data.schema ~= SCHEMA or type(data.sessions) ~= "table" then
        Say("This recording file uses a different format. Use the recorder version that wrote it.")
        return
    end
    local history = data.sessions
    local previous = history[#history]
    if previous and (type(previous) ~= "table" or not Positive(previous.id)) then
        Say("The saved session ID is invalid. Keep the file for analysis and start with a fresh copy.")
        return
    end
    local _, build, _, interface = GetBuildInfo()
    session = {
        id = previous and previous.id + 1 or 1,
        build = tonumber(build), interface = interface,
        class = Public(select(2, UnitClass("player"))), faction = Public(UnitFactionGroup("player")),
        positions = positions, elapsed_ms = 0, events = {},
    }
    while #history >= MAX_SESSIONS do table.remove(history, 1) end
    history[#history + 1] = session
    started = GetTime()
    for _, event in ipairs(events) do frame:RegisterEvent(event) end
    local active = session
    ticker = C_Timer.NewTicker(SAMPLE_SECONDS, function()
        if session == active and not loading then Sample() end
    end)
    Sample(0)
    Say(positions and "Recording with coarse positions." or "Recording with map IDs only.")
end

SLASH_OPENXPRECORDER1 = "/oxprec"
SlashCmdList.OPENXPRECORDER = function(message)
    local command = message:lower():match("^%s*(.-)%s*$")
    if command == "start" or command == "start positions" then
        Start(command == "start positions")
    elseif command == "stop" and session then
        Sample()
        if session then Finish("stopped") end
    elseif command == "status" or command == "stop" then
        Say(session and ("Recording session %d. %d events collected so far."):format(session.id, #session.events)
            or "Recorder is stopped.")
    else
        Say("/oxprec start, /oxprec start positions, /oxprec stop, /oxprec status")
    end
end
