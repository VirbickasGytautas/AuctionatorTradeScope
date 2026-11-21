-- TradeScope 4.6.0-beta1: conservative, read-only strategy research.
-- Three distinct source types: scanned opportunities, known-cost positions,
-- and physical inventory concentration. No orders, no fabricated sales.
local A=ATS
local floor,max,min=math.floor,math.max,math.min
local HOUR=3600
local definitions={
  discount={en="Value watch",ru="Поиск скидки",hintEn="Recent scanner candidates verified against actual recent prices.",
    hintRu="Кандидаты сканера со свежей повторно проверенной ценой."},
  exit={en="Exit review",ru="Проверка выхода",hintEn="Open journal lots with known cost, estimated net return after fees.",
    hintRu="Позиции с известной себестоимостью, оценка после комиссии."},
  exposure={en="Concentration",ru="Концентрация",hintEn="Unusually concentrated market value in current bags; not a sale recommendation.",
    hintRu="Сильная концентрация оценённой стоимости в сумках, не совет продавать."},
}
local order={"discount","exit","exposure"}
function A.StrategyKinds()return order,definitions end

local function finite(v)
  v=tonumber(v)
  return v and v==v and v>=0 and v<math.huge and v or nil
end
local function mark(result,reason)
  result.excluded=result.excluded+1
  result.reasons[reason]=(result.reasons[reason] or 0)+1
end
local function validQuote(entry,now,maxAge)
  if type(entry)~="table" then return nil end
  local p=finite(entry.price)
  local t=finite(entry.t)
  if not p or p<=0 or not t or t>now or now-t>maxAge then return nil end
  return p,t
end
local function sort(rows)
  table.sort(rows,function(a,b)
    if a.priority~=b.priority then return a.priority>b.priority end
    return tostring(a.key)<tostring(b.key)
  end)
