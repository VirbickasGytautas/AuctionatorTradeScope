-- TradeScope 4.5.0-beta3: portfolio overview for confirmed revenue and inventory.
-- Stock != purchased lots. Inventory market value != realized/unrealized profit.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l,fs,button,newPage,heading,lineList,tex,currency=
  C.l,C.fs,C.button,C.newPage,C.heading,C.lineList,C.tex,C.currency
local PAGE_SIZE=6
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

local function allocationTip(control,row,report)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(row.key))
  GameTooltip:AddDoubleLine(l("Source value","Стоимость источника"),currency(row.value),1,1,1,.91,.85,.52)
  GameTooltip:AddDoubleLine(l("Share of priced subset","Доля в оценённой части"),
    string.format("%.1f%%",row.share),1,1,1,.76,.92,.65)
  GameTooltip:AddDoubleLine(l("Units / trades","Единиц / продаж"),tostring(row.qty),1,1,1,.77,.86,.96)
  if report.basis=="bags" or report.basis=="bank" then
    GameTooltip:AddLine(l("Measured market value, not known profit.",
      "Рыночная оценка, а не известная прибыль."),1,.79,.47,true)
  elseif report.basis=="sales" then
    GameTooltip:AddLine(l("Confirmed NET mail-sale revenue, not profit.",
      "Чистая выручка по подтверждённым письмам, не прибыль."),1,.79,.47,true)
  else
    GameTooltip:AddLine(l("Open Journal purchase cost, not physical holdings.",
      "Закупочная стоимость журнала, не запасы сумок."),1,.79,.47,true)
  end
  if report.basis=="bank" then
    GameTooltip:AddLine(l("Last bank visit: ","Последнее посещение банка: ")..
      (report.bankAge and string.format("%.1f h",report.bankAge/3600) or "?"),.78,.83,.9)
  end
  if report.excluded>0 then
    GameTooltip:AddLine(l("Unpriced/stale items are excluded from shares.",
      "Предметы без свежей цены не включены в доли."),1,.76,.42,true)
  end
  GameTooltip:Show()
end
local function allocationWarning(report)
  local messages={
    not_scanned={"Source has not been scanned.","Источник ещё не проверен."},
    no_comparable_value={"No comparable value available.","Нет сопоставимых оценок."},
    partial_quotes={"Some items lack recent prices: shares cover the priced subset only.",
      "Часть цен отсутствует: доли только среди оценённых предметов."},
    single_item={"Only one valued item: diversification cannot be assessed.",
      "Оценён один предмет: диверсификацию оценить нельзя."},
    top_heavy={"Concentration: one item is 50%+ of this source.",
      "Концентрация: один предмет занимает 50%+ этого источника."},
    top_three_heavy={"Concentration: top three items are 85%+ of the source.",
      "Концентрация: три предмета дают 85%+ стоимости источника."},
    bank_stale={"Bank snapshot is over 24h old (or time unknown).",
      "Снимок банка старше 24 ч (или время неизвестно)."},
  }
  local words={}
  for i,code in ipairs(report.warnings or {}) do
    local msg=messages[code]
    if msg then words[#words+1]=l(msg[1],msg[2]) end
  end
  if #words==0 then return l("No concentration warning for this source.",
    "Для этого источника предупреждений нет.") end
  return table.concat(words,"  |  ")
end

