-- TradeScope 4.0: WoW-native multi-tool trading workstation.
local A=ATS
local WIDTH,HEIGHT=990,780
local TOOLS={"scanner","alerts","candles","activity","journal","craft","indicators","heatmap","quality","craftscan"}
local function l(en,ru) return A.locale=="ruRU" and ru or en end
local names={
 scanner={"Market scanner","Сканер рынка"},alerts={"Price alerts","Ценовые сигналы"},
 candles={"OHLC candles","Свечные графики"},activity={"Market activity","Активность рынка"},
 journal={"Trading journal","Журнал сделок"},craft={"Crafting calculator","Калькулятор крафта"},
 indicators={"Indicators","Индикаторы"},heatmap={"Price heatmap","Тепловая карта"},
 quality={"Data quality","Качество данных"},craftscan={"Recipe catalog","Каталог крафта"},
}
local function tr(key) local n=names[key];return n and l(n[1],n[2]) or key end
local function tex(p,x,y,w,h,r,g,b,a)
  local t=p:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,a or 1)
  t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);t:SetSize(w,h)
  return t
end
local function fs(p,text,x,y,width,normal)
  local t=p:CreateFontString(nil,"ARTWORK",normal and "GameFontNormal" or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);t:SetWidth(width or 690)
  t:SetJustifyH("LEFT");t:SetText(text or "")
  return t
end
local function button(p,title,x,y,w,fn,h)
  local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
  b:SetSize(w or 110,h or 24);b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
  b:SetText(title)
  b:SetScript("OnClick",fn or function()end)
  if A.StyleButton then A.StyleButton(b) end
  return b
end
-- All money/quantity fields retain their numeric behavior; item fields share
-- the same name/ID search used by the original TradeScope market terminal.
local function helpText(caption)
  local lower=string.lower(tostring(caption or ""))
  if lower:find("item",1,true) or lower:find("ingredient",1,true) or lower:find("материал",1,true)
    or lower:find("предмет",1,true) or lower:find("ссылка",1,true) or lower:find("результат",1,true) then
    return l("Search the local Auctionator item cache by name, ID, or item link. Select an entry from the dropdown. Items not yet scanned may not appear.",
             "Поиск по названию, ID или ссылке среди известных Auctionator предметов. Выберите подсказку. Неотсканированные предметы могут отсутствовать.")
  end
  if lower:find("gold",1,true) or lower:find("золото",1,true) or lower:find("silver",1,true) or lower:find("серебро",1,true) or lower:find("copper",1,true) or lower:find("медь",1,true) then
    return l("The unit price for ONE item. Enter gold, silver and copper in separate fields.",
             "Цена за ОДИН предмет. Укажите золото, серебро и медь в отдельных полях.")
  end
  if lower:find("quantity",1,true) or lower:find("количество",1,true) or lower:find("qty",1,true) or lower:find("кол-во",1,true) then
    return l("Number of items in this transaction or recipe ingredient.","Количество предметов в сделке или ингредиентах рецепта.")
  end
  if lower:find("hour",1,true) or lower:find("час",1,true) then
    return l("Length of the observed period in hours; no missing historical data is fabricated.",
             "Длительность периода в часах; недостающая история не создаётся искусственно.")
  end
  return l("Edit this parameter, then click the calculation/update button to apply it.",
           "Измените параметр и нажмите кнопку расчёта или обновления.")
end
local function showHelp(control, title, detail)
  if not GameTooltip then return end
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(tostring(title or "TradeScope"))
  GameTooltip:AddLine(tostring(detail or ""),1,1,1,true)
  GameTooltip:Show()
end
local function attachHelp(control,title,detail)
  control:SetScript("OnEnter",function(self) showHelp(self,title,detail) end)
  control:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
