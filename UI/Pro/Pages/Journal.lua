-- Trading Journal 2.0: manual ledger with read-only per-trade P&L and filters.
-- All filters and page numbers are local UI state, not SavedVariables.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l=C.l
local fs=C.fs
local button=C.button
local dropdown=C.dropdown
local tex=C.tex
local edit=C.edit
local marketInput=C.marketInput
local anyItem=C.anyItem
local fillMarketEdit=C.fillMarketEdit
local shareMarketChoice=C.shareMarketChoice
local newPage=C.newPage
local heading=C.heading
local lineList=C.lineList
local currency=C.currency

local DAY=24*60*60
local PAGE_SIZE=8
local periods={0,7,30,90}
local function feeText(entry)
  if entry.kind=="buy" then return "" end
  if entry.matched==0 then return l("Unmatched","Без закупки") end
  local value=(entry.pnl>=0 and "+" or "")..currency(entry.pnl)
  return (entry.unmatched>0 and "~" or "")..value
end
local function details(row,entry)
  if not GameTooltip then return end
  GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
  GameTooltip:SetText(A.ProItemName(entry.key).." x"..entry.qty)
  GameTooltip:AddLine(date("%d.%m.%Y %H:%M",entry.t),.65,.75,.86)
  GameTooltip:AddDoubleLine(l("Unit price","Цена за шт."),currency(entry.price),1,1,1,1,.84,.39)
  if entry.kind=="sell" then
    GameTooltip:AddDoubleLine(l("Matched quantity","Учтено количество"),tostring(entry.matched),1,1,1,.53,.95,.63)
    if entry.unmatched>0 then
      GameTooltip:AddDoubleLine(l("Without purchase","Без закупки"),tostring(entry.unmatched),1,.70,.40,1,.70,.40)
    end
    GameTooltip:AddDoubleLine(l("Auction fees","Комиссии"),currency(entry.fees),1,1,1,1,.80,.50)
    GameTooltip:AddDoubleLine(l("Known cost basis","Известная себестоимость"),currency(entry.costBasis),1,1,1,.80,.84,1)
    GameTooltip:AddDoubleLine(l("Realized P&L","Реализованная прибыль"),entry.pnl and currency(entry.pnl) or "-",1,1,1,.55,.95,.65)
    if entry.roi then GameTooltip:AddLine(string.format("ROI: %.1f%%",entry.roi),.75,.90,.72) end
    if entry.unmatched>0 then
      GameTooltip:AddLine(l("Unmatched units are excluded from realized P&L.",
        "Продажи без известной закупки исключены из расчёта прибыли."),1,.76,.44,true)
    end
  else
    GameTooltip:AddDoubleLine(l("Purchase cost","Расход на закупку"),currency(entry.price*entry.qty),1,1,1,.80,.84,1)
  end
  GameTooltip:Show()
end

