-- Test the journal page filter/button integration with WoW-independent widgets.
ATS={locale="enUS",db={pro={journal={},journalFee=5}}}
local A=ATS
local now=1700000000
function time()return now end
function date(_,n)return tostring(n) end
function UnitName()return "Tester" end
function A.Init()end
function A.RealmKey()return "Realm" end
function A.ProItemName(key)return "Item "..key end
function A.FitItemName(n) return n end
A.Money=function(n)return tostring(n)end
local function w(text)
  local o={text=text or "",shown=true,scripts={}}
  function o:SetText(value)self.text=value end
  function o:GetText()return self.text end
  function o:SetScript(event,fn)self.scripts[event]=fn end
  function o:GetScript(event)return self.scripts[event] end
  function o:Show()self.shown=true end
  function o:Hide()self.shown=false end
  function o:GetFontString()return self end
  return o
end
local function button(p,label,x,y,width,fn)
  local o=w(label)
  o:SetScript("OnClick",fn)
  p.buttons[#p.buttons+1]=o
  return o
end
local function fs(p,label)return w(label)end
local function edit(p,_,x,y,width,value)return w(value)end
local function marketInput(p)return w("")end
local function newPage(root)return {buttons={}} end
local function lineList(p,n)
  local rows={}
  for i=1,n do rows[i]=button(p,"") end
  return rows
end
A.ProUIShared={l=function(en) return en end,fs=fs,button=button,edit=edit,
  marketInput=marketInput,anyItem=function(p)return p.selection.itemKey end,
  fillMarketEdit=function(e,v)e.itemKey=v.key;e:SetText(v.text)end,
  shareMarketChoice=function()end,
  newPage=newPage,heading=function()end,lineList=lineList,
  currency=function(value)return value and tostring(value) or "-" end}
A.ProUIBuilders={}
assert(loadfile("Finance/Journal/Ledger.lua"))()
assert(loadfile("Finance/Journal/Analysis.lua"))()
assert(loadfile("UI/Pro/Pages/Journal.lua"))()
local key="Realm:Tester"
local data={}
-- 22 sequential manual trades; alternate items and sides; one week contains 7 records.
for i=1,22 do
  data[i]={key=(i%2==0) and "db:2" or "db:1",
    kind=(i%3==0) and "sell" or "buy",qty=1,
    price=100,fee=5,t=now-(22-i)*86400}
end
A.db.pro.journal[key]=data
local p=A.ProUIBuilders.journal({})
assert(p.total.text:find("Realized P&L",1,true))
assert(p.pageText.text=="Page 1 / 3")
assert(p.rows[1].text:find("db:2",1,true))
assert(p.rows[8].shown)
p.next.scripts.OnClick()
assert(p.pageIndex==2 and p.pageText.text=="Page 2 / 3")
p.kindFilter.scripts.OnClick()
assert(p.filter.kind=="buy" and p.pageIndex==1)
assert(p.filterSummary.text:find("Records: 15",1,true))
p.kindFilter.scripts.OnClick()
assert(p.filter.kind=="sell" and p.filterSummary.text:find("Records: 7",1,true))
p.itemFilter.scripts.OnClick()
assert(p.filter.onlyItem and p.filterSummary.text:find("Records: 0",1,true))
p.selection.itemKey="db:1"
p.update()
assert(p.filterSummary.text:find("Records: 4",1,true))
p.timeFilter.scripts.OnClick()
assert(p.filter.periodIndex==2)
assert(p.filterSummary.text:find("Records: 2",1,true))
p.clearFilter.scripts.OnClick()
assert(not p.filter.onlyItem and p.filter.kind=="all" and p.filter.periodIndex==1)
assert(p.filterSummary.text:find("Records: 22",1,true))
assert(p.pageIndex==1)
local before=#data
-- Creating a trade changes only the journal itself, not filter state keys.
p.selection.itemKey="db:5"
p.qty:SetText("2");p.gold:SetText("1");p.silver:SetText("2");p.copper:SetText("3")
local buy
for _,b in ipairs(p.buttons) do if b.text=="Record BUY" then buy=b end end
assert(buy)
buy.scripts.OnClick()
assert(#data==before+1 and data[#data].key=="db:5" and data[#data].price==10203)
assert(A.db.pro.filter==nil and A.db.pro.journalFilter==nil)
print("PASS journal UI filters, pagination, buy/sell workflow, and unsaved UI state")
