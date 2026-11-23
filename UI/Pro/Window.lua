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
 terminal={"Choose an item by ID, link, name, bag or watchlist. Compare historical quotes, supply and estimated decline; wheel zooms the chart. Quotes do not confirm sales.",
  "Выберите предмет по ID, ссылке, названию, из сумки или списка наблюдения. Сравнивайте историю цен и предложения; колесо меняет масштаб графика. Наблюдения не подтверждают сделки."},
 balance={"Optional history of your character's observed gold balance. Day, week and month change the period; cursor shows the last known value, not a continuous measured balance.",
  "История наблюдений золота персонажа. День, неделя и месяц меняют период; курсор показывает последнее известное значение, а не непрерывные замеры."},
 scanner={"Find quotes below their observed median. Opportunity Score combines discount, data quality, freshness, volatility, quantity and evidence. Risk Score measures uncertainty, not sale probability. Configure filters under Market Scanner 2.0.","Поиск цен ниже исторической медианы. Рейтинг учитывает скидку, качество, свежесть, волатильность и количество. Риск оценивает неопределённость, не вероятность продажи. Фильтры — в настройках Сканера 2.0."},
 alerts={"Choose a condition: price threshold, deviation from median, price change, supply reduction, volatility or Opportunity Score. Signals only evaluate new Auctionator scans. Price and supply changes are not confirmed trades.","Выберите условие: цена, отклонение от медианы, изменение цены, сокращение предложения, волатильность или Opportunity Score. Сигналы проверяются при новых сканах Auctionator. Это не подтверждённые сделки."},
 candles={"OHLC candles summarize observed prices by time buckets. Empty time slots have no observations; candles are not recorded market trades.","Свечи OHLC объединяют наблюдаемые цены по времени. Пробелы означают отсутствие замеров, а не отсутствие сделок."},
 activity={"Activity on the left is estimated from Auctionator observations; data reliability on the right measures observation age, gaps, source and coverage. Both are estimates, not recorded sales.","Слева — активность по наблюдениям Auctionator, справа — надёжность истории: свежесть, пропуски, источник и покрытие. Ни один показатель не означает подтверждённую продажу."},
 journal={"Enable Auto-mail, then open a mailbox. Completed Auction House invoices are imported when item, amount and quantity are unambiguous. Missing prices, ambiguous items and duplicate-looking mail are skipped. Manual trades, filters, per-sale cost and ROI remain available.","Включите «Почта», затем откройте почтовый ящик. Подтверждённые аукционные счета импортируются при точном определении предмета, суммы и количества. Неполные и похожие письма пропускаются. Ручные сделки, фильтры и прибыль остаются доступны."},
 portfolio={"Portfolio modes: Stock (live bags, last-known bank), Sales (confirmed net revenue), Cost basis (journal lots), Allocation (choose ONE source). Shares use priced values only; large concentration indicates exposure, not predicted loss or profit.",
"Режимы портфеля: Запасы (сумки и последний банк), Продажи (подтверждённая выручка), Себестоимость (журнал), Распределение (выберите ОДИН источник). Доли считаются по оценённым предметам; высокая концентрация — не прогноз убытка или прибыли."},
 strategies={"Three read-only research profiles: value watch requires current verified quotes and quality checks, exit review requires known purchase costs, concentration reviews current bag valuations. Strategy outputs are NOT predictions, purchase instructions or automatically placed orders.",
"Три исследовательских профиля: скидки по проверенным ценам и качеству данных, сценарии выхода только с известной закупкой и концентрация оценённых запасов сумок. Это НЕ прогнозы, торговые приказы или автосделки."},
 craft={"Open a profession and click Scan recipes. Then select a saved recipe by name or output item ID. Crafts sets the batch size. Bag/bank tracking reduces additional purchases, but owned materials still have market value. Bank counts are from its last opening.",
"Откройте окно профессии и нажмите «Сканировать рецепты». Затем выберите сохранённый рецепт по названию или ID предмета. «Изготовлений» задаёт размер партии. Учёт сумок и банка уменьшает закупки, но свои ресурсы также имеют рыночную стоимость. Данные банка — с последнего открытия."},
 indicators={"Indicators use actual observed time buckets. Missing buckets are never filled. Short histories produce explicitly marked preliminary values, not reliable signals.","Индикаторы используют реальные интервалы наблюдений. Пустые часы не заполняются. При короткой истории значения предварительные, а не надёжные сигналы."},
 heatmap={"View observed average prices by day and hour. Blank cells mean no scans were captured in that time slot.","Средняя наблюдаемая цена по дням и часам. Пустые клетки означают отсутствие сканирований."},
 quality={"Assess data recency, coverage and gaps. A high score means better observed history, not higher chances of sale.","Оценка свежести, продолжительности и пропусков истории. Высокий балл — полнота данных, не шанс продажи."},
 craftscan={"Browse ALL imported recipes: profit, loss and missing prices. Sort priced recipes by expected profit or ROI; incomplete ones stay visible with No data. Import each profession separately.",
"Каталог ВСЕХ импортированных рецептов: прибыль, убыток и отсутствие цен. Рассчитанные сортируются по прибыли или ROI, неполные остаются видимыми. Каждую профессию импортируйте отдельно."},
}
-- Permanent HOW IT WORKS sidebars are intentionally retired. Every page uses
-- the same top-right ? tooltip and contextual hover help near its controls.

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
  -- Beta4: all pages share one canvas immediately below the compact header.
  -- The sidebar and content use a common top edge without legacy modal gutters.
  local mainSurface=tex(f,15,-15,WIDTH-30,HEIGHT-30,.042,.064,.086,1)
  if A.TrackBackgroundTexture then A.TrackBackgroundTexture("pro",mainSurface) end
  tex(f,21,-70,WIDTH-42,1,.38,.29,.15,.54)
  tex(f,21,-738,WIDTH-42,1,.43,.33,.16,.75)
  -- The sidebar is navigation, not an additional modal/overlay.
  tex(f,20,-79,181,648,.031,.047,.063,.91)
  tex(f,207,-79,1,647,.35,.30,.20,.61)
  local logo=f:CreateTexture(nil,"ARTWORK")
  logo:SetTexture("Interface\\AddOns\\AuctionatorTradeScope\\Media\\Icon")
  logo:SetSize(31,31);logo:SetPoint("TOPLEFT",f,"TOPLEFT",23,-22)
  f.title=fs(f,"TradeScope",63,-20,250,true)
  -- Page name belongs under the addon name rather than in a second header column.
  f.contextTitle=fs(f,l("Terminal","Терминал"),63,-42,760,true)
  f.versionLabel=fs(f,"v"..tostring(A.version or "?"),895,-31,196)
  f.versionLabel:SetTextColor(.72,.77,.81)
  local function headerHelp(self)
    if not GameTooltip then return end
    local key=f.active or "terminal"
    local message=helpContent[key]
    if not message then return end
    -- Right-edge help must open inward, not off the game screen.
    GameTooltip:SetOwner(self,"ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(tr(key))
    GameTooltip:AddLine(l(message[1],message[2]),1,1,1,true)
    GameTooltip:Show()
  end
  f.helpButton=button(f,"?",WIDTH-85,-25,27,headerHelp,27)
  if A.StyleButton then A.StyleButton(f.helpButton,"secondary") end
  f.helpButton:SetScript("OnEnter",headerHelp)
  f.helpButton:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-8)

  f.nav={}
  f.content=CreateFrame("Frame",nil,f)
  f.content:SetSize(946,660)
  f.content:SetPoint("TOPLEFT",f,"TOPLEFT",219,-74)
  local icons={
    terminal="Interface\\AddOns\\AuctionatorTradeScope\\Media\\Icon",
    balance="Interface\\Icons\\INV_Misc_Coin_01",
    scanner="Interface\\Icons\\INV_Misc_Spyglass_03",
    alerts="Interface\\Icons\\INV_Misc_Bell_01",
    candles="Interface\\Icons\\INV_Misc_Coin_02",
    activity="Interface\\Icons\\Ability_Hunter_MasterMarksman",
    journal="Interface\\Icons\\INV_Misc_Book_09",
    craft="Interface\\Icons\\INV_Misc_Gear_02",
    indicators="Interface\\Icons\\Spell_Holy_MindVision",
    heatmap="Interface\\Icons\\INV_Misc_Map_01",
    quality="Interface\\Icons\\INV_Misc_EngGizmos_02",
    craftscan="Interface\\Icons\\INV_Misc_Coin_17",
    strategies="Interface\\Icons\\INV_Misc_Note_01",
    portfolio="Interface\\Icons\\INV_Misc_Bag_10",
  }
  -- Short, unambiguous labels prevent clipping in the compact sidebar.
  -- The complete localized tool name stays visible in the header and tooltip.
  local shortNames={
    terminal=l("Terminal","Терминал"),balance=l("Gold history","История золота"),
    scanner=l("Scanner","Сканер"),alerts=l("Alerts","Сигналы"),
    candles=l("Candles","Свечи"),activity=l("Activity / quality","Активность / качество"),
    journal=l("Journal","Журнал"),craft=l("Calculator","Калькулятор"),
    indicators=l("Indicators","Индикаторы"),heatmap=l("Heatmap","Тепловая карта"),
    quality=l("Data quality","Качество данных"),craftscan=l("Recipe catalog","Каталог крафта"),
    strategies=l("Strategies","Стратегии"),portfolio=l("Portfolio","Портфель"),
  }
  -- Four groups, 13 destinations. Activity and quality share one two-column tab.
  local groups={
    {label=l("MARKET","РЫНОК"),y=-88,items={"terminal","scanner","alerts","candles","activity"}},
    {label=l("ANALYTICS","АНАЛИТИКА"),y=-285,items={"indicators","heatmap"}},
    {label=l("TRADING","ТОРГОВЛЯ"),y=-387,items={"strategies","portfolio","journal","balance"}},
    {label=l("CRAFTING","КРАФТ"),y=-554,items={"craft","craftscan"}},
  }
  f.navGroups=groups
  for _,group in ipairs(groups) do
    local groupTitle=fs(f,group.label,34,group.y,147,true)
    groupTitle:SetTextColor(.75,.69,.49)
    for j=1,#group.items do
      local id=group.items[j]
      local y=group.y-24-(j-1)*31
      local nav=CreateFrame("Button",nil,f)
      nav:SetSize(163,31);nav:SetPoint("TOPLEFT",f,"TOPLEFT",29,y)
      nav:EnableMouse(true)
      local bg=tex(nav,0,0,163,31,.065,.092,.119,.70)
      local accent=tex(nav,0,0,3,31,.92,.72,.32,1)
      accent:Hide()
      local icon=nav:CreateTexture(nil,"ARTWORK")
      icon:SetTexture(icons[id]);icon:SetSize(17,17)
      icon:SetPoint("LEFT",nav,"LEFT",9,0)
      local label=nav:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
      label:SetPoint("LEFT",nav,"LEFT",32,0)
      label:SetWidth(123);label:SetJustifyH("LEFT")
      label:SetText(shortNames[id] or tr(id))
      nav.bg=bg;nav.sideAccent=accent;nav.titleLabel=label;nav.icon=icon
      nav:SetScript("OnClick",function()A.ShowProTab(id)end)
      nav:SetScript("OnEnter",function(self)
        if f.active~=id then self.bg:SetVertexColor(.115,.147,.170,.92) end
        local message=helpContent[id]
        if message then showHelp(self,tr(id),l(message[1],message[2])) end
      end)
      nav:SetScript("OnLeave",function(self)
        if f.active~=id then self.bg:SetVertexColor(.065,.092,.119,.70) end
        if GameTooltip then GameTooltip:Hide() end
      end)
      f.nav[id]=nav
    end
  end
  f.footer=fs(f,l("Auctionator: observed market data, not confirmed transactions.",
    "Auctionator: наблюдения рынка, а не подтверждённые сделки."),228,-746,927)
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
    -- No legacy restore-on-close: the market terminal is already a page.
    self.restoreDashboard=false
  end)
  f:Hide()
  A.proWindow=f
  return f
