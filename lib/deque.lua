-- lib/buffer.lua
local deque = {}
deque.__index = deque

-- Create a new deque
function deque.new(max_size)
    local self = setmetatable({}, deque)
    self.max_size = max_size or 10
    self.items = {}
    self.start = 1
    self.count = 0
    return self
end

-- Add an element to the back of the deque
function deque:push_back(value)
    if self.count == self.max_size then
        self:pop_front()
    end
    local end_index = (self.start + self.count - 1) % self.max_size + 1
    self.items[end_index] = value
    self.count = self.count + 1
end

-- Remove an element from the front of the deque
function deque:pop_front()
    if self.count > 0 then
        local removed = self.items[self.start]
        self.items[self.start] = nil
        self.start = (self.start % self.max_size) + 1
        self.count = self.count - 1
        return removed
    end
end

function deque:resize(new_max_size)
    if new_max_size < 1 then
        print("Invalid max size")
        return
    end

    if new_max_size == self.max_size then
        return
    end

    local old_items = self:get_items()
    self.max_size = new_max_size
    self.items = {}
    self.start = 1

    -- Keep the most recent items if the new max size is smaller
    if new_max_size < #old_items then
        local start_index = #old_items - new_max_size + 1
        for i = start_index, #old_items do
            table.insert(self.items, old_items[i])
        end
        self.count = new_max_size
        -- mp.msg.info(" smmall count is " .. self.count .. " and size is " .. #old_items)
    else
        -- Otherwise, keep all items if resizing to a larger size
        for i = 1, #old_items do
            self.items[i] = old_items[i]
        end
        self.count = #old_items
        -- mp.msg.info("count is " .. self.count .. " and size is " .. #old_items)
    end
end

-- Get all items in order, considering circular structure
function deque:get_items()
    local result = {}
    for i = 0, self.count - 1 do
        local index = (self.start + i - 1) % self.max_size + 1
        result[i + 1] = self.items[index]
    end
    return result
end

function deque:print_items()
    local items = self:get_items()
    for _, item in ipairs(items) do
        print(item or "nil")
    end
end

function deque:is_empty()
    return self.count == 0
end

function deque:peek_front()
    if self.count > 0 then
        return self.items[self.start]
    end
    return nil -- or any default value if applicable
end

-- Example usage
local function example_usage()
    local my_buffer = deque.new(5) -- Start with max_size of 5

    -- Adding elements to the deque
    for i = 1, 7 do
        my_buffer:push_back("Message " .. i)
        print("Current Buffer:")
        my_buffer:print_items()
        print("---")
    end

    -- Resizing to a larger size
    print("Resizing to 10")
    my_buffer:resize(10)
    my_buffer:print_items()
    print("---")

    -- Adding more elements
    for i = 8, 12 do
        my_buffer:push_back("Message " .. i)
        print("Current Buffer:")
        print("my_buffer", table.concat(my_buffer:get_items()))
        my_buffer:print_items()
        print("---")
    end

    -- Resizing to a smaller size
    print("Resizing to 3")
    my_buffer:resize(3)
    print("my_buffer", table.concat(my_buffer:get_items()))
    print("Current Buffer after resizing to 3:")
    print("my_buffer", table.concat(my_buffer:get_items()))
end

-- Uncomment to test
-- example_usage()

return deque
