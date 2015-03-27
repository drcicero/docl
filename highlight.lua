--- Simple Syntax Highlighting

local M = {}

--- Wrap corresponding parts of Lua-Code with HTML-Spans of the classes
-- 'comment', 'string', 'escape', 'operator' and 'keyword'. Does not really
-- work with multiline comments or multiline strings, everything else should
-- be fine.
--[=[
local highlight = require "highlight"

return highlight.highlight( [[
   function get(table, key)
       return table[key]
   end
]] )
]=]--@RUN
function M.highlight(string)
    local inserts = {}

    local function wrapclass(class) return function(x, y)
        if not y then y = "" end
        table.insert(inserts, "<span class=" .. class .. ">" .. x .. "</span>")
        return "$" .. #inserts .. ";" .. y
    end end

    local function suspend(x)
        table.insert(inserts, x)
        return "$" .. #inserts .. ";"
    end

    return (string
        :gsub("<", "&lt;") .. "<")
        :gsub("\n", "<br>")

        :gsub("%$", suspend)
--        :gsub("%$.-;", suspend)

        :gsub("\\\\", suspend)
        :gsub('\\["\']', wrapclass("escape"))
--        :gsub("(<br>%-%-.-)([\n<])", wrapclass("comment"))
        :gsub("'.-'", wrapclass("string")):gsub('".-"', wrapclass("string"))
        :gsub("(%-%-.-)([\n<])", wrapclass("comment"))

--        :gsub("(%d+)([^;])", wrapclass("number"))

        :gsub("[=()#[%]+-*/{}]", wrapclass("operator"))

        :gsub("(elseif)([ \n<])", wrapclass("keyword"))
        :gsub("(do)([ \n<])", wrapclass("keyword"))
        :gsub("(in)([ \n<])", wrapclass("keyword"))
        :gsub("(if)([ \n<])", wrapclass("keyword"))
        :gsub("(for)([ \n<])", wrapclass("keyword"))
        :gsub("(end)([ \n<])", wrapclass("keyword"))
        :gsub("(else)([ \n<])", wrapclass("keyword"))
        :gsub("(then)([ \n<])", wrapclass("keyword"))
        :gsub("(break)([ \n<])", wrapclass("keyword"))
        :gsub("(until)([ \n<])", wrapclass("keyword"))
        :gsub("(local)([ \n<])", wrapclass("keyword"))
        :gsub("(while)([ \n<])", wrapclass("keyword"))
        :gsub("(return)([ \n<])", wrapclass("keyword"))
        :gsub("(function)([ \n<])", wrapclass("keyword"))


        :gsub(" ", "&nbsp;")

        :gsub("$(.-);", function (x) return inserts[tonumber(x)] end)
        :gsub("$(.-);", function (x) return inserts[tonumber(x)] end)

        :sub(1, -2)

-- debugging
--        .. "</pre>" .. doc.wraps(doc.map(inserts, function (x) return "------<br>" .. x end ), "p")
end

return M
