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
    "Выберите рецепт, чтобы увидеть ресурсы и их стоимость."),66,-124,600,true)
  p.productMade=fs(p,"",66,-147,324)
  -- Both the result icon and its name are one interactive hover target.
  local productHotspot=CreateFrame("Frame",nil,p)
  productHotspot:SetSize(575,43)
  productHotspot:SetPoint("TOPLEFT",p,"TOPLEFT",20,-124)
  productHotspot:SetFrameLevel(p:GetFrameLevel()+10)
  productHotspot:EnableMouse(true)
  p.productHotspot=productHotspot
  productHotspot:Hide()

  local tableDivider=tex(p,20,-180,900,1,.40,.33,.16,.8)
  local tableHeaders={}
  local columns={
    {l("MATERIAL","МАТЕРИАЛ"),84,337},
    {l("NEED","НУЖНО"),444,54},
    {l("OWNED","ЕСТЬ"),515,58},
    {l("BUY","ДОКУПИТЬ"),588,71},
    {l("EACH","ЗА ШТ."),671,96},
    {l("TOTAL","СТОИМОСТЬ"),782,125},
  }
  for i=1,#columns do
    local c=columns[i]
    local head=fs(p,c[1],c[2],-188,c[3],true)
    head:SetTextColor(1,.82,.36)
    tableHeaders[#tableHeaders+1]=head
  end

  local PAGE_SIZE=6
  local active, page = nil,1
  local refreshBrowse
  local drawReport -- row click handlers need this forward declaration
  fs(p,l("Crafts in batch","Изготовлений"),730,-125,111)
  p.batchCount=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
  p.batchCount:SetSize(58,24)
  p.batchCount:SetPoint("TOPLEFT",p,"TOPLEFT",852,-121)
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
  p.stockToggle:SetPoint("TOPLEFT",p,"TOPLEFT",619,-150)
  local stockLabel=fs(p,l("Count own materials (bags + bank)","Учёт собственных ресурсов (сумки + банк)"),649,-154,268)
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
    local bgrow=tex(p,20,y,900,33,.09,.14,.18,i%2==1 and .82 or .57)
    local include=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    include:SetSize(22,22);include:SetPoint("TOPLEFT",p,"TOPLEFT",21,y-5)
    include:SetFrameLevel(p:GetFrameLevel()+12)
    local icon=p:CreateTexture(nil,"ARTWORK")
    icon:SetSize(25,25)
    icon:SetPoint("TOPLEFT",p,"TOPLEFT",49,y-4)
    local title=fs(p,"",84,y-7,337)
    local qty=fs(p,"",444,y-7,53)
    local owned=fs(p,"",515,y-7,54)
    local buy=fs(p,"",588,y-7,70)
    local unit=fs(p,"",671,y-7,97)
    local total=fs(p,"",782,y-7,125)
    local hotspot=CreateFrame("Frame",nil,p)
    hotspot:SetSize(869,33)
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
  -- Scan feedback is actionable status, not reference documentation. Keep it
  -- near the recipe input after removing the permanent help sidebar.
  p.status=fs(p,"",544,-78,370)
  p.status:SetTextColor(.76,.83,.88)
  if p.status.SetWordWrap then p.status:SetWordWrap(true) end
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

  local renderReport=assert(A.CreateCraftReportRenderer)({
    p=p,productHotspot=productHotspot,productIcon=productIcon,
    displayName=displayName,formatValue=formatValue,pageSize=PAGE_SIZE,
    getActive=function() return active end,
    getBatchCount=function() return batchCount end,
    getPage=function() return page end,
    setPage=function(value) page=value end,
  })
  -- One layout for a populated table, a compact financial summary and an
  -- actionable browse state. A blank table should not occupy the whole pane.
  local pageButtons={}
  local function moveTo(control,x,y)
    if not control then return end
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
  end
  local function alignReport()
    local visible=active and math.min(PAGE_SIZE,math.max(0,#active.materials-(page-1)*PAGE_SIZE)) or 0
    local navY=-215-visible*37-15
    if navY>-379 then navY=-379 end
    moveTo(pageButtons.prev,20,navY)
    moveTo(pageButtons.next,143,navY)
    moveTo(p.pageLabel,275,navY-3)
    moveTo(pageButtons.shopping,408,navY)
    moveTo(pageButtons.refresh,550,navY)
    moveTo(p.summary1,22,navY-40)
    moveTo(p.summary2,22,navY-63)
    moveTo(p.summary3,22,navY-86)
    moveTo(p.info,22,navY-109)
    for _,buttonWidget in pairs(pageButtons) do
      if active then buttonWidget:Show() else buttonWidget:Hide() end
    end
    if active then
      tableDivider:Show()
      for _,headingWidget in ipairs(tableHeaders) do headingWidget:Show() end
    else
      tableDivider:Hide()
      for _,headingWidget in ipairs(tableHeaders) do headingWidget:Hide() end
    end
  end
  drawReport=function()
    renderReport()
    alignReport()
    if refreshBrowse then refreshBrowse() end
  end

  local function applyRecipe(recipe)
    if not recipe or type(recipe.materials)~="table" or #recipe.materials==0 then return end
    active=recipe
    page=1
    -- Keep the complete imported recipe, even if it has more than six reagents.
    if A.ProRecipeLabel then A.ProRecipeLabel(recipe) end
    A.ProRecipes()[tostring(recipe.product)]=recipe
    p.applyingRecipe=true
    p.recipeSelected=true
    popup:Hide()
    -- Clear focus BEFORE replacing the query. An edit-box OnTextChanged
    -- arriving from the catalog must not display the selector over results.
    p.recipeQuery:ClearFocus()
    p.recipeQuery:SetText(A.ProRecipeLabel and A.ProRecipeLabel(recipe)
      or recipe.name or ("#"..tostring(recipe.product)))
    p.recipeQuery:ClearFocus()
    popup:Hide()
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

  -- Inline saved-recipe browser: the empty calculator becomes useful rather
  -- than showing an empty 900px material table. Unlike search suggestions,
  -- these entries never cover the calculation or require clearing a modal.
  local browse=CreateFrame("Frame",nil,p)
  browse:SetSize(900,438)
  browse:SetPoint("TOPLEFT",p,"TOPLEFT",20,-182)
  local browseTitle=fs(browse,l("Saved recipes - choose to calculate",
    "Сохранённые рецепты — выберите для расчёта"),0,-2,885,true)
  browseTitle:SetTextColor(1,.84,.41)
  local browseInfo=fs(browse,"",0,-28,880)
  local browseRows={}
  for i=1,12 do
    local row=CreateFrame("Button",nil,browse)
    row:SetSize(435,45)
    row:SetPoint("TOPLEFT",browse,"TOPLEFT",(i-1)%2*454,-56-math.floor((i-1)/2)*54)
    local shade=tex(row,0,0,435,45,.08,.12,.16,.90)
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetSize(27,27);icon:SetPoint("LEFT",row,"LEFT",7,0)
    local name=fs(row,"",43,-10,370)
    name:SetTextColor(1,.86,.47)
    row.icon=icon;row.label=name;row.shade=shade
    row:SetScript("OnClick",function(self)
      if self.recipe then applyRecipe(self.recipe) end
    end)
    row:SetScript("OnEnter",function(self)
      self.shade:SetVertexColor(.18,.21,.18,.96)
    end)
    row:SetScript("OnLeave",function(self)
      self.shade:SetVertexColor(.08,.12,.16,.90)
    end)
    row:Hide()
    browseRows[i]=row
  end
  refreshBrowse=function()
    if active then browse:Hide();return end
    local recipes=loadRecipeChoices()
    if #recipes==0 then
      browseInfo:SetText(l("No saved recipes. Open a profession and scan its recipes above.",
        "Нет сохранённых рецептов. Откройте профессию и нажмите «Сканировать рецепты»."))
    else
      browseInfo:SetText(string.format(l("Saved: %d. Pick a recipe or use the search field.",
        "Сохранено: %d. Выберите рецепт или воспользуйтесь поиском."),#recipes))
    end
    for i,row in ipairs(browseRows) do
      local entry=recipes[i]
      if entry then
        row.recipe=entry.recipe
        row.label:SetText(A.FitItemName and A.FitItemName(entry.name,row.label,350) or entry.name)
        local texture=entry.icon
        if A.ResolveItemInfo then
          local _,resolved=A.ResolveItemInfo("item:"..tostring(entry.product),nil)
          texture=resolved or texture
        end
        row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row:Show()
      else row.recipe=nil;row:Hide() end
    end
    browse:Show()
  end
  p.recipeBrowse=browse
  selectRecipe=function(candidate)
    if not candidate then return end
    if candidate.recipe then applyRecipe(candidate.recipe)
    else p.status:SetText(l("Recipe is not available. Scan your profession again.",
      "Рецепт недоступен. Повторите сканирование профессии."));popup:Hide() end
  end
  assert(A.AttachCraftRecipePicker)({
    p=p,popup=popup,choices=choices,pageCount=pageCount,
    loadRecipeChoices=loadRecipeChoices,selectRecipe=selectRecipe,
  })
  pageButtons.prev=button(p,l("< Prev","< Назад"),20,-434,110,function()
    if not active then return end
    page=math.max(1,page-1);drawReport()
  end)
  pageButtons.next=button(p,l("Next >","Вперёд >"),143,-434,120,function()
    if not active then return end
    page=page+1;drawReport()
  end)
  local shoppingButton=button(p,l("Buy list","Закупки"),408,-434,126,function(self)
    -- Also permit a click to display the same list as the hover tooltip.
    if self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
  end)
  pageButtons.shopping=shoppingButton
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
  pageButtons.refresh=button(p,l("Refresh data","Обновить данные"),550,-434,158,function()
    if A.RefreshCraftStock then A.RefreshCraftStock() end
    drawReport()
  end)
  p.update=function() if active then drawReport() end end
  drawReport()
  return p
end

