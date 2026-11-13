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

function B.indicators(root)
  local p=newPage(root)
  heading(p,l("Technical indicators 2.0 - observed time buckets",
    "Технические индикаторы 2.0 - реальные интервалы наблюдений"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Calculate","Рассчитать"),272,-83,132,function()p.update()end)
  p.identity=makeItemIdentity(p)
  p.rows={}
  for i=1,10 do p.rows[i]=fs(p,"",20,-183-(i-1)*35,326,i==1) end
  fs(p,"RSI",375,-163,305,true)
  fs(p,"MACD",375,-354,305,true)
  p.rsiPlot=newPlot(p,368,-185,338,156)
  p.macdPlot=newPlot(p,368,-376,338,155)
  local rsiUpper=fs(p.rsiPlot,"70",6,-41,32)
  rsiUpper:SetTextColor(.85,.48,.50)
  local rsiMid=fs(p.rsiPlot,"50",6,-74,32)
  rsiMid:SetTextColor(.57,.65,.74)
  local rsiLower=fs(p.rsiPlot,"30",6,-104,32)
  rsiLower:SetTextColor(.43,.83,.60)
  attachIndicatorCursor(p.rsiPlot,"rsi")
  attachIndicatorCursor(p.macdPlot,"macd")
  p.rsiStatus=fs(p.rsiPlot,"",20,-67,298)
  p.rsiStatus:SetJustifyH("CENTER")
  p.macdStatus=fs(p.macdPlot,"",20,-67,298)
  p.macdStatus:SetJustifyH("CENTER")
  p.details=fs(p,"",20,-535,695)
  p.details:SetTextColor(.70,.82,.87)
  local glossary={
    {"EMA","Экспоненциальная средняя: больше вес последних наблюдаемых цен, по одному значению на интервал."},
    {"RSI","Индекс 0-100 по росту/падению цены. 70/30 - ориентиры, не торговые сигналы. До полного периода значение предварительное."},
    {"MACD","Разность EMA(12) и EMA(26) по временным интервалам. На первых интервалах индикатор ещё прогревается."},
    {"MACD Histogram","MACD минус сигнальная EMA(9). Положительные и отрицательные значения показывают изменение импульса цены."},
    {"Bollinger Bands","Средняя цена и полосы +/-2 стандартных отклонения по указанному числу наблюдаемых интервалов."},
  }
  local glossaryEN={
    "Exponential moving average with extra weight on recent observed bucket-closing prices.",
    "Strength index 0-100 from observed price changes. 70/30 are guides, not trading signals; partial history produces preliminary values.",
    "EMA(12) minus EMA(26) from observed time buckets. Early values are in warm-up.",
    "MACD minus its EMA(9) signal. Positive or negative bars show observed price momentum changes.",
    "Observed moving average plus/minus two standard deviations. Missing prices are not invented."
  }
  for i=2,8 do
    local term=i==2 and 1 or (i==3 and 2 or (i==4 and 3 or (i==5 and 4 or 5)))
    local overlay=CreateFrame("Frame",nil,p)
    overlay:SetSize(310,28)
    overlay:SetPoint("TOPLEFT",p,"TOPLEFT",18,-183-(i-1)*35+3)
    overlay:EnableMouse(true)
    attachHelp(overlay,glossary[term][1],l(glossaryEN[term],glossary[term][2]))
  end
  local function clearPlots()
    p.rsiPlot:clear();p.macdPlot:clear()
    p.rsiPlot:setHoverValues(nil);p.macdPlot:setHoverValues(nil)
    p.rsiStatus:SetText("");p.macdStatus:SetText("")
  end
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    clearPlots()
    if not key then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("Select an item.","Выберите предмет."))
      p.details:SetText("")
      return
    end
    local ind=A.ProIndicators(A.ProSamples(key))
    local v=ind.latest
    if not v then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("No observations.","Нет наблюдений."))
      p.details:SetText("")
      return
    end
    local cfg=A.db.pro
    local disabled=l("off","выкл.")
    local missing=l("not enough data","недостаточно данных")
    local rsiStatus
    if cfg.showRSI then
      if v.rsi then
        rsiStatus=string.format("%.1f",v.rsi)
        if v.rsiPreliminary then rsiStatus=rsiStatus..l(" (prelim.)"," (предв.)") end
      else rsiStatus=missing end
    else rsiStatus=disabled end
    local macdText=cfg.showMACD and labelNumber(v.macd) or disabled
    local statusNote=l("Based on real observations.","По реальным наблюдениям.")
    if cfg.showRSI and v.rsiPreliminary then
      statusNote=l("RSI: preliminary (","RSI: предварительный (")..
        tostring(v.rsiChanges or 0).."/"..tostring(cfg.rsiPeriod)..")"
    elseif cfg.showRSI and v.rsi==nil then
      statusNote=l("RSI: need 4+ time buckets","RSI: нужно от 4 интервалов")
    end
    local text={
      l("Samples: ","Замеров: ")..ind.count..l("   Buckets: ","   Интервалов: ")..ind.bucketCount,
      "EMA("..cfg.emaPeriod.."): "..(cfg.showEMA and currency(v.ema) or disabled),
      "RSI("..cfg.rsiPeriod.."): "..rsiStatus,
      "MACD: "..macdText..(cfg.showMACD and v.signalPreliminary and " *" or ""),
      l("MACD histogram: ","Гистограмма MACD: ")..(cfg.showMACD and labelNumber(v.hist) or disabled),
      l("Bollinger upper: ","Боллинджер, верх: ")..(cfg.showBollinger and (v.upper and currency(v.upper) or missing) or disabled),
      l("Bollinger middle: ","Боллинджер, середина: ")..(cfg.showBollinger and (v.bollMiddle and currency(v.bollMiddle) or missing) or disabled),
      l("Bollinger lower: ","Боллинджер, низ: ")..(cfg.showBollinger and (v.lower and currency(v.lower) or missing) or disabled),
      l("Segments: ","Участков: ")..ind.segments..l("   Last: ","   Последний: ")..v.segmentCount,
      statusNote,
    }
    for i=1,#p.rows do p.rows[i]:SetText(text[i] or "") end
    p.details:SetText(string.format(l("Bucket: %d min    Reset gap: %d h    * MACD signal warm-up until 34+ buckets.",
       "Интервал: %d мин    Пропуск: %d ч    * Сигнал MACD прогрев до 34+ интервалов."),
       ind.bucketMinutes,ind.gapHours))
    local rPlot,mPlot=p.rsiPlot,p.macdPlot
    local points=ind.values
    local n=#points
    if n==0 then return end
    local first=math.max(1,n-100)
    local tMin=points[first].t
    local timeSpan=math.max(1,points[n].t-tMin)
    local function x(point) return (point.t-tMin)/timeSpan*338 end
    if cfg.showRSI then
      for _,threshold in ipairs({30,50,70}) do
        local r,g,b=.32,.39,.49
        if threshold==70 then r,g,b=.70,.32,.34
        elseif threshold==30 then r,g,b=.28,.61,.43 end
        rPlot:rect(0,threshold/100*156,338,1,r,g,b,.83)
      end
    end
    if cfg.showMACD then mPlot:rect(0,77,338,1,.38,.45,.53,.86) end
    local macdRange=.1
    for i=first,n do
      local pt=points[i]
      macdRange=math.max(macdRange,math.abs(pt.macd or 0),math.abs(pt.signal or 0),math.abs(pt.hist or 0))
    end
    -- Draw the histogram behind MACD and signal lines.
    if cfg.showMACD then
      for i=first,n do
        local pt=points[i]
        local xx=x(pt)
        local val=(pt.hist or 0)/macdRange*65
        if val>=0 then mPlot:rect(xx-2,77,4,math.max(1,val),.31,.68,.48,.62)
        else mPlot:rect(xx-2,77+val,4,math.max(1,-val),.85,.39,.36,.62) end
      end
    end
    local previousRSI,previousMACD,previousSignal
    local rData,mData={},{}
    for i=first,n do
      local pt=points[i]
      local xx=x(pt)
      local prev=points[i-1]
      -- Never draw a continuous line through an unobserved interval.
      local canJoin=prev and pt.segment==prev.segment and pt.slot-prev.slot<=2
      if cfg.showRSI and pt.rsi then
        local yy=pt.rsi/100*156
        if previousRSI and canJoin then miniLine(rPlot,previousRSI.x,previousRSI.y,xx,yy,.33,.89,.91) end
        rPlot:rect(xx-1.5,yy-1.5,3,3,.32,.9,1)
        previousRSI={x=xx,y=yy}
        rData[#rData+1]={x=xx,data=pt}
      else previousRSI=nil end
      if cfg.showMACD then
        local yy=77+(pt.macd or 0)/macdRange*67
        local sy=77+(pt.signal or 0)/macdRange*67
        if previousMACD and canJoin then miniLine(mPlot,previousMACD.x,previousMACD.y,xx,yy,.42,.9,.55) end
        if previousSignal and canJoin then miniLine(mPlot,previousSignal.x,previousSignal.y,xx,sy,1,.72,.22) end
        previousMACD={x=xx,y=yy};previousSignal={x=xx,y=sy}
        mData[#mData+1]={x=xx,data=pt}
      end
    end
    rPlot:setHoverValues(rData);mPlot:setHoverValues(mData)
    if cfg.showRSI then
      if #rData==0 then
        p.rsiStatus:SetText(l("RSI: insufficient distinct time buckets",
          "RSI: недостаточно временных интервалов"))
      elseif v.rsiPreliminary then
        p.rsiStatus:SetText(l("Preliminary RSI", "Предварительный RSI"))
      end
    else p.rsiStatus:SetText(l("RSI disabled in settings", "RSI отключён в настройках")) end
    if cfg.showMACD and v.signalPreliminary then
      p.macdStatus:SetText(l("MACD: warm-up (not a full signal)",
        "MACD: период накопления, не полный сигнал"))
    elseif not cfg.showMACD then
      p.macdStatus:SetText(l("MACD disabled in settings", "MACD отключён в настройках"))
    end
  end
  p:HookScript("OnHide",function()
    p.rsiPlot:SetScript("OnUpdate",nil)
    p.macdPlot:SetScript("OnUpdate",nil)
    p.rsiPlot.cursor:Hide();p.macdPlot.cursor:Hide()
    if GameTooltip then GameTooltip:Hide() end
  end)
  return p
end

