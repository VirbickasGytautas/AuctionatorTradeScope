-- 4.5.0-beta4: do not double-count physical stock, sales and manual cost.
ATS={}
function time() return 1700000000 end
assert(loadfile('Finance/Portfolio/Allocation.lua'))()
local A=ATS
local now=time()
local holdings={bagKnown=true,bankKnown=true,bankTime=now-25*3600,
 items={
  {key='db:1',bagQty=4,bankQty=10,status='priced',bagValue=600,bankValue=1500},
  {key='db:2',bagQty=2,bankQty=0,status='priced',bagValue=200,bankValue=0},
  {key='db:3',bagQty=6,bankQty=0,status='stale'},
  {key='db:4',bagQty=1,bankQty=2,status='missing'},
  {key='db:5',bagQty=4,bankQty=5,status='priced',bagValue=100,bankValue=125},
 }}
local journal={positions={
 {key='db:1',cost=500,qty=5},{key='db:2',cost=500,qty=10},{key='db:3',cost=0,qty=3},
 }}
local sales={sales={
 {key='db:1',net=150,qty=1,source='auction_mail'},
 {key='db:1',net=50,qty=1,source='auction_mail'},
 {key='db:2',net=200,qty=2,source='auction_mail'},
 {key='db:8',net=400,qty=8,source='manual'}, -- do not count manual sale
 }}
local old=holdings.items[1].bagValue
local bags=A.PortfolioAllocation(holdings,journal,sales,'bags',{now=now})
assert(bags.count==3 and bags.eligible==5 and bags.excluded==2)
assert(bags.total==900 and bags.rows[1].key=='db:1')
assert(math.abs(bags.topShare-600/900*100)<0.000001)
assert(bags.warnings[1]=='partial_quotes' and bags.warnings[2]=='top_heavy')
assert(bags.sourceAvailable and not bags.bankStale)
local bank=A.PortfolioAllocation(holdings,journal,sales,'bank',{now=now})
assert(bank.total==1625 and bank.eligible==3 and bank.excluded==1)
assert(bank.count==2 and bank.bankStale and bank.bankAge==25*3600)
assert(bank.warnings[#bank.warnings]=='bank_stale')
local cost=A.PortfolioAllocation(holdings,journal,sales,'cost',{now=now})
assert(cost.total==1000 and cost.count==2 and cost.rows[1].key=='db:1')
assert(cost.topShare==50 and cost.concentration==5000)
local confirmed=A.PortfolioAllocation(holdings,journal,sales,'sales',{now=now})
assert(confirmed.total==400 and confirmed.count==2)
assert(confirmed.rows[1].key=='db:1' and confirmed.rows[1].qty==2)
assert(confirmed.rows[2].key=='db:2' and confirmed.rows[2].qty==2)
assert(confirmed.rows[1].share==50 and confirmed.topThreeShare==100)
local blank=A.PortfolioAllocation({bagKnown=false,items=holdings.items},journal,sales,'bags')
assert(blank.count==0 and blank.total==0 and not blank.sourceAvailable)
assert(blank.warnings[1]=='not_scanned')
local single=A.PortfolioAllocation({bagKnown=true,items={
 {key='db:99',bagQty=9,status='priced',bagValue=500}}},nil,nil,'bags')
assert(single.count==1 and single.warnings[1]=='single_item')
local unpriced=A.PortfolioAllocation({bagKnown=true,items={
 {key='db:77',bagQty=3,status='missing'}}},nil,nil,'bags')
assert(unpriced.count==0 and unpriced.excluded==1 and unpriced.eligible==1)
local future=A.PortfolioAllocation({bankKnown=true,bankTime=now+10,items={
 {key='db:1',bankQty=2,status='priced',bankValue=20}}},nil,nil,'bank',{now=now})
assert(future.bankStale and future.rows[1].value==20)
assert(holdings.items[1].bagValue==old and sales.sales[1].net==150)
assert(journal.positions[1].cost==500)
print('PASS allocation: 4 independent bases, coverage, concentrations, old bank, exclusions, immutable inputs')
