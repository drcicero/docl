--- The help string
-- provides a string containing the command line help

local opt = require "parseopt"
local doc = require "doc"

local M = {}

--- M.help
-- the string containing the command line help
M.help = [[
  'docl [options] FILES'

  Generate the documentation files. Create files at
  'OUTPUTDIR/path.to.file.html' for every specified file and an 'index.html'
  file, containing a summary.

  For example the documentation of 'src/plugins/vector.lua' would be placed
  at 'docs/src.plugins.vector.lua.html'.

  Before generating the documentation the first time, you need to create the
  output-directory and place a style.css there. You can create the directory
  and place the default style there either using your favorite file-manager or
  by executing:

  'mkdir doc; cp /path/to/docl/default_style.css doc/style.css'

  Then you can generate the documentation by executing:

  'cd path/to/lua/files; ./path/to/docl/docl --dir doc *.lua'
]]

M.options = {
  {"_v", opt.empty, "show version number and exit."},
  {"_h", opt.empty, "show this help and exit."},
  {"__dir", "doc",  "specify output directory."},

  {"__lift", opt.empty,
      "lift a specific file. eg. make its documentation into the index page.\n      you probably want to do that with the main file."},

  {"__source", "false",
      "if 'true', include a button on every page to show the source of the\n      documentation."},

  {"__suffix", "Documentation",
      "the <title> tag is constructed as 'MODULETITLE - SUFFIX'.\n      recommended value is 'MYPOGRAMM Documentation'."},
}


--- M.default_options
-- an 'option defaults' table for $parseopt
M.default_options = {}
for i,e in ipairs(M.options) do
  M.default_options[e[1]] = e[2]
end


--- M.optionshelp
-- a string that contains the options help to be displayed on recieving the -h
-- option
local t = {"Options"}
for i,e in ipairs(M.options) do
  local desc = e[2] == opt.empty and e[3]
    or e[3] .. "\n      default is '" .. e[2] .. "'."

  local arg = e[1]:sub(1,2)=="__" and " <ARG>" or ""

  table.insert(t, table.concat {
    "\n  ", e[1]:gsub("_", "-"), arg, "\n      ", desc, "\n" })
end
M.optionshelp = table.concat(t)

--- M.webhelp
-- a html string containing the web help
local t = {"<h2>Options</h2>"}
for i,e in ipairs(M.options) do
  local arg = e[1]:sub(1,2)=="__" and " <ARG>" or ""
  local dt = e[1]:gsub("_", "-") .. " " .. arg
  local dd = e[2] == opt.empty and e[3]
    or e[3] .. "\n      default is '" .. e[2] .. "'."

  table.insert(t,
      doc.wrap(doc.link(dt:gsub("<", "&lt;")), "dt")
   .. doc.wrap(doc.link(dd:gsub("<", "&lt;")), "dd"))
end

M.webhelp = ""
  .. (doc.link(M.help
      :gsub("<", "&lt;")
      :gsub("(.-)\n", function (x) return (x == "" or x:sub(1,1) == " ")
          and x .. "\n"
           or doc.wrap(x, "h2") end)))

      :gsub("\n\n", "<p></p>")

  .. "<dl>" .. table.concat(t) .. "</dl>"

return M

