--- helper functions
-- Functions for comment parsing and unit testing, html generation and list
-- operations.
--[[
  doc = require "doc"
]]--@RUN
-- See #doc.parse for how it expects your files to be written.

local ok,res = pcall(require, "traceback")
if ok then traceback = res end
local doc = {}

--- Parse documention from file.
-- returns a list of sections, where each section is a list of defintions plus a description.
--
-- A Doccomment begins with '---' and continues with '--', newlines are ignored,
-- empty lines seperate paragraphs. For example:
--[[
--- Add 2 numbers.
-- This function the two numbers 'x' and 'y'.
-- 
-- WARNING using this function with nil will generate strange errors!
function add(x, y)
return x + y
end
]]
--
-- Besides commenting functions, you can also give a file an introduction
-- by starting a doccomment without a function in the next line.
--[[
--- Arithmetic Operations
-- This module contains a lot of useful arithemtic operations like
-- + - * / % as well as pow, log, sin, cos, tan, acos, asin, atan, atan2.
--
-- This module depends on the math module.
require "math"

-- ...
-- rest of the file
]]
function doc.parse_file (file)
    local env
    local sections = {{}}
    local doccomment, doctest
    local i = 0

 -- generate new global table for the scripts
    env = {}
    setmetatable(env, {__index = _G})
    env._G = env
    env.arg = {}
    local dir = ("./" .. file):match'(.*/)(.*)'
    env.package.path = dir .. "/?.lua;" .. package.path

 -- helper functions
    local function end_doctest (line)
        if line:sub(1,  8 + doctest.level) == "]" .. ("="):rep(doctest.level) .. "]--@RUN"
        or line:sub(1, 11 + doctest.level) == "]" .. ("="):rep(doctest.level) .. "]--@EXPECT" then

            local ok
--            local chunk, result = loadstring(table.concat(doctest, "\n"), file)
            local chunk, result = loadstring(table.concat(doctest, "\n"), file, "bt", env)

            if chunk then
