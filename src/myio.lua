--- IO Shortcuts

local M = {}

--- Return string content of path.
function M.read(path)
  local f, err = io.open(path)
  if not f then error(err) end
  local content, err = f:read("*a")
  f:close()
  if not content then error(err) end
  return content
end

--- Write string content to path.
function M.write(path, content)
  local f, err = io.open(path, "w")
  if not f then error(err) end
  f:write(content)
  f:close()
  return true
end

--- Copy content of source to destination.
function M.copy(source, destination)
  return M.write(destination, M.read(source))
end

--- Check, whether path exists (by testing whether renaming it to itself is successful).
function M.exists(name)
  return os.rename(name, name)
end

--- Check, whether path is a file (by trying to read from it).
function M.is_file(path)
  local f = io.open(path)
  local ok = false
  if f then
    if f:read(1) then
      ok = true
    end
    f:close()
  end
  return ok
end

--- <strong>Check, whether path is a directory.</strong><br>
-- (This is done by choosing a random filename in the directory. If it exists
-- or can be created and immediately deleted, the function returns 'true', else 'nil'.)
-- <br><em>TODO Does it work under windows, too?</em>
function M.is_dir(path)
  local testpath = path .. "/" .. "test"
  return M.exists(testpath) or
    (pcall(M.write, testpath, "") and os.remove(testpath))
end

-- Alternatively
-- Check, whether path is a directory (by trying to read from it).
--function M.is_dir(path)
--  return M.exists(path) and M.read(path) == nil
--end

return M