-- Hoverable, localized explanations for numerical research output.
-- Attach the mouse hit area to the text itself instead of independently
-- reproducing its x/y offsets. Both research tabs use the same centered,
-- fixed-height highlight even though their row spacing differs.
local function addMetricTooltips(page,rows,descriptions,width)
  local height=22
  for i=1,math.min(#descriptions,#rows) do
    local row=rows[i]
    local entry=descriptions[i]
    local hit=CreateFrame("Frame",nil,page)
    hit:SetSize(width,height)
    hit:SetPoint("LEFT",row,"LEFT",0,0)
    hit:EnableMouse(true)
    local highlight=tex(hit,0,0,width,height,.38,.30,.12,.18)
    highlight:Hide()
    hit:SetScript("OnEnter",function(self)
      local label=row:GetText()
      if type(label)~="string" or label=="" then return end
      highlight:Show()
      showHelp(self,label,l(entry[1],entry[2]))
    end)
    hit:SetScript("OnLeave",function()
      highlight:Hide()
      if GameTooltip then GameTooltip:Hide() end
    end)
  end
  page:HookScript("OnHide",function()if GameTooltip then GameTooltip:Hide() end end)
end
local function asExactItem(text)
  if type(text)~="string" then return nil end
  local number=tonumber(text:match("item:(%d+)")) or tonumber(text:match("^%s*(%d+)%s*$"))
  return number and ("db:"..number) or nil
end
-- A single selected market item is shared by the research pages. Recipe inputs
-- are intentionally separate: a recipe is not an Auction House item selection.
local itemKey -- resolved after edit() is defined; called only from UI callbacks.
local function sharedMarketChoice()
  if type(A.proSharedMarketChoice)=="table" then return A.proSharedMarketChoice end
  local pro=A.db and A.db.pro
  if pro and (type(pro.sharedMarketText)=="string" or type(pro.sharedMarketKey)=="string") then
    A.proSharedMarketChoice={key=pro.sharedMarketKey,text=pro.sharedMarketText or ""}
    return A.proSharedMarketChoice
  end
end
local function fillMarketEdit(e,choice)
  if not e or not choice then return end
  local key=choice.key
  local text=choice.text or ""
  if key and A.ProItemName then
    -- Prefer readable item names when the client's cache has loaded them.
    local resolved=A.ProItemName(key)
    if type(resolved)=="string" and resolved~="" and not resolved:match("^#%d+$") then
      text=resolved
    elseif text=="" then text=resolved end
  end
  e._applying=true
  e.itemKey=key
  e:SetText(text)
  e._applying=false
  if e.searchPopup then e.searchPopup:Hide() end
end
local function shareMarketChoice(e,forcedKey)
  if not e or not e._proMarketItem or e._applying then return end
  local text=e:GetText() or ""
  local key=forcedKey or (itemKey and itemKey(e))
  -- An intentionally empty field clears the shared selection rather than
  -- quietly showing the previously researched item in another tab.
  local choice={key=key,text=text}
  A.proSharedMarketChoice=choice
  if A.db and A.db.pro then
    A.db.pro.sharedMarketKey=key
    A.db.pro.sharedMarketText=text
  end
  local frame=A.proWindow
  if frame and frame.pages then
    for _,page in pairs(frame.pages) do
      local other=page.proMarketEdit
      if other and other~=e then fillMarketEdit(other,choice) end
    end
  end
end
local function attachItemSearch(e,p)
  local popup=CreateFrame("Frame",nil,p:GetParent())
  popup:SetSize(math.max(205,e:GetWidth()),120)
  popup:SetPoint("TOPLEFT",e,"BOTTOMLEFT",0,-3)
  popup:SetFrameStrata("FULLSCREEN_DIALOG")
  popup:SetFrameLevel((p:GetParent():GetFrameLevel() or 1)+55)
  popup:EnableMouse(true)
  local bg=popup:CreateTexture(nil,"BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetVertexColor(.035,.050,.069,.99)
  bg:SetAllPoints(popup)
  if popup.SetBackdrop then
    popup:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
      insets={left=3,right=3,top=3,bottom=3}})
  end
  popup.rows={}
  popup:Hide()
  local function choose(match)
    if not match then return end
    e.itemKey="db:"..match.id
    e._applying=true
    e:SetText(match.name or ("#"..match.id))
    e._applying=false
    e:ClearFocus()
    popup:Hide()
    shareMarketChoice(e,e.itemKey)
    if p.update then p.update() end
  end
  local rows=5
  for i=1,rows do
    local b=CreateFrame("Button",nil,popup)
    b:SetSize(popup:GetWidth()-8,23)
    b:SetPoint("TOPLEFT",popup,"TOPLEFT",4,-4-(i-1)*23)
    local highlight=b:CreateTexture(nil,"BACKGROUND")
    highlight:SetAllPoints(b);highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(.23,.21,.10,.68)
    if b.SetHighlightTexture then b:SetHighlightTexture(highlight) end
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetSize(19,19);icon:SetPoint("LEFT",b,"LEFT",2,0)
    local name=b:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    name:SetPoint("LEFT",b,"LEFT",26,0)
    name:SetWidth(popup:GetWidth()-40);name:SetJustifyH("LEFT")
    b.icon=icon;b.label=name
    b:SetScript("OnClick",function(self) choose(self.match) end)
    popup.rows[i]=b
  end
  local matches,offset={},0
  local function refresh()
    -- Never resurrect a stale dropdown when a tab/window is reopened or
    -- when SetText() restores an item programmatically.
    if not e.HasFocus or not e:HasFocus() or not p:IsShown() then
      popup:Hide();return
    end
    local query=e:GetText() or ""
    local isNumeric=query:match("^%d+$")~=nil
    if #query < (isNumeric and 1 or 2) or not A.FindKnownItems then
      popup:Hide();return
    end
    matches=A.FindKnownItems(query,80) or {}
    offset=math.max(0,math.min(offset,math.max(0,#matches-rows)))
    for i=1,rows do
      local item=matches[offset+i]
      local b=popup.rows[i]
      if item then
        b.match=item
        b.label:SetText(item.name or ("#"..item.id))
        b.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        b:Show()
      else b.match=nil;b:Hide() end
    end
    if #matches>0 then
      popup:SetHeight(8+math.min(rows,#matches)*23)
      popup:Show()
    else popup:Hide() end
  end
  popup:EnableMouseWheel(true)
  popup:SetScript("OnMouseWheel",function(_,delta)
    offset=math.max(0,math.min(math.max(0,#matches-rows),offset-(delta>0 and 1 or -1)))
    refresh()
  end)
  e:SetScript("OnTextChanged",function(self)
    if self._applying then return end
    self.itemKey=nil
    offset=0
    refresh()
  end)
  e:SetScript("OnEnterPressed",function(self)
    local raw=self:GetText() or ""
    local key=asExactItem(raw)
    if key then
      self.itemKey=key
    elseif #matches>0 then
      choose(matches[offset+1]);return
    end
    popup:Hide();self:ClearFocus()
    shareMarketChoice(self,self.itemKey)
    if p.update then p.update() end
  end)
  e:SetScript("OnEscapePressed",function(self) popup:Hide();self:ClearFocus() end)
  e:SetScript("OnEditFocusLost",function(self)
    -- On older WoW clients focus is lost before a dropdown row receives its
    -- mouse click. Do not hide the popup here; clicking its row will commit the
    -- exact choice. Share typed values when changing tabs via the keyboard.
    if p:IsShown() then shareMarketChoice(self) end
  end)
  e.searchPopup=popup
  -- The popup belongs to the Pro window, not the tab; explicitly hide it
  -- before showing another tab or reopening the window.
  p.marketPopups=p.marketPopups or {}
  p.marketPopups[#p.marketPopups+1]=popup
  -- The parent page can be hidden when switching tabs. Prevent stale popups.
  p:HookScript("OnHide",function()popup:Hide()end)
end
local function edit(p,caption,x,y,w,value,numeric,noItemSearch)
  local label
  if caption then label=fs(p,caption,x,y-2,w+65) end
  local e=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
  e:SetSize(w or 110,24);e:SetPoint("TOPLEFT",p,"TOPLEFT",x,y-23)
  e.label=label
  e:SetAutoFocus(false);e:SetMaxLetters(190)
  if numeric and e.SetNumeric then e:SetNumeric(true) end
  e:SetText(value and tostring(value) or "")
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  local detail=helpText(caption)
  attachHelp(e,caption,detail)
  -- FontStrings do not receive mouse scripts on all WoW client versions.
  if not numeric and not noItemSearch then attachItemSearch(e,p) end
  return e
end
-- Every analytical tab uses one label and a common baseline/left margin.
-- Only the alerts page needs a lower row because its extra explanatory text.
local function marketInput(p,x,y,w)
  local e=edit(p,l("Item / ID","Предмет / ID"),x or 20,y or -60,w or 216)
  e._proMarketItem=true
  p.proMarketEdit=e
  return e
end
itemKey = function(e)
  if not e then return nil end
  if e.itemKey then return e.itemKey end
  local raw=e:GetText() or ""
  local direct=asExactItem(raw)
  if direct then return direct end
  if A.FindKnownItems and #raw>1 then
    local found=A.FindKnownItems(raw,20)
    for i=1,#found do
      if found[i].name==raw then return "db:"..found[i].id end
    end
  end
end
local function itemID(e)
  local key=itemKey(e)
  return key and tonumber(key:match("(%d+)$")) or nil
end

local function heading(p,s,y)
  fs(p,s,20,y,715,true)
  tex(p,16,y-26,709,1,.48,.38,.16,.7)
end
local function pbutton(p,title,y,fn)
  return button(p,title,20,y,170,25,fn)
end
local function currency(value)
  if type(value)~="number" then return "-" end
  return (value<0 and "-" or "")..A.Money(math.abs(value))
end
local function asItem(text)
  return asExactItem(text)
end
local function selectedKey(f)
  local field=f and f.proMarketEdit
  if field then
    local key=itemKey(field)
    if key then
      local last=sharedMarketChoice()
      if not last or last.key~=key then shareMarketChoice(field,key) end
      return key
    end
    -- An unknown nonempty search term should NOT silently reuse another item.
    if (field:GetText() or ""):match("%S") then return nil end
  end
  local shared=sharedMarketChoice()
  if shared then return shared.key end
  local key=f and f.selection and itemKey(f.selection) or nil
  if not key and A.dashboard and A.dashboard.key then key=A.dashboard.key end
  if not key and A.state then key=A.state.key end
  return key
end

local function anyItem(f)
  return selectedKey(f)
end
local function inspect(key)
  if A.OpenDashboardScanKey and A.ProItemLink(key) then
    if A.proWindow and A.proWindow:IsShown() then
      A.proWindow.restoreDashboard=false
      A.proWindow:Hide()
    end
    A.OpenDashboardScanKey(key)
  end
end
local function newPage(root)
  local p=CreateFrame("Frame",nil,root.content)
  p:SetSize(946,557);p:SetPoint("TOPLEFT",root.content,"TOPLEFT",0,0)
  p:Hide()
  return p
end
local function lineList(p,n,start,spacing)
  local rows={}
  for i=1,n do
    local y=start-(i-1)*(spacing or 29)
    local b=button(p,"",18,y,706,nil,26)
    local t=b:GetFontString()
    if t and t.SetJustifyH then t:SetJustifyH("LEFT") end
    b:Hide();rows[i]=b
  end
  return rows
end
local function captureRow(p,x,y,title,body)
  fs(p,title,x,y,340,true)
  fs(p,body,x,y-27,670)
end
local function labelNumber(n) return n and string.format("%.1f",n) or "-" end

-- Consistent item-identification strip across all market research tabs.
-- It deliberately shows the SAME selected item and the SAME coordinates.
local function makeItemIdentity(page)
  local bar=CreateFrame("Frame",nil,page)
  bar:SetSize(694,42)
  bar:SetPoint("TOPLEFT",page,"TOPLEFT",20,-117)
  tex(bar,0,0,694,42,.095,.125,.14,.90)
  tex(bar,0,0,694,1,.46,.35,.17,.82)
  bar.icon=bar:CreateTexture(nil,"ARTWORK")
  bar.icon:SetSize(32,32);bar.icon:SetPoint("TOPLEFT",bar,"TOPLEFT",6,-5)
  bar.name=fs(bar,"",47,-6,620,true)
  bar.description=fs(bar,"",47,-24,630)
  bar:EnableMouse(true)
  bar:SetScript("OnEnter",function(self)
    if not self.key then return end
    showHelp(self,self.name:GetText(),l(
      "Selected item. Data is based on stored Auctionator scans; click to open its market chart.",
      "Выбранный предмет. Данные получены из истории Auctionator; нажмите, чтобы открыть график рынка."))
  end)
  bar:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
  bar:SetScript("OnMouseUp",function(self,button)
    if button=="LeftButton" and self.key and A.OpenDashboardScanKey then inspect(self.key) end
  end)
  function bar:showItem(key)
    self.key=key
    if not key then
      self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      self.name:SetText(l("Select an item to analyze","Выберите предмет для анализа"))
      self.name:SetTextColor(.75,.79,.84)
      self.description:SetText(l("Enter a name or ID above","Введите название или ID выше"))
      return
    end
    local name,icon,id=A.ProItemMeta(key)
    self.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.name:SetText(A.FitItemName and A.FitItemName(name,self.name,615) or name)
    local link=A.ProItemLink(key)
    local quality
    if type(GetItemInfo)=="function" and link then
      local ok,_,_,q=pcall(GetItemInfo,link)
      if ok then quality=q end
    end
    local r,g,b=1,.82,.3
    if type(GetItemQualityColor)=="function" and type(quality)=="number" then
      local ok,rr,gg,bb=pcall(GetItemQualityColor,quality)
      if ok and type(rr)=="number" then r,g,b=rr,gg,bb end
    end
    self.name:SetTextColor(r,g,b)
    local samples=A.ProSamples and A.ProSamples(key) or {}
    self.description:SetText(string.format("ID: %s    %s: %d",tostring(id or "?"),
      l("Observations","Замеров"),#samples))
  end
  bar:showItem(nil)
  page.identity=bar
  return bar
end

local function normalizeRussian(text)
  text=tostring(text or ""):lower()
  local uppercase="АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
  local lowercase="абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
  local src,dst={},{}
  for c in uppercase:gmatch("[\194-\244][\128-\191]*") do src[#src+1]=c end
  for c in lowercase:gmatch("[\194-\244][\128-\191]*") do dst[#dst+1]=c end
  if #src==#dst then
    for i=1,#src do text=text:gsub(src[i],dst[i]) end
  end
  return text
end

local function makeScanner(root)
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

local function makeAlerts(root)
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

local function newPlot(p,x,y,w,h)
  local plot=CreateFrame("Frame",nil,p)
  plot:SetSize(w,h);plot:SetPoint("TOPLEFT",p,"TOPLEFT",x,y)
  -- Plot shares the Pro workstation surface, including its opacity slider.
  tex(plot,0,0,w,h,.018,.035,.055,0)
  plot.pool={};plot.used=0
  function plot:clear()
    for i=1,#self.pool do self.pool[i]:Hide() end
    self.used=0
  end
  function plot:rect(l,b,tw,th,r,g,bb,alpha)
    self.used=self.used+1
    local t=self.pool[self.used]
    if not t then
      t=self:CreateTexture(nil,"ARTWORK")
      t:SetTexture("Interface\\Buttons\\WHITE8X8")
      self.pool[self.used]=t
    end
    t:ClearAllPoints();t:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",l,b)
    t:SetSize(math.max(1,tw),math.max(1,th))
    t:SetVertexColor(r,g,bb,alpha or 1);t:Show()
    return t
  end
  return plot
end
local function miniLine(plot,x1,y1,x2,y2,r,g,b)
  local dx,dy=x2-x1,y2-y1
  local len=math.sqrt(dx*dx+dy*dy)
  if len<.1 then return end
  local tx=plot:rect((x1+x2)/2-len/2,(y1+y2)/2-1,len,2,r,g,b)
  if tx.SetRotation then
    local angle
    if math.atan2 then angle=math.atan2(dy,dx)
    elseif dx==0 then angle=dy>0 and math.pi/2 or -math.pi/2
    else angle=math.atan(dy/dx);if dx<0 then angle=angle+math.pi end end
    tx:ClearAllPoints()
    tx:SetPoint("CENTER",plot,"BOTTOMLEFT",(x1+x2)/2,(y1+y2)/2)
    tx:SetRotation(angle)
  end
end
local function makeCandles(root)
  local p=newPage(root)
  heading(p,l("Candlesticks (observed OHLC, no trade volume)","Свечи OHLC по замерам (без объёма сделок)"),-12)
  p.selection=marketInput(p,20,-60,216)
  p.bucket=edit(p,l("Bucket (hours)","Интервал свечи (ч)"),246,-60,100,tostring(A.db.pro.candleBucketHours),true)
  p.hours=edit(p,l("History (hours)","История (часов)"),365,-60,113,tostring(A.db.pro.candleHours),true)
  p.identity=makeItemIdentity(p)
  p.plot=newPlot(p,56,-174,630,292)
  p.info=fs(p,"",22,-478,690)
  p.hint=fs(p,l("Green = rising; red = falling. Empty hours mean no price observations.",
     "Зелёные — рост, красные — падение. Пустые часы — нет наблюдений."),22,-508,698)
  button(p,l("Update chart","Обновить"),506,-83,152,function()
    A.db.pro.candleBucketHours=math.max(1,math.min(168,math.floor(tonumber(p.bucket:GetText()) or 1)))
    A.db.pro.candleHours=math.max(1,math.min(2160,math.floor(tonumber(p.hours:GetText()) or 24)))
    p.update()
  end)
  p.update=function()
    local key=anyItem(p)
    p.identity:showItem(key)
    if not key then p.info:SetText(l("Select an item.","Выберите предмет."));p.plot:clear();return end
    local samples=A.ProSamples(key)
    local hours=A.db.pro.candleHours
    local bucket=A.db.pro.candleBucketHours
    local candles=A.ProCandles(samples,hours,bucket)
    local plot=p.plot
    plot:clear()
    for i=0,4 do plot:rect(0,i*73,630,1,.18,.28,.40,.6) end
    local lo,hi
    for i=1,#candles do
      lo=math.min(lo or candles[i].low,candles[i].low)
      hi=math.max(hi or candles[i].high,candles[i].high)
    end
    if not lo then p.info:SetText(l("No observations in selected period.","За период нет наблюдений."));return end
    local span=math.max(1,hi-lo)
    local start=time()-hours*3600
    local candW=math.max(2,math.min(13,(bucket/hours)*630*.66))
    local function y(price) return math.max(3,math.min(289,14+(price-lo)/span*262)) end
    local previousEMA,previousBoll,previousLower
    local indi=A.ProIndicators(samples)
    local lastIndi=indi.latest
    for i=1,#candles do
      local c=candles[i]
      local x=(c.t-start)/(hours*3600)*630
      if x>=0 and x<=630 then
        local rising=c.close>=c.open
        local r,g,b=rising and .24 or .95,rising and .88 or .31,rising and .49 or .29
        plot:rect(x,y(c.low),2,math.max(2,y(c.high)-y(c.low)),r,g,b)
        plot:rect(x-candW/2,math.min(y(c.open),y(c.close)),candW,
          math.max(3,math.abs(y(c.open)-y(c.close))),r,g,b)
      end
    end
    if A.db.pro.showEMA or A.db.pro.showBollinger then
      for i=1,#indi.values do
        local v=indi.values[i];local x=(v.t-start)/(hours*3600)*630
        if x>=0 and x<=630 then
          if A.db.pro.showEMA and v.ema then
            local yy=y(v.ema)
            if previousEMA and previousEMA.segment==v.segment and
                v.slot-previousEMA.slot<=2 then
              miniLine(plot,previousEMA.x,previousEMA.y,x,yy,1,.8,.25)
            end
            previousEMA={x=x,y=yy,slot=v.slot,segment=v.segment}
          end
          if A.db.pro.showBollinger and v.upper and v.lower then
            local yy=y(v.upper)
            local bottom=y(v.lower)
            if previousBoll and previousBoll.segment==v.segment and
                v.slot-previousBoll.slot<=2 then
              miniLine(plot,previousBoll.x,previousBoll.y,x,yy,.69,.5,.95)
            end
            if previousLower and previousLower.segment==v.segment and
                v.slot-previousLower.slot<=2 then
              miniLine(plot,previousLower.x,previousLower.y,x,bottom,.69,.5,.95)
            end
            previousBoll={x=x,y=yy,slot=v.slot,segment=v.segment}
            previousLower={x=x,y=bottom,slot=v.slot,segment=v.segment}
          end
        end
      end
    end
    p.info:SetText(l("Candles: ","Свечей: ")..#candles..
      "   L: "..currency(lo).."   H: "..currency(hi).."   EMA: "..currency(lastIndi and lastIndi.ema))
  end
  return p
end

local function makeActivity(root)
  local p=newPage(root)
  heading(p,l("Observed market activity index (0-100)","Индекс активности рынка по замерам (0–100)"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Analyze","Анализировать"),272,-83,132,function()p.update()end)
  p.identity=makeItemIdentity(p)
  p.rows={}
  for i=1,9 do p.rows[i]=fs(p,"",20,-181-(i-1)*37,694,i==1) end
  addMetricTooltips(p,p.rows,{
    {"Combined score (0-100) of recent observations (35%), price changes (30%), supply changes (20%), and data quality (15%). It measures observed activity, not trades.",
     "Общий индекс (0–100): число свежих замеров (35%), изменения цены (30%), изменения предложения (20%) и качество данных (15%). Это активность наблюдений, не объём сделок."},
    {"Number of recorded snapshots in the selected activity window (configured in Settings). Multiple scans can occur within the same hour.",
     "Количество записанных замеров за выбранный период активности (задаётся в настройках). Несколько замеров могут приходиться на один час."},
    {"How often the observed price differed from the preceding observation within the analysis window. Does not count sales.",
     "Сколько раз наблюдаемая цена отличалась от предыдущего замера в пределах периода. Не показывает число продаж."},
    {"How often the observed item quantity changed between consecutive observations. Items can disappear due to purchases, expiration, or canceled auctions.",
     "Сколько раз изменилось число предметов между соседними замерами. Лоты могут исчезать из-за покупки, окончания срока или снятия с аукциона."},
    {"Score of data coverage, recency, and observation span. Higher means better historical evidence, not a higher chance of selling.",
     "Оценка полноты, свежести и продолжительности истории. Высокое значение означает более качественные данные, а не больший шанс продажи."},
    {"Last recorded Auctionator market price. It may already be outdated if the auction was not scanned recently.",
     "Последняя записанная цена Auctionator. Может устареть, если аукцион давно не сканировали."},
    {"Variation of recorded prices over the observation period. Higher volatility means more unstable observed pricing, not necessarily more demand.",
     "Разброс записанных цен за период наблюдений. Высокая волатильность означает нестабильную цену, но не обязательно высокий спрос."},
    {"Last observed quantity available on the Auction House. This is a snapshot, not a live stock counter.",
     "Последнее известное количество предметов на аукционе. Это сохранённый снимок, а не счётчик в реальном времени."},
    {"Market activity is estimated only from local Auctionator observations. It is not verified traded volume or a prediction.",
     "Активность оценивается только по локальным наблюдениям Auctionator. Это не подтверждённый объём продаж и не прогноз."},
  },694)
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    if not key then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("Select an item.","Выберите предмет."))
      return
    end
    local data=A.ProActivity(key)
    local m=data.metrics
    local lines={
      l("Market activity score","Индекс активности")..": "..data.score.." / 100",
      l("Recent observations","Недавние замеры")..": "..data.observations,
      l("Price movements","Изменения цены")..": "..data.priceChanges,
      l("Supply movements","Изменения предложения")..": "..data.quantityChanges,
      l("Reliability","Надёжность")..": "..data.quality.score.." / 100",
      l("Latest market price","Последняя цена")..": "..currency(m.currentPrice),
      l("Volatility","Волатильность")..": "..A.FmtVolatility(m.volatility),
      l("On market","На рынке")..": "..A.FmtCount(m.currentQuantity),
      l("Index describes observed changes, not verified trade volume.",
        "Индекс показывает изменения в замерах, а не реальные продажи."),
    }
    for i=1,#p.rows do p.rows[i]:SetText(lines[i]) end
  end
  return p
end

local function makeJournal(root)
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

local function makeCraft(root)
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
    "Выберите рецепт, чтобы увидеть ресурсы и их стоимость."),66,-124,630,true)
  p.productMade=fs(p,"",66,-147,630)
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
    {l("MATERIAL","МАТЕРИАЛ"),84,205},
    {l("QTY","КОЛ-ВО"),299,58},
    {l("IN STOCK","В НАЛИЧИИ"),350,96},
    {l("EACH","ЗА ШТ."),445,110},
    {l("TOTAL","СТОИМОСТЬ"),559,148},
  }
  for i=1,#columns do
    local c=columns[i]
    local head=fs(p,c[1],c[2],-188,c[3],true)
    head:SetTextColor(1,.82,.36)
  end

  local PAGE_SIZE=6
  local active, page = nil,1
  local drawReport -- row click handlers need this forward declaration
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
    local title=fs(p,"",84,y-7,202)
    local qty=fs(p,"",301,y-7,55)
    local owned=fs(p,"",360,y-7,76)
    local unit=fs(p,"",445,y-7,108)
    local total=fs(p,"",560,y-7,142)
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
    local row={background=bgrow,icon=icon,title=title,qty=qty,owned=owned,unit=unit,
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
  p.pageLabel=fs(p,"",295,-442,190)
  p.summary1=fs(p,"",22,-472,680,true)
  p.summary2=fs(p,"",22,-495,680)
  p.summary3=fs(p,"",22,-518,680)
  p.info=fs(p,"",22,-540,690)
  p.status=fs(p,l("Search saved recipes or open a profession and scan its recipes.",
    "Найдите сохранённый рецепт или откройте профессию и просканируйте её рецепты."),20,-106,680)
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
      row.owned:Hide();row.unit:Hide();row.total:Hide();row.hotspot:Hide();row.include:Hide()
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
    p.productMade:SetText(l("Produced: ","Результат: ")..made.." "..
      l("unit(s) per craft","шт. за изготовление"))
    local list=active.materials or {}
    local pages=math.max(1,math.ceil(#list/PAGE_SIZE))
    page=math.max(1,math.min(page,pages))
    p.pageLabel:SetText(l("Materials ","Материалы ")..#list.."   "..
      l("Page ","Страница ")..page.."/"..pages)
    local report=A.EvaluateRecipeWithInventory and A.EvaluateRecipeWithInventory(active)
    local rows=report and report.rows or {}
    for index=1,#list do
      local mat=list[index]
      if index>(page-1)*PAGE_SIZE and index<=page*PAGE_SIZE then
        local row=p.materialRows[index-(page-1)*PAGE_SIZE]
        local result=rows[index]
        local itemName,itemTexture=displayName(mat.id,mat.name,mat.icon)
        row.icon:SetTexture(itemTexture or mat.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.title:SetText(A.FitItemName and A.FitItemName(itemName,row.title,200) or itemName)
        row.qty:SetText(tostring(mat.qty or 1))
        if report and report.inventoryEnabled then
          local total=result and result.stock or 0
          row.owned:SetText(tostring(total))
          row.owned:SetTextColor(.48,.86,.62)
        else
          row.owned:SetText("-")
          row.owned:SetTextColor(.54,.59,.64)
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
        row.owned:Show();row.unit:Show();row.total:Show();row.hotspot:Show();row.include:Show()
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
    p.summary3:SetText(l("Market-basis profit: ","Прибыль по рыночной стоимости: ")..
      formatValue(baseline)..(report and report.inventoryEnabled and
      ("   "..l("Profit with owned stock: ","Прибыль с собственными: ")..formatValue(cashProfit)) or ""))
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
  button(p,l("Refresh data","Обновить данные"),550,-434,158,function()
    if A.RefreshCraftStock then A.RefreshCraftStock() end
    drawReport()
  end)
  p.update=function() if active then drawReport() end end
  drawReport()
  return p
end

-- Cursor and visual guides for Technical Indicators 2.0.
-- Values are displayed at the nearest genuine observation; there is no
-- fabricated value for a missing time bucket.
local function attachIndicatorCursor(plot,kind)
  plot:EnableMouse(true)
  local cursor=plot:CreateTexture(nil,"OVERLAY")
  cursor:SetTexture("Interface\\Buttons\\WHITE8X8")
  cursor:SetVertexColor(.82,.87,.97,.62)
  cursor:SetWidth(1)
  cursor:SetHeight(plot:GetHeight())
  cursor:Hide()
  plot.cursor=cursor
  plot.hoverValues={}
  local function updateHover(self)
    local points=self.hoverValues
    if not points or #points==0 or
       type(GetCursorPosition)~="function" or
       type(self.GetLeft)~="function" then return end
    local left=self:GetLeft()
    if type(left)~="number" then return end
    local scale=self.GetEffectiveScale and self:GetEffectiveScale() or 1
    if type(scale)~="number" or scale<=0 then scale=1 end
    local screenX=GetCursorPosition()
    if not screenX then return end
    local x=screenX/scale-left
    if x<0 or x>self:GetWidth() then
      cursor:Hide()
      if GameTooltip then GameTooltip:Hide() end
      self.lastHover=nil
      return
    end
    local nearest=nil
    local best=math.huge
    for i=1,#points do
      local pt=points[i]
      local distance=math.abs(pt.x-x)
      if distance<best then best=distance;nearest=pt end
    end
    if not nearest then return end
    cursor:ClearAllPoints()
    cursor:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",nearest.x,0)
    cursor:Show()
    if self.lastHover==nearest then return end
    self.lastHover=nearest
    local v=nearest.data
    local timestamp=date("%d.%m %H:%M",v.t)
    local title=(kind=="rsi" and "RSI" or "MACD").." | "..timestamp
    local explanation
    if kind=="rsi" then
      explanation=(v.rsi and string.format("%.1f / 100",v.rsi) or "-")
      if v.rsiPreliminary then explanation=explanation..l(" (preliminary)"," (предварительно)") end
    else
      explanation=string.format("MACD: %.2f    Signal: %.2f    Histogram: %.2f",
        v.macd or 0,v.signal or 0,v.hist or 0)
      if v.macdPreliminary then explanation=explanation..l(" (warming up)"," (период накопления)") end
    end
    showHelp(self,title,explanation..l("; from observed price buckets only.",
      "; только по реальным интервалам наблюдений."))
  end
  plot:SetScript("OnEnter",function(self)
    self.lastHover=nil
    self:SetScript("OnUpdate",updateHover)
    updateHover(self)
  end)
  plot:SetScript("OnLeave",function(self)
    self:SetScript("OnUpdate",nil)
    self.lastHover=nil
    cursor:Hide()
    if GameTooltip then GameTooltip:Hide() end
  end)
  function plot:setHoverValues(points)
    self.hoverValues=points or {}
    self.lastHover=nil
    cursor:Hide()
    if GameTooltip and type(GameTooltip.IsOwned)=="function" and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end
end

local function makeIndicators(root)
  local p=newPage(root)
  heading(p,l("Technical indicators 2.0 - observed time buckets",
    "Технические индикаторы 2.0 - реальные интервалы наблюдений"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Calculate","Рассчитать"),272,-83,132,function()p.update()end)
  p.identity=makeItemIdentity(p)
  p.rows={}
  for i=1,10 do p.rows[i]=fs(p,"",20,-183-(i-1)*35,326,i==1) end
  fs(p,"RSI",375,-163,305,true)
  fs(p,"MACD",375,-354,305,true)
  p.rsiPlot=newPlot(p,368,-185,338,156)
  p.macdPlot=newPlot(p,368,-376,338,155)
  local rsiUpper=fs(p.rsiPlot,"70",6,-41,32)
  rsiUpper:SetTextColor(.85,.48,.50)
  local rsiMid=fs(p.rsiPlot,"50",6,-74,32)
  rsiMid:SetTextColor(.57,.65,.74)
  local rsiLower=fs(p.rsiPlot,"30",6,-104,32)
  rsiLower:SetTextColor(.43,.83,.60)
  attachIndicatorCursor(p.rsiPlot,"rsi")
  attachIndicatorCursor(p.macdPlot,"macd")
  p.rsiStatus=fs(p.rsiPlot,"",20,-67,298)
  p.rsiStatus:SetJustifyH("CENTER")
  p.macdStatus=fs(p.macdPlot,"",20,-67,298)
  p.macdStatus:SetJustifyH("CENTER")
  p.details=fs(p,"",20,-535,695)
  p.details:SetTextColor(.70,.82,.87)
  local glossary={
    {"EMA","Экспоненциальная средняя: больше вес последних наблюдаемых цен, по одному значению на интервал."},
    {"RSI","Индекс 0-100 по росту/падению цены. 70/30 - ориентиры, не торговые сигналы. До полного периода значение предварительное."},
    {"MACD","Разность EMA(12) и EMA(26) по временным интервалам. На первых интервалах индикатор ещё прогревается."},
    {"MACD Histogram","MACD минус сигнальная EMA(9). Положительные и отрицательные значения показывают изменение импульса цены."},
    {"Bollinger Bands","Средняя цена и полосы +/-2 стандартных отклонения по указанному числу наблюдаемых интервалов."},
  }
  local glossaryEN={
    "Exponential moving average with extra weight on recent observed bucket-closing prices.",
    "Strength index 0-100 from observed price changes. 70/30 are guides, not trading signals; partial history produces preliminary values.",
    "EMA(12) minus EMA(26) from observed time buckets. Early values are in warm-up.",
    "MACD minus its EMA(9) signal. Positive or negative bars show observed price momentum changes.",
    "Observed moving average plus/minus two standard deviations. Missing prices are not invented."
  }
  for i=2,8 do
    local term=i==2 and 1 or (i==3 and 2 or (i==4 and 3 or (i==5 and 4 or 5)))
    local overlay=CreateFrame("Frame",nil,p)
    overlay:SetSize(310,28)
    overlay:SetPoint("TOPLEFT",p,"TOPLEFT",18,-183-(i-1)*35+3)
    overlay:EnableMouse(true)
    attachHelp(overlay,glossary[term][1],l(glossaryEN[term],glossary[term][2]))
  end
  local function clearPlots()
    p.rsiPlot:clear();p.macdPlot:clear()
    p.rsiPlot:setHoverValues(nil);p.macdPlot:setHoverValues(nil)
    p.rsiStatus:SetText("");p.macdStatus:SetText("")
  end
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    clearPlots()
    if not key then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("Select an item.","Выберите предмет."))
      p.details:SetText("")
      return
    end
    local ind=A.ProIndicators(A.ProSamples(key))
    local v=ind.latest
    if not v then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("No observations.","Нет наблюдений."))
      p.details:SetText("")
      return
    end
    local cfg=A.db.pro
    local disabled=l("off","выкл.")
    local missing=l("not enough data","недостаточно данных")
    local rsiStatus
    if cfg.showRSI then
      if v.rsi then
        rsiStatus=string.format("%.1f",v.rsi)
        if v.rsiPreliminary then rsiStatus=rsiStatus..l(" (prelim.)"," (предв.)") end
      else rsiStatus=missing end
    else rsiStatus=disabled end
    local macdText=cfg.showMACD and labelNumber(v.macd) or disabled
    local statusNote=l("Based on real observations.","По реальным наблюдениям.")
    if cfg.showRSI and v.rsiPreliminary then
      statusNote=l("RSI: preliminary (","RSI: предварительный (")..
        tostring(v.rsiChanges or 0).."/"..tostring(cfg.rsiPeriod)..")"
    elseif cfg.showRSI and v.rsi==nil then
      statusNote=l("RSI: need 4+ time buckets","RSI: нужно от 4 интервалов")
    end
    local text={
      l("Samples: ","Замеров: ")..ind.count..l("   Buckets: ","   Интервалов: ")..ind.bucketCount,
      "EMA("..cfg.emaPeriod.."): "..(cfg.showEMA and currency(v.ema) or disabled),
      "RSI("..cfg.rsiPeriod.."): "..rsiStatus,
      "MACD: "..macdText..(cfg.showMACD and v.signalPreliminary and " *" or ""),
      l("MACD histogram: ","Гистограмма MACD: ")..(cfg.showMACD and labelNumber(v.hist) or disabled),
      l("Bollinger upper: ","Боллинджер, верх: ")..(cfg.showBollinger and (v.upper and currency(v.upper) or missing) or disabled),
      l("Bollinger middle: ","Боллинджер, середина: ")..(cfg.showBollinger and (v.bollMiddle and currency(v.bollMiddle) or missing) or disabled),
      l("Bollinger lower: ","Боллинджер, низ: ")..(cfg.showBollinger and (v.lower and currency(v.lower) or missing) or disabled),
      l("Segments: ","Участков: ")..ind.segments..l("   Last: ","   Последний: ")..v.segmentCount,
      statusNote,
    }
    for i=1,#p.rows do p.rows[i]:SetText(text[i] or "") end
    p.details:SetText(string.format(l("Bucket: %d min    Reset gap: %d h    * MACD signal warm-up until 34+ buckets.",
       "Интервал: %d мин    Пропуск: %d ч    * Сигнал MACD прогрев до 34+ интервалов."),
       ind.bucketMinutes,ind.gapHours))
    local rPlot,mPlot=p.rsiPlot,p.macdPlot
    local points=ind.values
    local n=#points
    if n==0 then return end
    local first=math.max(1,n-100)
    local tMin=points[first].t
    local timeSpan=math.max(1,points[n].t-tMin)
    local function x(point) return (point.t-tMin)/timeSpan*338 end
    if cfg.showRSI then
      for _,threshold in ipairs({30,50,70}) do
        local r,g,b=.32,.39,.49
        if threshold==70 then r,g,b=.70,.32,.34
        elseif threshold==30 then r,g,b=.28,.61,.43 end
        rPlot:rect(0,threshold/100*156,338,1,r,g,b,.83)
      end
    end
    if cfg.showMACD then mPlot:rect(0,77,338,1,.38,.45,.53,.86) end
    local macdRange=.1
    for i=first,n do
      local pt=points[i]
      macdRange=math.max(macdRange,math.abs(pt.macd or 0),math.abs(pt.signal or 0),math.abs(pt.hist or 0))
    end
    -- Draw the histogram behind MACD and signal lines.
    if cfg.showMACD then
      for i=first,n do
        local pt=points[i]
        local xx=x(pt)
        local val=(pt.hist or 0)/macdRange*65
        if val>=0 then mPlot:rect(xx-2,77,4,math.max(1,val),.31,.68,.48,.62)
        else mPlot:rect(xx-2,77+val,4,math.max(1,-val),.85,.39,.36,.62) end
      end
    end
    local previousRSI,previousMACD,previousSignal
    local rData,mData={},{}
    for i=first,n do
      local pt=points[i]
      local xx=x(pt)
      local prev=points[i-1]
      -- Never draw a continuous line through an unobserved interval.
      local canJoin=prev and pt.segment==prev.segment and pt.slot-prev.slot<=2
      if cfg.showRSI and pt.rsi then
        local yy=pt.rsi/100*156
        if previousRSI and canJoin then miniLine(rPlot,previousRSI.x,previousRSI.y,xx,yy,.33,.89,.91) end
        rPlot:rect(xx-1.5,yy-1.5,3,3,.32,.9,1)
        previousRSI={x=xx,y=yy}
        rData[#rData+1]={x=xx,data=pt}
      else previousRSI=nil end
      if cfg.showMACD then
        local yy=77+(pt.macd or 0)/macdRange*67
        local sy=77+(pt.signal or 0)/macdRange*67
        if previousMACD and canJoin then miniLine(mPlot,previousMACD.x,previousMACD.y,xx,yy,.42,.9,.55) end
        if previousSignal and canJoin then miniLine(mPlot,previousSignal.x,previousSignal.y,xx,sy,1,.72,.22) end
        previousMACD={x=xx,y=yy};previousSignal={x=xx,y=sy}
        mData[#mData+1]={x=xx,data=pt}
      end
    end
    rPlot:setHoverValues(rData);mPlot:setHoverValues(mData)
    if cfg.showRSI then
      if #rData==0 then
        p.rsiStatus:SetText(l("RSI: insufficient distinct time buckets",
          "RSI: недостаточно временных интервалов"))
      elseif v.rsiPreliminary then
        p.rsiStatus:SetText(l("Preliminary RSI", "Предварительный RSI"))
      end
    else p.rsiStatus:SetText(l("RSI disabled in settings", "RSI отключён в настройках")) end
    if cfg.showMACD and v.signalPreliminary then
      p.macdStatus:SetText(l("MACD: warm-up (not a full signal)",
        "MACD: период накопления, не полный сигнал"))
    elseif not cfg.showMACD then
      p.macdStatus:SetText(l("MACD disabled in settings", "MACD отключён в настройках"))
    end
  end
  p:HookScript("OnHide",function()
    p.rsiPlot:SetScript("OnUpdate",nil)
    p.macdPlot:SetScript("OnUpdate",nil)
    p.rsiPlot.cursor:Hide();p.macdPlot.cursor:Hide()
    if GameTooltip then GameTooltip:Hide() end
  end)
  return p
end

local function makeHeatmap(root)
  local p=newPage(root)
  heading(p,l("Observed average prices by weekday / hour","Средние наблюдаемые цены по дням и часам"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Update","Обновить"),272,-83,132,function()p.update()end)
  local weekdays={"Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
  local weekdaysRU={"Пн","Вт","Ср","Чт","Пт","Сб","Вс"}
  p.identity=makeItemIdentity(p)
  p.cells={}
  for h=0,23 do fs(p,tostring(h),80+h*25,-168,24) end
  for day=1,7 do
    fs(p,A.locale=="ruRU" and weekdaysRU[day] or weekdays[day],20,-205-(day-1)*42,50)
    p.cells[day]={}
    for h=0,23 do
      local b=CreateFrame("Button",nil,p)
      b:SetSize(21,31);b:SetPoint("TOPLEFT",p,"TOPLEFT",79+h*25,-199-(day-1)*42)
      local bg=b:CreateTexture(nil,"BACKGROUND")
      bg:SetTexture("Interface\\Buttons\\WHITE8X8");bg:SetAllPoints(b)
      b.bg=bg
      b:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        local c=self.cell
        GameTooltip:SetText((A.locale=="ruRU" and weekdaysRU[day] or weekdays[day]).." "..h..":00")
        GameTooltip:AddLine(l("Observations: ","Замеров: ")..tostring(c and c.count or 0),1,1,1)
        if c and c.count>0 then GameTooltip:AddLine(l("Average: ","Средняя: ")..currency(c.sum/c.count),1,.82,.30) end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
      p.cells[day][h]=b
    end
  end
  p.hint=fs(p,l("Empty cells mean no scans. Color is relative to observed prices only.",
    "Пустая клетка — не было сканов. Цвет относительно наблюдаемых цен."),24,-515,690)
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    local map=key and A.ProHeatmap(A.ProSamples(key),A.db.pro.heatmapDays) or nil
    local lo,hi
    if map then
      for d=1,7 do for h=0,23 do
        local c=map[d][h]
        if c.count>0 then local avg=c.sum/c.count;lo=math.min(lo or avg,avg);hi=math.max(hi or avg,avg) end
      end end
    end
    for d=1,7 do for h=0,23 do
      local b=p.cells[d][h];local c=map and map[d][h]
      b.cell=c
      if c and c.count>0 then
        local n=(c.sum/c.count-(lo or 0))/math.max(1,(hi or 0)-(lo or 0))
        b.bg:SetVertexColor(.12+n*.72,.67-n*.47,.26,.95)
      else b.bg:SetVertexColor(.12,.17,.24,.68) end
    end end
  end
  return p
end

local function makeQuality(root)
  local p=newPage(root)
  heading(p,l("Data reliability and scan coverage","Надёжность данных и покрытие сканированием"),-12)
  p.selection=marketInput(p,20,-60,216)
  button(p,l("Analyze","Анализировать"),272,-83,132,function()p.update()end)
  p.identity=makeItemIdentity(p)
  p.rows={}
  for i=1,13 do p.rows[i]=fs(p,"",20,-181-(i-1)*27,694,i==1) end
  addMetricTooltips(p,p.rows,{
    {"Overall data reliability score from 0 to 100. Combines distinct observed hours, history span, recency, and time-window coverage. This is not a sale probability.",
     "Общая оценка качества данных от 0 до 100. Учитывает часы с замерами, длительность истории, свежесть и покрытие временных интервалов. Это не вероятность продажи."},
    {"Total number of valid stored price observations for this item across its available history. Repeated observations in one hour are counted individually.",
     "Общее число сохранённых замеров с действительной ценой за всю доступную историю предмета. Несколько замеров в один час считаются отдельно."},
    {"Number of different clock hours containing at least one price observation. Ten measurements in the same hour count as one observed hour.",
     "Количество разных часов, в которых есть хотя бы один замер цены. Десять замеров за один час считаются одним часом с наблюдениями."},
    {"Time elapsed since the latest recorded valid price, in hours. Smaller means a fresher quote, but prices can change between scans.",
     "Сколько часов прошло после последней записанной цены. Чем меньше значение, тем свежее данные, но между сканированиями цена могла измениться."},
    {"Elapsed time from the first to the last stored price observation, in hours. A long span does not mean there were scans throughout the entire period.",
     "Время между первым и последним замером цены в часах. Большой период не означает, что наблюдения велись непрерывно."},
    {"Longest time gap between two consecutive price observations, in hours. Market changes during this gap are unknown.",
     "Самый длительный перерыв между соседними замерами цены, в часах. Изменения рынка внутри этого перерыва неизвестны."},
    {"Share of time buckets containing a real observation within the recent coverage window (up to seven days). Depending on the window, buckets represent 1 or 6 hours. Missing intervals stay unknown.",
     "Доля временных интервалов с реальными замерами за недавний период (до семи дней). Интервалы могут составлять 1 или 6 часов. Пустые интервалы остаются неизвестными."},
    {"Number of price observations attributed to Auctionator scans within the recent coverage window. Older records may not contain source information.",
     "Число замеров, записанных после сканирования Auctionator, за недавний период покрытия. У старых записей источник может быть неизвестен."},
    {"Number of price observations attributed to item tooltip checks within the recent coverage window. These are not independent Auction House sales.",
     "Число замеров, полученных при наведении на предмет, за недавний период. Это не отдельные продажи на аукционе."},
    {"Observations whose origin was not stored or cannot be identified. Typically older historical records; they are still price observations.",
     "Замеры без сохранённого или распознанного источника. Обычно это старая история; такие записи всё равно содержат наблюдения цены."},
    {"Qualitative classification of the score: high at 75 or above, medium from 45 to 74, and low below 45.",
     "Словесная оценка индекса: высокое качество от 75, среднее от 45 до 74, низкое ниже 45."},
    {"More observations spread over several hours and days generally provide stronger evidence than many scans made in a short burst.",
     "Замеры за разные часы и дни обычно информативнее, чем много сканирований за короткое время."},
    {"The quality score describes coverage and recency of your local data. It cannot tell whether an item will sell, or how quickly.",
     "Оценка качества описывает полноту и свежесть локальной истории. Она не показывает, продастся ли предмет и как быстро."},
  },694)
  p.update=function()
    local key=selectedKey(p)
    p.identity:showItem(key)
    if not key then
      for i=1,#p.rows do p.rows[i]:SetText("") end
      p.rows[1]:SetText(l("Choose a scanned item.","Выберите отсканированный предмет."))
      return
    end
    local q=A.ProQuality(A.ProSamples(key))
    local lines={
      l("Data quality: ","Качество данных: ")..q.score.." / 100",
      l("Total observations","Всего замеров")..": "..q.count,
      l("Independent hour buckets","Часов с замерами")..": "..q.uniqueHours,
      l("Age of newest price (hours)","Возраст последней цены (ч)")..": "..labelNumber(q.age),
      l("Observed history span (hours)","Период наблюдений (ч)")..": "..labelNumber(q.coverage),
      l("Largest gap (hours)","Самый большой пропуск (ч)")..": "..labelNumber(q.maxGap),
      l("Time-window coverage","Покрытие временных окон")..": "..string.format("%.1f%%",q.coveragePercent or 0)..
        " ("..tostring(q.coverageBucketHours or 1)..l("h buckets)","ч интервалы)"),
      l("Scan observations (period)","Замеры сканера (период)")..": "..tostring(q.scanObservations or 0),
      l("Tooltip observations (period)","Замеры подсказок (период)")..": "..tostring(q.hoverObservations or 0),
      l("Older/unknown-source observations","Старые замеры без типа источника")..": "..tostring(q.unknownObservations or 0),
      l("Quality","Качество")..": "..(q.label=="high" and l("High","Высокое") or
        (q.label=="medium" and l("Medium","Среднее") or l("Low","Низкое"))),
      l("Use higher observation counts and multiple days for stronger signals.",
        "Надёжнее выводы при большем числе сканов и наблюдений за разные дни."),
      l("This score measures data coverage, not trade success probability.",
        "Оценка отражает покрытие, а не вероятность успешной сделки."),
    }
    for i=1,#p.rows do p.rows[i]:SetText(lines[i] or "") end
  end
  return p
end

local function makeCraftScanner(root)
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

local helpContent={
 scanner={"Find quotes below their observed median. Opportunity Score combines discount, data quality, freshness, volatility, quantity and evidence. Risk Score measures uncertainty, not sale probability. Configure filters under Market Scanner 2.0.","Поиск цен ниже исторической медианы. Рейтинг учитывает скидку, качество, свежесть, волатильность и количество. Риск оценивает неопределённость, не вероятность продажи. Фильтры — в настройках Сканера 2.0."},
 alerts={"Choose a condition: price threshold, deviation from median, price change, supply reduction, volatility or Opportunity Score. Signals only evaluate new Auctionator scans. Price and supply changes are not confirmed trades.","Выберите условие: цена, отклонение от медианы, изменение цены, сокращение предложения, волатильность или Opportunity Score. Сигналы проверяются при новых сканах Auctionator. Это не подтверждённые сделки."},
 candles={"OHLC candles summarize observed prices by time buckets. Empty time slots have no observations; candles are not recorded market trades.","Свечи OHLC объединяют наблюдаемые цены по времени. Пробелы означают отсутствие замеров, а не отсутствие сделок."},
 activity={"The activity index is an estimate based on changes in observed quotes and supply; it is not actual sales volume.","Индекс активности оценивает изменения наблюдаемых цен и предложения, а не реальный объём продаж."},
 journal={"Enter actual purchases and sales manually. Only matched buy and sell lots contribute to realized profit.","Вносите фактические покупки и продажи вручную. Реальная прибыль считается по сопоставленным сделкам."},
 craft={"Pick a recipe to view materials. Every material has a checkbox (included by default). Optional bag/bank tracking reduces additional purchases, but owned resources still have market value. Bank counts are saved from its last opening.",
"Выберите рецепт и смотрите ресурсы. У каждого галочка (по умолчанию включена). Дополнительный учёт сумок/банка уменьшает расходы на докупку, но свои ресурсы имеют рыночную стоимость. Банк учитывается по последнему открытию."},
 indicators={"Indicators use actual observed time buckets. Missing buckets are never filled. Short histories produce explicitly marked preliminary values, not reliable signals.","Индикаторы используют реальные интервалы наблюдений. Пустые часы не заполняются. При короткой истории значения предварительные, а не надёжные сигналы."},
 heatmap={"View observed average prices by day and hour. Blank cells mean no scans were captured in that time slot.","Средняя наблюдаемая цена по дням и часам. Пустые клетки означают отсутствие сканирований."},
 quality={"Assess data recency, coverage and gaps. A high score means better observed history, not higher chances of sale.","Оценка свежести, продолжительности и пропусков истории. Высокий балл — полнота данных, не шанс продажи."},
 craftscan={"Browse ALL imported recipes: profit, loss and missing prices. Sort priced recipes by expected profit or ROI; incomplete ones stay visible with No data. Import each profession separately.",
"Каталог ВСЕХ импортированных рецептов: прибыль, убыток и отсутствие цен. Рассчитанные сортируются по прибыли или ROI, неполные остаются видимыми. Каждую профессию импортируйте отдельно."},
}
local function toolHelpPanel(page,key)
  local holder=CreateFrame("Frame",nil,page)
  holder:SetSize(194,438);holder:SetPoint("TOPRIGHT",page,"TOPRIGHT",-5,-18)
  -- Help occupies the same continuous surface as the active tool.
  tex(holder,0,0,1,438,.40,.31,.18,.48)
  tex(holder,11,0,183,1,.58,.41,.16,.75)
  fs(holder,l("HOW IT WORKS","КАК ЭТО РАБОТАЕТ"),11,-17,174,true)
  local message=helpContent[key] or {"Local market data only.","Только локальные данные рынка."}
  local detail=fs(holder,l(message[1],message[2]),11,-55,174)
  if detail.SetWordWrap then detail:SetWordWrap(true) end
  if key=="indicators" then
    fs(holder,l("EMA: weighted average of recent quotes.",
      "EMA: средняя с большим весом свежих цен."),11,-147,174)
    fs(holder,l("RSI: 0–100 momentum scale.",
      "RSI: индекс импульса 0–100."),11,-192,174)
    fs(holder,l("MACD: difference of two EMAs.",
      "MACD: разница двух EMA."),11,-232,174)
    fs(holder,l("Bollinger: price volatility bands.",
      "Боллинджер: границы разброса цены."),11,-273,174)
  end
  local tip=(key=="activity" or key=="quality") and
    l("Tip: hover over a result row for an explanation.",
      "Совет: наведите на строку результата для пояснения.") or
    l("Tip: hover over any input field for an explanation.",
      "Совет: наведите на поле ввода для пояснения.")
  fs(holder,tip,11,key=="indicators" and -340 or -255,174)
  fs(holder,l("Auctionator cannot report confirmed sales made by other players.",
              "Auctionator не сообщает о подтверждённых продажах других игроков."),11,key=="indicators" and -403 or -335,174)
  page.helpPanel=holder
end

local builders={scanner=makeScanner,alerts=makeAlerts,candles=makeCandles,
  activity=makeActivity,journal=makeJournal,craft=makeCraft,indicators=makeIndicators,
  heatmap=makeHeatmap,quality=makeQuality,craftscan=makeCraftScanner}
local function create()
  if A.proWindow then return A.proWindow end
  local f=CreateFrame("Frame","ATSTradeScopePro",UIParent)
  f:SetSize(WIDTH,HEIGHT);f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG");f:SetFrameLevel(245)
  f:SetMovable(true);f:EnableMouse(true)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  if f.SetBackdrop then
    f:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
      edgeSize=30,insets={left=12,right=12,top=12,bottom=12}})
  end
  -- Same single, tracked background as the market terminal. Avoid a second
  -- opaque backdrop below it or slider percentages would be misleading.
  local mainSurface=tex(f,15,-15,WIDTH-30,HEIGHT-30,.042,.064,.086,1)
  if A.TrackBackgroundTexture then A.TrackBackgroundTexture("pro",mainSurface) end
  tex(f,21,-70,WIDTH-42,1,.38,.29,.15,.54)
  tex(f,21,-159,WIDTH-42,2,.46,.34,.14,.9)
  tex(f,22,-736,WIDTH-44,1,.43,.33,.16,.75)
  local logo=f:CreateTexture(nil,"ARTWORK")
  logo:SetTexture("Interface\\AddOns\\AuctionatorTradeScope\\Media\\Icon")
  logo:SetSize(31,31);logo:SetPoint("TOPLEFT",f,"TOPLEFT",23,-22)
  f.title=fs(f,"TradeScope | "..l("Trading Workstation","Торговый терминал").."  v"..tostring(A.version or "?"),63,-28,715,true)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-8)
  f.nav={}
  f.content=CreateFrame("Frame",nil,f)
  f.content:SetSize(947,558);f.content:SetPoint("TOPLEFT",f,"TOPLEFT",22,-166)
  local icons={
    scanner="Interface\\Icons\\INV_Misc_Spyglass_03",alerts="Interface\\Icons\\INV_Misc_Bell_01",
    candles="Interface\\Icons\\INV_Misc_Coin_02",activity="Interface\\Icons\\Ability_Hunter_MasterMarksman",
    journal="Interface\\Icons\\INV_Misc_Book_09",craft="Interface\\Icons\\INV_Misc_Gear_02",
    indicators="Interface\\Icons\\Spell_Holy_MindVision",heatmap="Interface\\Icons\\INV_Misc_Map_01",
    quality="Interface\\Icons\\INV_Misc_EngGizmos_02",craftscan="Interface\\Icons\\INV_Misc_Coin_17",
  }
  for i=1,#TOOLS do
    local id=TOOLS[i]
    local col=(i-1)%5;local row=math.floor((i-1)/5)
    local b=button(f,tr(id),25+col*190,-81-row*38,178,function()A.ShowProTab(id)end,31)
    if A.StyleButton then A.StyleButton(b,"tab") end
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetTexture(icons[id]);icon:SetSize(21,21)
    icon:SetPoint("LEFT",b,"LEFT",5,0)
    local title=b:GetFontString()
    if title then
      title:ClearAllPoints();title:SetPoint("LEFT",b,"LEFT",32,0)
      title:SetWidth(141);title:SetJustifyH("LEFT")
    end
    local focus=b:CreateTexture(nil,"BACKGROUND")
    focus:SetTexture("Interface\\Buttons\\WHITE8X8")
    focus:SetAllPoints(b);focus:SetVertexColor(.42,.31,.085,.42);focus:Hide()
    b.activeBackground=focus
    attachHelp(b,tr(id),l(helpContent[id][1],helpContent[id][2]))
    f.nav[id]=b
  end
  f.footer=fs(f,l("Only locally observed Auctionator data. Supply reductions are not verified sales.",
    "Только локальные данные Auctionator. Уменьшение предложения не означает продажи."),29,-745,900)
  f.footer:SetTextColor(.70,.76,.81)
  f.pages={}
  f.drag=CreateFrame("Frame",nil,f)
  f.drag:SetSize(855,44);f.drag:SetPoint("TOPLEFT",f,"TOPLEFT",17,-15)
  f.drag:EnableMouse(true);f.drag:RegisterForDrag("LeftButton")
  f.drag:SetScript("OnDragStart",function() f:StartMoving() end)
  f.drag:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
  f:SetScript("OnHide",function(self)
    local activePage=self.pages and self.pages[self.active]
    if activePage and activePage.proMarketEdit and activePage.proMarketEdit.HasFocus and
       activePage.proMarketEdit:HasFocus() then
      shareMarketChoice(activePage.proMarketEdit)
      activePage.proMarketEdit:ClearFocus()
    end
    -- Popups are children of this window, not of the active tab. Without an
    -- explicit hide they can reappear with an old query upon reopening Pro.
    for _,page in pairs(self.pages or {}) do
      for _,popup in ipairs(page.marketPopups or {}) do popup:Hide() end
      if page.conditionMenu then page.conditionMenu:Hide() end
      if page.sortMenu then page.sortMenu:Hide() end
    end
    if A.HideCraftPreview then A.HideCraftPreview() end
    if self.restoreDashboard and A.dashboard then
      self.restoreDashboard=false
      A.dashboard:Show()
      if A.RefreshDashboard then A.RefreshDashboard() end
    end
  end)
  f:Hide()
  A.proWindow=f
  return f
end
function A.ShowProTab(id)
  A.Init()
  local f=create()
  if not builders[id] then id="scanner" end
  -- Commit a name typed directly into another tab before its input loses
  -- visibility. This also works on clients that do not raise focus-lost when
  -- their parent frame becomes hidden.
  local oldPage=f.pages[f.active]
  if oldPage and oldPage.proMarketEdit and oldPage.proMarketEdit.HasFocus and
     oldPage.proMarketEdit:HasFocus() then
    shareMarketChoice(oldPage.proMarketEdit)
    oldPage.proMarketEdit:ClearFocus()
  end
  for key,page in pairs(f.pages) do page:Hide() end
  local p=f.pages[id]
  if not p then
    p=builders[id](f)
    f.pages[id]=p
    toolHelpPanel(p,id)
  end
  f.active=id
  if p.proMarketEdit then
    local choice=sharedMarketChoice()
    if choice then fillMarketEdit(p.proMarketEdit,choice) end
  end
  for _,popup in ipairs(p.marketPopups or {}) do popup:Hide() end
  p:Show()
  if not p.disabledOverlay then
    local overlay=CreateFrame("Frame",nil,p)
    overlay:SetAllPoints(p)
    overlay:SetFrameLevel(p:GetFrameLevel()+30)
    overlay:EnableMouse(true)
    tex(overlay,0,0,946,557,.025,.035,.055,.98)
    fs(overlay,l("This tool is disabled in settings.","Инструмент отключён в настройках."),
      65,-200,610,true)
    button(overlay,l("Open settings","Открыть настройки"),65,-257,185,
      function()A.OpenOptions()end)
    overlay:Hide()
    p.disabledOverlay=overlay
  end
  local disabled=A.db.pro[id.."Enabled"]==false
  if disabled then p.disabledOverlay:Show()
  else
    p.disabledOverlay:Hide()
    if p.update then
      local ok,err=pcall(p.update)
      if not ok then A.lastError=tostring(err);A.Say(err) end
    end
  end
  for key,buttonFrame in pairs(f.nav) do
    local chosen=key==id
    if buttonFrame.activeBackground then buttonFrame.activeBackground:Hide() end
    if A.StyleButton then A.StyleButton(buttonFrame,chosen and "activeTab" or "tab") end
  end
end
function A.OpenProTool(id)
  A.Init()
  local f=create()
  local sx=(UIParent:GetWidth()-22)/WIDTH
  local sy=(UIParent:GetHeight()-22)/HEIGHT
  f:SetScale(math.max(.55,math.min(1,sx,sy)))
  -- Never place the Pro workstation directly over the old terminal.
  if A.dashboard and A.dashboard.IsShown and A.dashboard:IsShown() then
    f.restoreDashboard=true
    A.dashboard:Hide()
  end
  f:Show()
  A.ShowProTab(id or "scanner")
end
-- Open alert configuration for the exact item selected in the market terminal.
function A.OpenProAlertForItem(key)
  A.OpenProTool("alerts")
  local f=A.proWindow
  local p=f and f.pages and f.pages.alerts
  if key and p and p.selection then
    p.selectedRule=nil
    p.selection._applying=true
    p.selection.itemKey=key
    p.selection:SetText(A.ProItemName(key))
    p.selection._applying=false
    if p.selection.searchPopup then p.selection.searchPopup:Hide() end
    shareMarketChoice(p.selection,key)
  end
end
function A.ToggleProTool(id)
  if A.proWindow and A.proWindow:IsShown() and A.proWindow.active==id then
    A.proWindow:Hide()
  else A.OpenProTool(id) end
end
