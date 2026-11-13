-- Craft calculator: render material rows and economic summary.
-- Extracted without changing the recipe evaluation or SavedVariables format.
local A=ATS
local C=assert(A.ProUIShared)
local l=C.l
local currency=C.currency

function A.CreateCraftReportRenderer(ctx)
  local p=assert(ctx.p)
  local productHotspot=assert(ctx.productHotspot)
  local productIcon=assert(ctx.productIcon)
  local displayName=assert(ctx.displayName)
  local formatValue=assert(ctx.formatValue)
  local PAGE_SIZE=assert(ctx.pageSize)
  return function()
    local active=ctx.getActive()
    local batchCount=ctx.getBatchCount()
    local page=ctx.getPage()
    p.stockToggle:SetChecked(A.db.pro.craftInventoryEnabled==true)
    for i=1,#p.materialRows do
      local row=p.materialRows[i]
      row.background:Hide();row.icon:Hide();row.title:Hide();row.qty:Hide()
      row.owned:Hide();row.buy:Hide();row.unit:Hide();row.total:Hide();row.hotspot:Hide();row.include:Hide()
      row.sourceIndex=nil
    end
    if not active then
      p.productName:SetText(l("Choose a recipe to see its ingredients and costs.",
        "Выберите рецепт, чтобы увидеть ресурсы и их стоимость."))
      p.productMade:SetText("")
      productHotspot:Hide()
      p.summary1:SetText("");p.summary2:SetText("")
      p.summary3:SetText("");p.info:SetText("")
      p.pageLabel:SetText("")
      return
    end
    local productName,productTexture=displayName(active.product,active.productName or active.name,active.productIcon)
    if type(productTexture)=="number" or type(productTexture)=="string" then
      productIcon:SetTexture(productTexture)
    else productIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
    p.productName:SetText(productName)
    productHotspot:Show()
    local made=math.max(1,math.floor(tonumber(active.made) or 1))
    p.productMade:SetText(l("Per craft: ","За крафт: ")..made..
      l("   Batch output: ","   В партии: ")..(made*batchCount))
    local list=active.materials or {}
    local pages=math.max(1,math.ceil(#list/PAGE_SIZE))
    page=math.max(1,math.min(page,pages))
    ctx.setPage(page)
    p.pageLabel:SetText(l("Items: ","Рес.: ")..#list.."  "..page.."/"..pages)
    local report=A.EvaluateCraftBatch and A.EvaluateCraftBatch(active,batchCount)
    local rows=report and report.rows or {}
    for index=1,#list do
      local mat=list[index]
      if index>(page-1)*PAGE_SIZE and index<=page*PAGE_SIZE then
        local row=p.materialRows[index-(page-1)*PAGE_SIZE]
        local result=rows[index]
        local itemName,itemTexture=displayName(mat.id,mat.name,mat.icon)
        row.icon:SetTexture(itemTexture or mat.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.title:SetText(A.FitItemName and A.FitItemName(itemName,row.title,179) or itemName)
        row.qty:SetText(tostring(result and result.qty or (tonumber(mat.qty) or 1)*batchCount))
        if report and report.inventoryEnabled then
          local total=result and result.stock or 0
          row.owned:SetText(tostring(total))
          row.owned:SetTextColor(.48,.86,.62)
          row.buy:SetText(result and result.include and tostring(result.buy or 0) or "-")
          row.buy:SetTextColor((result and result.buy or 0)>0 and 1 or .48,
            (result and result.buy or 0)>0 and .77 or .86,.42)
        else
          row.owned:SetText("-")
          row.owned:SetTextColor(.54,.59,.64)
          row.buy:SetText("-")
          row.buy:SetTextColor(.54,.59,.64)
        end
        row.unit:SetText(formatValue(result and result.unit))
        row.total:SetText(result and result.include and formatValue(result.cost)
          or l("Excluded","Исключён"))
        if result and not result.include then
          row.title:SetTextColor(.53,.57,.61)
          row.total:SetTextColor(.70,.58,.30)
        else
          row.title:SetTextColor(1,.85,.37)
          row.total:SetTextColor(1,1,1)
        end
        row.sourceIndex=index
        row.include:SetChecked(not result or result.include)
        row.hotspot.material={id=mat.id,name=itemName,
          stock=result and result.stock,bankTime=result and result.bankTime,
          buy=result and result.buy}
        row.background:Show();row.icon:Show();row.title:Show();row.qty:Show()
        row.owned:Show();row.buy:Show();row.unit:Show();row.total:Show();row.hotspot:Show();row.include:Show()
      end
    end
    local market=report and report.marketCost
    local cash=report and report.cashCost
    local net=report and report.net
    local excluded=report and report.excluded or 0
    p.summary1:SetText(l("Selected materials cost: ","Стоимость отмеченных ресурсов: ")..
      formatValue(market)..(report and report.inventoryEnabled and
      ("   "..l("Additional purchases: ","Нужно докупить на: ")..formatValue(cash)) or ""))
    p.summary2:SetText(l("Output quote: ","Цена результата: ")..
      formatValue(report and report.outputQuote).."   "..
      l("Net revenue: ","Выручка после комиссии: ")..formatValue(net))
    local baseline=report and report.marketProfit
    local cashProfit=report and report.cashProfit
    p.summary3:SetText(l("Market profit: ","Рыночная прибыль: ")..
      formatValue(baseline).."   ROI: "..
      (report and type(report.roi)=="number" and string.format("%.1f%%",report.roi)
        or l("No data","Нет данных"))..(report and report.inventoryEnabled and
      ("   "..l("Cash-basis: ","Денежная: ")..formatValue(cashProfit)) or ""))
    p.summary3:SetTextColor(type(baseline)=="number" and
      (baseline>=0 and .42 or 1) or 1,
      type(baseline)=="number" and (baseline>=0 and 1 or .55) or .73,.39)
    local messages={}
    if excluded>0 then messages[#messages+1]=l("Excluded ingredients: ",
      "Исключено ресурсов: ")..excluded.." ("..l("incomplete costs","неполная себестоимость")..")" end
    if report and (#report.missingMarket>0 or #report.missingCash>0) then
      messages[#messages+1]=l("Missing quotes: ","Нет цен: ")..
        table.concat(report.missingMarket,",")
    end
    if report and report.inventoryEnabled then
      local info=A.CraftStockInfo and A.CraftStockInfo()
      if info and not info.bankKnown then
        messages[#messages+1]=l("Bank not scanned; open bank to count it.",
          "Банк не проверен — откройте банк для учёта.")
      elseif info and info.bankTime then
        messages[#messages+1]=l("Bank last checked: ","Банк проверен: ")..
          date("%d.%m %H:%M",info.bankTime)
      end
    end
    if #messages==0 then
      messages[1]=l("Own stock reduces new gold expenses, not the market value of materials.",
        "Свои ресурсы снижают расходы на докупку, но имеют рыночную стоимость.")
    end
    p.info:SetText(table.concat(messages,"   "))
  end

end
