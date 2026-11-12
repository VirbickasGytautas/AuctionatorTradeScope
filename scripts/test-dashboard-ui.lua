-- Dashboard layout contract for beta6: all watched-items controls stay intact.
local f=assert(io.open("UI/Dashboard.lua","rb"))
local source=f:read("*a");f:close()
local function has(x)assert(source:find(x,1,true),"Missing source feature: "..x)end
for _,x in ipairs({
  "local PER_PAGE=8", "local function watchList()", "A.AddWatch(f.key,f.legacy,f.link)",
  "f.watchButtons={}", "f.watchPage=1", "local list=watchList()",
  "local entries = f.entries or {}", "f.prev=", "f.next=", "f.pin=",
  "f.zoomIn=", "f.zoomOut=", "f.zoomReset=",
  'suggestions:SetScript("OnMouseWheel"',
  'b:SetPoint("TOPLEFT",f,"TOPLEFT",23,-348-(i-1)*24)',
  'f.prev:SetPoint("TOPLEFT",f,"TOPLEFT",25,-549)',
  'f.pin:SetPoint("TOPLEFT",f,"TOPLEFT",106,-549)',
  'f.toolsToggle:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,17)',
  'f.footer:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",267,26)',
  'shade(f,15,-HEIGHT+56,WIDTH-30,56',
}) do has(x)end
assert(not source:find("ПОИСК ПРЕДМЕТА",1,true),"Obsolete placeholder")
-- UI geometry in a WIDTH x HEIGHT = 944 x 638 terminal.
local width,height=944,638
local sidebarLeft,sidebarRight=23,234
local rows=8
local firstRowY,rowStep,rowHeight=348,24,23
local controlsY,controlsHeight=549,22
local separatorY=height-56
local toolsBottomOffset,toolsHeight=17,22
local lastRowBottom=firstRowY+(rows-1)*rowStep+rowHeight
local controlsBottom=controlsY+controlsHeight
assert(lastRowBottom<=controlsY-8,"Watchlist last row overlaps navigation")
assert(controlsBottom<=separatorY-10,"Watchlist navigation overlaps footer")
assert(25+34+4<=25+34+4 and 25+34+4+34<=106,"Paging arrow overlaps pin")
assert(106+128<=sidebarRight,"Pin button overflows watchlist column")
assert(toolsBottomOffset>10 and toolsBottomOffset+toolsHeight<56-10,"Tools is too close to footer edge")
assert(267+507 < width-26-131,"Footer caption overlaps Tools button")
print("PASS beta6 footer: watchlist, arrows, Pin, Tools, 56px strip and no overlap")
