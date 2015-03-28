--- Simple shell parsing
-- A 'option-defaults' table is a table of shell options where "-" is substituted
-- for "_" as keys, and any other value as a default as values where opt.empty
-- means no default.
--
-- Example:
--[[
opt = require "parseopt"
defaults = {
  _v = opt.empty,
  _h = opt.empty,
  _q = opt.empty,
  __out = "a.out",
  __temp_dir = "tmp",
}
]]--@RUN

local M = {}

--- M.empty
-- the value meaning 'no default'
M.empty = {}

--- Parse a list of options into a lua table.
--
-- returns 'nil', as soon as any option that is not in the 'options table' is
-- encounted.
--
-- else, returns a table whose dict part contains:
--
-- * an entry 'key=value' for every '--key' and a subsequent value, and
--
-- * an entry 'option=true' for every '-option'.
--
-- the other elements are stored in the array part of the table.
--[[
-- when parsing a command args use the 'args' lua special variable
--   'opt.parse(args, defaults)'
-- but this is not the command line, so we use our own args-list
return opt.parse({"hello.c", "-q", "you.c",
    "fish.c", "--out", "hello", "--temp-dir", "/home/me/tmp"}, defaults)
]]--@RUN
function M.parse (args, defaults) 
  local options, kwarg = {}, nil
  for i, word in ipairs(args) do
    if kwarg then
      options[kwarg:gsub("-", "_")] = word
      kwarg = nil

    elseif word:sub(1,2) == "--" then
      if defaults[word:gsub("-", "_")] == nil then
        print("ERROR: unknown option '" .. kwarg .. "'")
        print()
        print("Please help yourself by typing 'docl.lua -h'")
        return
      end
      kwarg = word

    elseif word:sub(1,1) == "-" then
      if defaults[word:gsub("-", "_")] == nil then
        print("ERROR: unknown option '" .. word .. "'")
        print()
        print("Please help yourself by typing 'docl.lua -h'")
        return
      end
      options[word:gsub("-", "_")] = true

    else
      options[#options + 1] = word
    end
  end

  return options
end

--- apply the defaults of the 'options table' (see above) into the options
-- table. warn on using defaults if 'warn' is 'true'. returns nothing.
function M.apply_defaults(options, defaults, warn)
  for k,v in pairs(defaults) do
    if v ~= M.empty and options[k] == nil then
      if warn then
        print("WARNING: '"..k:gsub("_", "-").."' defaults to '"..v.."'")
      end
      options[k] = "doc"
    end
  end
end

return M
