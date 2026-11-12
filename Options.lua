-- Built-in AddOn settings: general, chart and analysis panels.
local A=ATS

local function title(parent,text,x,y,width,font)
  local f=parent:CreateFontString(nil,"ARTWORK",font or "GameFontNormal")
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetWidth(width or 555)
  f:SetJustifyH("LEFT")
  f:SetText(text)
  return f
end
local function check(parent,name,caption,x,y,field)
  local b=CreateFrame("CheckButton","ATS"..name,parent,"InterfaceOptionsCheckButtonTemplate")
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local label=_G[b:GetName().."Text"] or b.Text
  if label then label:SetText(caption) end
  b:SetChecked(A.db[field] and true or false)
  b:SetScript("OnClick",function(self)
    A.db[field]=self:GetChecked() and true or false
    if field=="trackBalance" and A.db.trackBalance then A.RecordBalance() end
    if field=="showLegend" or field=="showGrid" or field=="showDots" or field=="showTradeTools" then
      if A.dashboard and A.dashboard:IsShown() then A.RefreshDashboard() end
    end
    if field=="enabled" or field=="showTooltip" then
      if not A.db.enabled or not A.db.showTooltip then A.Hide() end
    end
  end)
  return b,field
end
local function slider(parent,name,label,x,y,minv,maxv,step,field,suffix)
  title(parent,label,x,y,555)
  local b=CreateFrame("Slider","ATS"..name,parent,"OptionsSliderTemplate")
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x+5,y-30)
  b:SetWidth(282)
  b:SetMinMaxValues(minv,maxv)
  if b.SetValueStep then b:SetValueStep(step) end
  if b.SetObeyStepOnDrag then b:SetObeyStepOnDrag(true) end
  local labelText=_G[b:GetName().."Text"]
  local lo=_G[b:GetName().."Low"]
  local hi=_G[b:GetName().."High"]
  if lo then lo:SetText(tostring(minv)) end
  if hi then hi:SetText(tostring(maxv)) end
  b:SetScript("OnValueChanged",function(self,v)
    if type(v)~="number" then return end
    v=math.max(minv,math.min(maxv,math.floor(v/step+0.5)*step))
    A.db[field]=v
    if labelText then labelText:SetText(tostring(v)..(suffix or "")) end
    if (field=="terminalTransparency" or field=="proTransparency" or
      field=="tooltipTransparency") and A.UpdateBackgroundTransparency then
      A.UpdateBackgroundTransparency(field=="terminalTransparency" and "terminal" or
        field=="proTransparency" and "pro" or "tooltip")
    end
  end)
  b:SetValue(A.db[field])
  return b,field
end
local function button(parent,name,x,y,w,callback)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w or 172,25)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(name)
  b:SetScript("OnClick",callback)
  if A.StyleButton then A.StyleButton(b) end
  return b
end
local function panel(name,subtitle)
  local f=CreateFrame("Frame",nil,UIParent)
  f.name=name
  f:SetSize(632,594)
  f:Hide()
  f.controls={}
  title(f,A.L.NAME,17,-12,585,"GameFontNormalLarge")
  title(f,subtitle,17,-41,600)
  return f
