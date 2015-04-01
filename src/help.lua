--- Help
-- provides strings for the command line help and documentation

local opt = require "parseopt"
local doc = require "doc"

local M = {}

local function wrap(str, indent, lines)
  local lines = lines or {}
  if #str < 80 then
    table.insert(lines, str)
    return indent .. table.concat(lines, indent)

  else
    local max = str:sub(1, 81 - #indent)
    local break_at = #max - max:reverse():find(" ")
    local line, rest = str:sub(1, break_at), str:sub(break_at+2)
    table.insert(lines, line)
    return wrap(rest, indent, lines)
  end
end

--- M.help
-- an description string for invoking the 'docl' command
M.help = [[
  'docl [options] --dir <output-directory> FILES'

Generate the html-documentation for the files 'FILES' in the output-directory.

Before generating the documentation the first time, you need to create the output-directory. For example, to create the directory 'doc' open a terminal and execute:

  '$ mkdir doc'

Then you can generate the documentation by executing:

  '$ cd path/to/lua/files'

  '$ ./path/to/docl/docl --dir doc *.lua'
]]


M.options = {
  {"__dir", "doc", "specify output directory."},

  {"__lift", opt.empty,
      "lift a specific file. eg. make its documentation into the index page. you probably want to do that with the main file."},

  {"__suffix", "Documentation",
      "the <title> tag is constructed as 'MODULETITLE - SUFFIX'. recommended value is 'MYPOGRAMM Documentation'."},

  {"__highlight", "lua", "choose a syntax-highligher.", {
      {"lua",  "produces already colored html output, but big files."},
      {"js",   "produces smaller files, but syntax-highlighting is only visible if js is enabled."},
      {"none", "no syntax-highlighting"},
  }},

  {"__source", "false", "choose to show the source code in the page", {
      {"false", "dont include source code"},
      {"true", "include a button on every page to show the source code."},
  }},

  {"_v", opt.empty, "show version number and exit."},
  {"_h", opt.empty, "show this help and exit."},
}


--- M.default_options
-- an 'option defaults' table for $parseopt
M.default_options = {}
for i,e in ipairs(M.options) do
  M.default_options[e[1]] = e[2]
end

--- M.allowed_args
-- an 'allowed args' table for $parseopt
M.allowed_args = {}
for i,e in ipairs(M.options) do
  M.allowed_args[e[1]] = e[4]
end

--- M.terminalhelp
-- the string to display on recieving the '-h' option
local t = {"Options"}
for i,e in ipairs(M.options) do
  local argdesc = e[4]==nil and "" or table.concat(doc.map(e[4], function (x)
    return wrap("* '" .. x[1] .. "' " .. x[2], "\n      ") end), "")
 
  local desc = e[2] == opt.empty and e[3]
    or e[3] .. " default is '" .. e[2] .. "'."

  local arg = e[1]:sub(1,2)=="__" and " <ARG>" or ""

  table.insert(t, table.concat {
    "\n  ", e[1]:gsub("_", "-"), arg, wrap(desc, "\n      "), argdesc, "\n" })
end

M.terminalhelp = "Synopsis\n"
  .. M.help:gsub("(.-)\n", function (x) return wrap(x, "\n  ") end)
  .. "\n\n" .. table.concat(t)
  .. "\nFurther information available via the docl documentation"
  .. "\nhttp://drcicero.github.io/docl/"


--- M.webhelp
-- a html string containing the web help
local t = {"<h2>Options</h2>"}
for i,e in ipairs(M.options) do
  local argdesc = e[4]==nil and "" or table.concat(doc.map(e[4], function (x)
    return "<ul><li><strong>" .. x[1]:gsub("<", "&lt;") .. "</strong><br>" .. x[2]:gsub("<", "&lt;") .. "</ul>" end), "")

  local arg = e[1]:sub(1,2)=="__" and " <ARG>" or ""
  local dt = e[1]:gsub("_", "-") .. " " .. arg
  local dd = e[2] == opt.empty and e[3]
    or e[3] .. " default is '" .. e[2] .. "'."

  table.insert(t,
      doc.wrap(doc.link(dt:gsub("<", "&lt;")), "dt")
   .. doc.wrap(doc.link(dd:gsub("<", "&lt;")) .. argdesc, "dd"))
end

M.webhelp = doc.link(M.help:gsub("<", "&lt;"))
  :gsub("\n\n", "<p></p>")
  .. "<dl>" .. table.concat(t) .. "</dl>"

return M