--              setfenv(chunk, env)
                ok, result = xpcall(chunk, traceback or function (s) return s end)
            end

         -- build html output of doctest
            local string = "<pre class=run>" .. doc.syntax_highlight(table.concat(doctest, "\n")) .. "</pre>"

            local expected
            if line:sub(1, 11 + doctest.level) == "]" .. ("="):rep(doctest.level) .. "]--@EXPECT" then
                expected = line:sub(13 + doctest.level)
                string = string .. "<pre class=success>" .. doc.syntax_highlight(expected) .. "</pre>"
            end

            if not ok then
                local error_line = tonumber(result:match("%[string .*]:(%x+).-") or 0) + doctest.firstline 
                print("  ERROR in line " .. error_line)
                print("", result)
                print()
                result = result:gsub(".-\n", function (line)
                    if line:match("^ *=") then
                        return doc.syntax_highlight(line):gsub("\t", "    "):gsub("  ", "&nbsp; ")
                    else
                        line = line:gsub("<", "&lt;")
                        if line:match("^TRACEBACK") then
                            line = "<span style=color:red>" .. line:sub(1, -1) .. "</span>"
                        end
                        return line:gsub("\n", "<br>"):gsub("\t", "    "):gsub("  ", "&nbsp; ")
                    end
                end)
                string = string .. "<pre class=error>" .. result .. "</pre>"

            else
                result = doc.repr(result)
                if expected ~= nil then
                    if expected ~= result then
                        print("  FAIL in line " .. tostring(doctest.firstline))
                        print("    expected: " .. expected)
                        print("    instead : " .. result)
                        string = string .. "<pre class=fail>" .. doc.syntax_highlight(result) .. "</pre>"

                    else
                        print("  success in line " .. tostring(i))
                    end

                else
                    print("  generated in line " .. tostring(i))
                    string = string .. "<pre class=success>" .. doc.syntax_highlight(result) .. "</pre>"
                end
            end

         -- merge doctest output into doccomment
            table.insert(doccomment, string)
            doctest = nil -- end doctest

        else
         -- merge doctest output into doccomment
            table.insert(doccomment, doc.wrap(doc.syntax_highlight(table.concat(doctest, "\n")), "pre"))
            doctest = nil -- end doctest
        end
    end

    local function end_doccomment (line)
        if not sections[#sections].first then
            -- the first doccomment is the file/section-description
            -- ignores line
            if #sections == 1 then
                local f = io.open(file, "r")
                local content = f:read("*a")
                f:close()
                doccomment[#doccomment+1] = [[
<div class=turnable>
  <input id=code-folder type=checkbox>
  <label for=code-folder>View source-code</label>
  <div><pre id=folded-code style=width:inherit>
]] .. doc.syntax_highlight(content) .. "</pre></div></div>"
            end
            sections[#sections].first = doccomment

        else
            -- else a function-description
            local name, args = line:match("function (.-) -[(](.-)[)]")
            if name~= nil and name~="" then
                table.insert(doccomment, 1, doccomment.first)
                doccomment.first = tostring(name) .. " (" .. tostring(args) .. ")"

            else
                local name, args = line:match("(.-)= -function -[(](.-)[)]")
                if name then
                    table.insert(doccomment, 1, doccomment.first)
                    doccomment.first = tostring(name) .. " (" .. tostring(args) .. ")"
                end
            end

--        if line:sub(1, 6) == "local " then
--            if not sections.locals then sections.locals = {} end
--            table.insert(sections.locals, doccomment)
--        else
            table.insert(sections[#sections], doccomment)
--        end
        end

        doccomment = nil -- end doccomment
    end

    local function start_doccomment (line)
        if doccomment then end_doccomment("") end
        doccomment = {first = doc.link(line)}
    end

    local function start_doctest (line, level)
        doctest = {}
        if not line:sub(5 + level):gmatch(" *") then
            table.insert(doctest, line:sub(5))
        end
        doctest.level = level
        doctest.firstline = i
    end

    local function change_section (line)
        start_doccomment(line)
        table.insert(sections, {})
    end


    for line in io.lines(file) do
        i = i+1
        local first_nonspace = line:find("[^ ]")
        if doctest then
            if line:sub(1, 2 + doctest.level) == "]" .. ("="):rep(doctest.level) .. "]" then
                end_doctest(line)

            else -- continue doctest
                table.insert(doctest, line)
            end

		elseif first_nonspace then
           	line = line:sub(first_nonspace)

            if line:sub(1,4) == "----" then
                change_section(line:sub(5))

            elseif line:sub(1,3) == "---" then
                start_doccomment(line:sub(4))

            elseif doccomment then
             -- continue doccomment

                local doctest_level = line:match("--%[(=*)%[")
                if line:sub(1,2) == "--" and doctest_level ~= nil then
                    start_doctest(line, #doctest_level)

                elseif line:sub(1,2) == "--" then
                 -- continue normal doccomment
                    table.insert(doccomment, doc.link(line:sub(3)))

                else
                    end_doccomment(line)
                end
            end
        end
    end

    return sections
end

--- Generate documentation and run unit tests for list of sections.
function doc.gen_file (sections)
    local function content_template(section)
        return doc.wrap(
            table.concat(doc.map(section, function(def)
                return doc.def_template(def.first, "<p>"..table.concat(def, "\n"):gsub("\n\n", "</p><p>").."</p>" ) end
            ))
        , "dl")
    end
    local function nav_template(section)
        return doc.wraps(
            doc.map(section, function(x)
                return "<a href=#" .. x.first:sub(1, (x.first:find(" ") or 1)-1) .. ">" .. x.first .. "</a>"
            end)
        , "li")
    end


--    if not sections[1].first then sections[1].first = {first="Reference"} end

    local content, navigation = "", "<a href=index.html>> Index</a>"
    for i, section in ipairs(sections) do
        local description = sections[i].first or {}
        local title = description.first or "TITLE"

        content = content
            .. doc.wrap(title, i==1 and "h1" or "h2")
            .. "<p>"..table.concat(description, "\n"):gsub("\n\n", "</p><p>").."<p>"
            .. content_template(section)

        navigation = navigation
            .. doc.wrap(title, i==1 and "h2" or "h3")
            .. nav_template(section)
    end


    if content ~= "<h1>Reference</h1><p><p><dl></dl>" then
      return doc.file_template(content, navigation)

    else
      return false
    end
end

-- Apply #doc.gen_file for Lua-files and #doc.gen_dir for directories to all
-- elements of dir.
--function doc.gen_dir (dir)
--    dir = dir:gsub(" ", "\\ ")
--
--    local t={}
--
--    local ls = io.popen("ls -F " .. dir):read("*a")
--    ls:gsub("(.-)\n", function (item)
--        if item:sub(-4) == ".lua" then
--            doc.gen_file(dir .. item)
--            t[#t+1] = dir:gsub("/", ".") .. item:sub(1, -5)
--
--        elseif item:sub(-1) == "/" then
--            for i, k in ipairs(doc.gen_dir(dir .. item)) do
--                t[#t+1] = k
--            end
--
--        end
--    end)
--    return t
--end

---- HTML-generators
--- Wrap corresponding parts of Lua-Code with HTML-Spans of the classes
-- 'comment', 'string', 'escape', 'operator' and 'keyword'. Does not really
-- work with multiline comments or multiline strings, everything else should
-- be fine.
--[=[
return doc.syntax_highlight( [[
   function get(table, key)
       return table[key]
   end
]] )
]=]--@RUN
function doc.syntax_highlight(string)
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

local max_id = 0
function generate_id()
	max_id = max_id + 1
	return max_id
end

--- Make a HTML-dl-Element (definition list) out of a string 'dt' and a
-- string 'dd'. 'dt' must contain a space.
--[[
return doc.def_template("Fish (Animal)", "Fish (from latin fishius) is a animal commonly found in water.")
]]
function doc.def_template(dt, dd)
    local id = dt:sub(1, (dt:find(" ") or 1)-1)
    return "<dt id=" .. id .. ">" .. "<a href=#" .. id .. ">" .. dt .. "</a>" .. "</dt>\n<dd>" .. dd .. "</dd>"
end

--- An html template.
-- pass a string 'content' and a string 'navigation'. returns an html string.
function doc.file_template(content, navigation)
    return [[
<!doctype html><html><head>
  <meta charset=utf-8>
  <title>Reference</title>
  <link href="style.css" rel="stylesheet" type="text/css"></meta>

</head><body>
  <div id=content>
]] .. content .. [[

  </div><div id=navigation>
]].. navigation .. [[

  </div><footer style=margin-right>
    generated with docl
  </footer></body></html>]]
end

--- Link #path.to.something for local references and $path.to.something for references to other files.
function doc.link (string)
    local alphanum = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVVWXYZ0123456789"
    local result = string
        :gsub("'(.-)'", function (code)
            return doc.wrap(doc.syntax_highlight(code), "code")
        end)

        :gsub("$([" .. alphanum .. "_./#]*)", function (path)
            if path == "" then
                return "$"
            end

            local end_ = ""
            if path:sub(-1) == "." or path:sub(-1) == "/" then
                path = path:sub(1, -2)
                end_ = "."
            end
            local point = path:find("#") or #path+1
            local link = path:sub(1, point-1) .. ".lua.html#" .. path:sub(point+1)
            return "<a href=" .. link .. ">" .. path .. "</a>" .. end_
        end)

--        :gsub("#(["..alphanum.."_./]*)", function (path)
--            local end_ = ""
--            if path:sub(-1) == "." or path:sub(-1) == "/" then
--                path = path:sub(1, -2)
--                end_ = "."
--            end
--            local point = #path -- - path:reverse():find("%.")
--            return "<a href=#" .. path .. ">" .. path .. "</a>" .. end_
--        end)

    return result
end

--- Wrap text with HMTL-Element elem.
--[[
return doc.wrap("in italics", "em")
]]--@EXPECT "<em>in italics</em>"
function doc.wrap(text, element, attrs)
    return table.concat {"<", element, ">", text, "</", element, ">"}
end

--- Wrap a list of elements with HTML-Element elem.
--[[
return doc.wraps({"hallo", "bello", "cello"}, "p")
]]--@EXPECT "<p>hallo</p><p>bello</p><p>cello</p>"
function doc.wraps(list, element)
    return table.concat(doc.map(list, doc.wrap, element))
end

---- Useful helper functions
--- Transform elems of list with f.
--[[
return doc.map({1,2,3}, function (x)
    return x+1
end)
]]--@EXPECT {2, 3, 4}
function doc.map(list, f, ...)
    local result = {}
    for i, item in ipairs(list) do
        table.insert(result, f(item, ...))
    end
    return result
end

-- Replace every element of list with its key-property.
--[[
--return doc.pluck("name", {
--    {name="Frank", age=25},
--    {name="Josefine", mail="josefine@example.com"},
--    {name="Adalbert", friends={"Frank", "Josefine"}, age=61}
--}, ", ")
--]]--@EXPECT {"Adalbert", "Frank", "Josefine"}
--function doc.pluck(key, list)
--    return doc.map(list, function(elem)
--        return elem[key]
--    end)
--end

local function key_repr(value)
    if type(value) == "string" then
        if value:match("%l%w*") then
            return value
        else
            return "[" + doc.repr(value) + "]"
        end
    else
        return tostring(value)
    end
end

--- Almost serialisation ;)
--
-- like python's repr function.
--[[
return doc.repr(nil)
]]--@EXPECT "nil"
--[[
return doc.repr(1)
]]--@EXPECT "1"
--[[
return doc.repr "teststring"
]]--@EXPECT "\"teststring\""
--[[
return doc.repr {1, 2, b=7, 3, a=6,}
]]--@EXPECT "{1, 2, 3, a=6, b=7}"
--[[
return doc.repr(function () end)
]]
function doc.repr(value)
    if type(value) == "table" then
        local t = {}
        for k,v in ipairs(value) do
            t[#t+1] = doc.repr(v)
        end
        local len = #t
        for k,v in pairs(value) do
            if type(k) ~= "number" or k > len then
                t[#t+1] = key_repr(k) .."=".. doc.repr(v)
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

return doc
