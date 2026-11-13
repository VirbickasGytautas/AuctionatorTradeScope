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

function B.heatmap(root)
  local p=newPage(root)
  heading(p,l("Observed average prices by weekday / hour","Средние наблюдаемые цены по дням и часам"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Update","Обновить"),272,-83,132,function()p.update()end)
  local weekdays={"Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
  local weekdaysRU={"Пн","Вт","Ср","Чт","Пт","Сб","Вс"}
  p.identity=makeItemIdentity(p)
  p.cells={}
  for h=0,23 do fs(p,tostring(h),80+h*25,-168,24) end
  for day=1,7 do
    fs(p,A.locale=="ruRU" and weekdaysRU[day] or weekdays[day],20,-205-(day-1)*42,50)
    p.cells[day]={}
    for h=0,23 do
      local b=CreateFrame("Button",nil,p)
      b:SetSize(21,31);b:SetPoint("TOPLEFT",p,"TOPLEFT",79+h*25,-199-(day-1)*42)
      local bg=b:CreateTexture(nil,"BACKGROUND")
      bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetAllPoints(b)
      b.bg=bg
      b:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        local c=self.cell
        GameTooltip:SetText((A.locale=="ruRU" and weekdaysRU[day] or weekdays[day]).." "..h..":00")
        GameTooltip:AddLine(l("Observations: ","Замеров: ")..tostring(c and c.count or 0),1,1,1)
        if c and c.count>0 then GameTooltip:AddLine(l("Average: ","Средняя: ")..currency(c.sum/c.count),1,.82,.30) end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
      p.cells[day][h]=b
    end
  end
  p.hint=fs(p,l("Empty cells mean no scans. Color is relative to observed prices only.",
    "Пустая клетка — не было сканов. Цвет относительно наблюдаемых цен."),24,-515,690)
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    local map=key and A.ProHeatmap(A.ProSamples(key),A.db.pro.heatmapDays) or nil
    local lo,hi
    if map then
      for d=1,7 do for h=0,23 do
        local c=map[d][h]
        if c.count>0 then local avg=c.sum/c.count;lo=math.min(lo or avg,avg);hi=math.max(hi or avg,avg) end
      end end
    end
    for d=1,7 do for h=0,23 do
      local b=p.cells[d][h];local c=map and map[d][h]
      b.cell=c
      if c and c.count>0 then
        local n=(c.sum/c.count-(lo or 0))/math.max(1,(hi or 0)-(lo or 0))
        b.bg:SetVertexColor(.12+n*.72,.67-n*.47,.26,.95)
      else b.bg:SetVertexColor(.12,.17,.24,.68) end
    end end
  end
  return p
end

