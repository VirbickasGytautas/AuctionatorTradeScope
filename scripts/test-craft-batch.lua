-- Runs with texlua; price and inventory sources are deterministic test doubles.
ATS={locale="enUS",db={pro={journalFee=5,craftInventoryEnabled=true,craftExcluded={},craftStock={},recipes={}}}}
local A=ATS
function A.Init() end
function A.RealmKey() return "TestRealm" end
function A.Valid(n) return type(n)=="number" and n>0 end
assert(loadfile('MarketPro.lua'))()
local prices={[1]=100,[2]=300,[99]=700}
A.GetProAuctionPrice=function(id) return prices[tonumber(id)] end
local stocks={[1]=5,[2]=1}
local calls={}
A.CraftOwnedCount=function(id)
  calls[id]=(calls[id] or 0)+1
  local n=stocks[id] or 0
  return n,0,123,n
end
local recipe={product=99,made=2,materials={{id=1,qty=2,name="A"},{id=2,qty=1,name="B"},{id=1,qty=1,name="A"}}}
local r=A.EvaluateCraftBatch(recipe,3)
assert(r.craftCount==3 and r.quantity==6 and r.outputPerCraft==2)
assert(r.marketCost==1800 and r.cashCost==1000 and r.net==3990)
assert(r.marketProfit==2190 and r.cashProfit==2990)
assert(math.abs(r.roi-(2190/1800*100))<.00001)
assert(r.rows[1].qty==6 and r.rows[1].own==5 and r.rows[1].buy==1)
assert(r.rows[3].qty==3 and r.rows[3].own==0 and r.rows[3].buy==3)
assert(r.rows[2].qty==3 and r.rows[2].own==1 and r.rows[2].buy==2)
assert(#r.shoppingList==2)
assert(r.shoppingList[1].qty==4 and r.shoppingList[2].qty==2)
assert(calls[1]==1 and calls[2]==1)
local r1=A.EvaluateRecipeWithInventory(recipe)
assert(r1.quantity==2 and r1.marketCost==600 and r1.cashCost==0)
assert(r1.rows[1].qty==2)
A.db.pro.craftInventoryEnabled=false
local off=A.EvaluateCraftBatch(recipe,2)
assert(off.marketCost==1200 and off.cashCost==1200)
assert(off.shoppingList[1].qty==6 and off.shoppingList[2].qty==2)
A.db.pro.craftInventoryEnabled=true
prices[2]=nil;stocks[2]=10
local missing=A.EvaluateCraftBatch(recipe,3)
assert(missing.marketCost==nil and missing.marketProfit==nil and missing.roi==nil)
assert(missing.cashCost==400 and #missing.missingCash==0)
-- Excluded ingredients should have no purchase or cost, while the UI warns.
A.SetRecipeIngredientIncluded(recipe,2,false)
local excluded=A.EvaluateCraftBatch(recipe,3)
assert(excluded.excluded==1 and excluded.rows[2].buy==0)
assert(excluded.marketCost==900 and excluded.cashCost==400)
assert(A.EvaluateCraftBatch(recipe,0).craftCount==1)
assert(A.EvaluateCraftBatch(recipe,10000).craftCount==999)
print("PASS batch calculations, repeated reagents, ROI, stock, unknown quotes, exclusions, clamp")
