for _, f in ipairs(arg) do
  local chunk, err = loadfile(f)
  assert(chunk, err)
end
print('PASS: '..#arg..' Lua files parsed')
