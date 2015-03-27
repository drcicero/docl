--- Readable tostring
-- provides the 'repr' function below.
--[[
repr = require "repr"
]]--@RUN

local M = {}

local function key_repr(value)
    if type(value) == "string" then
        return value:match("%l%w*") and
            value or "[" + M.repr(value) + "]"
    else
        return tostring(value)
    end
end

--- Generate a readable string out of any lua-value.
-- It is almost serialisation ;)
--
-- Examples:
--[[
return repr.repr(nil)
]]--@EXPECT "nil"
--[[
return repr.repr(1)
]]--@EXPECT "1"
--[[
return repr.repr "teststring"
]]--@EXPECT "\"teststring\""
--[[
return repr.repr {1, 2, b=7, 3, a=6,}
]]--@EXPECT "{1, 2, 3, a=6, b=7}"
--[[
return repr.repr(function () end)
]]--@RUN
function M.repr(value)
    if type(value) == "table" then
        local t = {}
        for k,v in ipairs(value) do
            t[#t+1] = M.repr(v)
        end
        local len = #t
        for k,v in pairs(value) do
            if type(k) ~= "number" or k > len then
                t[#t+1] = key_repr(k) .."=".. M.repr(v)
            end
        end
        table.sort(t)
        return "{" .. table.concat(t, ", ") .. "}"

    elseif type(value) == "string" then
--        if value:find("\\n") == nil then
            return ("%q"):format(value)
--        else
--            return "[[" .. value .. "]]"
--        end

    else
        return tostring(value)
    end
end

return M