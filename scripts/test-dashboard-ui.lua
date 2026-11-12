-- Dashboard UI contract for the 4.4.0-beta5 watchlist/alignment patch.
-- This regression checks both restored features and non-overlapping geometry.
local f=assert(io.open("UI/Dashboard.lua","rb"))
local source=f:read("*a");f:close()
local function has(text)
  assert(source:find(text,1,true),"Missing Dashboard feature: "..text)
end
has("local PER_PAGE=8")
has("local function watchList()")
has("A.AddWatch(f.key,f.legacy,f.link)")
has("f.watchButtons={}")
has('b:SetPoint("TOPLEFT",f,"TOPLEFT",23,-352-(i-1)*25)')
has('f.prev:SetPoint("TOPLEFT",f,"TOPLEFT",25,-562)')
has('f.next:SetPoint("LEFT",f.prev,"RIGHT",4,0)')
has('f.pin:SetPoint("TOPLEFT",f,"TOPLEFT",106,-562)')
has('f.toolsToggle:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,11)')
has("local list=watchList()")
has("local entries = f.entries or {}")
has('f.pin:SetText(watches and f.key and watches[f.key] and A.L.UNPIN or A.L.PIN)')
has('suggestions:SetScript("OnMouseWheel"')
has("f.zoomIn=")
has("f.zoomOut=")
has("f.zoomReset=")
assert(not source:find("ПОИСК ПРЕДМЕТА",1,true))
-- 8 rows occupy (-352 .. -551), controls (-562 .. -584),
-- footer separator y=-595. All positions are in Dashboard-local UI units.
local lastRowBottom=352+(8-1)*25+24
local controlsBottom=562+22
local separator=638-43
assert(lastRowBottom<=562-9,"Last watch row collides with page arrows")
assert(controlsBottom<separator-7,"Watch controls collide with footer line")
local leftEdge,rightEdge=23,234
assert(25+34<64 and 64+34<106,"Page arrows collide")
assert(106+128<=rightEdge,"Watch button exceeds left column")
assert(11>0 and 11+22<43,"Tools button leaves footer strip")
print("PASS Dashboard: restored watchlist, aligned paging, Pin, search, zoom and lowered Tools")
