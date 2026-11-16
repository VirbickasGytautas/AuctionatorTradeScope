-- TradeScope 4.5.0-beta3: portfolio overview for confirmed revenue and inventory.
-- Stock != purchased lots. Inventory market value != realized/unrealized profit.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l,fs,button,newPage,heading,lineList,tex,currency=
  C.l,C.fs,C.button,C.newPage,C.heading,C.lineList,C.tex,C.currency
local PAGE_SIZE=6
local function labelName(key,control,width)
  local name=A.ProItemName(key)
  if A.FitItemName then return A.FitItemName(name,control:GetFontString(),width) or name end
  return name
end
local function ageText(epoch)
  if type(epoch)~="number" or type(time)~="function" then return "?" end
  local hours=math.max(0,(time()-epoch)/3600)
  return string.format("%.1f h",hours)
end
local function positionTip(control,pos)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(pos.key).." x"..pos.qty)
  GameTooltip:AddDoubleLine(l("Known purchase cost","Известная цена закупки"),currency(pos.cost),1,1,1,.9,.84,.55)
  GameTooltip:AddDoubleLine(l("Average per unit","Средняя цена за шт."),currency(pos.avgCost),1,1,1,.9,.84,.55)
  if pos.status=="priced" then
    GameTooltip:AddDoubleLine(l("Latest observed price","Последний замер цены"),currency(pos.price),1,1,1,.6,.91,1)
    GameTooltip:AddDoubleLine(l("Est. sale value after fee","Оценка продажи после комиссии"),currency(pos.netValue),1,1,1,.6,.91,1)
    GameTooltip:AddDoubleLine(l("Est. unrealized profit","Оценка нереализованной прибыли"),currency(pos.pnl),1,1,1,.7,.95,.7)
    if pos.roi then GameTooltip:AddLine(string.format("ROI: %.1f%%",pos.roi),.75,.9,.7) end
  else
    GameTooltip:AddLine(pos.status=="stale" and l("Quote is stale","Цена устарела") or
      l("No current price","Нет актуальной цены"),1,.7,.35)
  end
  GameTooltip:AddLine(l("Journal position, not a count of physical bags.",
    "Позиция по журналу, не наличие в сумках."),.72,.77,.81,true)
  GameTooltip:Show()
end
local function stockTip(control,row,inventory)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(row.key))
  GameTooltip:AddDoubleLine(l("In bags","В сумках"),tostring(row.bagQty),1,1,1,.85,.95,1)
  GameTooltip:AddDoubleLine(l("In bank (last seen)","В банке (посл. проверка)"),tostring(row.bankQty),1,1,1,.85,.95,1)
  if row.status=="priced" then
    GameTooltip:AddDoubleLine(l("Observed unit price","Цена последнего замера"),currency(row.price),1,1,1,.85,.9,.5)
    GameTooltip:AddDoubleLine(l("Bags value","Стоимость сумок"),currency(row.bagValue),1,1,1,.85,.9,.5)
    GameTooltip:AddDoubleLine(l("Bank value (last seen)","Стоимость банка (посл. проверка)"),currency(row.bankValue),1,1,1,.85,.9,.5)
    GameTooltip:AddLine(l("Quote age: ","Возраст замера: ")..string.format("%.1f h",row.quoteAge/3600),.7,.83,.9)
  else
    GameTooltip:AddLine(row.status=="stale" and l("Stale quote, valuation excluded","Устаревшая цена, оценка исключена") or
      l("No quote, valuation excluded","Нет цены, оценка исключена"),1,.74,.4)
  end
  GameTooltip:AddLine(l("Inventory origin and acquisition cost are unknown. This is not profit.",
    "Происхождение и себестоимость неизвестны. Это не прибыль."),1,.79,.47,true)
  if inventory.bankKnown then
    GameTooltip:AddLine(l("Bank last checked: ","Банк проверен: ")..ageText(inventory.bankTime),.7,.78,.85)
  end
  GameTooltip:Show()
