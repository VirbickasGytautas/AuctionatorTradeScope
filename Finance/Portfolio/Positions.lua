-- TradeScope 4.5.0-beta1: read-only portfolio derived from manual journal lots.
-- Historical market observations are quotes, never evidence of a completed sale.
local A=ATS
local min,max,floor=math.min,math.max,math.floor
local WEEK=7*24*60*60

local function finite(value)
  local n=tonumber(value)
  return n and n==n and n<math.huge and n>-math.huge and n or nil
end

local function clampFee(percentage)
  return max(0,min(100,finite(percentage) or 0))/100
end

-- Keep the pricing source explicit: last actually observed Auctionator price.
-- A stale or future observation cannot be used for a current valuation.
local function latestQuote(key, now)
  if type(A.ProSamples)~="function" then return nil end
  local samples=A.ProSamples(key)
  local result
  for i=1,#(samples or {}) do
    local s=samples[i]
    local price=type(s)=="table" and finite(s.price)
    local ts=type(s)=="table" and finite(s.t)
    if price and price>0 and ts and ts<=now and
       (not result or ts>result.t) then
      result={price=price,t=ts,source="history"}
    end
  end
  return result
end

-- rows: optional test/manual journal rows (nil = current character's manual journal).
-- quotes: optional price map for deterministic tests; missing map entries mean
-- no quote, not an invitation to use an arbitrary current Auction House listing.
-- opts: {now, maxQuoteAge, feePercent}. Default 7-day freshness window.
function A.PortfolioSnapshot(rows,quotes,opts)
  opts=opts or {}
  local at=finite(opts.now) or (time and time() or 0)
  local maxAge=max(0,finite(opts.maxQuoteAge) or WEEK)
  local configured=A.db and A.db.pro and A.db.pro.journalFee
  local fee=clampFee(opts.feePercent~=nil and opts.feePercent or configured or 5)
  local report=A.JournalAnalysis(rows)
  local out={positions={},realized=report.realized,unmatched=report.unmatched,
    skipped=report.skipped,openUnits=0,openCount=0,invested=0,
    markedCost=0,marketValue=0,estimatedNet=0,unrealized=0,
    markedCount=0,unpricedCount=0,staleCount=0,asOf=at,
    quoteMaxAge=maxAge,feePercent=fee*100}
  for key,position in pairs(report.positions or {}) do
    local qty=finite(position.qty)
    local cost=finite(position.cost)
    if qty and qty>0 and cost and cost>=0 then
      local p={key=key,qty=qty,cost=cost,avgCost=cost/qty,
        price=nil,value=nil,netValue=nil,pnl=nil,roi=nil,
        status="missing"}
      out.openUnits=out.openUnits+qty
      out.invested=out.invested+cost
      local quote=quotes and quotes[key] or (not quotes and latestQuote(key,at))
      local price=type(quote)=="table" and finite(quote.price) or nil
      local ts=type(quote)=="table" and finite(quote.t) or nil
      if price and price>0 and ts and ts<=at then
        p.price=price;p.quoteTime=ts;p.quoteAge=at-ts
        if p.quoteAge<=maxAge then
          p.status="priced"
          p.value=price*qty
          p.netValue=p.value*(1-fee)
          p.pnl=p.netValue-cost
          p.roi=cost>0 and p.pnl/cost*100 or nil
          out.marketValue=out.marketValue+p.value
          out.estimatedNet=out.estimatedNet+p.netValue
          out.unrealized=out.unrealized+p.pnl
          out.markedCost=out.markedCost+cost
          out.markedCount=out.markedCount+1
        else
          p.status="stale"
          out.staleCount=out.staleCount+1
        end
      else
        out.unpricedCount=out.unpricedCount+1
      end
      out.positions[#out.positions+1]=p
    end
  end
  table.sort(out.positions,function(a,b)
    if a.cost~=b.cost then return a.cost>b.cost end
    return tostring(a.key)<tostring(b.key)
  end)
  out.openCount=#out.positions
  out.complete=(out.markedCount==out.openCount)
  for _,p in ipairs(out.positions) do
    p.weight=out.invested>0 and p.cost/out.invested*100 or nil
  end
  return out
end
