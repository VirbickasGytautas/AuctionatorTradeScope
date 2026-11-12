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

function B.craft(root)
  local p=newPage(root)
  heading(p,l("Crafting cost by selected profession recipe",
    "Себестоимость по выбранному рецепту профессии"),-12)
  p.recipeQuery=edit(p,l("Recipe name or item ID","Название рецепта или ID"),20,-59,302,"",false,true)
  attachHelp(p.recipeQuery,l("Find saved recipe","Поиск сохранённого рецепта"),l(
    "Search recipes already imported from professions by name or output item ID. Scan an open profession first to add recipes.",
    "Поиск сохранённых рецептов по названию или ID готового предмета. Для добавления откройте профессию и нажмите «Сканировать рецепты»."))
  -- Only saved recipes are selectable. Profession data is imported explicitly
  -- with the Scan recipes action; the broken live-profession dropdown is gone.
  local popup=CreateFrame("Frame",nil,p)
  popup:SetSize(525,226)
  popup:SetPoint("TOPLEFT",p.recipeQuery,"BOTTOMLEFT",0,-5)
  popup:SetFrameStrata("FULLSCREEN_DIALOG")
  popup:SetFrameLevel(p:GetFrameLevel()+55)
  popup:EnableMouse(true)
  local popupBg=popup:CreateTexture(nil,"BACKGROUND")
  popupBg:SetAllPoints(popup)
  popupBg:SetTexture("Interface\\Buttons\\WHITE8X8")
  popupBg:SetVertexColor(.035,.055,.072,.99)
  if popup.SetBackdrop then
    popup:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  end
  popup:Hide()
  p.recipePopup=popup
  p.recipeChoices={}
  p.recipeOffset=0
  p.recipeSelectedIndex=1
  local pageCount=6
  local choices={}
  -- Forward declaration: suggestions handle the mouse press before the edit
  -- box can lose focus.  OnClick remains as a compatibility fallback.
  local selectRecipe
  local popupTitle=fs(popup,l("SAVED RECIPES","СОХРАНЁННЫЕ РЕЦЕПТЫ"),12,-7,492,true)
  popupTitle:SetTextColor(.97,.81,.34)
  tex(popup,8,-29,508,1,.46,.34,.16,.82)
  for i=1,pageCount do
    local row=CreateFrame("Button",nil,popup)
    row:EnableMouse(true)
    row:SetSize(505,27)
    row:SetPoint("TOPLEFT",popup,"TOPLEFT",10,-32-(i-1)*27)
    local hl=row:CreateTexture(nil,"BACKGROUND")
    hl:SetAllPoints(row)
    hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    hl:SetVertexColor(.36,.29,.12,.30)
    hl:Hide()
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetSize(23,23)
    icon:SetPoint("LEFT",row,"LEFT",4,0)
    local title=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    title:SetPoint("LEFT",row,"LEFT",34,0)
    title:SetWidth(368)
    title:SetJustifyH("LEFT")
    local detail=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    detail:SetPoint("RIGHT",row,"RIGHT",-5,0)
    detail:SetWidth(89)
    detail:SetJustifyH("RIGHT")
    detail:SetTextColor(.64,.76,.84)
    row.icon=icon;row.label=title;row.detail=detail;row.highlight=hl
    -- WoW can fire OnEditFocusLost before an OnClick reaches this button.
    -- Select on the initial mouse press to prevent losing the chosen recipe.
    local function chooseFromRow(self,mouseButton)
      if mouseButton and mouseButton~="LeftButton" then return end
      if popup:IsShown() and self.candidate and selectRecipe then
        selectRecipe(self.candidate)
      end
    end
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnMouseDown",chooseFromRow)
    row:SetScript("OnClick",chooseFromRow)
    row:SetScript("OnEnter",function(self) self.highlight:Show() end)
    row:SetScript("OnLeave",function(self)
      if not self.keyboardSelected then self.highlight:Hide() end
    end)
    choices[i]=row
  end
  popup.status=fs(popup,"",10,-201,510)
  popup.status:SetTextColor(.75,.80,.87)
  -- A click on the page background dismisses the list.  Clicks within
  -- the popup must never be treated as outside clicks.
  p:HookScript("OnMouseDown",function()
    if popup:IsShown() and not (popup.IsMouseOver and popup:IsMouseOver()) then
      popup:Hide()
    end
  end)
  local productIcon=p:CreateTexture(nil,"ARTWORK")
  productIcon:SetSize(36,36)
  productIcon:SetPoint("TOPLEFT",p,"TOPLEFT",20,-125)
  productIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  p.productName=fs(p,l("Choose a recipe to see its ingredients and costs.",
    "Выберите рецепт, чтобы увидеть ресурсы и их стоимость."),66,-124,448,true)
  p.productMade=fs(p,"",66,-147,324)
  -- Both the result icon and its name are one interactive hover target.
  local productHotspot=CreateFrame("Frame",nil,p)
  productHotspot:SetSize(340,43)
  productHotspot:SetPoint("TOPLEFT",p,"TOPLEFT",20,-124)
  productHotspot:SetFrameLevel(p:GetFrameLevel()+10)
  productHotspot:EnableMouse(true)
  p.productHotspot=productHotspot
  productHotspot:Hide()

  tex(p,20,-180,688,1,.40,.33,.16,.8)
  local columns={
    {l("MATERIAL","МАТЕРИАЛ"),84,184},
    {l("NEED","НУЖНО"),274,54},
    {l("OWNED","ЕСТЬ"),338,58},
    {l("BUY","ДОКУПИТЬ"),397,68},
    {l("EACH","ЗА ШТ."),473,98},
    {l("TOTAL","СТОИМОСТЬ"),579,129},
  }
  for i=1,#columns do
    local c=columns[i]
    local head=fs(p,c[1],c[2],-188,c[3],true)
    head:SetTextColor(1,.82,.36)
  end

  local PAGE_SIZE=6
  local active, page = nil,1
  local drawReport -- row click handlers need this forward declaration
  fs(p,l("Crafts in batch","Изготовлений"),524,-125,111)
  p.batchCount=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
  p.batchCount:SetSize(58,24)
  p.batchCount:SetPoint("TOPLEFT",p,"TOPLEFT",644,-121)
  p.batchCount:SetAutoFocus(false)
  p.batchCount:SetMaxLetters(3)
  if p.batchCount.SetNumeric then p.batchCount:SetNumeric(true) end
  local batchCount=math.max(1,math.min(999,math.floor(
    tonumber(A.db.pro.craftBatchCount) or 1)))
  p.batchCount:SetText(tostring(batchCount))
  attachHelp(p.batchCount,l("Batch size (crafts)","Размер партии (изготовлений)"),l(
    "Number of crafting actions, 1 to 999. A recipe may produce multiple items per action. Changes are saved automatically.",
    "Число изготовлений от 1 до 999. Один крафт может давать несколько готовых предметов. Значение сохраняется автоматически."))
  p.batchCount:SetScript("OnTextChanged",function(self)
    local value=tonumber(self:GetText() or "")
    if not value or value<1 then return end
    value=math.min(999,math.floor(value))
    if value~=batchCount then
      batchCount=value
      A.db.pro.craftBatchCount=value
      if active and drawReport then drawReport() end
    end
  end)
  p.batchCount:SetScript("OnEditFocusLost",function(self)
    self:SetText(tostring(batchCount))
  end)
  p.batchCount:SetScript("OnEnterPressed",function(self)
    self:ClearFocus()
  end)
  p.batchCount:SetScript("OnEscapePressed",function(self)
    self:ClearFocus()
  end)
  p.stockToggle=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
  p.stockToggle:SetSize(24,24)
  p.stockToggle:SetPoint("TOPLEFT",p,"TOPLEFT",395,-150)
  local stockLabel=fs(p,l("Count own materials (bags + bank)","Учёт собственных ресурсов (сумки + банк)"),422,-154,287)
  attachHelp(p.stockToggle,l("Use my materials","Учитывать мои ресурсы"),l(
    "Optional. Reads bags now and remembers the bank when opened. Shows remaining resources to buy and estimated additional gold to spend. Previously owned reagents still have market value!",
    "По желанию. Сумки проверяются сейчас, банк запоминается при открытии. Показывает, что нужно докупить и сколько золота потратить. Свои ресурсы также имеют рыночную стоимость!"))
  p.stockToggle:SetScript("OnClick",function(self)
    if A.SetCraftInventoryEnabled then A.SetCraftInventoryEnabled(self:GetChecked() and true or false) end
    if drawReport then drawReport() end
  end)
  p.materialRows={}
  for i=1,PAGE_SIZE do
    local y=-215-(i-1)*37
    local bgrow=tex(p,20,y,688,33,.09,.14,.18,i%2==1 and .82 or .57)
    local include=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    include:SetSize(22,22);include:SetPoint("TOPLEFT",p,"TOPLEFT",21,y-5)
    include:SetFrameLevel(p:GetFrameLevel()+12)
    local icon=p:CreateTexture(nil,"ARTWORK")
    icon:SetSize(25,25)
    icon:SetPoint("TOPLEFT",p,"TOPLEFT",49,y-4)
    local title=fs(p,"",84,y-7,184)
    local qty=fs(p,"",276,y-7,53)
    local owned=fs(p,"",338,y-7,54)
    local buy=fs(p,"",400,y-7,65)
    local unit=fs(p,"",473,y-7,97)
    local total=fs(p,"",581,y-7,125)
    local hotspot=CreateFrame("Frame",nil,p)
    hotspot:SetSize(659,33)
    hotspot:SetPoint("TOPLEFT",p,"TOPLEFT",49,y)
    hotspot:EnableMouse(true)
    hotspot:SetScript("OnEnter",function(self)
      local entry=self.material
      if not entry or not GameTooltip then return end
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      local ok=false
      if GameTooltip.SetHyperlink then ok=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..tostring(entry.id)) end
      if not ok then GameTooltip:SetText(tostring(entry.name or ("#"..tostring(entry.id)))) end
      GameTooltip:AddLine(l("Last known Auctionator price per unit; not a live quote.",
        "Последняя известная цена Auctionator за единицу, не текущая котировка."),.75,.85,1,true)
      if entry.stock~=nil then
        GameTooltip:AddLine(l("Total in stock: ","Всего в наличии: ")..tostring(entry.stock),
          .55,.95,.65,true)
        GameTooltip:AddLine(l("Need to buy: ","Нужно докупить: ")..tostring(entry.buy or 0),
          1,.82,.4,true)
        if entry.bankTime and type(date)=="function" then
          GameTooltip:AddLine(l("Bank last checked: ","Банк проверен: ")..
            date("%d.%m %H:%M",entry.bankTime),.85,.78,.56,true)
        end
      end
      GameTooltip:Show()
      if type(GameTooltip_ShowCompareItem)=="function" then
        pcall(GameTooltip_ShowCompareItem,GameTooltip)
      end
      if A.ScheduleCraftPreview then A.ScheduleCraftPreview(self,entry.id) end
    end)
    hotspot:SetScript("OnLeave",function(self)
      -- Keep the original item tooltip and equipped-item comparison visible
      -- while the cursor moves from the material onto its market chart.
      if A.DeferCraftPreview then A.DeferCraftPreview() end
      if not (A.craftPreviewGraph and A.craftPreviewGraph:IsShown()) and
          GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner()==self then
        GameTooltip:Hide()
      end
    end)
    local row={background=bgrow,icon=icon,title=title,qty=qty,owned=owned,buy=buy,unit=unit,
      total=total,hotspot=hotspot,include=include,sourceIndex=nil}
    include:SetScript("OnClick",function(self)
      if active and row.sourceIndex then
        A.SetRecipeIngredientIncluded(active,row.sourceIndex,self:GetChecked() and true or false)
        if drawReport then drawReport() end
      end
    end)
    attachHelp(include,l("Include material in calculation","Учитывать ингредиент в расчёте"),l(
      "Uncheck to deliberately exclude this ingredient from both cost and profit calculations. An exclusion does not make a complete economic cost estimate.",
      "Снимите галочку, чтобы исключить этот ингредиент из себестоимости и расчёта прибыли. При исключении расчёт уже не отражает полную экономическую стоимость."))
    p.materialRows[i]=row
  end
  p.pageLabel=fs(p,"",266,-442,134)
  p.summary1=fs(p,"",22,-472,680,true)
  p.summary2=fs(p,"",22,-495,680)
  p.summary3=fs(p,"",22,-518,680)
  p.info=fs(p,"",22,-540,690)
  -- The recipe instructions and scan/status messages belong to the side
  -- HOW IT WORKS panel.  No help text is placed below the recipe input.
  -- toolHelpPanel(p,"craft") creates p.status after this page is built.
  local function displayName(id,provided,providedIcon)
    local name,icon=nil,nil
    if A.ResolveItemInfo then name,icon=A.ResolveItemInfo("item:"..tostring(id),provided) end
    if not name or name=="?" or name==("#"..tostring(id)) then
      name=provided or (l("Item #","Предмет #")..tostring(id))
    end
    if icon=="Interface\\Icons\\INV_Misc_QuestionMark" and providedIcon then
      icon=providedIcon
    end
    return name,icon or providedIcon
  end

  productHotspot:SetScript("OnEnter",function(self)
    if not active or not active.product then return end
    if GameTooltip then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      local ok=false
      if GameTooltip.SetHyperlink then
        ok=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..tostring(active.product))
      end
      if not ok then GameTooltip:SetText(tostring(p.productName:GetText() or active.name or "?")) end
      GameTooltip:AddLine(l("Crafted result: last observed Auctionator prices.",
        "Готовый предмет: последние известные цены Auctionator."),.78,.88,1,true)
      GameTooltip:Show()
      if type(GameTooltip_ShowCompareItem)=="function" then
        pcall(GameTooltip_ShowCompareItem,GameTooltip)
      end
    end
    if A.ScheduleCraftPreview then A.ScheduleCraftPreview(self,active.product) end
  end)
  productHotspot:SetScript("OnLeave",function(self)
    if A.DeferCraftPreview then A.DeferCraftPreview() end
    if not (A.craftPreviewGraph and A.craftPreviewGraph:IsShown()) and
        GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner()==self then
      GameTooltip:Hide()
    end
  end)
  local function formatValue(n)
    return type(n)=="number" and currency(n) or l("No data","Нет данных")
  end

  drawReport=function()
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

  local function applyRecipe(recipe)
    if not recipe or type(recipe.materials)~="table" or #recipe.materials==0 then return end
    active=recipe
    page=1
    -- Keep the complete imported recipe, even if it has more than six reagents.
    if A.ProRecipeLabel then A.ProRecipeLabel(recipe) end
    A.ProRecipes()[tostring(recipe.product)]=recipe
    p.applyingRecipe=true
    popup:Hide()
    p.recipeQuery:SetText(A.ProRecipeLabel and A.ProRecipeLabel(recipe)
      or recipe.name or ("#"..tostring(recipe.product)))
    p.recipeQuery:ClearFocus()
    p.recipeSelected=true
    p.applyingRecipe=false
    p.status:SetText("")
    drawReport()
  end
  -- The recipe catalog opens this exact recipe in the existing calculator.
  p.applyExternalRecipe=applyRecipe

  local function whyText(reason)
    local messages={
      ["missing-product"]={"This client did not return an output item ID.","Клиент не вернул ID готового предмета."},
      ["missing-reagents"]={"The profession did not return a complete reagent list.","Профессия не вернула полный список ресурсов."},
      ["missing-reagent-id"]={"A resource has no item ID. Import stopped.","Ресурс без ID. Импорт остановлен."},
      ["optional-reagents"]={"Alternative resources are not supported; please select a fixed recipe.",
        "Альтернативные ресурсы пока не поддерживаются. Выберите обычный рецепт."},
      ["too-many-reagents"]={"Recipe exceeds the supported 40 reagents.","В рецепте больше 40 ресурсов."},
      ["no-selection"]={"Select a profession recipe or choose one from the list.",
        "Выберите рецепт в профессии или в списке TradeScope."},
    }
    local pair=messages[reason] or messages["no-selection"]
    return l(pair[1],pair[2])
  end
  local function loadRecipeChoices()
    local all={}
    for _,recipe in pairs(A.ProRecipes() or {}) do
      if type(recipe)=="table" and type(recipe.materials)=="table" and
          #recipe.materials>0 and recipe.product then
        local name=A.ProRecipeLabel and A.ProRecipeLabel(recipe) or
          recipe.name or ("#"..tostring(recipe.product))
        all[#all+1]={id=recipe.product,name=name,kind="saved",recipe=recipe,
          product=recipe.product,icon=recipe.productIcon}
      end
    end
    table.sort(all,function(a,b) return normalizeRussian(a.name)<normalizeRussian(b.name) end)
    p.recipeChoices=all
    return all
  end
  p.loadRecipeChoices=loadRecipeChoices
  selectRecipe=function(candidate)
    if not candidate then return end
    if candidate.recipe then applyRecipe(candidate.recipe)
    else p.status:SetText(l("Recipe is not available. Scan your profession again.",
      "Рецепт недоступен. Повторите сканирование профессии."));popup:Hide() end
  end
  local function refreshChoices()
    local query=normalizeRussian(p.recipeQuery:GetText() or "")
    local ranked={}
    for i=1,#p.recipeChoices do
      local c=p.recipeChoices[i]
      local name=normalizeRussian(c.name or "")
      local itemID=tostring(c.product or "")
      local npos=query=="" and 1 or name:find(query,1,true)
      if npos or (query~="" and itemID:find(query,1,true)) then
        local rank=(name==query or itemID==query) and 0 or
          (npos==1 and 1 or 2)
        ranked[#ranked+1]={value=c,rank=rank,original=i}
      end
    end
    table.sort(ranked,function(a,b)
      if a.rank~=b.rank then return a.rank<b.rank end
      return a.original<b.original
    end)
    local filtered={}
    for i=1,#ranked do filtered[i]=ranked[i].value end
    p.filteredRecipes=filtered
    p.recipeSelectedIndex=math.max(1,math.min(p.recipeSelectedIndex,#filtered))
    p.recipeOffset=math.max(0,math.min(p.recipeOffset,math.max(0,#filtered-pageCount)))
    if p.recipeSelectedIndex<p.recipeOffset+1 then
      p.recipeOffset=math.max(0,p.recipeSelectedIndex-1)
    elseif p.recipeSelectedIndex>p.recipeOffset+pageCount then
      p.recipeOffset=math.max(0,p.recipeSelectedIndex-pageCount)
    end
    for i=1,pageCount do
      local row=choices[i]
      local index=p.recipeOffset+i
      local candidate=filtered[index]
      if candidate then
        row.candidate=candidate
        row.label:SetText(A.FitItemName and
          A.FitItemName(candidate.name or "?",row.label,365) or candidate.name)
        if candidate.product and A.ResolveItemInfo then
          local _,texture=A.ResolveItemInfo("item:"..tostring(candidate.product),nil)
          row.icon:SetTexture(texture or candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        else
          row.icon:SetTexture(candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        row.detail:SetText("#"..tostring(candidate.product))
        row.keyboardSelected=index==p.recipeSelectedIndex
        if row.keyboardSelected then row.highlight:Show() else row.highlight:Hide() end
        -- The click handler reads row.candidate dynamically; rebuilding
        -- suggestions must not leave a callback pointing to an old entry.
        row:Show()
      else row.candidate=nil;row:Hide() end
    end
    popup.status:SetText(string.format(l(
      "Found: %d  |  Wheel / Up-Down / Enter / Esc",
      "Найдено: %d  |  Колесо / Вверх-Вниз / Enter / Esc"),#filtered))
    popup:Show()
  end
  p.refreshRecipeChoices=refreshChoices
  popup:EnableMouseWheel(true)
  popup:SetScript("OnMouseWheel",function(_,delta)
    if not p.filteredRecipes or #p.filteredRecipes==0 then return end
    p.recipeSelectedIndex=math.max(1,math.min(#p.filteredRecipes,
      p.recipeSelectedIndex-(delta>0 and 1 or -1)))
    refreshChoices()
  end)
  local function showSaved(clearSearch)
    p.recipeSelectedIndex=1;p.recipeOffset=0
    if clearSearch then
      p.applyingRecipe=true
      p.recipeQuery:SetText("")
      p.applyingRecipe=false
    end
    local all=loadRecipeChoices()
    refreshChoices()
    if #all==0 then
      p.status:SetText(l("No saved recipes yet. Open a profession and scan it.",
        "Сохранённых рецептов пока нет. Откройте профессию и выполните сканирование."))
    end
  end
  p.showSavedRecipes=showSaved
  button(p,l("Scan recipes","Сканировать рецепты"),340,-82,180,function()
    popup:Hide()
    if A.proRecipeImportActive then
      p.status:SetText(l("Recipe scan is already running.","Сканирование уже выполняется."))
      return
    end
    if not A.ImportProfessionRecipeCatalog then
      p.status:SetText(l("Recipe scanner unavailable.","Сканер рецептов недоступен."))
      return
    end
    local ok,count=A.ImportProfessionRecipeCatalog(function(done,total,stored)
      if p:IsShown() then
        p.status:SetText(string.format(l("Scanning %d/%d, saved: %d",
          "Сканирование %d/%d, сохранено: %d"),done,total,stored))
      end
    end,function(stored,skipped,total)
      if not p:IsShown() then return end
      p.status:SetText(string.format(l(
        "Scan complete: %d saved, %d skipped (of %d).",
        "Сканирование завершено: сохранено %d, пропущено %d (из %d)."),stored,skipped,total))
      -- Refresh saved list but do not obscure the calculator by reopening it.
      loadRecipeChoices()
      if popup:IsShown() then refreshChoices() end
    end)
    if ok then p.status:SetText(string.format(l("Scanning %d profession recipes...",
      "Сканирование %d рецептов профессии..."),tonumber(count) or 0))
    else p.status:SetText(l("Open a profession window first, then scan its recipes.",
      "Сначала откройте окно профессии, затем нажмите «Сканировать рецепты».")) end
  end)
  button(p,l("Saved recipes","Сохранённые рецепты"),536,-82,172,function()
    showSaved(true)
  end)
  p.recipeQuery:SetScript("OnTextChanged",function(self)
    if p.applyingRecipe then return end
    p.recipeSelectedIndex=1;p.recipeOffset=0
    if self:GetText()=="" then popup:Hide();return end
    loadRecipeChoices()
    refreshChoices()
  end)
  p.recipeQuery:SetScript("OnEscapePressed",function(self)
    popup:Hide();self:ClearFocus()
  end)
  p.recipeQuery:SetScript("OnEnterPressed",function(self)
    local candidate=p.filteredRecipes and p.filteredRecipes[p.recipeSelectedIndex]
    if popup:IsShown() and candidate then selectRecipe(candidate)
    else
      p.status:SetText(l("Recipe not saved. Open a profession and scan available recipes.",
        "Рецепт не найден. Откройте профессию и просканируйте доступные рецепты."))
    end
    popup:Hide();self:ClearFocus()
  end)
  if p.recipeQuery.SetScript then
    pcall(p.recipeQuery.SetScript,p.recipeQuery,"OnArrowPressed",function(_,key)
      if not popup:IsShown() or not p.filteredRecipes or #p.filteredRecipes==0 then return end
      if key=="UP" then p.recipeSelectedIndex=math.max(1,p.recipeSelectedIndex-1)
      elseif key=="DOWN" then p.recipeSelectedIndex=math.min(#p.filteredRecipes,p.recipeSelectedIndex+1)
      else return end
      refreshChoices()
    end)
  end
  -- Deliberately do not dismiss the popup on OnEditFocusLost.  Some
  -- WoW Forever clients report the old mouse focus here, even when the
  -- pointer is over a suggestion, which used to cancel the row click.
  -- The list closes after selection, Esc, page background click, or tab hide.
  p:HookScript("OnHide",function()
    popup:Hide()
    if A.HideCraftPreview then A.HideCraftPreview() end
  end)
  button(p,l("< Prev","< Назад"),20,-434,110,function()
    if not active then return end
    page=math.max(1,page-1);drawReport()
  end)
  button(p,l("Next >","Вперёд >"),143,-434,120,function()
    if not active then return end
    page=page+1;drawReport()
  end)
  local shoppingButton=button(p,l("Buy list","Закупки"),408,-434,126,function(self)
    -- Also permit a click to display the same list as the hover tooltip.
    if self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
  end)
  shoppingButton:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(l("Materials to purchase","Список закупок"))
    if not active then
      GameTooltip:AddLine(l("Select a saved recipe.","Выберите сохранённый рецепт."),1,1,1,true)
    else
      local report=A.EvaluateCraftBatch(active,batchCount)
      local list=report and report.shoppingList or {}
      if #list==0 then
        GameTooltip:AddLine(l("No additional materials needed.","Дополнительные материалы не нужны."),.46,1,.55,true)
      else
        for i=1,math.min(#list,20) do
          local item=list[i]
          local name=displayName(item.id,item.name)
          GameTooltip:AddDoubleLine(tostring(name).." x"..item.qty,
            formatValue(item.cost),1,.85,.35,.86,.93,1)
        end
        if #list>20 then
          GameTooltip:AddLine(l("Additional ingredients not shown.",
            "Остальные ингредиенты не показаны."),.75,.78,.83,true)
        end
        GameTooltip:AddLine(l("Additional purchases: ","Нужно докупить на: ")..
          formatValue(report.cashCost),.5,1,.7,true)
      end
      if not report.inventoryEnabled then
        GameTooltip:AddLine(l("Own stock tracking is OFF: full quantities shown.",
          "Учёт запасов выключен: показана полная потребность."),1,.7,.44,true)
      end
    end
    GameTooltip:Show()
  end)
  shoppingButton:SetScript("OnLeave",function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  button(p,l("Refresh data","Обновить данные"),550,-434,158,function()
    if A.RefreshCraftStock then A.RefreshCraftStock() end
    drawReport()
  end)
  p.update=function() if active then drawReport() end end
  drawReport()
  return p
end

