-- TradeScope 4.6.0-beta1 deterministic strategy engine regression.
ATS={}
local A=ATS
local now=1800000000
function time()return now end
assert(loadfile("Market/Strategies.lua"))()
local order,defs=A.StrategyKinds()
assert(#order==3 and defs.discount and defs.exit and defs.exposure)
local valid={
 key="db:2772",price=8700,median=11000,score=68,risk=31,
 quality=84,samples=28,quantity=15,volatility=24}
local weak={key="db:1206",price=2000,median=4000,score=90,risk=92,
 quality=15,samples=3,quantity=2,volatility=120}
local scanner={valid,weak}
local quotes={["db:2772"]={price=8700,t=now-600},
 ["db:1206"]={price=2000,t=now-700}}
local input={scanner=scanner,quotes=quotes,scannerTime=now-3600}
local r=A.StrategyEvaluate(input,"discount",{now=now})
assert(r.kind=="discount" and r.policy=="observation_only")
assert(r.count==1 and r.rows[1].key=="db:2772")
assert(r.rows[1].discount>20 and r.rows[1].priority>0)
assert(r.considered==2 and r.excluded==1 and r.reasons.quality_or_risk==1)
assert(input.scanner[1].score==68 and not input.scanner[1].priority)
local stale=A.StrategyEvaluate({scanner=scanner,quotes=quotes,scannerTime=now-25*3600},
 "discount",{now=now})
assert(not stale.sourceKnown and stale.count==nil and stale.reasons.scanner_stale==1)
assert(stale.considered==0 and stale.rows[1]==nil)
local noQuote=A.StrategyEvaluate({scanner={valid},scannerTime=now,quotes={
 ["db:2772"]={price=8700,t=now-7*3600}}},"discount",{now=now})
assert(#noQuote.rows==0 and noQuote.reasons.price_or_median==1)
local scanZero=A.StrategyEvaluate({scanner={valid},scannerTime=now,quotes={}},
 "discount",{now=now})
assert(#scanZero.rows==0 and scanZero.reasons.price_or_median==1)
local noSupply=A.StrategyEvaluate({scanner={{key="db:1",median=500,score=80,
 risk=15,quality=90,samples=30,volatility=8}},quotes={
 ["db:1"]={price=300,t=now}
 },scannerTime=now},"discount",{now=now})
assert(noSupply.reasons.supply_unknown==1)
local direct=A.StrategyEvaluate({positions={
 {key="db:1",qty=2,cost=10000},
 {key="db:2",qty=1,cost=0},
 {key="db:3",qty=2,cost=20000},
},quotes={
 ["db:1"]={price=7000,t=now-600},
 ["db:2"]={price=9999,t=now-10},
 ["db:3"]={price=5000,t=now-50},
},feePercent=5},"exit",{now=now})
assert(direct.kind=="exit" and #direct.rows==1)
assert(direct.rows[1].key=="db:1" and direct.rows[1].profit==3300)
assert(math.abs(direct.rows[1].roi-33)<.001)
assert(direct.reasons.cost_unknown==1 and direct.reasons.roi_too_small==1)
local missingCost=A.StrategyEvaluate({positions={{key="db:x",qty=21,cost=nil}},
 quotes={["db:x"]={price=100000,t=now}}},"exit",{now=now})
assert(#missingCost.rows==0 and missingCost.reasons.cost_unknown==1)
local concentration=A.StrategyEvaluate({allocation={sourceAvailable=true,coverage=60,
 count=3,excluded=2,rows={
 {key="db:3",value=6000,share=60,qty=30},
 {key="db:4",value=2500,share=25,qty=10},
 {key="db:5",value=1500,share=15,qty=20},
}}},"exposure",{now=now})
assert(#concentration.rows==1 and concentration.rows[1].share==60)
assert(concentration.reasons.partial_quotes==2)
assert(concentration.rows[1].coverage==60 and concentration.rows[1].source=="priced_bags")
assert(concentration.rows[1].cost==nil and concentration.rows[1].profit==nil)
local absent=A.StrategyEvaluate({allocation={sourceAvailable=false,rows={{key="db:1",share=100,value=200}}}},
 "exposure",{now=now})
assert(not absent.sourceKnown and #absent.rows==0 and absent.reasons.stock_unknown==1)
local singleton=A.StrategyEvaluate({allocation={sourceAvailable=true,count=1,
 rows={{key="db:1",share=100,value=200}}}},"exposure",{now=now})
assert(singleton.rows[1].singleItem and #singleton.rows==1)

-- Verify adapters use only pre-existing source data and do not mutate state.
local scannerTime=now-3600
A.db={pro={scannerTime=scannerTime,journalFee=5}}
A.Init=function()end
A.ProScanner=function()return scanner end
A.PortfolioLatestQuote=function(key) return quotes[key] end
A.PortfolioSnapshot=function()return {positions={{key="db:1",qty=2,cost=10000}}}end
A.PortfolioHoldings=function()return {}end
A.PortfolioAllocation=function()return {sourceAvailable=true,count=1,rows={
 {key="db:11",value=500,share=100}}}end
assert(#A.StrategySnapshot("discount").rows==1)
assert(#A.StrategySnapshot("exposure").rows==1)
assert(#A.StrategySnapshot("exit").rows==0) -- no quote for db:1
assert(A.db.pro.scannerTime==scannerTime and scanner[1].median==11000)
print("PASS strategies: fresh evidence, quality/risk gates, cost-basis ROI, exposure and read-only adapters")
