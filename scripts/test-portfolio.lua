-- 4.5.0-beta1: deterministic, read-only manual portfolio accounting.
ATS={db={pro={journal={},journalFee=5}}}
local A=ATS
function A.Init()end
function A.RealmKey()return "Realm" end
function UnitName()return "Tester" end
function time()return 1700001000 end
assert(loadfile("Finance/Journal/Ledger.lua"))()
assert(loadfile("Finance/Journal/Analysis.lua"))()
assert(loadfile("Finance/Portfolio/Positions.lua"))()
local now=time()
local rows={
 {key="db:1",kind="buy",qty=10,price=100,fee=0,t=now-1000},
 {key="db:1",kind="sell",qty=4,price=150,fee=5,t=now-900},
 {key="db:2",kind="buy",qty=3,price=200,fee=0,t=now-800},
 {key="db:2",kind="sell",qty=10,price=300,fee=5,t=now-700},
 {key="db:3",kind="buy",qty=2,price=1000,fee=0,t=now-600},
 {key="db:4",kind="buy",qty=1,price=400,fee=0,t=now-500},
}
local backup={}
for i,r in ipairs(rows) do
  backup[i]={};for k,v in pairs(r) do backup[i][k]=v end
end
local quotes={
 ["db:1"]={price=120,t=now-60},
 ["db:2"]={price=500,t=now-30},
 ["db:3"]={price=1500,t=now-9*86400},
 -- db:4 deliberately missing
}
local r=A.PortfolioSnapshot(rows,quotes,{now=now,feePercent=5})
assert(r.openCount==3 and r.openUnits==9 and r.unmatched==7)
assert(r.invested==3000 and r.markedCount==1 and r.staleCount==1 and r.unpricedCount==1)
assert(r.positions[1].key=="db:3" and r.positions[1].status=="stale")
assert(r.positions[2].key=="db:1" and r.positions[2].qty==6)
assert(r.positions[3].key=="db:4" and r.positions[3].status=="missing")
assert(r.marketValue==720 and r.markedCost==600 and r.estimatedNet==684)
assert(r.unrealized==84 and not r.complete)
assert(math.abs(r.positions[2].roi-14)<0.0000001)
assert(r.realized==4*(150*.95-100)+3*(300*.95-200))
local fresh=A.PortfolioSnapshot(rows,quotes,{now=now,maxQuoteAge=10*86400,feePercent=0})
assert(fresh.markedCount==2 and fresh.unpricedCount==1)
assert(fresh.marketValue==3720 and fresh.markedCost==2600 and fresh.unrealized==1120)
local empty=A.PortfolioSnapshot({}, {}, {now=now})
assert(empty.openCount==0 and empty.complete and empty.invested==0)
-- Future quote cannot silently enter the portfolio.
local future=A.PortfolioSnapshot(rows,{["db:1"]={price=999,t=now+1}},{now=now})
assert(future.unpricedCount==3 and future.staleCount==0)
-- Quoted rows never mutate trade history or market quotes.
for i,row in ipairs(rows) do
  for k,v in pairs(backup[i]) do assert(row[k]==v, "saved row mutated") end
  for k,v in pairs(row) do assert(backup[i][k]==v, "saved row field added") end
end
assert(quotes["db:1"].price==120 and quotes["db:3"].t==now-9*86400)
-- Current character journal is the default, no cross-character merges.
A.db.pro.journal["Realm:Tester"]={{key="db:7",kind="buy",qty=2,price=10,t=now-20}}
local own=A.PortfolioSnapshot(nil,{["db:7"]={price=15,t=now}},{now=now})
assert(own.openCount==1 and own.positions[1].key=="db:7")
print("PASS portfolio: open lots, matched sells, stale/missing prices, fees, ROI, no data mutation")
