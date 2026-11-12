-- Journal 2.0 analytics: must be read-only and preserve the original entrypoints.
ATS={db={pro={journal={},journalFee=5}}}
function ATS.Init() end
function ATS.RealmKey() return "TestRealm" end
function UnitName() return "TestCharacter" end
function time() return 1700000100 end
assert(loadfile("Finance/Journal/Ledger.lua"))()
assert(loadfile("Finance/Journal/Analysis.lua"))()
local A=ATS
local t0=1700000000
local sample={
  {key="db:1",kind="buy",qty=10,price=100,fee=0,t=t0},
  {key="db:2",kind="buy",qty=2,price=50,fee=0,t=t0+1},
  {key="db:1",kind="sell",qty=4,price=180,fee=5,t=t0+2},
  {key="db:1",kind="buy",qty=10,price=200,fee=0,t=t0+3},
  {key="db:1",kind="sell",qty=12,price=250,fee=5,t=t0+4},
  {key="db:2",kind="sell",qty=3,price=100,fee=10,t=t0+5},
  {key="db:1",kind="sell",qty=6,price=100,fee=5,t=t0+6},
  {key="db:1",kind="sell",qty=-1,price=12,fee=0,t=t0+7},
}
local before={}
for i,row in ipairs(sample) do
  before[i]={}
  for k,v in pairs(row) do before[i][k]=v end
end
local r=A.JournalAnalysis(sample)
assert(#r.entries==7 and r.skipped==1)
assert(r.buys==22 and r.sells==25 and r.unmatched==3 and r.matched==22)
assert(r.openUnits==0)
-- Weighted average: first sale (4 * (171-100)) = 284.
-- Next sale matches 12 * (237.5-162.5) = 900.
-- Item 2 sale matches 2 * (90-50) = 80, one unmatched.
-- Last item 1 sale matches 4 * (95-162.5) = -270, two unmatched.
assert(math.abs(r.realized-(284+900+80-270))<0.00001)
assert(r.byItem["db:1"].unmatched==2 and r.byItem["db:2"].unmatched==1)
assert(r.byItem["db:1"].matched==20 and r.byItem["db:2"].matched==2)
assert(r.fees==720*0.05+3000*0.05+300*0.10+600*0.05)
local f=A.JournalAnalysis(sample,{fromTime=t0+4,toTime=t0+4,itemKey="db:1"})
assert(#f.entries==1 and f.sells==12 and f.buys==0)
assert(math.abs(f.realized-900)<0.00001) -- Cost basis includes earlier purchases.
assert(f.openUnits==0) -- Inventory ignores display filters.
for i,row in ipairs(sample) do
  for k,v in pairs(before[i]) do assert(row[k]==v,"input was modified: "..tostring(k)) end
  for k,v in pairs(row) do assert(before[i][k]==v,"extra mutated field: "..tostring(k)) end
end
-- Legacy public storage/reports remain callable after module extraction.
assert(A.AddJournalTrade("db:8","buy",2,100,5))
local ledger=A.ProJournal()
assert(#ledger==1 and ledger[1].qty==2)
assert(A.JournalReport().spent==200)
A.DeleteJournalTrade(1)
assert(#A.ProJournal()==0)
print("PASS: read-only journal breakdown, cost basis, time filters, fees, unmatched and legacy APIs")

-- Beta3: precise filtered accounting, original indexes and pagination.
local sellOnly=A.JournalAnalysis(sample,{kind="sell"})
assert(#sellOnly.entries==4 and sellOnly.buys==0 and sellOnly.spent==0)
assert(sellOnly.entries[1].index==3 and sellOnly.entries[4].index==7)
assert(sellOnly.entries[1].costBasis==400 and sellOnly.entries[1].pnl==284)
assert(math.abs(sellOnly.entries[1].roi-71)<0.00001)
assert(sellOnly.entries[3].unmatched==1 and sellOnly.entries[4].unmatched==2)
assert(math.abs(sellOnly.realized-r.realized)<0.00001)
assert(sellOnly.positions["db:1"].qty==0 and sellOnly.positions["db:2"].qty==0)
local itemOnly=A.JournalAnalysis(sample,{itemKey="db:2"})
assert(#itemOnly.entries==2 and itemOnly.buys==2 and itemOnly.matched==2)
assert(itemOnly.unmatched==1 and itemOnly.byItem["db:1"]==nil)
assert(itemOnly.openUnits==0)
local unmatchedOnly=A.JournalAnalysis({{key="db:77",kind="sell",qty=2,price=150,fee=5,t=2}})
assert(unmatchedOnly.entries[1].pnl==nil and unmatchedOnly.entries[1].roi==nil)
assert(unmatchedOnly.realized==0 and unmatchedOnly.unmatched==2)
local zeroCost=A.JournalAnalysis({
  {key="db:1",kind="buy",qty=1,price=0,t=1},
  {key="db:1",kind="sell",qty=1,price=150,t=2,fee=0},
})
assert(zeroCost.realized==150 and zeroCost.roi==nil and zeroCost.entries[2].roi==nil)
local badFee=A.JournalAnalysis({
  {key="db:3",kind="buy",qty=1,price=100,t=1},
  {key="db:3",kind="sell",qty=1,price=200,fee=200,t=2},
})
assert(badFee.entries[2].fees==200 and badFee.entries[2].pnl==-100)
local paging={}
for i=1,22 do paging[i]={index=i} end
local first,page,pages=A.JournalPage(paging,1,8)
assert(page==1 and pages==3 and #first==8 and first[1].index==22 and first[8].index==15)
local last,lastPage,lastPages=A.JournalPage(paging,30,8)
assert(lastPage==3 and lastPages==3 and #last==6 and last[1].index==6 and last[6].index==1)
local none,emptyPage,emptyPages=A.JournalPage({},1,8)
assert(#none==0 and emptyPage==1 and emptyPages==1)
-- Legacy report must not decorate stored trades with transient _pnl fields.
A.AddJournalTrade("db:8","buy",2,100,0)
A.AddJournalTrade("db:8","sell",1,250,5)
local rows=A.ProJournal()
assert(rows[2]._pnl==nil)
local legacy=A.JournalReport()
assert(legacy.realized==137.5 and legacy.unmatched==0)
assert(rows[2]._pnl==nil and rows[1]._pnl==nil)
print("PASS beta3 journal filters, realized P&L, zero basis, paging and saved-row immutability")