end
function A.ShowProTab(id)
  if A.InCombat and A.InCombat() then return end
  A.Init()
  -- Keep /ats quality, old minimap shortcuts and historical links working.
  if id=="quality" then id="activity" end
  local f=create()
  if id~="terminal" and id~="balance" and not builders[id] then id="terminal" end
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
    if id=="terminal" then
      p=newPage(f)
      assert(A.EmbedDashboard,"Market terminal unavailable")(p)
      p.update=function()
        if A.RefreshDashboard then A.RefreshDashboard() end
        if A.StartItemNameIndex then A.StartItemNameIndex() end
      end
      p:HookScript("OnHide",function()
        A.bagPicking=false
        if A.dashboard and A.dashboard.suggestions then A.dashboard.suggestions:Hide() end
      end)
    elseif id=="balance" then
      p=newPage(f)
      assert(A.EmbedBalanceHistory,"Gold history unavailable")(p)
      p.update=function()if A.RefreshBalanceWindow then A.RefreshBalanceWindow() end end
    else
      p=builders[id](f)
    end
    f.pages[id]=p
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
    tex(overlay,0,0,946,660,.025,.035,.055,.98)
    fs(overlay,l("This tool is disabled in settings.","Инструмент отключён в настройках."),
      65,-200,610,true)
    button(overlay,l("Open settings","Открыть настройки"),65,-257,185,
      function()A.OpenOptions()end)
    overlay:Hide()
    p.disabledOverlay=overlay
  end
  -- Old saved activity/quality toggles remain valid; the merged tab is
  -- disabled only when both legacy sections were explicitly disabled.
  local disabled=(id=="activity") and (A.db.pro.activityEnabled==false and
    A.db.pro.qualityEnabled==false) or (id~="activity" and A.db.pro[id.."Enabled"]==false)
  if disabled then p.disabledOverlay:Show()
  else
    p.disabledOverlay:Hide()
    if p.update then
      local ok,err=pcall(p.update)
      if not ok then A.lastError=tostring(err);A.Say(err) end
    end
  end
  if f.contextTitle then f.contextTitle:SetText(tr(id)) end
  for key,nav in pairs(f.nav) do
    local chosen=key==id
    if chosen then
      nav.sideAccent:Show()
      nav.bg:SetVertexColor(.23,.19,.105,.92)
      nav.titleLabel:SetTextColor(1,.85,.56)
    else
      nav.sideAccent:Hide()
      nav.bg:SetVertexColor(.065,.092,.119,.70)
      nav.titleLabel:SetTextColor(.85,.88,.91)
    end
  end
end
function A.OpenStrategies()
  A.OpenProTool("strategies")
end
function A.OpenPortfolio()
  A.OpenProTool("portfolio")
end
function A.OpenProTool(id)
  if A.InCombat and A.InCombat() then return end
  A.Init()
  local f=create()
  local sx=(UIParent:GetWidth()-22)/WIDTH
  local sy=(UIParent:GetHeight()-22)/HEIGHT
  f:SetScale(math.max(.55,math.min(1,sx,sy)))
  f:Show()
  A.ShowProTab(id or "terminal")
end
-- Open alert configuration for the exact item selected in the market terminal.
function A.OpenProAlertForItem(key)
  if A.InCombat and A.InCombat() then return end
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
  if A.InCombat and A.InCombat() then return end
  if A.proWindow and A.proWindow:IsShown() and A.proWindow.active==id then
    A.proWindow:Hide()
  else A.OpenProTool(id) end
end
