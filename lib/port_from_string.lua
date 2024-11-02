function GeneratePortNumber(input_string, length)
    -- Simple hash function to convert a string into a numeric representation
    local hash = 0

    for i = 1, #input_string do
        local char = input_string:sub(i, i)
        hash = hash + string.byte(char) * i
    end

    -- Ensure hash is positive and convert to a string
    hash = math.abs(hash)
    local fixed_length_number = tostring(hash)

    -- Trim or pad the number to the desired length
    if #fixed_length_number < length then
        fixed_length_number = string.rep("0", length - #fixed_length_number) .. fixed_length_number
    else
        fixed_length_number = fixed_length_number:sub(1, length)
    end

    return fixed_length_number
end

-- Example usage




return {
    GeneratePortNumber = GeneratePortNumber
}
