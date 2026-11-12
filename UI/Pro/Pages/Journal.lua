-- Trading Journal 2.0: manual ledger with read-only per-trade P&L and filters.
-- All filters and page numbers are local UI state, not SavedVariables.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l=C.l
local fs=C.fs
local button=C.button
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
local kinds={"all","buy","sell"}
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
  p.selection=marketInput(p,20,-60,188)
  p.qty=edit(p,l("Quantity","Количество"),223,-60,87,"1",true)
  p.gold=edit(p,l("Gold","Золото"),326,-60,75,"0",true)
  p.silver=edit(p,l("Silver","Серебро"),411,-60,75,"0",true)
  p.copper=edit(p,l("Copper","Медь"),496,-60,75,"0",true)
  p.total=fs(p,"",20,-154,705,true)
  p.summary=fs(p,"",20,-175,705)
  p.filterSummary=fs(p,"",20,-231,690)
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
  button(p,l("Record BUY","Записать ПОКУПКУ"),20,-127,170,function()record("buy")end)
  button(p,l("Record SELL","Записать ПРОДАЖУ"),204,-127,170,function()record("sell")end)

  p.itemFilter=button(p,"",20,-201,173,function()
    p.filter.onlyItem=not p.filter.onlyItem
    resetPage()
  end)
  p.kindFilter=button(p,"",202,-201,155,function()
    local index=1
    for i=1,#kinds do if kinds[i]==p.filter.kind then index=i;break end end
    p.filter.kind=kinds[index%#kinds+1]
    resetPage()
  end)
  p.timeFilter=button(p,"",366,-201,153,function()
    p.filter.periodIndex=p.filter.periodIndex%#periods+1
    resetPage()
  end)
  p.clearFilter=button(p,l("Clear filters","Сброс фильтров"),528,-201,180,function()
    p.filter.onlyItem=false;p.filter.kind="all";p.filter.periodIndex=1
    resetPage()
  end)
  p.rows=lineList(p,PAGE_SIZE,-255,31)
  p.prev=button(p,l("< Prev","< Назад"),20,-507,115,function()
    if p.pageIndex>1 then p.pageIndex=p.pageIndex-1;p.update() end
  end)
  p.pageText=fs(p,"",147,-513,265)
  p.next=button(p,l("Next >","Вперёд >"),400,-507,122,function()
    p.pageIndex=p.pageIndex+1;p.update()
  end)
  button(p,l("Undo last trade","Отменить последнюю"),520,-529,190,function()
    local ledger=A.ProJournal()
    if #ledger>0 then A.DeleteJournalTrade(#ledger) end
    resetPage()
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
    local kindNames={all={"Side: all","Тип: все"},buy={"Side: BUY","Тип: ПОКУПКА"},sell={"Side: SELL","Тип: ПРОДАЖА"}}
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
