-- Confirmed sales get gross/net revenue even when acquisition cost is unknown.
ATS={db={pro={journal={},journalFee=5}}}
local A=ATS
function A.Init()end
function A.RealmKey()return "Realm"end
function UnitName()return "Tester"end
assert(loadfile("Finance/Journal/Ledger.lua"))()
assert(loadfile("Finance/Journal/Analysis.lua"))()
assert(loadfile("Finance/Portfolio/Sales.lua"))()
local rows={
 {key="db:1",kind="sell",qty=6,price=25000,fee=5,source="auction_mail",t=1},
 {key="db:2",kind="sell",qty=2,price=900,fee=5,source="auction_mail",t=2},
 {key="db:1",kind="buy",qty=3,price=10000,source="auction_mail",t=3},
 {key="db:1",kind="sell",qty=2,price=14000,fee=5,source="auction_mail",t=4},
 {key="db:2",kind="sell",qty=1,price=900,fee=0,t=5}, -- manual
}
local originals={}
for i,r in ipairs(rows) do originals[i]={};for k,v in pairs(r) do originals[i][k]=v end end
local s=A.PortfolioSalesReport(rows)
assert(s.count==3 and s.units==10 and s.manualCount==1 and s.manualNet==900)
assert(s.gross==150000+1800+28000)
assert(s.fees==7500+90+1400)
assert(s.net==s.gross-s.fees)
assert(s.unmatched==8 and s.matched==2 and s.knownProfit)
assert(s.realized==2*(14000*.95-10000))
assert(s.sales[1].t==4 and s.sales[3].t==1)
assert(s.sales[3].pnl==nil and s.sales[3].unmatched==6)
local noCost=A.PortfolioSalesReport({{key="db:3",kind="sell",qty=21,price=3000,fee=5,source="auction_mail",t=5}})
assert(noCost.net==21*3000*.95 and noCost.units==21)
assert(not noCost.knownProfit and noCost.realized==0 and noCost.unmatched==21)
for i,r in ipairs(rows) do
 for k,v in pairs(r) do assert(originals[i][k]==v,"modified saved row") end
 for k,v in pairs(originals[i]) do assert(r[k]==v,"removed saved field") end
end
print("PASS portfolio sales: confirmed revenue, fees, matched-only profit and manual separation")
