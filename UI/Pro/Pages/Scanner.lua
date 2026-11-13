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

function B.scanner(root)
  local p=newPage(root)
  heading(p,l("Market opportunities by discount, score and risk","Рыночные возможности: скидка, рейтинг и риск"),-12)
  fs(p,l("Scores use local Auctionator observations; neither score predicts successful sales.",
    "Оценка по локальной истории Auctionator. Баллы не прогнозируют успешную продажу."),20,-51,701)
  p.status=fs(p,"",20,-80,704)
  button(p,l("Scan local history","Проверить базу"),20,-111,158,function()
    p.status:SetText(l("Scanning...","Анализ базы..."))
    A.StartProScanner(function(n,total)
      p.status:SetText(string.format("%d / %d",n,total))
    end,function(results)
      p.page=1
      if A.QueueScannerItemMetadata then A.QueueScannerItemMetadata(results,300) end
      if p.update then p.update() end
    end)
  end)
  p.showUnknown=A.db.pro.scannerShowUnknown==true
  local filterButton=button(p,"",187,-111,205,function()
    p.showUnknown=not p.showUnknown
    A.db.pro.scannerShowUnknown=p.showUnknown
    p.page=1;p.update()
  end)
  button(p,l("Load item names","Загрузить названия"),401,-111,151,function()
    if A.QueueScannerItemMetadata then A.QueueScannerItemMetadata(A.ProScanner(),350) end
    p.update()
  end)
  local sortModes={
    {id="score",title=l("Opportunity score","По рейтингу"),
      detail=l("Highest opportunity score first, based on the available local observations.",
        "Сначала самый высокий рейтинг возможностей по локальным данным.")},
    {id="discount",title=l("Discount to median","По скидке"),
      detail=l("Largest discount compared to the historical median first.",
        "Сначала максимальная скидка относительно исторической медианы.")},
    {id="risk",title=l("Lowest uncertainty","По риску"),
      detail=l("Lowest Risk Score first. Risk is uncertainty, not the chance of a failed sale.",
        "Сначала минимальный Risk Score. Риск означает неопределённость, а не вероятность непродажи.")},
  }
  local sortMenu
  local sortButton=button(p,"",561,-111,154,function()
    if not sortMenu then return end
    if sortMenu:IsShown() then sortMenu:Hide()
    else
      if GameTooltip then GameTooltip:Hide() end
      sortMenu:Show()
    end
  end)
  if A.StyleButton then A.StyleButton(sortButton,"secondary") end
  local sortArrow=sortButton:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
  sortArrow:SetPoint("RIGHT",sortButton,"RIGHT",-8,0)
  sortArrow:SetText("v");sortArrow:SetTextColor(.96,.79,.39)
  sortMenu=CreateFrame("Frame",nil,p)
  p.sortMenu=sortMenu
  sortMenu:SetSize(239,116)
  sortMenu:SetPoint("TOPRIGHT",sortButton,"BOTTOMRIGHT",0,-3)
  sortMenu:SetFrameStrata("FULLSCREEN_DIALOG")
  sortMenu:SetFrameLevel(math.max(p:GetFrameLevel()+20,sortButton:GetFrameLevel()+12))
  sortMenu:EnableMouse(true)
  tex(sortMenu,0,0,239,116,.025,.036,.048,1)
  if sortMenu.SetBackdrop then
    sortMenu:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
      insets={left=3,right=3,top=3,bottom=3}})
    if sortMenu.SetBackdropBorderColor then sortMenu:SetBackdropBorderColor(.70,.55,.25,1) end
  end
  local sortTitle=fs(sortMenu,l("SORT RESULTS","СОРТИРОВКА"),10,-7,217)
  sortTitle:SetTextColor(1,.78,.32)
  tex(sortMenu,8,-27,223,1,.53,.40,.19,.8)
  local sortRows={}
  for i=1,#sortModes do
    local option=sortModes[i]
    local row=CreateFrame("Button",nil,sortMenu)
    row:SetSize(223,26);row:SetPoint("TOPLEFT",sortMenu,"TOPLEFT",8,-31-(i-1)*27)
    local fill=tex(row,0,0,223,26,.075,.105,.13,.94)
    local mark=row:CreateTexture(nil,"ARTWORK")
    mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    mark:SetSize(17,17);mark:SetPoint("LEFT",row,"LEFT",4,0)
    local label=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    label:SetPoint("LEFT",row,"LEFT",25,0);label:SetWidth(188)
    label:SetJustifyH("LEFT");label:SetText(option.title)
    row.fill=fill;row.mark=mark;row.label=label;row.mode=option.id
    row:SetScript("OnEnter",function(self)
      self.fill:SetVertexColor(.24,.22,.12,.98)
      showHelp(self,option.title,option.detail)
    end)
    row:SetScript("OnLeave",function(self)
      local selected=A.db.pro.scannerSort==self.mode
      self.fill:SetVertexColor(selected and .23 or .075,selected and .17 or .105,
        selected and .075 or .13,.94)
      if GameTooltip then GameTooltip:Hide() end
    end)
    local function selectSort()
      if not sortMenu:IsShown() then return end
      A.db.pro.scannerSort=option.id
      sortMenu:Hide()
      p.page=1
      if p.update then p.update() end
    end
    row:SetScript("OnMouseDown",selectSort)
    row:SetScript("OnClick",selectSort)
    sortRows[i]=row
  end
  function sortMenu:RefreshSelection()
    for i=1,#sortRows do
      local row=sortRows[i]
      local active=row.mode==(A.db.pro.scannerSort or "score")
      row.fill:SetVertexColor(active and .23 or .075,active and .17 or .105,
        active and .075 or .13,.94)
      if active then row.mark:Show();row.label:SetTextColor(1,.87,.56)
      else row.mark:Hide();row.label:SetTextColor(.92,.93,.92) end
    end
  end
  sortMenu:SetScript("OnKeyDown",function(self,key)if key=="ESCAPE" then self:Hide() end end)
  sortMenu:SetScript("OnShow",function(self)
    self:RefreshSelection()
    if self.EnableKeyboard then self:EnableKeyboard(true) end
  end)
  sortMenu:SetScript("OnHide",function(self)
    if self.EnableKeyboard then self:EnableKeyboard(false) end
    if GameTooltip then GameTooltip:Hide() end
  end)
  sortMenu:Hide()
  p:HookScript("OnHide",function()sortMenu:Hide()end)
  sortButton:SetScript("OnEnter",function(self)
    if not sortMenu:IsShown() then
      showHelp(self,l("Sort scanner results","Сортировка результатов"),
        l("Choose a sort order from the dropdown. Rankings are not forecasts.",
          "Выберите порядок сортировки в меню. Рейтинги не являются прогнозом."))
    end
  end)
  sortButton:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
  local legend=fs(p,l("Score 0–100 = opportunity   Risk 0–100 = uncertainty (lower is better)",
    "Рейтинг 0–100 = возможность   Риск 0–100 = неопределённость (меньше лучше)"),20,-151,696)
  legend:SetTextColor(.78,.83,.88)
  tex(p,20,-176,696,1,.36,.29,.17,.66)
  -- One continuous list surface, rather than a stack of red button blocks.
  -- Each full-width transparent button is only an interaction target; the
  -- subtle row divider and hover overlay are drawn over the shared background.
  p.rows={}
  for i=1,11 do
    local row=CreateFrame("Button",nil,p)
    row:SetSize(696,27)
    row:SetPoint("TOPLEFT",p,"TOPLEFT",20,-184-(i-1)*29)
    local hover=tex(row,0,0,696,27,.52,.38,.12,.20)
    hover:Hide()
    row.hoverBackground=hover
    tex(row,0,-26,696,1,.33,.30,.24,.32)
    local icon=row:CreateTexture(nil,"ARTWORK")
    icon:SetSize(21,21);icon:SetPoint("LEFT",row,"LEFT",7,0)
    row.scanIcon=icon
    local label=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    label:SetPoint("LEFT",row,"LEFT",35,0)
    label:SetPoint("RIGHT",row,"RIGHT",-5,0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1,.84,.40)
    row:SetFontString(label)
    row:Hide()
    p.rows[i]=row
  end
  p.page=1
  button(p,"<",17,-518,38,function()p.page=math.max(1,p.page-1);p.update()end)
  button(p,">",66,-518,38,function()p.page=p.page+1;p.update()end)
  p.update=function()
    p.showUnknown=A.db.pro.scannerShowUnknown==true
    local results=A.ProScanner()
    if p.queuedResults~=results then
      p.queuedResults=results
      if A.QueueScannerItemMetadata then A.QueueScannerItemMetadata(results,300) end
    end
    -- Historical saved results created by older versions may lack new scores.
    -- Do not fabricate a score for them. Ask the user to rescan instead.
    local sorted={}
    for i=1,#results do sorted[i]=results[i] end
    if A.SortScannerResults then A.SortScannerResults(sorted,A.db.pro.scannerSort) end
    local display,unknown,known={},0,0
    for i=1,#sorted do
      local item=sorted[i]
      local link=A.ProItemLink and A.ProItemLink(item.key)
      local name,icon,id,ready
      if A.PeekItemMetadata then name,icon,id,ready=A.PeekItemMetadata(link) end
      if ready then known=known+1 else unknown=unknown+1 end
      if ready or p.showUnknown then
        display[#display+1]={item=item,name=name,icon=icon,id=id,ready=ready}
      end
    end
    local mode=A.db.pro.scannerSort or "score"
    local sortNames={score=l("Score","Рейтинг"),discount=l("Discount","Скидка"),risk=l("Risk","Риск")}
    sortButton:SetText(l("Sort: ","Сорт.: ")..(sortNames[mode] or sortNames.score))
    filterButton:SetText(p.showUnknown and
      l("Hide unknown IDs","Скрыть неизвестные ID") or
      l("Show unknown IDs","Показать неизвестные ID"))
    p.status:SetText(string.format(l(
      "Matches: %d    Named: %d    Unidentified: %d%s",
      "Совпадений: %d    С названиями: %d    Неизвестных: %d%s"),
      #results,known,unknown,(not p.showUnknown and unknown>0) and l(" (hidden)"," (скрыты)") or ""))
    local maxPage=math.max(1,math.ceil(#display/#p.rows))
    p.page=math.max(1,math.min(maxPage,p.page))
    for i=1,#p.rows do
      local view=display[(p.page-1)*#p.rows+i]
      local row=p.rows[i]
      if view then
        local item=view.item
        local itemName=view.name or string.format(l("Unknown item (#%d)","Неизвестный предмет (#%d)"),view.id or 0)
        local score=item.score and tostring(item.score) or "?"
        local risk=item.risk and tostring(item.risk) or "?"
        row:SetText(string.format("%s   -%.1f%%   %s   S:%s R:%s",itemName,item.discount or 0,
          currency(item.price),score,risk))
        row.scanIcon:SetTexture(view.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row:SetScript("OnClick",function()inspect(item.key)end)
        row:SetScript("OnEnter",function(self)
          if self.hoverBackground then self.hoverBackground:Show() end
          if not GameTooltip then return end
          GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
          GameTooltip:SetText(itemName)
          GameTooltip:AddLine(string.format(l("Discount: %.1f%% | Opportunity: %s/100 | Risk: %s/100",
            "Скидка: %.1f%% | Рейтинг: %s/100 | Риск: %s/100"),item.discount or 0,score,risk),1,.85,.35)
          GameTooltip:AddLine(l("Data quality: ","Качество данных: ")..tostring(item.quality or "?").."/100",.8,.92,1)
          if item.age then GameTooltip:AddLine(string.format(l("Age: %.1f hours","Возраст: %.1f ч"),item.age),.8,.9,1) end
          if item.samples then GameTooltip:AddLine(l("Observations: ","Замеров: ")..tostring(item.samples),.8,.9,1) end
          if not view.ready then GameTooltip:AddLine(l("Item name not loaded by the client.","Клиент не загрузил название предмета."),1,.7,.4,true) end
          if not item.score then GameTooltip:AddLine(l("Legacy results. Refresh the scanner to calculate scores.","Старые результаты. Обновите сканер для расчёта рейтингов."),1,.7,.4,true) end
          GameTooltip:AddLine(l("Risk is uncertainty, NOT the probability of failing to sell.","Риск — неопределённость, НЕ вероятность непродажи."),.9,.85,.65,true)
          GameTooltip:AddLine(l("Click to inspect market history.","Нажмите для просмотра истории."),.8,.9,1)
          GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function(self)
          if self.hoverBackground then self.hoverBackground:Hide() end
          if GameTooltip then GameTooltip:Hide() end
        end)
        row:Show()
      else
        if row.hoverBackground then row.hoverBackground:Hide() end
        row:Hide()
      end
    end
    if #display==0 and #results>0 then
      p.status:SetText(p.status:GetText()..l("  |  Load names or show IDs.","  |  Загрузите имена или покажите ID."))
    end
  end
  A.RefreshProItemLabels=function()
    local w=A.proWindow
    if w and w:IsShown() and w.active=="scanner" and p:IsShown() then p.update() end
  end
  return p
end