function B.journal(root)
  local p=newPage(root)
  heading(p,l("Trading Journal: weighted-cost P&L","Журнал сделок: прибыль с учётом себестоимости"),-12)
  -- Inputs use a shared baseline. Actions and summaries have independent rows.
  p.selection=marketInput(p,20,-55,200)
  p.qty=edit(p,l("Quantity","Количество"),236,-55,92,"1",true)
  p.gold=edit(p,l("Gold","Золото"),344,-55,82,"0",true)
  p.silver=edit(p,l("Silver","Серебро"),442,-55,80,"0",true)
  p.copper=edit(p,l("Copper","Медь"),538,-55,78,"0",true)
  p.filter={onlyItem=false,kind="all",periodIndex=1}
  p.pageIndex=1

  local function resetPage()
    p.pageIndex=1
    if p.update then p.update() end
  end
  local function record(kind)
    local key=anyItem(p)
    local price=(tonumber(p.gold:GetText()) or 0)*10000+
      (tonumber(p.silver:GetText()) or 0)*100+(tonumber(p.copper:GetText()) or 0)
    if not key then p.total:SetText(l("Choose an item.","Выберите предмет."));return end
    if not A.AddJournalTrade(key,kind,tonumber(p.qty:GetText()),price,A.db.pro.journalFee) then
      p.total:SetText(l("Invalid transaction.","Ошибка заполнения."));return
    end
    resetPage()
  end
  button(p,l("Record BUY","Записать ПОКУПКУ"),20,-125,180,function()record("buy")end)
  button(p,l("Record SELL","Записать ПРОДАЖУ"),211,-125,180,function()record("sell")end)
  -- First portfolio beta: explicit route from the existing manual journal.
  button(p,l("Portfolio","Портфель"),402,-125,115,function()
    A.ShowProTab("portfolio")
  end)
  p.undo=button(p,l("Undo last trade","Отменить последнюю"),529,-125,180,function()
    local ledger=A.ProJournal()
    if #ledger>0 then A.DeleteJournalTrade(#ledger) end
    resetPage()
  end)

  -- Same quiet gold-toned summary as the market scanner, without overlapping buttons.
  tex(p,18,-159,698,50,.055,.075,.095,.73)
  tex(p,18,-159,698,1,.49,.36,.15,.65)
  p.total=fs(p,"",25,-165,686,true)
  p.summary=fs(p,"",25,-187,686)
  fs(p,l("FILTER TRANSACTIONS","ФИЛЬТРЫ СДЕЛОК"),20,-213,690)

  -- Dropdowns choose an option directly; no repeated-click cycling.
  p.itemFilter=dropdown(p,l("ITEM FILTER","ФИЛЬТР ПРЕДМЕТА"),20,-235,198,{
    {value="all",text=l("All items","Все предметы")},
    {value="selected",text=l("Selected item","Выбранный предмет")},
  },function()return p.filter.onlyItem and "selected" or "all" end,function(value)
    p.filter.onlyItem=value=="selected"
    resetPage()
  end)
  p.kindFilter=dropdown(p,l("TRANSACTION TYPE","ТИП СДЕЛКИ"),229,-235,182,{
    {value="all",text=l("All transactions","Все сделки")},
    {value="buy",text=l("BUY only","Только ПОКУПКИ")},
    {value="sell",text=l("SELL only","Только ПРОДАЖИ")},
  },function()return p.filter.kind end,function(value)
    p.filter.kind=value
    resetPage()
  end)
  p.timeFilter=dropdown(p,l("TIME PERIOD","ПЕРИОД"),422,-235,179,{
    {value=1,text=l("All time","Всё время")},
    {value=2,text=l("Last 7 days","За 7 дней")},
    {value=3,text=l("Last 30 days","За 30 дней")},
    {value=4,text=l("Last 90 days","За 90 дней")},
  },function()return p.filter.periodIndex end,function(value)
    p.filter.periodIndex=value
    resetPage()
  end)
  p.clearFilter=button(p,l("Reset","Сброс"),613,-235,96,function()
    p.filter.onlyItem=false;p.filter.kind="all";p.filter.periodIndex=1
    for _,menu in ipairs(p.proDropdowns or {}) do menu:Hide() end
    resetPage()
  end)
  p.filterSummary=fs(p,"",20,-266,696)
  tex(p,20,-284,696,1,.43,.34,.17,.60)

  -- Compact row rhythm fits eight trades and navigation inside the 557px page.
  p.rows=lineList(p,PAGE_SIZE,-298,25)
  p.emptyTitle=fs(p,l("No trades to show","Нет сделок для отображения"),34,-340,660,true)
  p.emptyHint=fs(p,l("Record a purchase or sale above, or change the filters.",
    "Добавьте покупку или продажу выше либо измените фильтры."),34,-364,660)
  p.prev=button(p,l("< Prev","< Назад"),20,-520,120,function()
    if p.pageIndex>1 then p.pageIndex=p.pageIndex-1;p.update() end
  end)
  p.pageText=fs(p,"",156,-527,285)
  p.next=button(p,l("Next >","Вперёд >"),591,-520,117,function()
    p.pageIndex=p.pageIndex+1;p.update()
  end)

  p.update=function()
    local opts={kind=p.filter.kind}
    local key
    if p.filter.onlyItem then
      key=anyItem(p)
      -- A sentinel yields zero entries instead of accidentally showing all.
      opts.itemKey=key or "__tradescope_no_selected_item__"
    end
    local days=periods[p.filter.periodIndex]
    if days>0 then opts.fromTime=time()-days*DAY end
    local report=A.JournalAnalysis(nil,opts)
    local pageRows,page,pages=A.JournalPage(report.entries,p.pageIndex,PAGE_SIZE)
    p.pageIndex=page
    p.itemFilter:SetText(p.filter.onlyItem and l("Item: selected","Предмет: выбран") or l("Item: all","Предмет: все"))
    local kindNames={all={"Type: all","Тип: все"},buy={"Type: BUY","Тип: ПОКУПКА"},sell={"Type: SELL","Тип: ПРОДАЖА"}}
    local text=kindNames[p.filter.kind]
    p.kindFilter:SetText(l(text[1],text[2]))
    p.timeFilter:SetText(days==0 and l("Period: all","Период: весь") or
      (l("Last ","За ")..days..l(" days"," дн.")))
    p.total:SetText(l("Realized P&L: ","Реализованная прибыль: ")..currency(report.realized)..
      "    ROI: "..(report.roi and string.format("%.1f%%",report.roi) or "-"))
    p.summary:SetText(l("Matched: ","Продано с закупкой: ")..report.matched..
      "    "..l("Unmatched: ","Без закупки: ")..report.unmatched..
      "    "..l("Fees: ","Комиссии: ")..currency(report.fees))
    p.filterSummary:SetText(l("Records: ","Записей: ")..#report.entries..
      "    "..l("All open units: ","Общий остаток: ")..report.openUnits..
      (p.filter.onlyItem and not key and l("   Select an item first.","   Сначала выберите предмет.") or ""))
    p.pageText:SetText(l("Page ","Страница ")..page.." / "..pages)
    local empty=#report.entries==0
    if empty then
      p.emptyTitle:Show();p.emptyHint:Show()
    else
      p.emptyTitle:Hide();p.emptyHint:Hide()
    end
    if p.prev.SetEnabled then p.prev:SetEnabled(page>1) end
    if p.next.SetEnabled then p.next:SetEnabled(page<pages) end
    for i=1,#p.rows do
      local entry=pageRows[i]
      local row=p.rows[i]
      if entry then
        local name=A.ProItemName(entry.key)
        if A.FitItemName then name=A.FitItemName(name,row:GetFontString(),218) or name end
        local side=entry.kind=="buy" and l("BUY","ПОКУПКА") or l("SELL","ПРОДАЖА")
        local tail=entry.kind=="sell" and ("   P&L "..feeText(entry)) or ""
        row:SetText(date("%d.%m %H:%M",entry.t).."  "..side.." x"..entry.qty..
          "  "..name.."  "..currency(entry.price)..tail)
        row:SetScript("OnClick",function()
          fillMarketEdit(p.selection,{key=entry.key,text=A.ProItemName(entry.key)})
          shareMarketChoice(p.selection,entry.key)
          if p.filter.onlyItem then resetPage() end
        end)
        row:SetScript("OnEnter",function(self) details(self,entry) end)
        row:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
        row:Show()
      else
        row:Hide()
        row:SetScript("OnClick",nil)
        row:SetScript("OnEnter",nil)
      end
    end
  end
  p.update()
  return p
end
