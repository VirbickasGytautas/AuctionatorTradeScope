-- Beta3 portfolio screen: source-separated inventory, sales, journal positions.
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
local buttons={}
local function button(p,text,x,y,width,fn)
 local w=widget(text);w:SetScript("OnClick",fn);buttons[#buttons+1]=w;return w
end
local function fs(_,text)return widget(text)end
local function lineList(_,count)
 local list={};for i=1,count do list[i]=widget() end;return list
end
A.ProUIShared={l=function(en)return en end,fs=fs,button=button,
 newPage=function()return {}end,heading=function()end,lineList=lineList,
 tex=function()end,currency=function(n)return tostring(n)end}
A.ProUIBuilders={}
function A.ProItemName(key)return "Item "..key end
function A.FitItemName(s)return s end
function A.ProItemLink()return "item:55"end
function A.OpenDashboardScanKey(key)A.lastKey=key end
function A.ShowProTab(t)A.tab=t end
function time()return 1700000000 end
local stock={items={},count=9,bagKnown=true,bankKnown=false,bagUnits=90,
  bankUnits=0,bankValue=0,bagValue=960,bagsTime=time(),pricedCount=9}
for i=1,9 do stock.items[i]={key="db:"..i,bagQty=i,bankQty=0,
  status="priced",bagValue=i*20,bankValue=0,price=20,quoteAge=0} end
A.PortfolioHoldings=function()return stock end
A.RefreshPortfolioStock=function()A.refreshed=(A.refreshed or 0)+1 end
local sales={sales={},count=2,units=21,gross=30000,fees=1500,net=28500,
  realized=0,matched=0,unmatched=21}
for i=1,2 do sales.sales[i]={key="db:"..i,qty=i,net=1000*i,
  unmatched=i,matched=0,gross=i*1500,fees=i*75,t=i}end
A.PortfolioSalesReport=function()return sales end
local ledger={positions={{key="db:100",qty=2,cost=500,avgCost=250,
   pnl=100,status="priced",netValue=600,price=300,roi=20}},
 openCount=1}
A.PortfolioSnapshot=function()return ledger end
assert(loadfile("UI/Pro/Pages/Portfolio.lua"))()
local p=A.ProUIBuilders.portfolio({})
assert(p.mode=="stock" and p.sales.text:find("Confirmed AH sales: 2",1,true))
assert(p.revenue.text:find("NET REVENUE: 28500",1,true))
assert(p.profit.text:find("unknown",1,true) and p.profit.text:find("21",1,true))
assert(p.stock.text:find("Bags: 90",1,true))
assert(p.rows[1].text:find("Bags 1",1,true))
assert(p.pageText.text=="Page 1 / 2")
assert(p.prev.enabled==false and p.next.enabled==true)
p.next.scripts.OnClick();assert(p.pageIndex==2)
p.salesMode.scripts.OnClick()
assert(p.mode=="sales" and p.pageIndex==1)
assert(p.rows[1].text:find("COST UNKNOWN",1,true))
assert(p.rows[3].visible==false)
p.ledgerMode.scripts.OnClick()
assert(p.mode=="ledger" and p.rows[1].text:find("Cost 500",1,true))
assert(p.rows[2].visible==false)
assert(p.realized==nil and p.profit.text:find("unknown",1,true))
p.stockMode.scripts.OnClick()
assert(p.mode=="stock")
for _,b in ipairs(buttons) do if b.text=="Refresh" then b.scripts.OnClick() end end
assert(A.refreshed>=2)
stock.items={};stock.count=0;stock.bagKnown=false;stock.bagUnits=0
p.update();assert(p.empty.visible and p.empty.text:find("unavailable",1,true))
print("PASS portfolio UI: sales revenue, unknown profit, three modes and pagination")
