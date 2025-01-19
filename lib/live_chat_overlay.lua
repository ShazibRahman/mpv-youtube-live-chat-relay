local mp = require 'mp'
local deque = require "lib.deque"
local socket = require('socket')

-- Configuration
local no_of_lines_in_chat = 15
local font_size = 15
local retry_interval = 3

local read_from_socket_interval = 0.5

-- ASS Styling Header
local ass_header = string.format([[{\q2\an7\fs%d\fnFiraMono Nerd Font\c&HFFFFFF&\1a&H00&\bord1\pos(10,10)}]], font_size)

local right_osd_prefix = "{\\fs20\\c&HFFFFFF&}"

local chat_messages = deque.new(no_of_lines_in_chat)

local is_overlay_active = false


local last_position = 0 -- Track the last read position in the file

local deque_timer

local read_from_cleint_timer 

local message_timeout = 6

local client = nil

local left_osd = mp.create_osd_overlay("ass-events")

local right_osd = mp.create_osd_overlay("ass-events")


left_osd.id = 1

right_osd.id = 2

-- Helper Functions

local function clear_overlay()
    if not is_overlay_active then return end
    left_osd:remove()
    is_overlay_active = false
end


local function push_message_with_timeout(message_text)
    local message = { text = message_text, timestamp = mp.get_time() }
    chat_messages:push_back(message)
end

--- Update the On-Screen Display (OSD) with chat overlay.
local function update_chat_overlay()
    local overlay_text = ass_header
    local messages = {}

    for _, item in ipairs(chat_messages:get_items()) do
        table.insert(messages, item.text)
    end

    overlay_text = overlay_text .. table.concat(messages, "\\N")
    left_osd.data = overlay_text
    -- print(overlay_text)
    left_osd:update()
    is_overlay_active = true
end

local function check_and_expire_messages()
    local current_time = mp.get_time()
    while not chat_messages:is_empty() do
        local first_message = chat_messages:peek_front()
        ---@diagnostic disable-next-line: need-check-nil
        if current_time - first_message.timestamp >= message_timeout then
            chat_messages:pop_front()
        else
            break
        end
    end

    if chat_messages:is_empty() then
        clear_overlay()
        if deque_timer then
            deque_timer:stop()
        end
    else
        update_chat_overlay()
    end
end


--- Read new chat messages from a file starting from the last read position.
---@param chat_file_path string
local function read_new_messages(chat_file_path)
    local file = io.open(chat_file_path, "r")

    if not file then
        mp.msg.warn("Chat file not found. Retrying in " .. retry_interval .. " seconds...")
        mp.add_timeout(retry_interval, function() read_new_messages(chat_file_path) end)
        return
    end

    -- Seek to the last read position and read new lines
    file:seek("set", last_position)
    local new_data_found = false

    for line in file:lines() do
        push_message_with_timeout(line)
        new_data_found = true
    end

    last_position = file:seek() -- Update last read position
    file:close()

    if new_data_found then
        update_chat_overlay()
        if not deque_timer then
            deque_timer = mp.add_periodic_timer(2, check_and_expire_messages)
        elseif not deque_timer:is_enabled() then
            deque_timer:resume()
        end
    end
end

local function read_from_cleint()
    read_from_cleint_timer = mp.add_periodic_timer(read_from_socket_interval, function()
        if not client then return end
        local response, err = client:receive()

        if response then
            push_message_with_timeout(response)
            update_chat_overlay()
            if not deque_timer then
                deque_timer = mp.add_periodic_timer(2, check_and_expire_messages)
            elseif not deque_timer:is_enabled() then
                deque_timer:resume()
            end
        elseif err ~= "timeout" then
            mp.msg.error("Socket connection error: " .. err)
            return -- Exit if there's an error
        end
    end)
end


--- Continuously receive messages from a server socket and update the overlay.
local function read_from_socket(port)
    client = assert(socket.connect("127.0.0.1", port))
    client:settimeout(0) -- Non-blocking mode

    -- Start a periodic timer to check the socket for incoming messages
    read_from_cleint()
