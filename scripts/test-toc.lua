local toc=assert(io.open("AuctionatorTradeScope.toc","rb"))
local seen,loaded={},{}
for line in toc:lines() do
  line=line:gsub("\r", "")
  if line:match("^[^#%s].*%.lua%s*$") then
    local path=line:gsub("\\","/")
    assert(not seen[path], "Duplicate TOC file "..path)
    seen[path]=true
    local fd=assert(io.open(path,"rb"),"Missing TOC source "..path)
    fd:close()
    local fn,err=loadfile(path)
    assert(fn,err)
    loaded[#loaded+1]=path
  end
end
toc:close()
assert(#loaded==31,"Expected 31 source files, found "..#loaded)
assert(loaded[1]=="Engine/Core.lua")
assert(loaded[#loaded]=="UI/Minimap.lua")
print("PASS TOC: "..#loaded.." Lua sources exist in load order and parse")
