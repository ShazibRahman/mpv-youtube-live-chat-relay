local o = { fetch_aot = 5 } -- Fetch interval
local utils = require "mp.utils"
local options = require 'mp.options'
local live_chat_overlay = require "lib.live_chat_overlay"
options.read_options(o)

local chat_sid, stream_id, subtitle_file
local subtitle_added = false
local generate_port = require "lib.port_from_string".GeneratePortNumber
local port

local ON_WINDOWS = package.config:sub(1, 1) ~= "/"
local python_path = ON_WINDOWS and "python" or "python3"

local lib_path = utils.join_path(mp.get_script_directory(), "lib")
local live_dump = utils.join_path(lib_path, "live_dump.py")
local past_dump = utils.join_path(lib_path, "past_dump.py")
local is_live = utils.join_path(lib_path, "is_live.py")

local is_live_stream = false

if not mp.get_script_directory() then
    mp.msg.error("This script must be placed in a script directory")
    return
end

-- Main function to update subtitles or overlay for past streams
local function timer_callback()
    if is_live_stream or mp.get_property_native("pause") then return end

    if not subtitle_file then
        subtitle_file = utils.join_path(mp.get_script_directory(), stream_id .. ".txt")
    end

    if not subtitle_added then
        mp.command_native({ name = "sub-add", url = subtitle_file, title = "Youtube Chat" })
        chat_sid = mp.get_property_native("sid")
        subtitle_added = true
    else
        mp.command_native({ "sub-reload", chat_sid })
    end
end

-- Track change handler for past streams
local function handle_track_change(_, sid)
    if is_live_stream then return end
    if sid and chat_sid ~= sid then
        chat_sid = sid
        timer_callback()
    end
end

-- Overlay function for port-based live stream handling
local function handle_live_stream_from_port()
    port = generate_port(stream_id, 4)
    local args = { python_path, live_dump, stream_id, tostring(port) }

    mp.command_native_async({ name = "subprocess", capture_stdout = false, playback_only = false, args = args })

    mp.add_timeout(5, function()
        live_chat_overlay.start_chat_overlay(tonumber(port), nil, o.fetch_aot)
    end)
end

-- File-based live stream overlay handling
local function handle_live_stream_from_file()
    subtitle_file = utils.join_path(mp.get_script_directory(), stream_id .. ".txt")
    local args = { python_path, live_dump, stream_id }

    mp.command_native_async({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
    live_chat_overlay.start_chat_overlay(nil, subtitle_file, o.fetch_aot)
end

-- Handle past streams
local function handle_past_stream()
    local args = { python_path, past_dump, stream_id }

    mp.command_native_async({
        name = "subprocess", capture_stdout = true, playback_only = false, args = args
    }, function(success, result, error)
        if success then
            timer_callback()
        else
            print("Error:", error)
        end
    end)

    mp.command_native({
        name = "sub-add",
        url = "memory://1\n0:0:0,0 --> 999:0:0,0\nloading...past..stream...chat",
        title =
        "Youtube Chat"
    })
    chat_sid = mp.get_property_native("sid")
end

-- Initialize stream and decide if live or past
local function init()
    stream_id = string.match(mp.get_property("path"), "youtu%.be/([%w_-]+)")
    if not stream_id then return end

    subtitle_file = utils.join_path(mp.get_script_directory(), stream_id .. ".txt")

    mp.command_native_async({
        name = "subprocess", capture_stdout = true, args = { python_path, is_live, stream_id }
    }, function(success, result, error)
        local response = result.stdout:match("-?%d+")
        print(response)
        if success and response == "1" then
            is_live_stream = true
            handle_live_stream_from_port()
        elseif success and response == "0" then
            handle_past_stream()
        else
            -- exit the script
            return
        end
    end)
end

-- Clean up subtitle file
local function cleanup()
    if subtitle_file and utils.file_info(subtitle_file) then
        local success, err = os.remove(subtitle_file)
        if not success then mp.msg.error("Failed to delete subtitle file: " .. tostring(err)) end
    end
end

-- Register events
mp.register_event("shutdown", cleanup)
mp.register_event("start-file", init)
mp.observe_property("current-tracks/sub/id", "native", handle_track_change)