function B.portfolio(root)
  local p=newPage(root)
  heading(p,l("Trading Portfolio: stock, sales and cost basis",
    "Торговый портфель: запасы, продажи и себестоимость"),-12)
  p.mode="stock";p.pageIndex=1;p.allocationBasis="bags"
  local modes={stock={"Stock","Запасы"},sales={"Sales","Продажи"},
    ledger={"Cost basis","Себестоимость"},allocation={"Allocation","Распределение"}}
  button(p,l("Refresh","Обновить"),20,-53,106,function()
    if A.RefreshPortfolioStock then A.RefreshPortfolioStock(true) end
    p.update()
  end)
  for _,control in ipairs({{id="stock",x=137,width=101},{id="sales",x=249,width=101},
    {id="ledger",x=361,width=130},{id="allocation",x=502,width=121}}) do
    p[control.id.."Mode"]=button(p,l(modes[control.id][1],modes[control.id][2]),
      control.x,-53,control.width,function()
        p.mode=control.id;p.pageIndex=1;p.update()
      end)
  end
  button(p,l("Journal","Журнал"),634,-53,77,function()A.ShowProTab("journal")end)
  p.subtitle=fs(p,"",20,-94,696)
  tex(p,18,-113,695,103,.063,.085,.107,.78)
  tex(p,18,-113,695,1,.48,.37,.19,.73)
  p.sales=fs(p,"",25,-121,685,true)
  p.revenue=fs(p,"",25,-148,685)
  p.profit=fs(p,"",25,-174,685)
  p.stock=fs(p,"",25,-200,685)
  p.section=fs(p,"",20,-231,486,true)
  p.allocationSource=assert(C.dropdown)(p,l("ALLOCATION BASIS","ОСНОВА РАСПРЕДЕЛЕНИЯ"),
    510,-225,200,{
      {value="bags",text=l("Bags: observed value","Сумки: рыночная оценка")},
      {value="bank",text=l("Bank: last-known value","Банк: последний снимок")},
      {value="cost",text=l("Journal: invested cost","Журнал: вложения")},
      {value="sales",text=l("AH sales: net revenue","Продажи: чистая выручка")},
    },function()return p.allocationBasis end,function(value)
      p.allocationBasis=value;p.pageIndex=1;p.update()
    end)
  p.allocationSource:Hide()
  tex(p,20,-250,693,1,.43,.33,.16,.64)
  p.rows=lineList(p,PAGE_SIZE,-263,32)
  -- Shared portfolio row layout, matching the Market Scanner's 21px item icon.
  -- Keep the item name and metrics in separate columns; Allocation alone adds
  -- a full-width, 7px distribution bar below the headline.
  local ICON_SIZE=21
  local BAR_WIDTH,BAR_HEIGHT=640,7
  local UNKNOWN_ICON="Interface\\Icons\\INV_Misc_QuestionMark"
  p.allocationBars={}
  for i,row in ipairs(p.rows) do
    assert(C.attachProRowIcon)(row,7,ICON_SIZE)

    local title=row:GetFontString()
    if title then
      title:ClearAllPoints()
      title:SetPoint("TOPLEFT",row,"TOPLEFT",36,-7)
      title:SetWidth(245)
      title:SetJustifyH("LEFT")
      if title.SetWordWrap then title:SetWordWrap(false) end
    end
    row.itemTitle=title
    local metrics=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    metrics:SetPoint("TOPRIGHT",row,"TOPRIGHT",-11,-7)
    metrics:SetWidth(385)
    metrics:SetJustifyH("RIGHT")
    if metrics.SetWordWrap then metrics:SetWordWrap(false) end
    row.itemMetrics=metrics

    local track=row:CreateTexture(nil,"ARTWORK")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetVertexColor(.17,.23,.28,.97)
    track:SetSize(BAR_WIDTH,BAR_HEIGHT)
    track:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",36,2)
    local fill=row:CreateTexture(nil,"OVERLAY")
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetVertexColor(.98,.76,.31,1)
    fill:SetSize(1,BAR_HEIGHT)
    fill:SetPoint("BOTTOMLEFT",track,"BOTTOMLEFT",0,0)
    track:Hide();fill:Hide()
    p.allocationBars[i]={track=track,fill=fill,width=BAR_WIDTH,height=BAR_HEIGHT}
  end
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
    local allocation=A.PortfolioAllocation(inventory,ledger,sales,p.allocationBasis)
    local hasMatched=sales.matched>0
    if p.mode=="allocation" then
      p.allocationSource:Show()
      local basisNames={bags=l("Bags: market value","Сумки: рыночная стоимость"),
        bank=l("Bank: last-known","Банк: последний снимок"),
        cost=l("Journal: known cost","Журнал: закупочная стоимость"),
        sales=l("AH sales: net receipts","Продажи: чистая выручка")}
      p.allocationSource:SetText(basisNames[p.allocationBasis])
      p.subtitle:SetText(l("One source at a time. Shares exclude unpriced items.",
        "Один источник за раз. Предметы без цены исключены из долей."))
    else
      if p.allocationSource.popup then p.allocationSource.popup:Hide() end
      p.allocationSource:Hide()
      p.subtitle:SetText("")
    end
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
    if p.mode=="allocation" then
      list=allocation.rows
      p.section:SetText(l("DISTRIBUTION OF ONE SOURCE","РАСПРЕДЕЛЕНИЕ ОДНОГО ИСТОЧНИКА"))
      local sourceWord=l("Valued: ","Оценено: ")..allocation.count.."/"..allocation.eligible
      local top=string.format("%.1f%%",allocation.topShare)
      p.subtitle:SetText(sourceWord..l("   Top item: ","   Крупнейший: ")..top..
        l("   Top 3: ","   Топ-3: ")..string.format("%.1f%%",allocation.topThreeShare))
      p.note:SetText(l("Basis total: ","Всего по источнику: ")..currency(allocation.total)..
        "   "..allocationWarning(allocation))
      p.empty:SetText(l("No comparable values for the selected source.",
        "Нет сопоставимых оценок для выбранного источника."))
    elseif p.mode=="sales" then
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
        -- ProItemMeta uses the same localized icon resolver as the scanner.
        -- Fall back to a question-mark icon if the item is not cached yet.
        local name=assert(C.renderProRowItem)(row,entry.key) or A.ProItemName(entry.key)
        row:SetText(A.FitItemName and row.itemTitle and
          (A.FitItemName(name,row.itemTitle,245) or name) or name)
        local allocationMode=p.mode=="allocation"
        local offset=allocationMode and 1 or 7
        if row.itemTitle then
          row.itemTitle:ClearAllPoints()
          row.itemTitle:SetPoint("TOPLEFT",row,"TOPLEFT",36,-offset)
        end
        row.itemMetrics:ClearAllPoints()
        row.itemMetrics:SetPoint("TOPRIGHT",row,"TOPRIGHT",-11,-offset)
        if allocationMode then
          -- The percentage is printed, not just encoded as a bar length.
          row.itemMetrics:SetText(string.format("%.1f%%",entry.share).."   "..currency(entry.value))
          row:SetScript("OnEnter",function(self)allocationTip(self,entry,allocation)end)
        elseif p.mode=="sales" then
          row.itemMetrics:SetText("x"..entry.qty..
            l("   Net ","   Выручка ")..currency(entry.net)..
            (entry.unmatched>0 and l("   COST UNKNOWN","   НЕТ СЕБЕСТ.") or ""))
          row:SetScript("OnEnter",function(self)saleTip(self,entry)end)
        elseif p.mode=="ledger" then
          local status=entry.status=="priced" and currency(entry.pnl) or
            (entry.status=="stale" and l("STALE","УСТАРЕЛО") or l("NO PRICE","НЕТ ЦЕНЫ"))
          row.itemMetrics:SetText("x"..entry.qty..l("   Cost ","   Закупка ")..
            currency(entry.cost)..l("   Est. ","   Оценка ")..status)
          row:SetScript("OnEnter",function(self)positionTip(self,entry)end)
        else
          local estimate=entry.status=="priced" and currency(entry.bagValue) or
            (entry.status=="stale" and l("STALE","УСТАРЕЛО") or l("NO PRICE","НЕТ ЦЕНЫ"))
          row.itemMetrics:SetText(l("Bags ","Сумки ")..entry.bagQty..
            l("   Bank* ","   Банк* ")..entry.bankQty..
            l("   Value ","   Цена ")..estimate)
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
        row:Hide()
        C.renderProRowItem(row,nil)
        row.itemMetrics:SetText("")
        row:SetScript("OnEnter",nil)
        row:SetScript("OnClick",nil)
      end
      local bar=p.allocationBars[i]
      if entry and p.mode=="allocation" then
        bar.track:Show();bar.fill:Show()
        bar.fill:SetSize(math.max(1,math.floor(bar.width*math.max(0,math.min(100,entry.share))/100+.5)),bar.height)
      else
        bar.track:Hide();bar.fill:Hide()
      end
    end
  end
  -- Initialize the live bag snapshot even if the Crafting stock setting is off.
  if A.RefreshPortfolioStock then A.RefreshPortfolioStock(false) end
  p.update()
  if C.watchProRowIcons then C.watchProRowIcons(p,p.rows) end
  return p
end
