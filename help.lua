--- The help string
-- provides a string containing the command line help

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

Options
  '-v'
      show version number and exit

  '-h'
      show this help and exit

  '--dir doc'
      specify output directory, default is 'doc'

  '--lift main.lua'
      lift a specific file. eg. make its documentation into the index page.
      you probably want to do that with the main file.

  '--source (true|false)'
      if 'true', include a button on every page to show the source of the
      documentation, default is 'true'
]]

return M
