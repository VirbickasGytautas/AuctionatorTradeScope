-- Trading Portfolio widget smoke: layout, navigation, missing quotes and refresh.
ATS={db={pro={journalFee=5}}}
local A=ATS
local function widget(text)
  local w={text=text or "",visible=true,scripts={}}
  function w:SetText(t)self.text=t end
  function w:GetText()return self.text end
  function w:SetEnabled(t)self.enabled=t end
  function w:SetScript(n,fn)self.scripts[n]=fn end
  function w:Show()self.visible=true end
  function w:Hide()self.visible=false end
  function w:GetFontString()return self end
  return w
end
local function btn(p,text,x,y,width,fn)
  local b=widget(text)
  b:SetScript("OnClick",fn)
  return b
end
local function label(p,t) return widget(t) end
local function page(root)return {} end
local function list(p,n)
  local entries={};for i=1,n do entries[i]=widget() end;return entries
end
local function money(n)return tostring(n) end
A.ProUIShared={l=function(en)return en end,fs=label,button=btn,newPage=page,
  heading=function()end,lineList=list,tex=function()end,currency=money}
A.ProUIBuilders={}
A.ProItemName=function(key)return "Item "..key end
A.FitItemName=function(x)return x end
A.ProItemLink=function(key)return "item:123" end
A.OpenDashboardScanKey=function(key) A.opened=key end
A.ShowProTab=function(key) A.tab=key end
local data={positions={},openCount=9,openUnits=18,invested=900,
  markedCount=7,unpricedCount=1,staleCount=1,
  marketValue=1050,estimatedNet=997.5,unrealized=97.5,
  realized=150,feePercent=5}
for i=1,9 do
  data.positions[i]={key="db:"..i,qty=2,cost=100,avgCost=50,
    pnl=i*2,status="priced",weight=100/9}
end
data.positions[8].status="stale";data.positions[9].status="missing"
A.PortfolioSnapshot=function()return data end
assert(loadfile("UI/Pro/Pages/Portfolio.lua"))()
local p=A.ProUIBuilders.portfolio({})
assert(p.overview.text:find("Open: 9",1,true))
assert(p.pricing.text:find("Valued: 7 / 9",1,true))
assert(p.realized.text:find("Unrealized",1,true))
assert(p.rows[1].visible and p.rows[1].text:find("Item db:1",1,true))
assert(p.rows[6].visible and p.pageText.text=="Page 1 / 2")
assert(p.prev.enabled==false and p.next.enabled==true)
p.rows[1].scripts.OnClick()
assert(A.opened=="db:1")
p.next.scripts.OnClick()
assert(p.pageIndex==2 and p.pageText.text=="Page 2 / 2")
assert(p.rows[1].text:find("Item db:7",1,true))
assert(p.rows[2].text:find("STALE",1,true))
assert(p.rows[3].text:find("NO PRICE",1,true))
assert(not p.rows[4].visible)
assert(p.prev.enabled==true and p.next.enabled==false)
p.prev.scripts.OnClick()
assert(p.pageIndex==1)
data.positions={};data.openCount=0;data.openUnits=0
p.update()
assert(p.empty.visible and not p.rows[1].visible and p.pageText.text=="Page 1 / 1")
assert(p.prev.enabled==false and p.next.enabled==false)
print("PASS portfolio UI: list, paging, detail routing, incomplete prices and empty state")
