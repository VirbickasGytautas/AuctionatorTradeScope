-- UI module extracted from the 4.3.0 Pro workstation without changing behavior.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local WIDTH=C.WIDTH
local HEIGHT=C.HEIGHT
local TOOLS=C.TOOLS
local names=C.names
local l=C.l
local tr=C.tr
local tex=C.tex
local fs=C.fs
local button=C.button
local helpText=C.helpText
local showHelp=C.showHelp
local attachHelp=C.attachHelp
local addMetricTooltips=C.addMetricTooltips
local asExactItem=C.asExactItem
local itemKey=C.itemKey
local sharedMarketChoice=C.sharedMarketChoice
local fillMarketEdit=C.fillMarketEdit
local shareMarketChoice=C.shareMarketChoice
local attachItemSearch=C.attachItemSearch
local edit=C.edit
local marketInput=C.marketInput
local itemID=C.itemID
local heading=C.heading
local pbutton=C.pbutton
local currency=C.currency
local asItem=C.asItem
local selectedKey=C.selectedKey
local anyItem=C.anyItem
local inspect=C.inspect
local newPage=C.newPage
local lineList=C.lineList
local captureRow=C.captureRow
local labelNumber=C.labelNumber
local makeItemIdentity=C.makeItemIdentity
local normalizeRussian=C.normalizeRussian
local newPlot=C.newPlot
local miniLine=C.miniLine
local attachIndicatorCursor=C.attachIndicatorCursor

function B.candles(root)
  local p=newPage(root)
  heading(p,l("Candlesticks (observed OHLC, no trade volume)","Свечи OHLC по замерам (без объёма сделок)"),-12)
  p.selection=marketInput(p,20,-60,216)
  p.bucket=edit(p,l("Bucket (hours)","Интервал свечи (ч)"),246,-60,100,tostring(A.db.pro.candleBucketHours),true)
  p.hours=edit(p,l("History (hours)","История (часов)"),365,-60,113,tostring(A.db.pro.candleHours),true)
  p.identity=makeItemIdentity(p)
  p.plot=newPlot(p,56,-174,630,292)
  p.info=fs(p,"",22,-478,690)
  p.hint=fs(p,l("Green = rising; red = falling. Empty hours mean no price observations.",
     "Зелёные — рост, красные — падение. Пустые часы — нет наблюдений."),22,-508,698)
  button(p,l("Update chart","Обновить"),506,-83,152,function()
    A.db.pro.candleBucketHours=math.max(1,math.min(168,math.floor(tonumber(p.bucket:GetText()) or 1)))
    A.db.pro.candleHours=math.max(1,math.min(2160,math.floor(tonumber(p.hours:GetText()) or 24)))
    p.update()
  end)
  p.update=function()
    local key=anyItem(p)
    p.identity:showItem(key)
    if not key then p.info:SetText(l("Select an item.","Выберите предмет."));p.plot:clear();return end
    local samples=A.ProSamples(key)
    local hours=A.db.pro.candleHours
    local bucket=A.db.pro.candleBucketHours
    local candles=A.ProCandles(samples,hours,bucket)
    local plot=p.plot
    plot:clear()
    for i=0,4 do plot:rect(0,i*73,630,1,.18,.28,.40,.6) end
    local lo,hi
    for i=1,#candles do
      lo=math.min(lo or candles[i].low,candles[i].low)
      hi=math.max(hi or candles[i].high,candles[i].high)
    end
    if not lo then p.info:SetText(l("No observations in selected period.","За период нет наблюдений."));return end
    local span=math.max(1,hi-lo)
    local start=time()-hours*3600
    local candW=math.max(2,math.min(13,(bucket/hours)*630*.66))
    local function y(price) return math.max(3,math.min(289,14+(price-lo)/span*262)) end
    local previousEMA,previousBoll,previousLower
    local indi=A.ProIndicators(samples)
    local lastIndi=indi.latest
    for i=1,#candles do
      local c=candles[i]
      local x=(c.t-start)/(hours*3600)*630
      if x>=0 and x<=630 then
        local rising=c.close>=c.open
        local r,g,b=rising and .24 or .95,rising and .88 or .31,rising and .49 or .29
        plot:rect(x,y(c.low),2,math.max(2,y(c.high)-y(c.low)),r,g,b)
        plot:rect(x-candW/2,math.min(y(c.open),y(c.close)),candW,
          math.max(3,math.abs(y(c.open)-y(c.close))),r,g,b)
      end
    end
    if A.db.pro.showEMA or A.db.pro.showBollinger then
      for i=1,#indi.values do
        local v=indi.values[i];local x=(v.t-start)/(hours*3600)*630
        if x>=0 and x<=630 then
          if A.db.pro.showEMA and v.ema then
            local yy=y(v.ema)
            if previousEMA and previousEMA.segment==v.segment and
                v.slot-previousEMA.slot<=2 then
              miniLine(plot,previousEMA.x,previousEMA.y,x,yy,1,.8,.25)
            end
            previousEMA={x=x,y=yy,slot=v.slot,segment=v.segment}
          end
          if A.db.pro.showBollinger and v.upper and v.lower then
            local yy=y(v.upper)
            local bottom=y(v.lower)
            if previousBoll and previousBoll.segment==v.segment and
                v.slot-previousBoll.slot<=2 then
              miniLine(plot,previousBoll.x,previousBoll.y,x,yy,.69,.5,.95)
            end
            if previousLower and previousLower.segment==v.segment and
                v.slot-previousLower.slot<=2 then
              miniLine(plot,previousLower.x,previousLower.y,x,bottom,.69,.5,.95)
            end
            previousBoll={x=x,y=yy,slot=v.slot,segment=v.segment}
            previousLower={x=x,y=bottom,slot=v.slot,segment=v.segment}
          end
        end
      end
    end
    p.info:SetText(l("Candles: ","Свечей: ")..#candles..
      "   L: "..currency(lo).."   H: "..currency(hi).."   EMA: "..currency(lastIndi and lastIndi.ema))
  end
  return p
end

