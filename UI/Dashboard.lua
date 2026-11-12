-- TradeScope 3.0 - Blizzard-styled market terminal and direct bag item selection.
local A=ATS
local WIDTH,HEIGHT=944,638

local function fs(parent,w,font)
  local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  f:SetWidth(w);f:SetJustifyH("LEFT");return f
end
local function button(parent,caption,w,h,action)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w or 95,h or 24);b:SetText(caption)
  if action then b:SetScript("OnClick",action) end
  if A.StyleButton then A.StyleButton(b) end
  return b
end
local function shade(parent,x,y,w,h,color)
  local t=parent:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(color[1],color[2],color[3],color[4] or 1)
  t:SetSize(w,h);t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  return t
end
local function iconOf(link,key)
  local _, icon = A.ResolveItemInfo(link or key)
  return icon
end
local function niceName(key,link,fallback)
  local name = A.ResolveItemInfo(link or key, fallback)
  return name
end
local function displayName(name)
  if type(name)=="string" and string.match(name,"^#%d+$") then
    return (A.locale=="ruRU" and "Неизвестный предмет (" or "Unknown item (")..name..")"
  end
  return name
end
local function watchTable(create)
  A.Init()
  local realm=A.RealmKey()
  local watches=A.db.watchlist[realm]
  if not watches and create then watches={};A.db.watchlist[realm]=watches end
  return watches
end
function A.AddWatch(key,legacy,link)
  if not key then return end
  local watches=watchTable(true)
  local name, icon, _, savedLink = A.ResolveItemInfo(link or key)
  watches[key]={key=key,legacy=legacy,link=savedLink or link,name=name,icon=icon}
  A.RememberItem(savedLink or link or key,name,icon)
  if A.dashboard and A.dashboard:IsShown() then A.RefreshDashboard() end
end
function A.RemoveWatch(key)
  local watches=watchTable(false)
  if watches then watches[key]=nil end
  if A.dashboard and A.dashboard:IsShown() then A.RefreshDashboard() end
end
local function parseItem(raw)
  if type(raw) ~= "string" then return nil end
  local known=A.FindKnownItems(raw,8)
  if not A.LegacyKey(raw) and not string.match(raw,"^%s*%d+%s*$") then
    local match
    for i=1,#known do
      if A.CleanItemName(known[i].name)==A.CleanItemName(raw) then match=known[i]; break end
    end
    if match then raw=match.link or ("item:"..match.id) end
  end
  local id = tonumber(string.match(raw, "^%s*(%d+)%s*$"))
  local legacy = A.LegacyKey(raw)
  if not id and legacy then id = tonumber(string.match(legacy, "item:(%d+)")) end
  if not id then return nil end
  legacy = legacy or ("item:" .. id)
  -- Preserve the clickable hyperlink, including [localized item name].
  -- The Auctionator DB key still uses the normalized legacy item data.
  local displayLink = string.find(raw, "|Hitem:", 1, true) and raw or legacy
  A.ResolveItemInfo(displayLink)
  return A.Key(displayLink) or ("db:" .. id), legacy, displayLink
end
local function signalColor(sig)
  if sig=="below" then return 0.38,0.93,0.52 end
  if sig=="above" then return 1,0.68,0.31 end
  return 0.80,0.85,0.92
end

function A.SelectItem(raw)
  local key,legacy,link=parseItem(raw)
  if not key then return false end
  local f=A.dashboard
  if not f then A.ToggleDashboard();f=A.dashboard end
  local changed = f.key ~= key
  f.key,f.legacy,f.link = key,legacy,link
  if changed and f.graph then f.graph.zoomHours = nil end
  local name, icon, _, savedLink = A.ResolveItemInfo(link)
  if savedLink then f.link=savedLink end
  -- Search input is independent of the selected item card.
  f.query.silent=true
  f.query:SetText("")
  f.query.silent=false
  if f.suggestions then f.suggestions:Hide() end
  f.itemLabel:SetText(A.FitItemName(displayName(name),f.itemLabel,548))
  f.selectedIcon:SetTexture(icon)
  -- Drop target is an empty, reusable area, never a second selected-item card.
  if f.dropCaption then f.dropCaption:SetText(A.L.DROP_ITEM) end
  if f:IsShown() then A.RefreshDashboard() end
  return true