end





--- Start the chat overlay either from a file or a socket connection.
---@param port number|nil
---@param subtitle_file string|nil
---@param interval number|nil
local function start_chat_overlay(port, subtitle_file, interval)
    interval = interval or 5
    if subtitle_file then
        mp.add_periodic_timer(interval, function() read_new_messages(subtitle_file) end)
    elseif port then
        read_from_socket(port)
    else
        mp.msg.warn("No valid input source (file or port) specified for chat overlay.")
        return
    end

    --  key binding to increase or decrease the no of lines in chat and font size in overlay_text

    mp.add_key_binding("Ctrl+Up", "increase_no_of_lines_in_chat",
        function()
            no_of_lines_in_chat = no_of_lines_in_chat + 1
            if chat_messages then
                chat_messages:resize(no_of_lines_in_chat)
            end
            if is_overlay_active then
                update_chat_overlay()
                right_osd.data = right_osd_prefix .. "No of Lines: " .. no_of_lines_in_chat
                right_osd:update()
                mp.add_timeout(1, function() right_osd:remove() end)
            end
        end)

    mp.add_key_binding("Ctrl+Down", "decrease_no_of_lines_in_chat",
        function()
            no_of_lines_in_chat = no_of_lines_in_chat - 1
            if chat_messages then
                chat_messages:resize(no_of_lines_in_chat)
            end
            if is_overlay_active then
                update_chat_overlay()
                right_osd.data = right_osd_prefix .. "No of Lines: " .. no_of_lines_in_chat
                right_osd:update()
                mp.add_timeout(1, function() right_osd:remove() end)
            end
        end)

    mp.add_key_binding("Ctrl+Right", "increase_font_size_in_chat",
        function()
            font_size = font_size + 1
            ass_header = string.format([[{\q2\an7\fs%d\fnFiraMono Nerd Font\c&HFFFFFF&\1a&H00&\bord1\pos(10,10)}]],
                font_size)
            if is_overlay_active then update_chat_overlay() end
        end)

    mp.add_key_binding("Ctrl+Left", "decrease_font_size_in_chat",
        function()
            font_size = font_size - 1
            ass_header = string.format([[{\q2\an7\fs%d\fnFiraMono Nerd Font\c&HFFFFFF&\1a&H00&\bord1\pos(10,10)}]],
                font_size)

            if is_overlay_active then update_chat_overlay() end
        end)

    mp.add_key_binding('Ctrl+Shift+Up', 'increase_message_timeout',
        function()
            message_timeout = message_timeout + 0.2
            right_osd.data = right_osd_prefix .. " Timeout: " .. string.format("%.1f", message_timeout)
            right_osd:update()
            -- clear after 1 second
            mp.add_timeout(1, function() right_osd:remove() end)
        end)

    mp.add_key_binding('Ctrl+Shift+Down', 'decrease_message_timeout',
        function()
            message_timeout = message_timeout - 0.2
            right_osd.data = right_osd_prefix .. " Timeout: " .. string.format("%.1f", message_timeout)
            right_osd:update()
            mp.add_timeout(1, function() right_osd:remove() end)
        end)
end

local function unload_chat_overlay()
    if deque_timer then
        deque_timer:stop()
        deque_timer = nil
    end
    if client then
        client:close()
        client = nil
    end
    if read_from_cleint_timer then
        read_from_cleint_timer:stop()
        read_from_cleint_timer = nil
    end
    clear_overlay()
    mp.remove_key_binding("increase_no_of_lines_in_chat")
    mp.remove_key_binding("decrease_no_of_lines_in_chat")
    mp.remove_key_binding("increase_font_size_in_chat")
    mp.remove_key_binding("decrease_font_size_in_chat")
    mp.remove_key_binding("increase_message_timeout")
    mp.remove_key_binding("decrease_message_timeout")
end

-- Exported Module
return {
    start_chat_overlay = start_chat_overlay,
    unload_chat_overlay = unload_chat_overlay
}
