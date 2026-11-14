-- 4.5.0-beta1: portfolio view for current character's MANUAL journal positions.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l,fs,button,newPage,heading,lineList,tex,currency=
  C.l,C.fs,C.button,C.newPage,C.heading,C.lineList,C.tex,C.currency
local PAGE_SIZE=6
local function showDetails(control,pos,fee)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(pos.key).." x"..pos.qty)
  GameTooltip:AddDoubleLine(l("Cost basis","Себестоимость"),currency(pos.cost),1,1,1,1,.85,.43)
  GameTooltip:AddDoubleLine(l("Average cost / unit","Средняя закупка / шт."),currency(pos.avgCost),1,1,1,1,.85,.43)
  GameTooltip:AddDoubleLine(l("Share of invested cost","Доля вложений"),
    pos.weight and string.format("%.1f%%",pos.weight) or "-",1,1,1,.8,.85,.94)
  if pos.status=="priced" then
    GameTooltip:AddDoubleLine(l("Last observed / unit","Последний замер / шт."),currency(pos.price),1,1,1,.85,.93,1)
    GameTooltip:AddDoubleLine(l("Gross market value","Рыночная оценка"),currency(pos.value),1,1,1,.85,.93,1)
    GameTooltip:AddDoubleLine(l("Net estimate after fee","Оценка после комиссии"),currency(pos.netValue),1,1,1,.85,.93,1)
    GameTooltip:AddDoubleLine(l("Unrealized estimate","Нереализованная оценка"),currency(pos.pnl),1,1,1,.58,.93,.65)
    if pos.roi then GameTooltip:AddLine(string.format("ROI: %.1f%%",pos.roi),.79,.89,.69) end
    GameTooltip:AddLine(l("Quote age: ","Возраст замера: ")..string.format("%.1f h",pos.quoteAge/3600),.7,.78,.83)
  elseif pos.status=="stale" then
    GameTooltip:AddLine(l("Last observed price is stale; excluded from totals.",
      "Последний замер устарел; не включён в оценку."),1,.75,.43,true)
  else
    GameTooltip:AddLine(l("No observed market quote. No value was invented.",
      "Нет рыночного замера. Стоимость не выдумывается."),1,.75,.43,true)
  end
  GameTooltip:AddLine(l("Estimates are not confirmed sales.",
    "Оценки не являются подтверждёнными продажами."),.75,.78,.82,true)
  GameTooltip:Show()
end

function B.portfolio(root)
  local p=newPage(root)
  heading(p,l("Trading Portfolio: open manual positions",
    "Торговый портфель: открытые ручные позиции"),-12)
  button(p,l("Refresh valuations","Обновить оценки"),20,-54,173,function()p.update()end)
  button(p,l("Trading Journal","Журнал сделок"),207,-54,168,function()
    A.ShowProTab("journal")
  end)
  p.subtitle=fs(p,l("Current character only. Inventory and unmatched sales are not positions.",
    "Только текущий персонаж. Сумки и продажи без закупки не считаются позициями."),20,-89,699)
  tex(p,18,-114,695,77,.063,.085,.107,.82)
  tex(p,18,-114,695,1,.48,.37,.19,.73)
  p.overview=fs(p,"",25,-124,685,true)
  p.pricing=fs(p,"",25,-150,685)
  p.realized=fs(p,"",25,-172,685)
  fs(p,l("OPEN POSITIONS (latest observed prices)",
    "ОТКРЫТЫЕ ПОЗИЦИИ (последние замеры)"),20,-204,693,true)
  tex(p,20,-227,694,1,.43,.33,.16,.64)
  p.rows=lineList(p,PAGE_SIZE,-245,35)
  p.empty=fs(p,l("No open positions. Add manual BUY/SELL entries in Trading Journal.",
    "Открытых позиций нет. Внесите покупки/продажи в журнал сделок."),25,-295,690)
  p.note=fs(p,l("Market value and P&L are estimates, not actual proceeds. Old/missing quotes are excluded.",
    "Стоимость и прибыль — оценки, не выручка. Старые/отсутствующие цены исключены."),20,-469,690)
  p.pageIndex=1
  p.prev=button(p,l("< Back","< Назад"),20,-519,126,function()
    if p.pageIndex>1 then p.pageIndex=p.pageIndex-1;p.update()end
  end)
  p.pageText=fs(p,"",162,-526,250)
  p.next=button(p,l("Next >","Вперёд >"),584,-519,126,function()
    p.pageIndex=p.pageIndex+1;p.update()
  end)
  p.update=function()
    local report=A.PortfolioSnapshot()
    local pages=math.max(1,math.ceil(report.openCount/PAGE_SIZE))
    p.pageIndex=math.max(1,math.min(pages,p.pageIndex))
    local unavailable=report.unpricedCount+report.staleCount
    p.overview:SetText(l("Open: ","Позиций: ")..report.openCount..
      l("  Units: ","  Штук: ")..report.openUnits..
      l("  Invested: ","  Вложено: ")..currency(report.invested))
    p.pricing:SetText(l("Valued: ","Оценено: ")..report.markedCount.." / "..report.openCount..
      l("  Gross: ","  Рыночная стоимость: ")..currency(report.marketValue)..
      l("  Net estimate: ","  После комиссии: ")..currency(report.estimatedNet))
    p.realized:SetText(l("Realized: ","Реализовано: ")..currency(report.realized)..
      l("  Unrealized (priced only): ","  Нереализовано (с ценой): ")..currency(report.unrealized))
    p.pageText:SetText(l("Page ","Страница ")..p.pageIndex.." / "..pages)
    if report.openCount==0 then p.empty:Show() else p.empty:Hide() end
    if p.prev.SetEnabled then p.prev:SetEnabled(p.pageIndex>1) end
    if p.next.SetEnabled then p.next:SetEnabled(p.pageIndex<pages) end
    p.note:SetText(l("Missing prices: ","Без цены: ")..report.unpricedCount..
      l("   Stale quotes: ","   Устарело: ")..report.staleCount..
      l("   Estimated sale fee: ","   Комиссия оценки: ")..string.format("%.0f%%",report.feePercent))
    for i=1,#p.rows do
      local pos=report.positions[(p.pageIndex-1)*PAGE_SIZE+i]
      local row=p.rows[i]
      if pos then
        local name=A.ProItemName(pos.key)
        if A.FitItemName then name=A.FitItemName(name,row:GetFontString(),185) or name end
        local status=pos.status=="priced" and (currency(pos.pnl)) or
          (pos.status=="stale" and l("STALE","УСТАРЕЛО") or l("NO PRICE","НЕТ ЦЕНЫ"))
        row:SetText(name.."  x"..pos.qty.."   "..l("Basis ","Закупка ")..
          currency(pos.cost).."   "..l("Est. P&L ","Оценка ")..status)
        row:SetScript("OnClick",function()
          if A.OpenDashboardScanKey and A.ProItemLink(pos.key) then A.OpenDashboardScanKey(pos.key) end
        end)
        row:SetScript("OnEnter",function(self)showDetails(self,pos,report.feePercent)end)
        row:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
        row:Show()
      else
        row:Hide()
        row:SetScript("OnEnter",nil)
        row:SetScript("OnClick",nil)
      end
    end
  end
  p.update()
  return p
end
