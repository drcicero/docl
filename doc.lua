--- helper functions
-- Functions for parsing, running code samples and html generation.
--[[
  doc = require "doc"
]]--@RUN
-- See #doc.parse for how it expects your files to be written.

local highlight = (require "highlight").highlight
local repr = (require "repr").repr

local ok,res = pcall(require, "traceback")
if ok then traceback = res end
local doc = {}

--- parse a codeblock and return pretty html.
function doc.codeblock2html (codeblock, env, highlight)
    local code = table.concat(codeblock, "\n")
    local chunk, result = loadstring(code, file) -- "bt")
    local ok
    if chunk then
        setfenv(chunk, env)
        ok, result = xpcall(chunk, traceback or function (s) return s end)
    end

    if not ok then
        local error_line = tonumber(result:match("%[string .*]:(%x+).-") or 0) + codeblock.firstline
        print("  ERROR in line " .. error_line)
        print("", result)
        print()
        result = result:gsub(".-\n", function (line)
            if line:match("^ *=") then
                return highlight(line)
            else
                line = line:gsub("<", "&lt;")
                if line:match("^TRACEBACK") then
                    line = "<span style=color:red>" .. line:sub(1, -1) .. "</span>"
                end
                return line:gsub("\n", "<br>"):gsub("\t", "    "):gsub("  ", "&nbsp; ")
            end
        end)
        return "error", "<pre class=error>" .. result .. "</pre>"

    elseif codeblock.kw == "INSERT_AS_TEXT" then
        print("  insert in line " .. tostring(codeblock.firstline))
        return "insert", result

    elseif codeblock.kw == "EXPECT" then
        result = repr(result)
       -- build html output of codeblock
        local expected = repr(loadstring("return " .. codeblock.argument)())
        local string = "<pre class=run>" .. highlight(code) .. "</pre>"
              .. "<pre class=success>" .. highlight(expected) .. "</pre>"

        if expected ~= result then
            print("  FAIL in line " .. tostring(codeblock.firstline))
            print("    expected: " .. expected)
            print("    instead : " .. result)
            return "fail", string .. "<pre class=fail>" .. highlight(result) .. "</pre>"

        else
            return "success", string
        end

    elseif codeblock.kw == "RUN" then
        return "run", "<pre class=run>" .. highlight(code) .. "</pre>"
            .. "<pre class=success>" .. highlight(repr(result)) .. "</pre>"
    end
end