end
function A.TryPickBagTooltip(tip,link)
  if not A.bagPicking or not A.dashboard or not A.LegacyKey(link) then return false end
  local selected=link
  if type(GetContainerItemLink)=="function" then
    local owner=tip and tip.GetOwner and tip:GetOwner()
    if owner and owner.GetID and owner.GetParent then
      local bag=owner:GetParent()
      if bag and bag.GetID then
        local ok,bagLink=pcall(GetContainerItemLink,bag:GetID(),owner:GetID())
        if ok and type(bagLink)=="string" and A.LegacyKey(bagLink) then selected=bagLink end
      end
    end
  end
  -- Fallback supports custom bag UIs (e.g. Baganator), where bag/slot IDs
  -- are not exposed by the tooltip owner. Selection is explicitly armed.
  A.RememberTooltipItem(tip, selected)
  A.bagPicking=false
  A.SelectItem(selected)
  if A.dashboard and A.dashboard.pickButton then
    A.dashboard.pickButton:SetText(A.L.PICK_FROM_BAG)
    A.dashboard.pickHelp:SetText(A.L.PICK_HINT)
  end
  return true
end

local function cursorItem()
  if type(GetCursorInfo)~="function" then return nil end
  local kind,id,link=GetCursorInfo()
  if kind~="item" then return nil end
  if type(link)=="string" and A.LegacyKey(link) then return link end
  if type(id)=="number" then
    if type(GetItemInfo)=="function" then
      local _,itemLink=GetItemInfo(id)
      if type(itemLink)=="string" then return itemLink end
    end
    return "item:"..id
  end
