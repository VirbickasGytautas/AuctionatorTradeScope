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

function B.craftscan(root)
  local p=newPage(root)
  heading(p,l("All imported crafting recipes", "Все импортированные рецепты крафта"),-12)
  fs(p,l("Profit, loss and missing quotes. Costs use saved Auctionator prices after auction fees.",
         "Прибыль, убыток и отсутствующие цены. Расчёт по базе Auctionator после комиссии."),20,-49,694)
  local status=fs(p,"",20,-149,690)
  p.status=status
  p.page=1
  p.order=A.db.pro.craftScannerSort=="roi" and "roi" or "profit"
  local list={}
  local perPage=9
  local rows={}
  fs(p,l("RECIPE","РЕЦЕПТ"),61,-171,275,true)
  local tableHeader=fs(p,l("PROFIT PER CRAFT  /  ROI","ПРИБЫЛЬ ЗА КРАФТ  /  ROI"),337,-171,350,true)
  tableHeader:SetJustifyH("RIGHT")
  local separator=tex(p,20,-184,690,1,.42,.31,.15,.85)
  for i=1,perPage do
    local y=-199-(i-1)*35
    local row=CreateFrame("Button",nil,p)
    row:SetPoint("TOPLEFT",p,"TOPLEFT",20,y)
    row:SetSize(696,32)
    local bg=tex(row,0,0,696,32,.085,.12,.145,.95)
    row.bg=bg
    local border=tex(row,0,-31,696,1,.36,.27,.13,.55)
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetSize(27,27);icon:SetPoint("LEFT",row,"LEFT",5,0)
    row.icon=icon
    local title=fs(row,"",41,-4,275)
    row.title=title
    local metrics=fs(row,"",319,-4,367)
    metrics:SetJustifyH("RIGHT")
    row.metrics=metrics
    row:SetScript("OnEnter",function(self)
      self.bg:SetVertexColor(.17,.18,.15,1)
      local d=self.record
      if d then
        showHelp(self,tostring(A.ProRecipeLabel and A.ProRecipeLabel(d.recipe) or d.recipe.name or "Recipe"),
          l("Click to open this recipe in Crafting Calculator. Values are estimates from saved Auctionator quotes. ROI = profit / material cost.",
            "Нажмите, чтобы открыть рецепт в калькуляторе. Оценка по сохранённым ценам Auctionator. ROI = прибыль / стоимость материалов."))
      end
    end)
    row:SetScript("OnLeave",function(self)
      self.bg:SetVertexColor(.085,.12,.145,.95)
      if GameTooltip then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick",function(self)
      if not self.record then return end
      if not A.db.pro.craftEnabled then
        status:SetText(l("Enable Crafting Calculator in settings first.",
          "Сначала включите калькулятор крафта в настройках."))
        return
      end
      local recipe=self.record.recipe
      A.ShowProTab("craft")
      local craftPage=A.proWindow and A.proWindow.pages and A.proWindow.pages.craft
      if craftPage and craftPage.applyExternalRecipe then craftPage.applyExternalRecipe(recipe) end
    end)
    row:Hide()
    rows[i]=row
  end
  local info=fs(p,"",20,-537,694)
  local function refresh()
    list,p.counts=A.ProCraftOpportunities(p.order,
      A.db.pro.craftScannerMinProfitGold,A.db.pro.craftScannerMinROI,
      A.db.pro.craftScannerOnlyProfitable==true)
    p.page=math.max(1,math.min(p.page,math.max(1,math.ceil(#list/perPage))))
    status:SetText(string.format(l(
      "Recipes: %d   Priced: %d   Profit: %d   Loss: %d   Missing quotes: %d",
      "Рецептов: %d   С ценами: %d   Прибыль: %d   Убыток: %d   Нет цен: %d"),
      p.counts.saved,p.counts.priced,p.counts.profitable,p.counts.loss,p.counts.missing))
    local floorIndex=(p.page-1)*perPage
    for i=1,#rows do
      local d=list[floorIndex+i]
      local row=rows[i]
      if d then
        local name,icon=A.ProItemMeta("db:"..tostring(d.product))
        if type(name)~="string" or name:match("^#%d+") or name:match("^Unknown") then
          name=A.ProRecipeLabel and A.ProRecipeLabel(d.recipe) or d.recipe.name or name
        end
        row.record=d
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.title:SetText(A.FitItemName and A.FitItemName(name or ("#"..d.product),row.title,274)
          or (name or ("#"..d.product)))
        row.title:SetTextColor(1,.82,.38)
        if d.status=="missing" then
          row.metrics:SetText(l("No prices / incomplete", "Нет цен / неполные данные"))
          row.metrics:SetTextColor(.95,.72,.37)
        else
          row.metrics:SetText(l("Profit: ","Прибыль: ")..currency(d.profit)..
            "    ROI: "..(d.roi and string.format("%.1f%%",d.roi) or "-"))
          if d.profit>0 then row.metrics:SetTextColor(.4,1,.57)
          elseif d.profit<0 then row.metrics:SetTextColor(1,.45,.40)
          else row.metrics:SetTextColor(.8,.8,.8) end
        end
        row:Show()
      else row.record=nil;row:Hide() end
    end
    info:SetText("")
    if p.counts.saved==0 then
      status:SetText(l("No saved recipes. Open a profession and click Import profession.",
        "Нет сохранённых рецептов. Откройте профессию и нажмите «Импорт профессии»."))
    elseif #list==0 then
      info:SetText("")
    end
  end
  p.update=refresh
  button(p,l("Refresh ranking","Обновить рейтинг"),20,-91,166,function()
    p.page=1;refresh()
  end)
  local import=button(p,l("Import profession","Импорт профессии"),199,-91,189,function()
    local ok,result=A.ImportProfessionRecipeCatalog(function(done,total,stored)
      status:SetText(string.format(l("Importing recipes: %d/%d    Saved: %d",
        "Импорт рецептов: %d/%d    Сохранено: %d"),done,total,stored))
    end,function(stored,skipped,total)
      p.page=1
      refresh()
      status:SetText(string.format(l("Imported: %d/%d    Unavailable: %d",
        "Импортировано: %d/%d    Недоступно: %d"),stored,total,skipped))
    end)
    if not ok then
      status:SetText(result=="running" and l("Import already running.","Импорт уже выполняется.")
        or l("Open a profession window to import its available recipes.",
          "Откройте окно профессии, чтобы импортировать доступные рецепты."))
    else
      status:SetText(string.format(l("Reading %d recipes in small batches...",
        "Чтение %d рецептов небольшими порциями..."),result))
    end
  end)
  attachHelp(import,l("Import profession","Импорт профессии"),
    l("Open a profession such as Blacksmithing first. Only complete recipes that the client makes available can be stored. You may need to import each profession separately.",
      "Сначала откройте профессию, например кузнечное дело. Сохраняются только доступные клиенту рецепты с полным списком материалов. Разные профессии импортируются отдельно."))
  button(p,l("Sort: profit","Сорт.: прибыль"),402,-91,145,function()
    p.order="profit";A.db.pro.craftScannerSort="profit";p.page=1;refresh()
  end)
  button(p,l("Sort: ROI","Сорт.: ROI"),557,-91,143,function()
    p.order="roi";A.db.pro.craftScannerSort="roi";p.page=1;refresh()
  end)
  local prevBtn=button(p,l("< Previous","< Назад"),20,-515,110,function()
    p.page=math.max(1,p.page-1);refresh()
  end)
  local nextBtn=button(p,l("Next >","Вперёд >"),142,-515,110,function()
    p.page=math.min(math.max(1,math.ceil(#list/perPage)),p.page+1);refresh()
  end)
  local footerHint=fs(p,l("Select a row to see all materials and the calculation.",
    "Нажмите на рецепт, чтобы посмотреть ресурсы и подробный расчёт."),268,-520,446)
  footerHint:SetTextColor(.96,.93,.86)
  local footerPage=fs(p,"",20,-544,694)
  local oldRefresh=refresh
  refresh=function()
    oldRefresh()
    footerPage:SetText(string.format(l(
      "Page %d/%d. All imported recipes (optional profit-only filter in settings).",
      "Страница %d/%d. Все импортированные рецепты (фильтр прибыльных в настройках)."),
      p.page,math.max(1,math.ceil(#list/perPage))))
    if p.counts and p.counts.saved>0 and #list==0 then
      footerPage:SetText(l("No recipes match the active filter. Disable Profit only in settings to see all.",
        "Нет рецептов с текущим фильтром. Отключите «Только прибыльные» в настройках."))
    end
  end
  p.update=refresh
  return p
end