--- Parse documention from file.
-- returns a list of sections, where each section is a list of defintions plus a description.
--
-- A Doccomment begins with '---' and continues with '--', newlines are ignored,
-- empty lines seperate paragraphs. For example:
--[[
--- Add 2 numbers.
-- This function the two numbers 'x' and 'y'.
--
-- x: first summand
--
-- y: second summand
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
function doc.parse_file (file, links, options)
    local msg

    local sections = {{}}
    local doccomment, codeblock
    local i = 0

 -- generate new global table for the scripts
    local env = {arg={}}
    env._G = env
    setmetatable(env, {__index = _G}) -- allow acces to all normal global functions
    -- allow relative requires
    env.package = {path = ("./" .. file):match'(.*/)(.*)' .. "/?.lua;" .. package.path}

    local highlight = options.__highlight == "lua" and highlight or
      function (x) return doc.wrap(x:gsub("<", "&lt;"), "code", " style=white-space:pre class=language-lua") end

 -- sub functions {
        local function end_codeblock (line)
            if doc.startswith(line, "--@") then
                codeblock.kw = (line:sub(4) .. " "):match("^(.-) ")
                codeblock.argument = line:sub(#codeblock.kw+4)
                msg, string = doc.codeblock2html(codeblock, env, highlight)

            else
                string = doc.wrap(highlight(table.concat(codeblock, "\n")), "pre")
            end

         -- merge codeblock output into doccomment
            table.insert(doccomment, string)
            codeblock = nil -- end codeblock
        end

        local function end_doccomment (line)
            -- the first doccomment is the section-description
            if not sections[#sections].first then
                if options.__source == "true" and #sections == 1 then
                    table.insert(doccomment, doc.source_template(file))
                end
                sections[#sections].first = doccomment

            else -- try a function-description
                local name, args = doc.parse_func_def(line)
                if name then
                    table.insert(doccomment, 1, doccomment.first)
                    doccomment.first = tostring(name) .. " (" .. tostring(args) .. ")"
                end
                table.insert(sections[#sections], doccomment)
            end

            doccomment = nil -- end doccomment
        end

        local function start_doccomment (line)
            if doccomment then end_doccomment("") end
            doccomment = {first = doc.link(line, links, file, i)}
        end

        local function start_codeblock (line, level)
            codeblock = {}
            if line:sub(5 + #level):find("[^ ]") then
                table.insert(codeblock, line:sub(5))
            end
            codeblock.ending = "]" .. level .. "]"
            codeblock.firstline = i
        end

        local function start_section (line)
            start_doccomment(line)
            table.insert(sections, {})
        end

        local function continue_doccomment (line)
            table.insert(doccomment, doc.link(line, links, file, i))
        end

        local function continue_codeblock (line)
            table.insert(codeblock, line)
        end

        local function parse_line(line)
            if codeblock then -- inside a codeblock?
                if doc.startswith(line, codeblock.ending) then
                    return end_codeblock(line:sub(#codeblock.ending+1)) end

                return continue_codeblock(line)
            end

            local first_nonspace = line:find("[^ ]") or 1
           	line = line:sub(first_nonspace)

            if doc.startswith(line, "----") then
                return start_section(line:sub(5)) end

            if doc.startswith(line, "---") then
                return start_doccomment(line:sub(4)) end

            if not doccomment then return end

            local codeblock_level = line:match("^--%[(=*)%[")
            if codeblock_level ~= nil then
                return start_codeblock(line, codeblock_level) end

            if doc.startswith(line, "--") then
                return continue_doccomment(line:sub(3)) end

            end_doccomment(line)
        end
    -- } sub functions

    for line in io.lines(file) do
        i = i+1
        parse_line(line)
    end

    sections.title = sections[1].first and sections[1].first.first or file
    return sections
end

--- Generate documentation and run unit tests for list of sections.
function doc.gen_file (sections, options)
    local content, navigation = "", "<a href=index.html>> Index</a>"
    for i, section in ipairs(sections) do
        local description = sections[i].first or {}
        local title = description.first or "TITLE"

        content = content
            .. doc.wrap(title, i==1 and "h1" or "h2")
            .. "<p>"..table.concat(description, "\n"):gsub("\n\n", "</p><p>").."<p>"
            .. doc.content_template(section)

        navigation = navigation
            .. doc.wrap(title, i==1 and "h2" or "h3")
            .. doc.nav_template(section)
    end


    if content ~= "<h1>Reference</h1><p><p><dl></dl>" then
      return doc.file_template(content, navigation, sections.title .. " - " .. options.__suffix, options)

    else
      return false
    end
end

---
function doc.content_template(section)
    return doc.wrap(
        table.concat(doc.map(section, function(def)
            return doc.def_template(def.first, "<p>"..table.concat(def, "\n"):gsub("\n\n", "</p><p>").."</p>" ) end
        ))
    , "dl")
end

---
function doc.nav_template(section)
    return table.concat(doc.map(section, function(x)
        return "<a class=func-link href=#" .. x.first:sub(1, (x.first:find(" ") or 1)-1) .. ">" .. x.first .. "</a>"
    end), "\n")
end

--- parse a line containing a function definition into a (name, list-of-args) pair
function doc.parse_func_def(line)
    local name, args
    name, args = line:match("function (.-) -[(](.-)[)]")
    if name~=nil and name~="" then return name, args end

    name, args = line:match("(.-)= -function -[(](.-)[)]")
    if name~=nil and name~="" then return name, args end
end

--- does the string 'str' start with the string 'beginning'?
function doc.startswith(str, beginning)
    return str:sub(1, #beginning) == beginning
end

---- HTML-generators

--local max_id = 0
--local function generate_id()
--	max_id = max_id + 1
--	return max_id
--end

--- Generate Sourcecode Drawer
function doc.source_template(file)
    local f = io.open(file, "r")
    local content = f:read("*a")
    f:close()
    return [[
<div class=turnable>
  <input id=code-folder type=checkbox>
  <label for=code-folder>View source-code</label>
  <div><pre id=folded-code style=width:inherit>
]] .. highlight(content) .. [[
</pre></div></div>
]]
end

--- Make a HTML-dl-Element (definition list) out of a string 'dt' and a
-- string 'dd'. 'dt' must contain a space.
--[[
return doc.def_template("Fish (Animal)", "Fish (from latin fishius) is a animal commonly found in water.")
]]--@RUN
function doc.def_template(dt, dd)
    local id = dt:sub(1, (dt:find(" ") or 1)-1)
    return "<dt id=" .. id .. ">" .. "<a href=#" .. id .. ">" .. dt .. "</a>" .. "</dt>\n<dd>" .. dd .. "</dd>"
end

--- An html template.
-- pass a string 'content' and a string 'navigation'. returns an html string.
function doc.file_template(content, navigation, title, options)
    return [[
<!doctype html><html><head>
  <meta charset=utf-8>
  <title>]] .. title .. [[</title>
  <link href="style.css" rel="stylesheet" type="text/css">

</head><body>
  <div id=content>
]] .. content .. [[

  </div><div id=navigation>
]].. navigation .. [[

  </div><footer style=margin-right>
    generated with docl
  </footer>
]] .. (options.__highlight == "js" and "\n<script async src=highlight.js></script>" or "") .. [[
</body></html>]]
end

--- Link #path.to.something for local references and $path.to.something for references to other files.
function doc.link (string, links, file, line)
    local alphanum = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVVWXYZ0123456789"
    local result = string
        :gsub("'(.-)'", function (code)
            return doc.wrap(highlight(code), "code")
        end)

        :gsub("$([" .. alphanum .. "_./#]+)", function (path)
            local end_ = ""
            if path:sub(-1) == "." or path:sub(-1) == "/" then
                path = path:sub(1, -2)
                end_ = "."
            end
            local point = path:find("#") or #path+1
            local link = path:sub(1, point-1) .. ".lua.html#" .. path:sub(point+1)
            table.insert(links, {url=link, file=file, line=line})
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
--[[return doc.wrap("in italics", "em")
]]--@EXPECT "<em>in italics</em>"
function doc.wrap(text, element, attr)
    return table.concat {"<", element, attr or "", ">", text, "</", element, ">"}
end

--- Wrap a list of elements with HTML-Element elem.
--[[return doc.wraps({"hallo", "bello", "cello"}, "p")
]]--@RUN '"<p>hallo</p>\n<p>bello</p>\n<p>cello</p>"'
function doc.wraps(list, element)
    local x = table.concat(doc.map(list, doc.wrap, element), "\n")
    return x
end

---- Useful helper functions
--- Transform elems of list with f.
--[[return doc.map({1,2,3}, function (x) return x+1 end)
]]--@EXPECT {2, 3, 4}
-- <br> [A] (A B... -> C) B... -> [C]
function doc.map(list, f, ...)
    local result = {}
    for i = 1, #list do
        result[i] = f(list[i], ...)
    end
    return result
end

--- Transform values of dict with f.
--[[return doc.kvmap({1, 2, a=5,b=7,c=9}, function (k,v)
  return "_" .. tostring(k), v+1 end)
]]--@EXPECT {_1=2, _2=3, _a=6, _b=8, _c=10}
-- <br> {A:B} (A B C... -> D E) C... -> {D:E}
function doc.kvmap(list, f, ...)
    local result = {}
    for k,v in pairs(list) do
        local k,v = f(k, v, ...)
        result[k] = v
    end
    return result
end

-- Replace every element of list with its key-property.
--[[
--]]--@RUN
--function partial(func, ...)
--    local args = {...}; local len = #args
--    return function(...)
--        local params = {unpack(args)}                      -- copy
--        for i,e in ipairs {...} do params[len + i] = e end -- merge
--        return func(unpack(params))                        -- apply
--    end
--end

return doc
