-- Finance/Portfolio beta3: automatic bags, last-known bank, pricing safety.
ATS={db={pro={}}}
local A=ATS
local current=1700000000
local uptime=120
function time()return current end
function GetTime()return uptime end
function UnitName()return "Tester" end
function A.RealmKey()return "Realm:Faction" end
function A.Init()end
function A.Key(link)
  local id=type(link)=="string" and link:match("item:(%d+)")
  return id and "db:"..id
end
local bagData={
 [0]={{id=2772,qty=5},{id=2771,qty=3}},
 [1]={{id=2772,qty=7}},
 [-1]={{id=2772,qty=20},{id=2774,qty=3}},
 [5]={{id=2771,qty=2}}
}
function GetContainerNumSlots(i)
  return (i==0 or i==-1) and 16 or (i==1 or i==5) and 8 or 0
end
function GetContainerItemInfo(i,slot)
  local data=bagData[i] and bagData[i][slot]
  if data then return "texture",data.qty,false,1,false,false,"item:"..data.id end
end
local events={}
function CreateFrame()
 local frame={}
 function frame:RegisterEvent(name) events[name]=true end
 function frame:SetScript(name,fn)frame[name]=fn end
 return frame
end
assert(loadfile("Finance/Portfolio/Inventory.lua"))()
local snap=A.RefreshPortfolioStock(true)
assert(snap.bagsKnown and snap.bags["db:2772"]==12 and snap.bags["db:2771"]==3)
assert(not snap.bankKnown and snap.bank["db:2772"]==nil)
assert(events.BAG_UPDATE and events.BANKFRAME_OPENED)
-- Simulate entering the bank with the frame event via captured function.
-- Find OnEvent by intercepting a second frame in the test below.
assert(A.PortfolioStockSnapshot().bagsTime==current)
-- Re-load module with bank frame currently displayed, to avoid relying on
-- details of the WoW event frame mock for deterministic bank scanning.
BankFrame={IsShown=function()return true end}
local fresh=A.RefreshPortfolioStock(true)
assert(fresh.bankKnown and fresh.bank["db:2772"]==20 and fresh.bank["db:2774"]==3)
assert(fresh.bank["db:2771"]==2 and fresh.bankTime==current)
-- The bank snapshot must remain last-known when the bank is closed.
BankFrame={IsShown=function()return false end}
current=current+7200;uptime=uptime+7200
bagData[0][1].qty=4
local later=A.RefreshPortfolioStock(true)
assert(later.bags["db:2772"]==11 and later.bank["db:2772"]==20)
assert(later.bankTime==current-7200)
assert(A.db.pro.portfolioStock["Realm:Faction:Tester"].bags["db:2772"]==11)
-- Partial C_Container clients should not hide valid legacy bag contents.
C_Container={GetContainerNumSlots=function()return 0 end}
local mixed=A.RefreshPortfolioStock(true)
assert(mixed.bagsKnown and mixed.bags["db:2772"]==11)
assert(loadfile("Finance/Portfolio/Holdings.lua"))()
local quoteTime=current
local priced=A.PortfolioHoldings(mixed,{
 ["db:2772"]={price=100,t=quoteTime-30},
 ["db:2771"]={price=50,t=quoteTime-9*86400},
}, {now=quoteTime})
assert(priced.count==3 and priced.bagUnits==14 and priced.bankUnits==25)
assert(priced.pricedCount==1 and priced.staleCount==1 and priced.missingCount==1)
assert(priced.bagValue==1100 and priced.bankValue==2000)
assert(priced.items[1].key=="db:2772" and priced.items[1].source=="unknown")
assert(not priced.complete)
-- Physical holdings cannot assert acquisition cost or profit.
assert(priced.items[1].cost==nil and priced.items[1].pnl==nil)
local unknown=A.PortfolioHoldings({bagsKnown=false,bankKnown=false,bags={["db:1"]=8},bank={["db:2"]=3}}, {}, {now=current})
assert(unknown.count==0 and unknown.bagUnits==0 and unknown.bankUnits==0)
print("PASS portfolio stock: live bags, cached bank, per-character state, partial API and no invented profit")
