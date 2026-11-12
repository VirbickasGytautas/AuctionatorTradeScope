-- TradeScope 3.3.0: professional-style, observation-based research tools.
-- Never claim live order-book, confirmed sales, or predictive certainty.
local A=ATS

local function percent(base,value)
  if not A.Valid(base) or type(value)~="number" then return nil end
  return (value-base)*100/base
end

function A.TradeSnapshot(key,legacy,samples,hours)
  A.Init()
  local all=samples or A.AllSamples(key,legacy)
  local window=hours or A.ChartHours(key,legacy,all)
  local m=A.MarketMetrics(key,legacy,all,window)
  local latestPrice, previous24, previous24Time, recentPoints, total24=nil,nil,nil,0,0
  local cutoff=time()-86400
  for i=1,#all do
    local p=all[i]
    if A.Valid(p.price) then
      if p.t<cutoff then previous24=p.price; previous24Time=p.t end
      latestPrice=p.price
      if p.t>=cutoff then recentPoints=recentPoints+1 end
    end
    if p.t>=cutoff then total24=total24+1 end
  end
  -- 24-hour momentum is unavailable without a baseline on or before cutoff.
  local dayChange=(previous24Time and (time()-previous24Time)<=48*3600 and recentPoints>0) and percent(previous24,latestPrice) or nil
  local range=nil
  if m.average and m.minPrice and m.maxPrice and m.average>0 then
    range=(m.maxPrice-m.minPrice)/m.average*100
  end
  local percentile=nil
  if m.minPrice and m.maxPrice and m.currentPrice then
    if m.maxPrice>m.minPrice then
      percentile=100*(m.currentPrice-m.minPrice)/(m.maxPrice-m.minPrice)
    else percentile=50 end
  end
  local medianDeviation=m.median and m.currentPrice and percent(m.median,m.currentPrice) or nil
  -- Decreases can be canceled/expired auctions; this is only observed pressure.
  local depletion=nil
  if m.estimatedDrops24 and m.currentQuantity and m.currentQuantity>0 then
    depletion=math.min(1000,100*m.estimatedDrops24/m.currentQuantity)
  end
  local ageHours=m.lastPriceTime and math.max(0,(time()-m.lastPriceTime)/3600) or nil
  local confidence="low"
  if (m.priceObservations or 0)>=A.db.tradeMinSamples and ageHours and ageHours<=24 then
    confidence="medium"
    if m.priceObservations>=math.max(12,A.db.tradeMinSamples*2) and ageHours<=4 and (m.quantitySamples24 or 0)>=3 then
      confidence="high"
    end
  end
  local guidance="insufficient"
  if A.db.showTradeAdvice and confidence~="low" and medianDeviation then
    if medianDeviation<=-A.db.signalThreshold then guidance="discount"
    elseif medianDeviation>=A.db.signalThreshold then guidance="premium"
    else guidance="neutral" end
  end
  return {
    metrics=m, dayChange=dayChange, range=range, position=percentile,
    medianDeviation=medianDeviation, depletion=depletion,
    ageHours=ageHours, recentPoints=recentPoints, total24=total24,
    confidence=confidence, guidance=guidance,
  }
end

function A.TradeBuyTable(create)
  A.Init()
  local realm=A.RealmKey()
  if not A.db.tradeBuys[realm] and create then A.db.tradeBuys[realm]={} end
  return A.db.tradeBuys[realm]
end
function A.GetTradeBuy(key)
  local records=A.TradeBuyTable(false)
  local record=records and records[key]
  return type(record)=="number" and record>=0 and record or nil
end
function A.SetTradeBuy(key,copper)
  if not key then return end
  local records=A.TradeBuyTable(true)
  if type(copper)=="number" and copper>=0 and copper<math.huge then
    records[key]=math.floor(copper+.5)
  else records[key]=nil end
end
-- Quantities are stored per item and realm, independently of purchase prices.
function A.TradeQuantityTable(create)
  A.Init()
  local realm=A.RealmKey()
  if not A.db.tradeQuantities[realm] and create then A.db.tradeQuantities[realm]={} end
  return A.db.tradeQuantities[realm]
end
function A.GetTradeQuantity(key)
  local records=A.TradeQuantityTable(false)
  local value=records and records[key]
  if type(value)=="number" and value>=1 then
    return math.min(1000000,math.max(1,math.floor(value)))
  end
  return 1
end
function A.SetTradeQuantity(key,quantity)
  if not key then return end
  local records=A.TradeQuantityTable(true)
  local number=tonumber(quantity)
  if number and number>=1 then
    records[key]=math.min(1000000,math.max(1,math.floor(number)))
  else records[key]=1 end
end

function A.CalculateTrade(buyCopper,sellCopper,feePercent,quantity)
  if type(buyCopper)~="number" or buyCopper<0 or not A.Valid(sellCopper) then return nil end
  local qty=tonumber(quantity) or 1
  if qty < 1 or qty>=math.huge then return nil end
  qty=math.min(1000000,math.floor(qty))
  buyCopper=math.floor(buyCopper+.5)
  local fee=math.max(0,math.min(15,tonumber(feePercent) or 5))/100
  local net=math.floor(sellCopper*(1-fee)+.5)
  local profit=net-buyCopper
  local totalBuy=buyCopper*qty
  local totalNet=net*qty
  local totalProfit=totalNet-totalBuy
  local roi=totalBuy>0 and totalProfit*100/totalBuy or nil
  -- Conservative break-even: sold at or above this price, the purchase
  -- cost will be covered after the configured percentage cut.
  local breakEven=math.ceil(buyCopper/math.max(0.01,1-fee))
  return {
    net=net, profit=profit, roi=roi, breakEven=breakEven, fee=fee*100,
    quantity=qty, buy=buyCopper, sell=sellCopper,
    totalBuy=totalBuy, totalNet=totalNet, totalProfit=totalProfit,
  }
end
