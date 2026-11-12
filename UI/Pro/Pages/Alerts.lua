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

function B.alerts(root)
  local p=newPage(root)
  heading(p,l("Smart Alerts 2.0 - new Auctionator observations", "Умные сигналы 2.0 - новые замеры Auctionator"),-12)
  fs(p,l("Select a known item, choose a condition and set its threshold. Only NEW scans trigger alerts.",
    "Выберите предмет, условие и порог. Сигналы срабатывают только при НОВЫХ сканах."),20,-46,702)
  p.selection=marketInput(p,20,-76,220)
  local conditions=A.SmartAlertKinds()
  p.condition=conditions[1]
  -- Explicit condition selector, instead of cycling through nine conditions on
  -- successive clicks. Native WoW textures/fonts keep this compatible with
  -- Forever's older UI; no UIDropDownMenuTemplate dependency is required.
  local conditionTips={
    below={"Notify when a new observed price is at or below this amount.","Сигнал, если новая наблюдаемая цена не выше указанной суммы."},
    above={"Notify when a new observed price is at or above this amount.","Сигнал, если новая наблюдаемая цена не ниже указанной суммы."},
    medianBelow={"Percent below the median of observed historical prices.","Процент ниже медианы сохранённой истории цен."},
    medianAbove={"Percent above the historical median price.","Процент выше исторической медианы цены."},
    priceDown={"Percent decline since the last comparable scan.","Процент снижения с прошлого сопоставимого сканирования."},
    priceUp={"Percent increase since the last comparable scan.","Процент повышения с прошлого сопоставимого сканирования."},
    supplyDrop={"Decrease in listed quantity; this does NOT prove a sale.","Сокращение предложения; это НЕ подтверждённая продажа."},
    volatility={"Observed price volatility reaches the chosen percentage.","Волатильность цены достигает указанного процента."},
    opportunity={"Opportunity Score meets the threshold, within the maximum Risk Score.",
      "Opportunity Score достигает порога при ограничении максимального Risk Score."},
  }
  fs(p,l("Condition", "Тип условия"),259,-76,231)
  local toggleConditionMenu
  local kindButton=button(p,"",259,-99,237,function()
    if toggleConditionMenu then toggleConditionMenu() end
  end)
  if A.StyleButton then A.StyleButton(kindButton,"secondary") end
  local chevron=kindButton:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
  chevron:SetPoint("RIGHT",kindButton,"RIGHT",-11,0)
  chevron:SetText("v")
  chevron:SetTextColor(.97,.79,.40)
  kindButton:SetScript("OnEnter",function(self)
    if not p.conditionMenu or not p.conditionMenu:IsShown() then
      showHelp(self,l("Select condition", "Выбор условия"),l(
        "Click to choose one of nine alert conditions from the dropdown.",
        "Нажмите для выбора одного из девяти условий из списка."))
    end
  end)
  kindButton:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
  local kindMenu=CreateFrame("Frame",nil,p)
  p.conditionMenu=kindMenu
  kindMenu:SetSize(365,359)
  kindMenu:SetPoint("TOPLEFT",kindButton,"BOTTOMLEFT",0,-4)
  kindMenu:SetFrameStrata("FULLSCREEN_DIALOG")
  kindMenu:SetFrameLevel(math.max(kindButton:GetFrameLevel()+12,p:GetFrameLevel()+20))
  kindMenu:EnableMouse(true)
  tex(kindMenu,0,0,365,359,.025,.036,.048,.99)
  if kindMenu.SetBackdrop then
    kindMenu:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,
      insets={left=3,right=3,top=3,bottom=3}})
    if kindMenu.SetBackdropBorderColor then kindMenu:SetBackdropBorderColor(.70,.55,.25,1) end
  end
  local menuTitle=fs(kindMenu,l("SELECT ALERT CONDITION","ВЫБЕРИТЕ УСЛОВИЕ"),12,-10,335)
  menuTitle:SetTextColor(1,.78,.32)
  tex(kindMenu,10,-29,345,1,.53,.40,.19,.8)
  local conditionGroups={
    {name=l("PRICE LIMITS","ПОРОГ ЦЕНЫ"),items={"below","above"}},
    {name=l("PRICE CHANGES","ИЗМЕНЕНИЕ ЦЕНЫ"),items={"medianBelow","medianAbove","priceDown","priceUp"}},
    {name=l("MARKET AND ANALYTICS","РЫНОК И АНАЛИТИКА"),items={"supplyDrop","volatility","opportunity"}},
  }
  local conditionRows={}
  local rowY=-37
  for _,group in ipairs(conditionGroups) do
    local groupLabel=fs(kindMenu,group.name,13,rowY,328)
    groupLabel:SetTextColor(.77,.65,.41)
    rowY=rowY-18
    for _,kind in ipairs(group.items) do
      local row=CreateFrame("Button",nil,kindMenu)
      row:SetSize(345,27)
      row:SetPoint("TOPLEFT",kindMenu,"TOPLEFT",10,rowY)
      row:EnableMouse(true)
      local fill=tex(row,0,0,345,27,.075,.105,.13,.94)
      local mark=row:CreateTexture(nil,"ARTWORK")
      mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
      mark:SetSize(17,17)
      mark:SetPoint("LEFT",row,"LEFT",4,0)
      local name=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
      name:SetPoint("LEFT",row,"LEFT",25,0)
      name:SetWidth(252)
      name:SetJustifyH("LEFT")
      name:SetText(A.SmartAlertLabel(kind))
      local unit=row:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
      unit:SetPoint("RIGHT",row,"RIGHT",-9,0)
      unit:SetJustifyH("RIGHT")
      unit:SetWidth(68)
      local kindUnit=A.SmartAlertUnit(kind)
      unit:SetText(kindUnit=="money" and l("coins","монеты") or
        kindUnit=="quantity" and l("items","шт.") or
        kindUnit=="score" and l("score","баллы") or "%")
      unit:SetTextColor(.75,.77,.75)
      row.kind=kind;row.fill=fill;row.mark=mark;row.name=name
      row:SetScript("OnEnter",function(self)
        self.fill:SetVertexColor(.24,.22,.12,.98)
        local pair=conditionTips[self.kind]
        showHelp(self,A.SmartAlertLabel(self.kind),pair and l(pair[1],pair[2]) or "")
      end)
      row:SetScript("OnLeave",function(self)
        self.fill:SetVertexColor(self.kind==p.condition and .23 or .075,
          self.kind==p.condition and .17 or .105,
          self.kind==p.condition and .075 or .13,.94)
        if GameTooltip then GameTooltip:Hide() end
      end)
      local function choose()
        if not kindMenu:IsShown() then return end
        p.condition=kind
        kindMenu:Hide()
        p.refreshFields()
      end
      row:SetScript("OnMouseDown",choose)
      row:SetScript("OnClick",choose)
      conditionRows[#conditionRows+1]=row
      rowY=rowY-28
    end
    rowY=rowY-3
  end
  function kindMenu:RefreshSelection()
    for i=1,#conditionRows do
      local row=conditionRows[i]
      local selected=row.kind==p.condition
      if selected then
        row.fill:SetVertexColor(.23,.17,.075,.94)
        row.mark:Show()
        row.name:SetTextColor(1,.87,.56)
      else
        row.fill:SetVertexColor(.075,.105,.13,.94)
        row.mark:Hide()
        row.name:SetTextColor(.92,.93,.92)
      end
    end
  end
  kindMenu:SetScript("OnKeyDown",function(self,key)
    if key=="ESCAPE" then self:Hide() end
  end)
  kindMenu:SetScript("OnShow",function(self)
    self:RefreshSelection()
    if self.EnableKeyboard then self:EnableKeyboard(true) end
  end)
  kindMenu:SetScript("OnHide",function(self)
    if self.EnableKeyboard then self:EnableKeyboard(false) end
    if GameTooltip then GameTooltip:Hide() end
  end)
  kindMenu:Hide()
  toggleConditionMenu=function()
    if kindMenu:IsShown() then kindMenu:Hide();return end
    if p.selection and p.selection.searchPopup then p.selection.searchPopup:Hide() end
    if p.selection then p.selection:ClearFocus() end
    if GameTooltip then GameTooltip:Hide() end
    kindMenu:Show()
  end
  p:HookScript("OnHide",function()kindMenu:Hide()end)
  -- Clicking elsewhere on the page dismisses the open selector.
  p:EnableMouse(true)
  p:HookScript("OnMouseDown",function()
    if kindMenu:IsShown() and
      not (kindMenu.IsMouseOver and kindMenu:IsMouseOver()) and
      not (kindButton.IsMouseOver and kindButton:IsMouseOver()) then
      kindMenu:Hide()
    end
  end)
  p.risk=edit(p,l("Max risk 0-100","Макс. риск 0-100"),504,-76,109,
    tostring(A.db.pro.alertDefaultRisk or 80),false,true)
  p.gold=edit(p,l("Gold","Золото"),20,-125,95,"0",true)
  p.silver=edit(p,l("Silver","Серебро"),129,-125,95,"1",true)
  p.copper=edit(p,l("Copper","Медь"),240,-125,95,"0",true)
  p.threshold=edit(p,l("Threshold","Порог"),354,-125,118,"15",false,true)
  local valueHelp=fs(p,"",20,-174,687)
  valueHelp:SetTextColor(.73,.80,.85)
  p.refreshFields=function()
    kindButton:SetText(A.SmartAlertLabel(p.condition))
    kindMenu:RefreshSelection()
    local money=A.SmartAlertUnit(p.condition)=="money"
    for _,e in ipairs({p.gold,p.silver,p.copper}) do
      -- Keep the label tied to the edit box; hide both for non-price conditions.
      if money then e:Show() else e:Hide() end
      if e.label then if money then e.label:Show() else e.label:Hide() end end
    end
    if money then p.threshold:Hide() else p.threshold:Show() end
    if p.threshold.label then if money then p.threshold.label:Hide() else p.threshold.label:Show() end end
    if p.condition=="opportunity" then p.risk:Show() else p.risk:Hide() end
    if p.risk.label then
      if p.condition=="opportunity" then p.risk.label:Show() else p.risk.label:Hide() end
    end
    local explanation={
      below={"Notify when the latest observed price is at or below the threshold.","Сигнал, если новая цена не выше порога."},
      above={"Notify when the latest observed price is at or above the threshold.","Сигнал, если новая цена не ниже порога."},
      medianBelow={"Percentage below the median of recorded prices (needs history).","Процент ниже медианы наблюдаемых цен (нужна история)."},
      medianAbove={"Percentage above the historical median (needs history).","Процент выше исторической медианы (нужна история)."},
      priceDown={"Percentage drop from the previous comparable observation.","Процент падения с прошлого сопоставимого замера."},
      priceUp={"Percentage increase from the previous comparable observation.","Процент роста с прошлого сопоставимого замера."},
      supplyDrop={"Decrease in listed item quantity, not confirmed sales.","Сокращение количества лотов, не подтверждённые продажи."},
      volatility={"Observed price volatility above this percentage.","Волатильность наблюдаемой цены выше порога."},
      opportunity={"Opportunity Score from 0 to 100, with an optional maximum Risk Score.",
        "Opportunity Score от 0 до 100 при ограничении Risk Score."},
    }
    local pair=explanation[p.condition]
    valueHelp:SetText(pair and l(pair[1],pair[2]) or "")
  end
  -- Different condition units share the same input position; ordinary labels
  -- should not remain visible when a field is hidden.
  local function bindLabel(editBox)
    -- The helper-created FontString is the immediately preceding label only
    -- when we attach it in edit(); no private region inspection required.
  end
  p.status=fs(p,"",20,-248,700)
  p.status:SetTextColor(.80,.91,.98)
  p.selectedRule=nil;p.rulePage=1;p.historyPage=1
  local perPage=3
  local function applyRule()
    local entered=p.selection:GetText() or ""
    local key=itemKey(p.selection)
    if entered~="" and not key then
      p.status:SetText(l("Unknown item. Choose a suggestion or enter an item ID.",
        "Предмет не найден. Выберите подсказку или введите ID."));return
    end
    key=key or selectedKey(p)
    if not key then p.status:SetText(l("Choose an item first.","Сначала выберите предмет."));return end
    local value
    if A.SmartAlertUnit(p.condition)=="money" then
      local g,s,c=tonumber(p.gold:GetText()),tonumber(p.silver:GetText()),tonumber(p.copper:GetText())
      if not g or not s or not c or g<0 or s<0 or c<0 or s>=100 or c>=100 then
        p.status:SetText(l("Enter valid gold / silver / copper values.","Укажите корректные золото / серебро / медь."));return
      end
      value=math.floor(g)*10000+math.floor(s)*100+math.floor(c)
    else value=tonumber(p.threshold:GetText()) end
    local ok,err=A.AddSmartAlert(key,p.condition,value,tonumber(p.risk:GetText()))
    if not ok then
      p.status:SetText(err=="threshold" and l("Invalid threshold.","Неверный порог.")
        or l("Invalid item ID.","Неверный ID предмета."));return
    end
    p.selectedRule=nil;p.rulePage=1
    p.status:SetText(l("Saved: ","Сохранено: ")..A.ProItemName(key).." | "..A.SmartAlertLabel(p.condition))
    p.update()
  end
  local createBtn=button(p,l("Save condition","Сохранить условие"),20,-205,156,applyRule)
  if A.ButtonActionIcon then A.ButtonActionIcon(createBtn,"primary") end
  attachHelp(createBtn,l("Save condition","Сохранить условие"),l(
    "Add or replace this condition for the item. Other conditions remain enabled.",
    "Добавить или обновить это условие для предмета. Другие условия сохранятся."))
  local removeBtn=button(p,l("Remove selected","Удалить выбранное"),192,-205,153,function()
    if not p.selectedRule then p.status:SetText(l("Select a rule below.","Выберите правило ниже."));return end
    A.RemoveSmartAlert(p.selectedRule.key,p.selectedRule.id)
    p.selectedRule=nil;p.update()
  end)
  if A.ButtonActionIcon then A.ButtonActionIcon(removeBtn,"danger") end
  attachHelp(removeBtn,l("Remove selected","Удалить выбранное"),l(
    "Delete only the highlighted condition. This does not erase market price history.",
    "Удалить только выделенное условие. История рыночных цен не удаляется."))
  local toggleBtn=button(p,l("Enable / disable","Включить / отключить"),357,-205,170,function()
    if not p.selectedRule then p.status:SetText(l("Select a rule below.","Выберите правило ниже."));return end
    if p.selectedRule.legacy then
      p.status:SetText(l("Old price rules can be removed and recreated.",
        "Старые ценовые условия можно удалить и создать заново."));return
    end
    local newEnabled=not p.selectedRule.enabled
    A.SetSmartAlertEnabled(p.selectedRule.key,p.selectedRule.id,newEnabled)
    p.selectedRule.enabled=newEnabled
    p.update()
  end)
  local header1=fs(p,l("ACTIVE CONDITIONS (click to select)","УСЛОВИЯ (нажмите для выбора)"),20,-268,700)
  header1:SetTextColor(1,.76,.21)
  local function itemRow(y)
    local b=CreateFrame("Button",nil,p)
    b:SetSize(696,26);b:SetPoint("TOPLEFT",p,"TOPLEFT",20,y)
    b.background=tex(b,0,0,696,26,.11,.15,.17,.68)
    local label=b:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    label:SetPoint("LEFT",b,"LEFT",9,0);label:SetWidth(675);label:SetJustifyH("LEFT")
    b.label=label
    b:SetScript("OnEnter",function(self)self.background:SetVertexColor(.26,.23,.12,.9)end)
    b:SetScript("OnLeave",function(self)
      if self._atsSelected then self.background:SetVertexColor(.27,.21,.10,.78)
      else self.background:SetVertexColor(.11,.15,.17,.68) end
    end)
    b:Hide()
    return b
  end
  p.ruleRows={}
  for i=1,perPage do p.ruleRows[i]=itemRow(-289-(i-1)*29) end
  button(p,l("< Rules","< Правила"),20,-378,106,function()
    p.rulePage=math.max(1,p.rulePage-1);p.update()
  end)
  button(p,l("Rules >","Правила >"),138,-378,106,function()
    p.rulePage=p.rulePage+1;p.update()
  end)
  p.rulePageLabel=fs(p,"",259,-386,441)
  local header2=fs(p,l("NOTIFICATION HISTORY (select to view item)","ИСТОРИЯ СИГНАЛОВ (нажмите для просмотра)"),20,-414,700)
  header2:SetTextColor(1,.76,.21)
  p.historyRows={}
  for i=1,3 do p.historyRows[i]=itemRow(-438-(i-1)*27) end
  button(p,l("< History","< История"),20,-525,110,function()
    p.historyPage=math.max(1,p.historyPage-1);p.update()
  end)
  button(p,l("History >","История >"),145,-525,110,function()
    p.historyPage=p.historyPage+1;p.update()
  end)
  button(p,l("Clear history","Очистить историю"),462,-525,168,function()
    A.ClearSmartAlertHistory();p.historyPage=1;p.update()
  end)
  p.historyPageLabel=fs(p,"",269,-531,185)
  p.update=function()
    if p.selectedRule and not p.selectedRule.legacy then
      if p.selectedRule.enabled then
        toggleBtn:SetText(l("Disable condition","Отключить условие"))
        if A.StyleButton then A.StyleButton(toggleBtn,"warning") end
      else
        toggleBtn:SetText(l("Enable condition","Включить условие"))
        if A.StyleButton then A.StyleButton(toggleBtn,"primary") end
      end
    else
      toggleBtn:SetText(l("Enable / disable","Включить / отключить"))
      if A.StyleButton then A.StyleButton(toggleBtn,"secondary") end
    end
    local all=A.AllSmartAlertRules()
    local pages=math.max(1,math.ceil(#all/perPage))
    p.rulePage=math.max(1,math.min(p.rulePage,pages))
    p.rulePageLabel:SetText(string.format(l("Rules %d/%d (%d)","Правила %d/%d (%d)"),p.rulePage,pages,#all))
    for i=1,#p.ruleRows do
      local entry=all[(p.rulePage-1)*perPage+i]
      local b=p.ruleRows[i]
      if entry then
        local isSelected=p.selectedRule and p.selectedRule.key==entry.key and tostring(p.selectedRule.id)==tostring(entry.id)
        b._atsSelected=isSelected and true or false
        if b._atsSelected then b.background:SetVertexColor(.27,.21,.10,.78)
        else b.background:SetVertexColor(.11,.15,.17,.68) end
        local selectMark=isSelected and "> " or ""
        b.label:SetText(selectMark..(entry.enabled and "|cffb8f8ba" or "|cff9b9b9b")..A.ProItemName(entry.key).." | "..
          A.SmartAlertLabel(entry.kind).." "..A.FormatSmartAlertValue(entry.kind,entry.value).."|r")
        b:SetScript("OnClick",function()
          kindMenu:Hide()
          p.selectedRule=entry;p.condition=entry.kind
          p.selection.itemKey=entry.key;p.selection._applying=true
          p.selection:SetText(A.ProItemName(entry.key));p.selection._applying=false
          shareMarketChoice(p.selection,entry.key)
          if entry.kind=="below" or entry.kind=="above" then
            local n=math.floor(entry.value+.5)
            p.gold:SetText(tostring(math.floor(n/10000)))
            p.silver:SetText(tostring(math.floor(n/100)%100))
            p.copper:SetText(tostring(n%100))
          else p.threshold:SetText(tostring(entry.value)) end
          if entry.risk then p.risk:SetText(tostring(entry.risk)) end
          p.refreshFields();p.update()
        end)
        b:Show()
      else b._atsSelected=false;b:Hide() end
    end
    local logs=A.GetSmartAlertHistory()
    local count=#logs
    local hpages=math.max(1,math.ceil(count/3))
    p.historyPage=math.max(1,math.min(p.historyPage,hpages))
    p.historyPageLabel:SetText(string.format(l("Page %d/%d", "Стр. %d/%d"),p.historyPage,hpages))
    for i=1,#p.historyRows do
      local entry=logs[(p.historyPage-1)*3+i]
      local b=p.historyRows[i]
      if entry then
        b.label:SetText(date("%d.%m %H:%M",entry.t).."  "..A.ProItemName(entry.key).."  | "..
          A.SmartAlertLabel(entry.kind)..": "..A.FormatSmartAlertValue(entry.kind,entry.observed))
        b:SetScript("OnClick",function()inspect(entry.key)end)
        b:Show()
      else b:Hide() end
    end
  end
  p.refreshFields()
  A.RefreshSmartAlerts=function()
    if p:IsShown() and A.proWindow and A.proWindow.active=="alerts" then p.update() end
  end
  return p
end