end
-- input contains injected evidence. Snapshot providers below only assemble
-- evidence; evaluation itself has no side effects or external dependencies.
function A.StrategyEvaluate(input,kind,opts)
  input=type(input)=="table" and input or {}
  opts=opts or {}
  if not definitions[kind] then kind="discount" end
  local now=finite(opts.now) or (type(time)=="function" and time() or 0)
  local maxQuoteAge=max(1,min(24,finite(opts.maxQuoteHours) or 6))*HOUR
  local scanAge=max(1,min(72,finite(opts.maxScannerHours) or 24))*HOUR
  local out={kind=kind,rows={},excluded=0,considered=0,reasons={},
    sourceTime=input.scannerTime,sourceKnown=true,policy="observation_only",
    asOf=now}
  if kind=="discount" then
    local scannerTime=finite(input.scannerTime)
    local scannerFresh=scannerTime and scannerTime<=now and now-scannerTime<=scanAge
    if not scannerFresh then
      out.sourceKnown=false
      out.reasons.scanner_stale=1
      return out
    end
    for _,record in ipairs(type(input.scanner)=="table" and input.scanner or {}) do
      out.considered=out.considered+1
      local key=record.key
      local price,t=key and validQuote(input.quotes and input.quotes[key],now,maxQuoteAge)
      local median=finite(record.median)
      local risk=finite(record.risk)
      local score=finite(record.score)
      local quality=finite(record.quality)
      local samples=finite(record.samples)
      local quantity=finite(record.quantity)
      local volatility=finite(record.volatility)
      if not key or not price or not median or median<=0 then mark(out,"price_or_median")
      elseif risk==nil or score==nil or quality==nil or samples==nil then mark(out,"evidence_missing")
      elseif quality<55 or samples<8 or risk>55 or score<25 then mark(out,"quality_or_risk")
      elseif quantity==nil or quantity<3 then mark(out,"supply_unknown")
      elseif volatility==nil or volatility>65 then mark(out,"volatility_unknown")
      else
        local discount=100*(median-price)/median
        if discount<12 then mark(out,"discount_too_small")
        else
          out.rows[#out.rows+1]={
            key=key,kind=kind,price=price,quoteTime=t,median=median,
            discount=discount,quality=quality,score=score,risk=risk,
            quantity=quantity,volatility=volatility,
            priority=score*(1-risk/150),source="scanner_and_quote",
          }
        end
      end
    end
  elseif kind=="exit" then
    for _,p in ipairs(type(input.positions)=="table" and input.positions or {}) do
      out.considered=out.considered+1
      local key=p.key
      local qty=finite(p.qty)
      local cost=finite(p.cost)
      local quote,ts=key and validQuote(input.quotes and input.quotes[key],now,maxQuoteAge)
      local fee=min(15,max(0,finite(input.feePercent) or 5))/100
      if not key or not qty or qty<=0 or not cost or cost<=0 then mark(out,"cost_unknown")
      elseif not quote then mark(out,"price_or_median")
      else
        local net=quote*qty*(1-fee)
        local gain=net-cost
        local roi=100*gain/cost
        if roi<(finite(opts.minExitROI) or 10) then mark(out,"roi_too_small")
        else
          out.rows[#out.rows+1]={
            key=key,kind=kind,price=quote,quoteTime=ts,
            qty=qty,cost=cost,net=net,feePercent=fee*100,
            profit=gain,roi=roi,priority=roi,source="journal_cost_and_quote"
          }
        end
      end
    end
  else
    local stock=input.allocation
    if not stock or stock.sourceAvailable==false then
      out.sourceKnown=false
      out.reasons.stock_unknown=1
      return out
    end
    if stock.excluded and stock.excluded>0 then
      out.reasons.partial_quotes=stock.excluded
    end
    -- The allocation model already excludes stale and missing item quotes.
    -- Never infer cost basis or confirmed sales from bag contents.
    for _,p in ipairs(type(stock.rows)=="table" and stock.rows or {}) do
      out.considered=out.considered+1
      local share=finite(p.share)
      local value=finite(p.value)
      if not p.key or not value or value<=0 or not share then mark(out,"price_or_median")
      elseif share<50 then mark(out,"share_too_small")
      else
        out.rows[#out.rows+1]={
          key=p.key,kind=kind,value=value,share=share,
          qty=p.qty,priority=share,source="priced_bags",
          coverage=stock.coverage,
          singleItem=stock.count==1
        }
      end
    end
  end
  sort(out.rows)
  out.count=#out.rows
  return out
end
local function nowTime()
  return type(time)=="function" and time() or 0
end
-- Build from extant sources; the strategy page does NOT run a hidden scan or
-- take a game action. Scanner must be explicitly refreshed on its own tab.
function A.StrategySnapshot(kind)
  A.Init()
  local now=nowTime()
  if kind=="discount" then
    local scanner=A.ProScanner() or {}
    local quoteMap={}
    local maxItems=math.min(#scanner,400)
    for i=1,maxItems do
      local key=scanner[i].key
      if key and A.PortfolioLatestQuote then
        quoteMap[key]=A.PortfolioLatestQuote(key,now)
      end
    end
    local list={}
    for i=1,maxItems do list[i]=scanner[i] end
    return A.StrategyEvaluate({scanner=list,scannerTime=A.db.pro.scannerTime,
      quotes=quoteMap},kind,{now=now})
  elseif kind=="exit" then
    local positions=A.PortfolioSnapshot() or {}
    local list=positions.positions or {}
    local quotes={}
    for i=1,#list do
      local key=list[i].key
      if key and A.PortfolioLatestQuote then quotes[key]=A.PortfolioLatestQuote(key,now) end
    end
    return A.StrategyEvaluate({positions=list,quotes=quotes,
      feePercent=A.db.pro.journalFee},kind,{now=now})
  end
  local holdings=A.PortfolioHoldings()
  local allocation=A.PortfolioAllocation(holdings,nil,nil,"bags",{now=now})
  return A.StrategyEvaluate({allocation=allocation},kind,{now=now})
end