end
local function attach(f,control,field)
  f.controls[#f.controls+1]={c=control,field=field}
end
local function refresh(f)
  for i=1,#f.controls do
    local r=f.controls[i]
    if r.c.SetChecked then r.c:SetChecked(A.db[r.field] and true or false)
    elseif r.c.SetValue then r.c:SetValue(A.db[r.field]) end
  end
end
local function addToggle(f,name,text,x,y,field)
  local c,key=check(f,name,text,x,y,field)
  attach(f,c,key)
end
local function addSlider(f,name,text,x,y,lo,hi,step,field,suffix)
  local c,key=slider(f,name,text,x,y,lo,hi,step,field,suffix)
  attach(f,c,key)
end

function A.ShowClearConfirmation()
  if type(StaticPopup_Show)~="function" or type(StaticPopupDialogs)~="table" then
    A.Say(A.L.CLEAR_CONFIRM)
    return
  end
  if not StaticPopupDialogs.ATS_CLEAR then
    StaticPopupDialogs.ATS_CLEAR={
      text=A.L.CLEAR_CONFIRM,button1=YES or "Yes",button2=NO or "No",
      OnAccept=function()
        A.db.realms={}
        if A.InvalidateHistoryCache then A.InvalidateHistoryCache() end
        A.Say(A.L.CLEARED)
      end,
      timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
    }
  end
  StaticPopup_Show("ATS_CLEAR")
end

function A.RegisterOptions()
  A.Init()
  if A.options then return end
  local general=panel(A.L.NAME,A.L.GENERAL_DESC)
  general.name=A.L.NAME
  title(general,A.L.GENERAL,22,-84,480,"GameFontNormalLarge")
  addToggle(general,"Enabled",A.L.ENABLE,22,-109,"enabled")
  addToggle(general,"CollectScan",A.L.COLLECT_SCAN,22,-147,"collectOnScan")
  addToggle(general,"CollectHover",A.L.COLLECT_HOVER,22,-185,"collectOnHover")
  addToggle(general,"ShowTooltip",A.L.SHOW_TOOLTIP,22,-223,"showTooltip")
  addSlider(general,"Delay",A.L.DELAY,45,-278,0,10,0.2,"graphDelay",A.L.SECONDS)
  addSlider(general,"Interval",A.L.INTERVAL,45,-360,30,3600,30,"sampleInterval",A.L.SECONDS)
  addSlider(general,"Retention",A.L.RETENTION,45,-442,1,90,1,"retentionDays",A.L.DAYS)
  button(general,A.L.OPEN_TERMINAL,315,-527,190,function() A.ToggleDashboard() end)
  button(general,A.L.CLEAR,15,-527,186,function() A.ShowClearConfirmation() end)

  local charts=panel(A.L.CHARTS,A.L.CHARTS_DESC)
  charts.parent=general.name
  title(charts,A.L.GRAPH_SELECTION,22,-76,600,"GameFontNormalLarge")
  addToggle(charts,"ShowCombined",A.L.GRAPH_COMBINED,22,-109,"showCombinedChart")
  addToggle(charts,"ShowPrice",A.L.GRAPH_PRICE,22,-148,"showPriceChart")
  addToggle(charts,"ShowMarket",A.L.GRAPH_MARKET,220,-148,"showMarketChart")
  addToggle(charts,"ShowSales",A.L.GRAPH_SALES,420,-148,"showSalesChart")
  addToggle(charts,"CombinedSales",A.L.COMBINED_BARS,22,-188,"combinedSalesBars")
  addToggle(charts,"Grid",A.L.DRAW_GRID,22,-226,"showGrid")
  addToggle(charts,"Dots",A.L.DRAW_DOTS,220,-226,"showDots")
  addToggle(charts,"MA",A.L.DRAW_MA,22,-265,"showMA")
  addToggle(charts,"Trend",A.L.DRAW_TREND,256,-265,"showTrendLine")
  title(charts,A.L.CHART_PERIOD,22,-322,580,"GameFontNormalLarge")
  local modes={
    {"auto",A.L.MODE_AUTO}, {"day",A.L.MODE_DAY}, {"week",A.L.MODE_WEEK},
    {"month",A.L.MODE_MONTH},{"custom",A.L.MODE_CUSTOM},
  }
  charts.modes={}
  local function syncModes()
    for i=1,#modes do charts.modes[i]:SetChecked(A.db.chartMode==modes[i][1]) end
  end
  for i=1,#modes do
    local mode=modes[i][1]
    local c=CreateFrame("CheckButton","ATSMode"..i,charts,"InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT",charts,"TOPLEFT",22+(i-1)*115,-357)
    local t=_G[c:GetName().."Text"] or c.Text
    if t then t:SetText(modes[i][2]) end
    c:SetScript("OnClick",function() A.db.chartMode=mode;syncModes() end)
    charts.modes[i]=c
  end
  title(charts,A.L.CUSTOM_HOURS,22,-398,380)
  local hours=CreateFrame("EditBox","ATSCustomHours",charts,"InputBoxTemplate")
  hours:SetPoint("TOPLEFT",charts,"TOPLEFT",395,-394)
  hours:SetSize(80,22);hours:SetAutoFocus(false)
  if hours.SetNumeric then hours:SetNumeric(true) end
  hours:SetMaxLetters(4)
  local function commit(self)
    local v=tonumber(self:GetText())
    if v and v>=1 and v<=2160 then
      A.db.customHours=math.floor(v)
      A.db.chartMode="custom"
      syncModes()
    end
    self:SetText(tostring(A.db.customHours));self:ClearFocus()
  end
  hours:SetScript("OnEnterPressed",commit)
  hours:SetScript("OnEditFocusLost",function(self) self:SetText(tostring(A.db.customHours)) end)
  charts.hours=hours
  charts:SetScript("OnShow",function(self)
    refresh(self);syncModes();self.hours:SetText(tostring(A.db.customHours))
  end)
  addSlider(charts,"MAWindow",A.L.MA_PERIOD,36,-449,2,20,1,"maWindow","")

  local analysis=panel(A.L.ANALYSIS,A.L.ANALYSIS_DESC)
  analysis.parent=general.name
  title(analysis,A.L.ANALYSIS,22,-85,580,"GameFontNormalLarge")
  addToggle(analysis,"Insights",A.L.SHOW_INSIGHTS,22,-118,"showInsights")
  addToggle(analysis,"Compact",A.L.COMPACT,22,-158,"compactSummary")
  addToggle(analysis,"Volatility",A.L.VOLATILITY,22,-198,"showVolatility")
  addSlider(analysis,"Threshold",A.L.SIGNAL_THRESHOLD,36,-257,1,30,1,"signalThreshold","%")
  addSlider(analysis,"SignalSamples",A.L.SIGNAL_SAMPLES,36,-334,3,20,1,"minSignalSamples","")
  addSlider(analysis,"AutoChanges",A.L.AUTO_CHANGES,36,-414,2,12,1,"autoChanges","")
  addSlider(analysis,"MaxPoints",A.L.PLOT_POINTS,36,-492,60,300,20,"maxPlotPoints","")

  local marketData=panel(A.locale=="ruRU" and "История и качество" or "History & Data Quality",
    A.locale=="ruRU" and
      "Контроль достоверности локальных сканирований Auctionator." or
      "Reliability controls for locally collected Auctionator scans.")
  marketData.parent=general.name
  title(marketData,A.locale=="ruRU" and "Пробелы в рыночных наблюдениях" or
    "Market observation gaps",22,-88,570,"GameFontNormalLarge")
  title(marketData,A.locale=="ruRU" and
    "Если между сканами слишком большой перерыв, уменьшение количества лотов нельзя достоверно оценить." or
    "When scans are too far apart, supply declines cannot be reliably attributed to observed activity.",
    22,-130,570)
  addSlider(marketData,"MaxSupplyGap",
    A.locale=="ruRU" and "Макс. перерыв между сравниваемыми сканами" or
      "Maximum gap between compared scans",35,-208,1,48,1,"maxCompareGapHours",
      A.locale=="ruRU" and " ч" or " h")
  title(marketData,A.locale=="ruRU" and
    "Цены и история не заполняются автоматически в пропущенные часы." or
    "TradeScope never fabricates prices for unobserved hours.",24,-321,560)
  title(marketData,A.locale=="ruRU" and
    "Качество истории показывает полноту замеров, а не вероятность продажи." or
    "Data quality indicates observation coverage, not the probability of sale.",24,-372,560)
  button(marketData,A.locale=="ruRU" and "Проверить данные" or "Inspect data quality",
    25,-463,202,function() if A.OpenProTool then A.OpenProTool("quality") end end)
  marketData:SetScript("OnShow",refresh)

  local appearance=panel(A.L.APPEARANCE,A.L.APPEARANCE_DESC)
  appearance.parent=general.name
  title(appearance,A.L.APPEARANCE,22,-85,570,"GameFontNormalLarge")
  addToggle(appearance,"Legend",A.L.LEGEND_TOGGLE,22,-119,"showLegend")
  title(appearance,A.L.PICK_COLOR,22,-164,520)
  local colorNames={"price","market","sales","ma","trend"}
  local colors={}
  local defaults={price={.20,.86,1},market={.33,.90,.52},sales={1,.66,.24},ma={1,.82,.35},trend={.75,.57,1}}
  local function refreshColors()
    for i=1,#colorNames do
      local name=colorNames[i]
      local rgb=A.db.colors[name]
      if colors[name] and rgb then colors[name].swatch:SetVertexColor(rgb[1],rgb[2],rgb[3],1) end
    end
    if A.dashboard and A.dashboard:IsShown() then A.RefreshDashboard() end
  end
  for i=1,#colorNames do
    local name=colorNames[i]
    local y=-195-(i-1)*53
    local text=title(appearance,A.L["COLOR_"..string.upper(name)],78,y-5,465)
    local btn=CreateFrame("Button",nil,appearance)
    btn:SetSize(38,28);btn:SetPoint("TOPLEFT",appearance,"TOPLEFT",28,y)
    btn:EnableMouse(true)
    local bg=btn:CreateTexture(nil,"BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(.15,.15,.15,1);bg:SetAllPoints(btn)
    local swatch=btn:CreateTexture(nil,"OVERLAY")
    swatch:SetTexture("Interface\\Buttons\\WHITE8X8")
    swatch:SetPoint("TOPLEFT",btn,"TOPLEFT",4,-4)
    swatch:SetPoint("BOTTOMRIGHT",btn,"BOTTOMRIGHT",-4,4)
    colors[name]={button=btn,swatch=swatch}
    btn:SetScript("OnClick",function()
      if not ColorPickerFrame or type(ColorPickerFrame.SetColorRGB)~="function" then return end
      local old=A.db.colors[name]
      local original={old[1],old[2],old[3]}
      ColorPickerFrame.func=function()
        local r,g,b=ColorPickerFrame:GetColorRGB()
        A.db.colors[name]={r,g,b};refreshColors()
      end
      ColorPickerFrame.opacityFunc=nil
      ColorPickerFrame.cancelFunc=function()
        A.db.colors[name]={original[1],original[2],original[3]}
        refreshColors()
      end
      ColorPickerFrame.hasOpacity=false
      ColorPickerFrame.previousValues=original
      ColorPickerFrame:SetColorRGB(original[1],original[2],original[3])
      ColorPickerFrame:Hide();ColorPickerFrame:Show()
    end)
  end
  button(appearance,A.L.COLORS_RESET,28,-484,208,function()
    for key,value in pairs(defaults) do
      A.db.colors[key]={value[1],value[2],value[3]}
    end
    refreshColors()
  end)
  appearance:SetScript("OnShow",function(self) refresh(self);refreshColors() end)

  -- Separate category: each slider changes only background textures, not
  -- windows' child controls or native Blizzard item/comparison tooltips.
  local opacity=panel(A.locale=="ruRU" and "Прозрачность окон" or "Window Transparency",
    A.locale=="ruRU" and "Прозрачность фона, без изменения текста и графиков." or
      "Background transparency without fading texts, buttons or graph lines.")
  opacity.parent=general.name
  title(opacity,A.locale=="ruRU" and "0% — непрозрачно, 100% — прозрачный фон" or
    "0% = opaque, 100% = fully transparent background",22,-94,580,"GameFontNormalLarge")
  addSlider(opacity,"TerminalOpacity",
    A.locale=="ruRU" and "Рыночный терминал" or "Market terminal",38,-151,
    0,100,5,"terminalTransparency","%")
  addSlider(opacity,"ProOpacity",
    A.locale=="ruRU" and "TradeScope Pro" or "TradeScope Pro",38,-260,
    0,100,5,"proTransparency","%")
  addSlider(opacity,"GraphOpacity",
    A.locale=="ruRU" and "Графики в подсказках" or "Tooltip market charts",38,-369,
    0,100,5,"tooltipTransparency","%")
  title(opacity,A.locale=="ruRU" and
    "Подсказки предметов самого WoW не изменяются." or
    "The game's original item and comparison tooltips are unaffected.",30,-486,550)
  opacity:SetScript("OnShow",refresh)

  local wallet=panel(A.L.WALLET,A.L.WALLET_DESC)
  wallet.parent=general.name
  title(wallet,A.L.WALLET,22,-86,540,"GameFontNormalLarge")
  addToggle(wallet,"WalletEnable",A.L.WALLET_ENABLE,22,-127,"trackBalance")
  title(wallet,A.L.WALLET_INFO,34,-186,550)
  button(wallet,A.L.WALLET_OPEN_BUTTON,38,-258,210,function() A.ToggleBalanceWindow() end)
  wallet:SetScript("OnShow",refresh)

  local trading=panel(A.L.TRADING_CATEGORY,A.L.TRADING_DESC)
  trading.parent=general.name
  title(trading,A.L.TRADING_CATEGORY,22,-86,555,"GameFontNormalLarge")
  addToggle(trading,"TradingEnable",A.L.TRADING_ENABLED,22,-126,"showTradeTools")
  addToggle(trading,"TradingAdvice",A.L.TRADING_ADVICE,22,-171,"showTradeAdvice")
  addSlider(trading,"TradeFee",A.L.TRADING_FEE,40,-246,0,15,1,"tradeFee","%")
  addSlider(trading,"TrustSamples",A.L.TRADING_MIN_SAMPLE,40,-331,2,30,1,"tradeMinSamples","")
  title(trading,A.L.TRADING_CAVEAT,30,-441,560)
  trading:SetScript("OnShow",refresh)

  general:SetScript("OnShow",refresh)
  analysis:SetScript("OnShow",refresh)
  A.options={main=general,charts=charts,analysis=analysis,marketData=marketData,
    appearance=appearance,opacity=opacity,wallet=wallet,trading=trading}
  -- Both the modern Settings API and the legacy Interface Options use categories.
  if type(Settings)=="table" and type(Settings.RegisterCanvasLayoutCategory)=="function"
     and type(Settings.RegisterAddOnCategory)=="function" then
    local root=Settings.RegisterCanvasLayoutCategory(general,general.name)
    Settings.RegisterAddOnCategory(root)
    general.category=root
    if type(Settings.RegisterCanvasLayoutSubcategory)=="function" then
      local c1=Settings.RegisterCanvasLayoutSubcategory(root,charts,charts.name)
      local c2=Settings.RegisterCanvasLayoutSubcategory(root,analysis,analysis.name)
      local cData=Settings.RegisterCanvasLayoutSubcategory(root,marketData,marketData.name)
      local c3=Settings.RegisterCanvasLayoutSubcategory(root,appearance,appearance.name)
      local cOpacity=Settings.RegisterCanvasLayoutSubcategory(root,opacity,opacity.name)
      local c4=Settings.RegisterCanvasLayoutSubcategory(root,wallet,wallet.name)
      local c5=Settings.RegisterCanvasLayoutSubcategory(root,trading,trading.name)
      Settings.RegisterAddOnCategory(c1);Settings.RegisterAddOnCategory(c2)
      Settings.RegisterAddOnCategory(cData);Settings.RegisterAddOnCategory(c3)
      Settings.RegisterAddOnCategory(cOpacity)
      Settings.RegisterAddOnCategory(c4);Settings.RegisterAddOnCategory(c5)
    end
  elseif type(InterfaceOptions_AddCategory)=="function" then
    InterfaceOptions_AddCategory(general)
    InterfaceOptions_AddCategory(charts)
    InterfaceOptions_AddCategory(analysis)
    InterfaceOptions_AddCategory(marketData)
    InterfaceOptions_AddCategory(appearance)
    InterfaceOptions_AddCategory(opacity)
    InterfaceOptions_AddCategory(wallet)
    InterfaceOptions_AddCategory(trading)
  else
    A.Say(A.L.OPTIONS_UNAVAILABLE)
  end
  if type(A.AddProOptions)=="function" then A.AddProOptions(general) end
end
function A.OpenOptions()
  A.RegisterOptions()
  local root=A.options.main
  if root.category and Settings and type(Settings.OpenToCategory)=="function" then
    Settings.OpenToCategory(root.category:GetID())
  elseif type(InterfaceOptionsFrame_OpenToCategory)=="function" then
    InterfaceOptionsFrame_OpenToCategory(root)
    InterfaceOptionsFrame_OpenToCategory(root)
  else root:Show() end
end