end
local function saleTip(control,row)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(row.key).." x"..row.qty)
  GameTooltip:AddDoubleLine(l("Gross receipt","Выручка до комиссии"),currency(row.gross),1,1,1,.9,.85,.52)
  GameTooltip:AddDoubleLine(l("Auction fee","Комиссия аукциона"),currency(row.fees),1,1,1,.9,.85,.52)
  GameTooltip:AddDoubleLine(l("Net receipt","Выручка после комиссии"),currency(row.net),1,1,1,.7,.95,.65)
  GameTooltip:AddDoubleLine(l("With known buy cost","С известной закупкой"),tostring(row.matched),1,1,1,.75,.84,.92)
  GameTooltip:AddDoubleLine(l("Without known buy cost","Без известной закупки"),tostring(row.unmatched),1,1,1,1,.76,.42)
  if row.matched>0 then
    GameTooltip:AddDoubleLine(l("Profit on matched units","Прибыль по учтённым единицам"),currency(row.pnl),1,1,1,.7,.95,.65)
  end
  GameTooltip:AddLine(l("Confirmed sale via auction mail. Unmatched profit is unknown.",
    "Продажа подтверждена почтой; прибыль без закупки неизвестна."),1,.82,.49,true)
  GameTooltip:Show()
end

function B.portfolio(root)
  local p=newPage(root)
  heading(p,l("Trading Portfolio: stock, sales and cost basis",
    "Торговый портфель: запасы, продажи и себестоимость"),-12)
  p.mode="stock";p.pageIndex=1
  local modes={stock={"Stock","Запасы"},sales={"Sales","Продажи"},ledger={"Cost basis","Себестоимость"}}
  button(p,l("Refresh","Обновить"),20,-53,126,function()
    if A.RefreshPortfolioStock then A.RefreshPortfolioStock(true) end
    p.update()
  end)
  for _,control in ipairs({{id="stock",x=159,width=112},{id="sales",x=284,width=112},
    {id="ledger",x=409,width=150}}) do
    p[control.id.."Mode"]=button(p,l(modes[control.id][1],modes[control.id][2]),
      control.x,-53,control.width,function()
        p.mode=control.id;p.pageIndex=1;p.update()
      end)
  end
  button(p,l("Journal","Журнал"),573,-53,138,function()A.ShowProTab("journal")end)
  p.subtitle=fs(p,"",20,-94,696)
  tex(p,18,-113,695,103,.063,.085,.107,.78)
  tex(p,18,-113,695,1,.48,.37,.19,.73)
  p.sales=fs(p,"",25,-121,685,true)
  p.revenue=fs(p,"",25,-148,685)
  p.profit=fs(p,"",25,-174,685)
  p.stock=fs(p,"",25,-200,685)
  p.section=fs(p,"",20,-231,692,true)
  tex(p,20,-250,693,1,.43,.33,.16,.64)
  p.rows=lineList(p,PAGE_SIZE,-263,32)
  p.empty=fs(p,"",25,-323,674)
  p.note=fs(p,"",20,-466,693)
  p.prev=button(p,l("< Back","< Назад"),20,-515,126,function()
    if p.pageIndex>1 then p.pageIndex=p.pageIndex-1;p.update() end
  end)
  p.pageText=fs(p,"",162,-521,270)
  p.next=button(p,l("Next >","Вперёд >"),584,-515,126,function()
    p.pageIndex=p.pageIndex+1;p.update()
  end)
  p.update=function()
    local sales=A.PortfolioSalesReport()
    local ledger=A.PortfolioSnapshot()
    local inventory=A.PortfolioHoldings()
    local hasMatched=sales.matched>0
    p.sales:SetText(l("Confirmed AH sales: ","Подтверждённых продаж: ")..sales.count..
      l("   Units: ","   Штук: ")..sales.units..
      l("   Gross: ","   До комиссии: ")..currency(sales.gross))
    p.revenue:SetText(l("Auction fees: ","Комиссии: ")..currency(sales.fees)..
      l("   NET REVENUE: ","   ЧИСТАЯ ВЫРУЧКА: ")..currency(sales.net))
    p.profit:SetText(l("Matched profit: ","Прибыль с себестоимостью: ")..
      (hasMatched and currency(sales.realized) or l("unknown","неизвестна"))..
      l("   Unmatched units: ","   Без закупки: ")..sales.unmatched)
    p.stock:SetText(l("Bags: ","В сумках: ")..
      (inventory.bagKnown and tostring(inventory.bagUnits) or "?")..
      l("   Bank (last seen): ","   Банк (посл. проверка): ")..
      (inventory.bankKnown and tostring(inventory.bankUnits) or "?")..
      l("   Bags value: ","   Цена сумок: ")..currency(inventory.bagValue))
    local list
    if p.mode=="sales" then
      list=sales.sales
      p.section:SetText(l("CONFIRMED AUCTION SALES (latest first)",
        "ПОДТВЕРЖДЁННЫЕ ПРОДАЖИ (сначала новые)"))
      p.note:SetText(l("Cash revenue is real; profit requires known purchase cost. Manual sales excluded.",
        "Выручка подтверждена; для прибыли нужна себестоимость. Ручные продажи отдельно."))
      p.empty:SetText(l("No confirmed auction sales yet. Enable mail import and open mailbox.",
        "Пока нет подтверждённых продаж. Включите импорт и откройте почту."))
    elseif p.mode=="ledger" then
      list=ledger.positions
      p.section:SetText(l("OPEN JOURNAL POSITIONS (known purchase cost)",
        "ПОЗИЦИИ ЖУРНАЛА (известная себестоимость)"))
      p.note:SetText(l("Journal units are not physical bag stock. Unrealized P&L is only an estimate.",
        "Позиции журнала не равны сумкам. Нереализованная прибыль — только оценка."))
      p.empty:SetText(l("No open journal purchase lots. Confirmed sales still appear above.",
        "Нет открытых закупок. Подтверждённые продажи показаны выше."))
    else
      list=inventory.items
      p.section:SetText(l("CURRENT BAGS + BANK (bank = last observed snapshot)",
        "СУМКИ И БАНК (банк = последний проверенный снимок)"))
      p.note:SetText(l("Bank valuation (last seen): ","Оценка банка (посл. снимок): ")..
        currency(inventory.bankValue)..l("   Bags: ","   Сумки: ")..
        (inventory.bagKnown and ageText(inventory.bagsTime) or "?")..
        l("   Bank: ","   Банк: ")..
        (inventory.bankKnown and ageText(inventory.bankTime) or l("not scanned","не проверен"))..
        l("   Excl. stale/missing", "   Без старых/пустых цен"))
      p.empty:SetText(inventory.bagKnown and l("No items in tracked bags/bank.",
        "В учтённых сумках/банке нет предметов.") or l("Bag data unavailable. Try Refresh or open your bags.",
        "Данные сумок недоступны. Нажмите «Обновить» или откройте сумки."))
    end
    local total=#list
    local pages=math.max(1,math.ceil(total/PAGE_SIZE))
    p.pageIndex=math.max(1,math.min(p.pageIndex,pages))
    p.pageText:SetText(l("Page ","Страница ")..p.pageIndex.." / "..pages)
    if total==0 then p.empty:Show() else p.empty:Hide() end
    if p.prev.SetEnabled then p.prev:SetEnabled(p.pageIndex>1) end
    if p.next.SetEnabled then p.next:SetEnabled(p.pageIndex<pages) end
    for i=1,#p.rows do
      local entry=list[(p.pageIndex-1)*PAGE_SIZE+i]
      local row=p.rows[i]
      if entry then
        local name=labelName(entry.key,row,196)
        if p.mode=="sales" then
          row:SetText(name.." x"..entry.qty..
            l("   Net ","   Выручка ")..currency(entry.net)..
            (entry.unmatched>0 and l("   COST UNKNOWN","   НЕТ СЕБЕСТ.") or ""))
          row:SetScript("OnEnter",function(self)saleTip(self,entry)end)
        elseif p.mode=="ledger" then
          local status=entry.status=="priced" and currency(entry.pnl) or
            (entry.status=="stale" and l("STALE","УСТАРЕЛО") or l("NO PRICE","НЕТ ЦЕНЫ"))
          row:SetText(name.." x"..entry.qty..l("   Cost ","   Закупка ")..
            currency(entry.cost)..l("   Est. ","   Оценка ")..status)
          row:SetScript("OnEnter",function(self)positionTip(self,entry)end)
        else
          local estimate=entry.status=="priced" and currency(entry.bagValue) or
            (entry.status=="stale" and l("STALE","УСТАРЕЛО") or l("NO PRICE","НЕТ ЦЕНЫ"))
          row:SetText(name..l("   Bags ","   Сумки ")..entry.bagQty..
            l("   Bank* ","   Банк* ")..entry.bankQty..
            l("   Bags value ","   Цена сумок ")..estimate)
          row:SetScript("OnEnter",function(self)stockTip(self,entry,inventory)end)
        end
        row:SetScript("OnClick",function()
          if A.OpenDashboardScanKey and A.ProItemLink and A.ProItemLink(entry.key) then
            A.OpenDashboardScanKey(entry.key)
          end
        end)
        row:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
        row:Show()
      else
        row:Hide();row:SetScript("OnEnter",nil);row:SetScript("OnClick",nil)
      end
    end
  end
  -- Initialize the live bag snapshot even if the Crafting stock setting is off.
  if A.RefreshPortfolioStock then A.RefreshPortfolioStock(false) end
  p.update()
  return p
end
