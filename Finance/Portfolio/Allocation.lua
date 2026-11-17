-- TradeScope 4.5.0-beta4: read-only distribution of a SINGLE accounting basis.
-- Bag and bank valuations, historical sale revenue, and journal cost are never
-- added together: they represent different concepts and may overlap by item.
local A=ATS
local floor,max,min=math.floor,math.max,math.min
local DAY=86400
local function finite(v)
  local n=tonumber(v)
  return n and n==n and n>=0 and n<math.huge and n or nil
end
local function add(map,key,value,qty)
  if (type(key)~="string" and type(key)~="number") or key=="" then return end
  value=finite(value)
  if not value or value<=0 then return end
  local row=map[key]
  if not row then row={key=key,value=0,qty=0};map[key]=row end
  row.value=row.value+value
  row.qty=row.qty+(finite(qty) or 0)
end

-- basis: bags | bank | cost | sales
-- Holdings valuations come only from recent observed Auctionator quotes.
-- The bank snapshot is ALWAYS last-known; it may be much older than the quote.
-- Sales basis is confirmed NET auction-mail revenue, not purchased stock.
function A.PortfolioAllocation(holdings,ledger,sales,basis,opts)
  opts=opts or {}
  basis=basis or "bags"
  if basis~="bags" and basis~="bank" and basis~="cost" and basis~="sales" then
    basis="bags"
  end
  holdings=holdings or {}
  ledger=ledger or {}
  sales=sales or {}
  local at=finite(opts.now) or (type(time)=="function" and time() or 0)
  local bankMaxAge=max(0,finite(opts.bankMaxAge) or DAY)
  local map={}
  local out={basis=basis,rows={},total=0,count=0,eligible=0,excluded=0,
    coverage=0,topShare=0,topThreeShare=0,concentration=0,
    bankAge=nil,bankStale=false,sourceAvailable=true,warnings={}}
  if basis=="bags" or basis=="bank" then
    local isBank=basis=="bank"
    if isBank then out.sourceAvailable=holdings.bankKnown==true
    else out.sourceAvailable=holdings.bagKnown==true end
    if isBank then
      local checked=finite(holdings.bankTime)
      if checked and checked<=at then
        out.bankAge=at-checked
        out.bankStale=out.bankAge>bankMaxAge
      else
        out.bankStale=out.sourceAvailable
      end
    end
    if out.sourceAvailable then
      for _,item in ipairs(type(holdings.items)=="table" and holdings.items or {}) do
        local qty=finite(isBank and item.bankQty or item.bagQty)
        if qty and qty>0 then
          out.eligible=out.eligible+1
          if item.status=="priced" then
            local value=finite(isBank and item.bankValue or item.bagValue)
            if value and value>0 then add(map,item.key,value,qty)
            else out.excluded=out.excluded+1 end
          else out.excluded=out.excluded+1 end
        end
      end
    end
  elseif basis=="cost" then
    for _,item in ipairs(type(ledger.positions)=="table" and ledger.positions or {}) do
      local cost=finite(item.cost)
      if cost and cost>0 then
        out.eligible=out.eligible+1
        add(map,item.key,cost,item.qty)
      end
    end
  else
    -- Distinct items across confirmed auction-mail sales.  Duplicate-looking
    -- messages are handled by the importer; aggregate actual accepted records.
    for _,item in ipairs(type(sales.sales)=="table" and sales.sales or {}) do
      local net=finite(item.net)
      if item.source=="auction_mail" and net and net>0 then
        add(map,item.key,net,item.qty)
      end
    end
    for _ in pairs(map) do out.eligible=out.eligible+1 end
  end
  for _,row in pairs(map) do
    out.rows[#out.rows+1]=row
    out.total=out.total+row.value
  end
  table.sort(out.rows,function(a,b)
    if a.value~=b.value then return a.value>b.value end
    return tostring(a.key)<tostring(b.key)
  end)
  out.count=#out.rows
  out.coverage=out.eligible>0 and out.count/out.eligible*100 or 0
  local sumSq=0
  for i,row in ipairs(out.rows) do
    row.share=out.total>0 and row.value/out.total*100 or 0
    sumSq=sumSq+row.share*row.share
    if i==1 then out.topShare=row.share end
    if i<=3 then out.topThreeShare=out.topThreeShare+row.share end
  end
  out.concentration=sumSq
  if not out.sourceAvailable then
    out.warnings[#out.warnings+1]="not_scanned"
  elseif out.count==0 then
    out.warnings[#out.warnings+1]="no_comparable_value"
  else
    if out.excluded>0 then out.warnings[#out.warnings+1]="partial_quotes" end
    if out.count==1 then
      out.warnings[#out.warnings+1]="single_item"
    elseif out.topShare>=50 then
      out.warnings[#out.warnings+1]="top_heavy"
    elseif out.count>=4 and out.topThreeShare>=85 then
      out.warnings[#out.warnings+1]="top_three_heavy"
    end
  end
  if out.bankStale then out.warnings[#out.warnings+1]="bank_stale" end
  -- This is an exposure indicator only; it makes NO profit prediction.
  return out
end
