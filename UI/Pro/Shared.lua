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


-- Local module-private helpers exposed only to the Pro workstation pages.
A.ProUIShared = {
  WIDTH=WIDTH,
  HEIGHT=HEIGHT,
  TOOLS=TOOLS,
  names=names,
  l=l,
  tr=tr,
  tex=tex,
  fs=fs,
  button=button,
  helpText=helpText,
  showHelp=showHelp,
  attachHelp=attachHelp,
  addMetricTooltips=addMetricTooltips,
  asExactItem=asExactItem,
  itemKey=itemKey,
  sharedMarketChoice=sharedMarketChoice,
  fillMarketEdit=fillMarketEdit,
  shareMarketChoice=shareMarketChoice,
  attachItemSearch=attachItemSearch,
  edit=edit,
  marketInput=marketInput,
  itemID=itemID,
  heading=heading,
  pbutton=pbutton,
  currency=currency,
  asItem=asItem,
  selectedKey=selectedKey,
  anyItem=anyItem,
  inspect=inspect,
  newPage=newPage,
  lineList=lineList,
  captureRow=captureRow,
  labelNumber=labelNumber,
  makeItemIdentity=makeItemIdentity,
  normalizeRussian=normalizeRussian,
  newPlot=newPlot,
  miniLine=miniLine,
  attachIndicatorCursor=attachIndicatorCursor,
}
A.ProUIBuilders = {}
