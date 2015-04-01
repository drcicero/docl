--- Simple Syntax Highlighting

local M = {}

--- Wrap corresponding parts of Lua-Code with HTML-Spans of the classes
-- 'comment', 'string', 'escape', 'operator' and 'keyword'. Does not
-- work with multiline comments and multiline strings, everything else should
-- be fine.
--[=[
local highlight = require "highlight"

return highlight.highlight( ""
.. "function get(table, key)"
.. "    return table[key]"
.. "end"
)
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

    return (string :gsub("&", "&amp;") :gsub("<", "&lt;") .. "<")

        :gsub("\n", "<br>")
        :gsub("\t", "    ")
        :gsub(" ", "<wbr>&nbsp;")

        :gsub("%$", suspend)

        :gsub("\\\\", wrapclass("escape"))
        :gsub('\\["\']', wrapclass("escape"))

        :gsub("'.-'", wrapclass("string"))
        :gsub('".-"', wrapclass("string"))

        :gsub("(%-%-.-)(<br>)", wrapclass("comment"))

--      :gsub("(%d+)([^;])", wrapclass("number"))

        :gsub("[=()#[%]+-*/{}]", wrapclass("operator"))

        :gsub("(elseif)(<)", wrapclass("keyword"))
        :gsub("(do)(<)", wrapclass("keyword"))
        :gsub("(in)(<)", wrapclass("keyword"))
        :gsub("(if)(<)", wrapclass("keyword"))
        :gsub("(for)(<)", wrapclass("keyword"))
        :gsub("(end)(<)", wrapclass("keyword"))
        :gsub("(else)(<)", wrapclass("keyword"))
        :gsub("(then)(<)", wrapclass("keyword"))
        :gsub("(break)(<)", wrapclass("keyword"))
        :gsub("(until)(<)", wrapclass("keyword"))
        :gsub("(local)(<)", wrapclass("keyword"))
        :gsub("(while)(<)", wrapclass("keyword"))
        :gsub("(return)(<)", wrapclass("keyword"))
        :gsub("(function)(<)", wrapclass("keyword"))

        :gsub("$(.-);", function (x) return inserts[tonumber(x)] end)
        :gsub("$(.-);", function (x) return inserts[tonumber(x)] end)

        :sub(1, -2)
end

return M
