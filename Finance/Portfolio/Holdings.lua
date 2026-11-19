-- TradeScope 4.5.0-beta3: price *physical* stock separately from purchase lots.
-- Provenance of items in bags/bank is UNKNOWN; never equate valuation to profit.
local A=ATS
local max=math.max
local function finite(n)
  n=tonumber(n)
  return n and n==n and n>=0 and n<math.huge and n or nil
end
-- Input snapshots/quotes optional for deterministic tests. Bank counts are
-- explicitly labelled last-known; included only in a separate subtotal.
function A.PortfolioHoldings(snapshot,quotes,opts)
  snapshot=snapshot or (A.PortfolioStockSnapshot and A.PortfolioStockSnapshot()) or {}
  opts=opts or {}
  local at=finite(opts.now) or (type(time)=="function" and time() or 0)
  local maxAge=max(0,finite(opts.maxQuoteAge) or 7*86400)
  local result={items={},bagUnits=0,bankUnits=0,bagKnown=snapshot.bagsKnown==true,
    bankKnown=snapshot.bankKnown==true,bagsTime=snapshot.bagsTime,
    bankTime=snapshot.bankTime,bankOpen=snapshot.bankOpen,
    bagValue=0,bankValue=0,pricedCount=0,staleCount=0,missingCount=0}
  local merged={}
  local function add(source,kind)
    for key,qty in pairs(type(source)=="table" and source or {}) do
      qty=finite(qty)
      if qty and qty>0 and qty==math.floor(qty) then
        local row=merged[key] or {key=key,bagQty=0,bankQty=0,source="unknown"}
        row[kind]=row[kind]+qty
        merged[key]=row
      end
    end
  end
  if result.bagKnown then add(snapshot.bags,"bagQty") end
  if result.bankKnown then add(snapshot.bank,"bankQty") end
  for key,row in pairs(merged) do
    local quote=quotes and quotes[key] or (not quotes and A.PortfolioLatestQuote and A.PortfolioLatestQuote(key,at))
    local price=type(quote)=="table" and finite(quote.price)
    local ts=type(quote)=="table" and finite(quote.t)
    row.status="missing"
    if price and price>0 and ts and ts<=at then
      row.price=price;row.quoteAge=at-ts
      if row.quoteAge<=maxAge then
        row.status="priced"
        row.bagValue=row.bagQty*price
        row.bankValue=row.bankQty*price
        result.pricedCount=result.pricedCount+1
        result.bagValue=result.bagValue+row.bagValue
        result.bankValue=result.bankValue+row.bankValue
      else result.staleCount=result.staleCount+1 end
    else result.missingCount=result.missingCount+1 end
    result.bagUnits=result.bagUnits+row.bagQty
    result.bankUnits=result.bankUnits+row.bankQty
    result.items[#result.items+1]=row
  end
  table.sort(result.items,function(a,b)
    local av=(a.bagValue or 0)+(a.bankValue or 0)
    local bv=(b.bagValue or 0)+(b.bankValue or 0)
    if av~=bv then return av>bv end
    if a.bagQty~=b.bagQty then return a.bagQty>b.bagQty end
    return tostring(a.key)<tostring(b.key)
  end)
  result.count=#result.items
  result.complete=result.pricedCount==result.count
  return result
end