end
local function create()
  if A.dashboard then return A.dashboard end
  local f=CreateFrame("Frame","ATSTradeScopeTerminal",UIParent)
  f:SetSize(WIDTH,HEIGHT);f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG");f:SetFrameLevel(220)
  f:SetMovable(true);f:EnableMouse(true)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  -- WoW dialog art and neutral gold borders, rather than an opaque blank canvas.
  if f.SetBackdrop then
    -- Decorative border only. A single tracked surface controls transparency,
    -- avoiding accumulated opacity from the backdrop and child background cards.
    f:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
      edgeSize=32,insets={left=11,right=11,top=12,bottom=11}})
  end
  f.isTradeScopeTerminal=true
  local mainSurface=shade(f,10,-10,WIDTH-20,HEIGHT-20,{.042,.064,.086,1})
  if A.TrackBackgroundTexture then A.TrackBackgroundTexture("terminal",mainSurface) end
  -- Match the Pro workstation: one continuous panel, fine gold separators.
  shade(f,15,-69,WIDTH-30,1,{.38,.29,.15,.62})
  shade(f,251,-69,1,HEIGHT-112,{.50,.37,.15,.62})
  shade(f,15,-HEIGHT+43,WIDTH-30,1,{.43,.33,.16,.65})
  local logo=f:CreateTexture(nil,"ARTWORK")
  logo:SetTexture("Interface\\AddOns\\AuctionatorTradeScope\\Media\\Icon")
  logo:SetSize(31,31);logo:SetPoint("TOPLEFT",f,"TOPLEFT",22,-20)
  f.heading=fs(f,780,"GameFontNormalLarge")
  f.heading:SetPoint("TOPLEFT",f,"TOPLEFT",62,-27)
  f.heading:SetText(A.L.TERMINAL)
  f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-7)
  f.balanceButton=button(f,A.L.WALLET_OPEN_BUTTON,126,24,function() A.ToggleBalanceWindow() end)
  f.balanceButton:SetPoint("TOPRIGHT",f,"TOPRIGHT",-46,-23)
  f.toolsToggle=button(f,A.L.TOOLS_BUTTON,131,24,function()
    f.showTools=not f.showTools
    A.RefreshDashboard()
  end)
  -- The chart/trader-tools switch belongs to the bottom content action area,
  -- not the persistent top navigation.  The tools pane ends 42 px above the
  -- window bottom, so this 22-px control stays clear of both the graph and it.
  f.toolsToggle:SetSize(131,22)
  f.toolsToggle:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,19)
  f.proButton=button(f,"TradeScope Pro",118,24,function()
    if A.OpenProTool then A.OpenProTool("scanner") end
  end)
  f.proButton:SetPoint("TOPRIGHT",f.balanceButton,"TOPLEFT",-8,0)
  f.alertButton=button(f,A.locale=="ruRU" and "Сигналы" or "Alerts",85,24,function()
    if A.OpenProAlertForItem then A.OpenProAlertForItem(f.key) end
  end)
  f.alertButton:SetPoint("TOPRIGHT",f.proButton,"TOPLEFT",-8,0)
  local title=fs(f,210,"GameFontNormal")
  title:SetPoint("TOPLEFT",f,"TOPLEFT",25,-87);title:SetText(A.L.SELECT_ITEM_TITLE)
  local searchLabel=fs(f,208)
  searchLabel:SetPoint("TOPLEFT",f,"TOPLEFT",25,-112);searchLabel:SetText(A.L.SEARCH)
  f.query=CreateFrame("EditBox","ATSTradeScopeQuery",f,"InputBoxTemplate")
  f.query:SetSize(207,24);f.query:SetPoint("TOPLEFT",f,"TOPLEFT",25,-134)
  f.query:SetMaxLetters(255);f.query:SetAutoFocus(false)
  local function queryAction()
    local raw=f.query:GetText()
    if not A.SelectItem(raw) then
      -- Enter selects the top autocomplete result for a partial item name.
      local first=f.suggestionMatches and f.suggestionMatches[(f.suggestionOffset or 0)+1]
      if first then A.SelectItem(first.link or ("item:"..first.id))
      else A.Say(A.L.SELECT_ITEM) end
    end
    f.query:ClearFocus()
  end
  f.query:SetScript("OnEnterPressed",queryAction)
  -- Search all locally identifiable Auctionator items, not only watched items.
  -- The popup is opaque: item icons underneath must never bleed through it.
  local suggestions=CreateFrame("Frame",nil,f)
  suggestions:SetSize(207,130)
  suggestions:SetPoint("TOPLEFT",f.query,"BOTTOMLEFT",0,-2)
  suggestions:SetFrameStrata("FULLSCREEN_DIALOG")
  suggestions:SetFrameLevel(f:GetFrameLevel()+45)
  suggestions:EnableMouse(true)
  suggestions:EnableMouseWheel(true)
  local popupBg=suggestions:CreateTexture(nil,"BACKGROUND")
  popupBg:SetTexture("Interface\\Buttons\\WHITE8X8")
  popupBg:SetVertexColor(.045,.06,.075,.99)
  popupBg:SetAllPoints(suggestions)
  if suggestions.SetBackdrop then
    suggestions:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=11,
      insets={left=3,right=3,top=3,bottom=3}})
  end
  suggestions.rows={}
  for i=1,7 do
    local b=CreateFrame("Button",nil,suggestions)
    b:SetSize(199,24)
    b:SetPoint("TOPLEFT",suggestions,"TOPLEFT",4,-4-(i-1)*24)
    b:EnableMouse(true)
    local highlight=b:CreateTexture(nil,"BACKGROUND")
    highlight:SetAllPoints(b);highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(.25,.24,.14,.5)
    b:SetHighlightTexture(highlight)
    local ico=b:CreateTexture(nil,"ARTWORK")
    ico:SetSize(20,20);ico:SetPoint("LEFT",b,"LEFT",3,0)
    local name=fs(b,164,"GameFontHighlightSmall")
    name:SetPoint("LEFT",b,"LEFT",26,0)
    b.icon=ico;b.label=name
    b:SetScript("OnClick",function(self)
      local match=self.match
      suggestions:Hide()
      if match then A.SelectItem(match.link or ("item:"..match.id)) end
      f.query:ClearFocus()
    end)
    b:SetScript("OnEnter",function(self) self.label:SetTextColor(1,.83,.23) end)
    b:SetScript("OnLeave",function(self) self.label:SetTextColor(1,1,1) end)
    suggestions.rows[i]=b
  end
  suggestions.footer=fs(suggestions,195,"GameFontDisableSmall")
  suggestions.footer:SetPoint("BOTTOMLEFT",suggestions,"BOTTOMLEFT",5,5)
  suggestions:Hide()
  f.suggestions=suggestions
  f.suggestionOffset=0
  f.suggestionMatches={}

  local function paintSuggestions()
    local matches=f.suggestionMatches
    if #matches==0 then
      for i=1,7 do suggestions.rows[i]:Hide() end
      if A.itemIndexRunning then
        suggestions:SetHeight(35)
        suggestions.footer:SetText(A.L.SEARCH_INDEXING or "Indexing...")
        suggestions:Show()
      else suggestions:Hide() end
      return
    end
    local visible=math.min(7,#matches)
    suggestions:SetHeight(8+visible*24+19)
    local offset=math.max(0,math.min(f.suggestionOffset,#matches-visible))
    f.suggestionOffset=offset
    for i=1,7 do
      local row=suggestions.rows[i]
      local match=matches[offset+i]
      row.match=match
      if match then
        row.icon:SetTexture(match.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.label:SetText(A.FitItemName(match.name,row.label,158))
        row:Show()
      else row:Hide() end
    end
    local caption=string.format("%d-%d / %d",offset+1,offset+visible,#matches)
    if A.itemIndexRunning then caption=caption.."  "..(A.L.SEARCH_INDEXING or "Indexing...") end
    suggestions.footer:SetText(caption)
    suggestions:Show()
  end
  suggestions:SetScript("OnMouseWheel",function(_,delta)
    f.suggestionOffset=f.suggestionOffset-(delta or 0)*3
    paintSuggestions()
  end)
  local function refreshSuggestions(self,byUser)
    if self.silent then return end
    local value=self:GetText() or ""
    -- The selected item is kept separately, not automatically pasted here.
    if value=="" or string.find(value,"item:",1,true) or string.find(value,"|H",1,true) then
      suggestions:Hide();f.suggestionMatches={};return
    end
    if byUser~=true then f.suggestionOffset=0 end
    if A.StartItemNameIndex then A.StartItemNameIndex() end
    f.suggestionMatches=A.FindKnownItems(value,500)
    paintSuggestions()
  end
  f.query:SetScript("OnTextChanged",refreshSuggestions)
  f.refreshSuggestions=refreshSuggestions
  f.query:SetScript("OnEscapePressed",function(self) suggestions:Hide();self:ClearFocus() end)
  f.query:SetScript("OnEditFocusLost",function()
    if not (suggestions.IsMouseOver and suggestions:IsMouseOver()) then suggestions:Hide() end
  end)
  local drop=CreateFrame("Button","ATSTradeScopeDrop",f)
  drop:SetPoint("TOPLEFT",f,"TOPLEFT",25,-172)
  drop:SetSize(207,66);drop:EnableMouse(true)
  local dropTex=drop:CreateTexture(nil,"BACKGROUND")
  dropTex:SetTexture("Interface\\Buttons\\WHITE8X8")
  dropTex:SetVertexColor(0.13,0.20,0.20,0.82);dropTex:SetAllPoints(drop)
  local dropIcon=drop:CreateTexture(nil,"ARTWORK")
  dropIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
  dropIcon:SetSize(33,33);dropIcon:SetPoint("LEFT",drop,"LEFT",9,0)
  f.dropCaption=fs(drop,154,"GameFontNormalSmall")
  f.dropCaption:SetPoint("LEFT",drop,"LEFT",47,0)
  f.dropCaption:SetText(A.L.DROP_ITEM)
  local function dropAction()
    local link=cursorItem()
    if link and A.SelectItem(link) then
      -- Select a bag item without adding an invisible watch entry.
      f.dropCaption:SetText(A.L.DROP_ITEM)
      if type(ClearCursor)=="function" then ClearCursor() end
    end
  end
  drop:SetScript("OnReceiveDrag",dropAction)
  drop:SetScript("OnMouseUp",dropAction)
  f.query:SetScript("OnReceiveDrag",dropAction)
  drop:SetScript("OnEnter",function(self)
    dropTex:SetVertexColor(0.22,0.38,0.35,0.94)
    if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(A.L.DROP_ITEM_TIP);GameTooltip:Show() end
  end)
  drop:SetScript("OnLeave",function() dropTex:SetVertexColor(0.13,0.20,0.20,0.82);if GameTooltip then GameTooltip:Hide() end end)
  f.pickButton=button(f,A.L.PICK_FROM_BAG,207,26,function(self)
    A.bagPicking=not A.bagPicking
    self:SetText(A.bagPicking and A.L.CANCEL_PICK or A.L.PICK_FROM_BAG)
    f.pickHelp:SetText(A.bagPicking and A.L.PICK_ACTIVE or A.L.PICK_HINT)
    if A.bagPicking and type(OpenAllBags)=="function" then pcall(OpenAllBags,true) end
  end)
  f.pickButton:SetPoint("TOPLEFT",f,"TOPLEFT",25,-246)
  f.pickHelp=fs(f,206)
  f.pickHelp:SetPoint("TOPLEFT",f,"TOPLEFT",25,-283)
  f.pickHelp:SetText(A.L.PICK_HINT)
  -- The old watchlist and its paging arrows are no longer visible. Keep the
  -- saved watch data and /ats add API for backwards compatibility.
  shade(f,23,-325,211,151,{.055,.075,.095,.68})
  shade(f,23,-325,211,1,{.47,.36,.18,.68})
  local guideTitle=fs(f,202,"GameFontNormal")
  guideTitle:SetPoint("TOPLEFT",f,"TOPLEFT",30,-335)
  guideTitle:SetText(A.locale=="ruRU" and "ПОИСК ПРЕДМЕТА" or "ITEM SEARCH")
  guideTitle:SetTextColor(.98,.82,.42)
  local guide=fs(f,192,"GameFontHighlightSmall")
  guide:SetPoint("TOPLEFT",f,"TOPLEFT",30,-365)
  guide:SetText(A.locale=="ruRU" and
    "Введите название или ID выше.\n\nВыберите подсказку из списка либо перетащите предмет из сумки.\n\nДля прокрутки результатов используйте колесо мыши." or
    "Search by name or item ID above.\n\nChoose a result from suggestions or drop an item from your bags.\n\nUse the mouse wheel to scroll search results.")
  guide:SetTextColor(.77,.82,.83)
  f.selectedIcon=f:CreateTexture(nil,"ARTWORK")
  f.selectedIcon:SetSize(40,40);f.selectedIcon:SetPoint("TOPLEFT",f,"TOPLEFT",267,-83)
  f.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  f.itemLabel=fs(f,560,"GameFontNormalLarge")
  f.itemLabel:SetPoint("TOPLEFT",f,"TOPLEFT",316,-91)
  f.itemLabel:SetText(A.L.DASHBOARD_NO_ITEM)
  local metricsBase=124
  f.metrics={}
  for i=1,3 do
    local text=fs(f,633,"GameFontHighlightSmall")
    text:SetPoint("TOPLEFT",f,"TOPLEFT",267,-metricsBase-(i-1)*21)
    f.metrics[i]=text
  end
  f.signal=fs(f,630,"GameFontHighlightSmall")
  f.signal:SetPoint("TOPLEFT",f,"TOPLEFT",267,-188)
  f.graphTabs={}
  local tabs={{"combined",A.L.TABS_COMBINED},{"price",A.L.TABS_PRICE},{"market",A.L.TABS_MARKET},{"sales",A.L.TABS_SALES}}
  for i=1,#tabs do
    local mode=tabs[i][1]
    local b=button(f,tabs[i][2],110,24,function()
      f.selectedGraph=mode;f.showTools=false;A.RefreshDashboard()
    end)
    b:SetPoint("TOPLEFT",f,"TOPLEFT",267+(i-1)*117,-211)
    f.graphTabs[i]=b
  end
  f.zoomIn=button(f,"+",34,24,function() A.ZoomGraph(f.graph,1) end)
  f.zoomIn:SetPoint("TOPLEFT",f,"TOPLEFT",741,-211)
  f.zoomOut=button(f,"-",34,24,function() A.ZoomGraph(f.graph,-1) end)
  f.zoomOut:SetPoint("LEFT",f.zoomIn,"RIGHT",3,0)
  f.zoomReset=button(f,A.L.ZOOM_RESET,87,24,function() A.ZoomGraph(f.graph,0,true) end)
  f.zoomReset:SetPoint("LEFT",f.zoomOut,"RIGHT",3,0)
  f.selectedGraph="combined"
  f.graph=A.NewGraph(f)
  -- One fixed plot viewport in the terminal for combined, price, quantity
  -- and supply-decline modes. Tooltip graphs retain their original heights.
  f.graph.terminalChartHeight=246
  f.graph:SetPoint("TOPLEFT",f,"TOPLEFT",261,-245)
  f.graph:SetFrameStrata("DIALOG")
  f.graph:SetFrameLevel(f:GetFrameLevel()+5)
  f.graph:SetScale(0.98)
  f.graph.allowWheel=true
  f.tradePanel=A.NewTradePanel(f)
  f.showTools=false
  -- Reserve the right side of the bottom strip for the mode switch.
  -- Keep the footnote on its own, non-overlapping side of that strip.
  f.footer=fs(f,507)
  f.footer:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",267,23)
  f.footer:SetText(A.L.FOOTNOTE)
  f.footer:SetTextColor(.78,.71,.50)
  local drag=CreateFrame("Frame",nil,f)
  drag:SetSize(840,45);drag:SetPoint("TOPLEFT",f,"TOPLEFT",20,-12)
  drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
  drag:SetScript("OnDragStart",function() f:StartMoving() end)
  drag:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
  f:Hide();A.dashboard=f
  return f
end
function A.RefreshDashboard()
  local f=create()
  for i=1,#f.graphTabs do
    local chosen=f.selectedGraph==({"combined","price","market","sales"})[i]
    if A.StyleButton then A.StyleButton(f.graphTabs[i],chosen and "activeTab" or "tab") end
  end
  if not f.key then
    for i=1,#f.metrics do f.metrics[i]:SetText("") end
    f.signal:SetText(A.L.PICK_HINT)
    f.graph:Hide()
    f.tradePanel:Hide()
    if A.db.showTradeTools then f.toolsToggle:Show() else f.toolsToggle:Hide() end
    return
  end
  local name, icon, _, resolvedLink = A.ResolveItemInfo(f.link or f.key)
  if resolvedLink then f.link=resolvedLink end
  f.itemLabel:SetText(A.FitItemName(displayName(name),f.itemLabel,545))
  f.selectedIcon:SetTexture(icon)
  f.dropCaption:SetText(A.L.DROP_ITEM)
  local all=A.AllSamples(f.key,f.legacy)
  local hours=f.graph.zoomHours or A.ChartHours(f.key,f.legacy,all)
  local m=A.MarketMetrics(f.key,f.legacy,all,hours)
  f.metrics[1]:SetText(A.L.METRIC_CURRENT .. ": " .. A.Money(m.currentPrice)
    .. "     " .. A.L.METRIC_MEAN .. ": " .. A.Money(m.average)
    .. "     " .. A.L.METRIC_MEDIAN .. ": " .. A.Money(m.median))
  f.metrics[2]:SetText(A.L.METRIC_MIN .. ": " .. A.Money(m.minPrice)
    .. "     " .. A.L.METRIC_MAX .. ": " .. A.Money(m.maxPrice)
    .. "     " .. A.L.METRIC_VOLATILITY .. ": " .. A.FmtVolatility(m.volatility))
  f.metrics[3]:SetText(A.L.METRIC_SUPPLY .. ": " .. A.FmtCount(m.currentQuantity)
    .. "     " .. A.L.METRIC_SUPPLY_CHANGE .. ": " .. A.FmtPercent(m.supplyPct)
    .. "     " .. A.L.METRIC_DECLINES .. ": " .. A.FmtCount(m.estimatedDrops24))
  f.signal:SetText(A.L.METRIC_SIGNAL .. ": " .. A.SignalText(m.signal)
    .. "    " .. A.L.METRIC_SAMPLES .. ": " .. m.observations)
  f.signal:SetTextColor(signalColor(m.signal))
  if A.db.showTradeTools then f.toolsToggle:Show() else f.toolsToggle:Hide() end
  f.toolsToggle:SetText(f.showTools and A.L.TOOLS_BACK or A.L.TOOLS_BUTTON)
  if A.StyleButton then A.StyleButton(f.toolsToggle,f.showTools and "activeTab" or "action") end
  if f.showTools and A.db.showTradeTools then
    f.graph:Hide()
    f.tradePanel:Show()
    A.UpdateTradePanel(f)
  else
    f.showTools=false
    f.tradePanel:Hide()
    A.RenderGraph(f.graph,f.key,f.legacy,f.selectedGraph)
  end
end
local function show()
  local f=create()
  local sx=(UIParent:GetWidth()-25)/WIDTH
  local sy=(UIParent:GetHeight()-25)/HEIGHT
  f:SetScale(math.min(1,math.max(0.58,math.min(sx,sy))))
  f:Show();A.RefreshDashboard()
  if A.StartItemNameIndex then A.StartItemNameIndex() end
  return f
end
function A.ToggleDashboard()
  A.Init()
  local f=create()
  if f:IsShown() then f:Hide();A.bagPicking=false;return end
  local key,legacy,link=A.HoveredItem()
  show()
  if key and link then A.SelectItem(link) end
end
function A.OpenDashboardItem(raw)
  show()
  if not A.SelectItem(raw) then A.Say(A.L.SELECT_ITEM) end
end

-- Preserve the exact scan-history DB key when navigating from Pro scanner.
-- Resolving a bare item ID alone may select a different item variant.
function A.OpenDashboardScanKey(key)
  if type(key)~="string" or not A.ProItemLink then return end
  local link=A.ProItemLink(key)
  if not link then return end
  show()
  if not A.SelectItem(link) then return end
  local frame=A.dashboard
  if frame and key~=frame.key and A.Days(key,false) then
    frame.key=key
    frame.legacy=nil
    if frame.graph then frame.graph.zoomHours=nil end
    A.RefreshDashboard()
  end
  -- Trigger a client item-info query even if the cache is initially empty.
  A.ResolveItemInfo(link)
end

-- Private-server item data may arrive after choosing an item by ID.
-- Update item labels/icons without continuously rebuilding the market graphs.
function A.RefreshItemWidgets()
  local f = A.dashboard
  if not f or not f:IsShown() then return end
  if f.key then
    local name, icon, _, fullLink = A.ResolveItemInfo(f.link or f.key)
    if fullLink then f.link=fullLink end
    -- Item data refresh must never overwrite text being entered in search.
    f.itemLabel:SetText(A.FitItemName(displayName(name),f.itemLabel,545))
    f.selectedIcon:SetTexture(icon)
    f.dropCaption:SetText(A.L.DROP_ITEM)
  end
end
local itemInfoListener = CreateFrame("Frame")
itemInfoListener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
-- RequestLoadItemDataByID may use this separate callback on Forever clients.
pcall(itemInfoListener.RegisterEvent,itemInfoListener,"ITEM_DATA_LOAD_RESULT")
itemInfoListener:SetScript("OnEvent",function(_,_,itemID)
  if A.CacheIndexedItem then A.CacheIndexedItem(itemID) end
  -- Indexing may generate many item-info callbacks; batch GUI refreshes.
  itemInfoListener.needsRefresh=true
end)
itemInfoListener:SetScript("OnUpdate",function(self,dt)
  self.elapsed=(self.elapsed or 0)+dt
  if self.elapsed >= 1.2 then
    self.elapsed=0
    if A.RetryPendingItemInfo then A.RetryPendingItemInfo(6) end
    A.RefreshItemWidgets()
    if A.RefreshProItemLabels then A.RefreshProItemLabels() end
    local f=A.dashboard
    if f and f:IsShown() and f.query and f.query.HasFocus and f.query:HasFocus() and f.refreshSuggestions then
      f.refreshSuggestions(f.query,true)
    end
  end
end)
