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

local helpContent={
 scanner={"Find quotes below their observed median. Opportunity Score combines discount, data quality, freshness, volatility, quantity and evidence. Risk Score measures uncertainty, not sale probability. Configure filters under Market Scanner 2.0.","Поиск цен ниже исторической медианы. Рейтинг учитывает скидку, качество, свежесть, волатильность и количество. Риск оценивает неопределённость, не вероятность продажи. Фильтры — в настройках Сканера 2.0."},
 alerts={"Choose a condition: price threshold, deviation from median, price change, supply reduction, volatility or Opportunity Score. Signals only evaluate new Auctionator scans. Price and supply changes are not confirmed trades.","Выберите условие: цена, отклонение от медианы, изменение цены, сокращение предложения, волатильность или Opportunity Score. Сигналы проверяются при новых сканах Auctionator. Это не подтверждённые сделки."},
 candles={"OHLC candles summarize observed prices by time buckets. Empty time slots have no observations; candles are not recorded market trades.","Свечи OHLC объединяют наблюдаемые цены по времени. Пробелы означают отсутствие замеров, а не отсутствие сделок."},
 activity={"The activity index is an estimate based on changes in observed quotes and supply; it is not actual sales volume.","Индекс активности оценивает изменения наблюдаемых цен и предложения, а не реальный объём продаж."},
 journal={"Record purchases and sales manually. Filter by selected item, BUY/SELL and last 7/30/90 days. Hover a sale to view matched cost, fees, P&L and ROI. Unmatched sale units are excluded from realized profit.","Вносите покупки и продажи вручную. Фильтры: выбранный предмет, ПОКУПКА/ПРОДАЖА, последние 7/30/90 дней. Наведите на продажу для себестоимости, комиссий, прибыли и ROI. Продажи без закупки не включаются в прибыль."},
 portfolio={"Open positions come only from manual Trading Journal buys minus matched sells for this character. Values use the last observed Auctionator price no older than seven days; missing or stale quotes are excluded. Unrealized P&L estimates net proceeds after the configured auction fee; it does not represent confirmed sales.",
"Открытые позиции — только ручные покупки журнала за вычетом сопоставленных продаж текущего персонажа. Оценки используют последние замеры Auctionator не старше семи дней; пустые и устаревшие цены исключены. Нереализованная прибыль — расчёт после комиссии, не подтверждённая продажа."},
 craft={"Open a profession and click Scan recipes. Then select a saved recipe by name or output item ID. Crafts sets the batch size. Bag/bank tracking reduces additional purchases, but owned materials still have market value. Bank counts are from its last opening.",
"Откройте окно профессии и нажмите «Сканировать рецепты». Затем выберите сохранённый рецепт по названию или ID предмета. «Изготовлений» задаёт размер партии. Учёт сумок и банка уменьшает закупки, но свои ресурсы также имеют рыночную стоимость. Данные банка — с последнего открытия."},
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
  if key=="craft" then
    -- Recipe search and scan feedback are shown only in the right column.
    -- The craft page is built before this panel, so assign its status now.
    page.status=fs(holder,"",11,-265,171)
    page.status:SetTextColor(.72,.77,.82)
    if page.status.SetWordWrap then page.status:SetWordWrap(true) end
    page.helpPanel=holder
    return
  end
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

local builders=B
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
  -- A portfolio shortcut belongs in the header, not a third row that would
  -- overlap the existing tool pages. The original ten tabs are unchanged.
  f.portfolioShortcut=button(f,l("Portfolio","Портфель"),802,-27,136,function()
    A.ShowProTab("portfolio")
  end,27)
  if A.StyleButton then A.StyleButton(f.portfolioShortcut,"tab") end
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
  if f.portfolioShortcut and A.StyleButton then
    A.StyleButton(f.portfolioShortcut,id=="portfolio" and "activeTab" or "tab")
  end
  for key,buttonFrame in pairs(f.nav) do
    local chosen=key==id
    if buttonFrame.activeBackground then buttonFrame.activeBackground:Hide() end
    if A.StyleButton then A.StyleButton(buttonFrame,chosen and "activeTab" or "tab") end
  end
end
function A.OpenPortfolio()
  A.OpenProTool("portfolio")
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
