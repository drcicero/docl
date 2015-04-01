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
        print("ERROR: unknown option '" .. word .. "'")
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

local doc = require "doc"

--- apply the defaults of the 'options table' (see above) into the options
-- table.
--
-- if 'warn' is 'true', prints warnings when defaults are used.
--
-- returns nothing.
--
-- errors on unknown arguments.
function M.apply_defaults(options, defaults, allowed_args, warn)
  local t = {}
  for k,v in pairs(allowed_args) do
    local t2 = {}
    for i,v in ipairs(v) do
      t2[v[1]] = true
    end
    t[k] = t2
  end

  for k,v in pairs(defaults) do
    if v ~= M.empty and options[k] == nil then
      if warn then
        print("Info: '"..k:gsub("_", "-").."' defaults to '"..v.."'")
      end
      options[k] = v

    elseif t[k] and not t[k][options[k]] then
      local t = {}
      for i,v in ipairs(allowed_args[k]) do
        table.insert(t, "'" .. v[1] .. "'")
      end

      error({msg="unknown argument '" .. options[k] .. "' for option " .. k .. "\n  expected either of " .. table.concat(t, ", ")})
    end
  end
end

return M
