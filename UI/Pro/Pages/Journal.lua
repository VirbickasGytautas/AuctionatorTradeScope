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

function B.journal(root)
  local p=newPage(root)
  heading(p,l("Manual trade journal: realized P&L","Ручной журнал сделок: фактический результат"),-12)
  p.selection=marketInput(p,20,-60,188)
  p.qty=edit(p,l("Quantity","Количество"),223,-60,87,"1",true)
  p.gold=edit(p,l("Gold","Золото"),326,-60,75,"0",true)
  p.silver=edit(p,l("Silver","Серебро"),411,-60,75,"0",true)
  p.copper=edit(p,l("Copper","Медь"),496,-60,75,"0",true)
  p.total=fs(p,"",20,-154,690,true)
  local function record(kind)
    local key=anyItem(p)
    local price=(tonumber(p.gold:GetText()) or 0)*10000+
      (tonumber(p.silver:GetText()) or 0)*100+(tonumber(p.copper:GetText()) or 0)
    if not key then p.total:SetText(l("Choose an item.","Выберите предмет."));return end
    local ok=A.AddJournalTrade(key,kind,tonumber(p.qty:GetText()),price,A.db.pro.journalFee)
    if not ok then p.total:SetText(l("Invalid transaction.","Ошибка заполнения."));return end
    p.update()
  end
  button(p,l("Record BUY","Записать ПОКУПКУ"),20,-127,170,function()record("buy")end)
  button(p,l("Record SELL","Записать ПРОДАЖУ"),204,-127,170,function()record("sell")end)
  p.rows=lineList(p,11,-195,30)
  button(p,l("Undo last trade","Отменить последнюю"),20,-536,205,function()
    local j=A.ProJournal();if #j>0 then A.DeleteJournalTrade(#j) end;p.update()
  end)
  p.update=function()
    local report=A.JournalReport()
    p.total:SetText(l("Realized P&L: ","Реализованная прибыль: ")..currency(report.realized)..
      "    "..l("Unmatched sold units: ","Продажи без закупки: ")..report.unmatched)
    for i=1,#p.rows do
      local index=#report.entries-i+1
      local t=report.entries[index];local row=p.rows[i]
      if t then
        row:SetText(date("%d.%m %H:%M",t.t).."   "..
          (t.kind=="buy" and l("BUY","ПОКУПКА") or l("SELL","ПРОДАЖА"))..
          "  "..A.ProItemName(t.key).."   x"..t.qty.."  "..currency(t.price))
        row:SetScript("OnClick",function()
          fillMarketEdit(p.selection,{key=t.key,text=A.ProItemName(t.key)})
          shareMarketChoice(p.selection,t.key)
        end)
        row:Show()
      else row:Hide() end
    end
  end
  return p
end

