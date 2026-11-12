-- TradeScope 4.0: per-tool configuration categories in WoW's AddOns options.
local A=ATS
local function l(en,ru) return A.locale=="ruRU" and ru or en end
local function text(parent,s,x,y,w,large)
  local t=parent:CreateFontString(nil,"ARTWORK",large and "GameFontNormalLarge" or "GameFontNormal")
  t:SetWidth(w or 570);t:SetJustifyH("LEFT")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetText(s);return t
end
local function panel(name,desc)
  local p=CreateFrame("Frame",nil,UIParent)
  p.name=name;p:SetSize(635,580);p:Hide();p.controls={}
  text(p,name,18,-16,570,true)
  text(p,desc,18,-49,590)
  return p
end
local seq=0
local function cb(parent,x,y,name,field,group,description)
  seq=seq+1
  local b=CreateFrame("CheckButton","ATSProCheck"..seq,parent,"InterfaceOptionsCheckButtonTemplate")
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local txt=_G[b:GetName().."Text"] or b.Text
  if txt then txt:SetText(name) end
  local function update(self)
    local v=self:GetChecked() and true or false
    local tableSource=group=="minimapTools" and A.db.pro.minimapTools or A.db.pro
    tableSource[field]=v
    if field=="craftInventoryEnabled" and A.SetCraftInventoryEnabled then
      A.SetCraftInventoryEnabled(v)
    end
    if A.UpdateMinimapButtons then A.UpdateMinimapButtons() end
  end
  b:SetScript("OnClick",update)
  parent.controls[#parent.controls+1]={kind="cb",object=b,group=group,field=field}
  if description then text(parent,description,x+26,y-29,555) end
  return b
end
local function sl(parent,x,y,title,field,minv,maxv,step,suffix)
  seq=seq+1
  text(parent,title,x,y,x>300 and 288 or 307)
  local slider=CreateFrame("Slider","ATSProSlider"..seq,parent,"OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT",parent,"TOPLEFT",x+9,y-29)
  slider:SetWidth(x>300 and 260 or 284)
  slider:SetMinMaxValues(minv,maxv)
  if slider.SetValueStep then slider:SetValueStep(step) end
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  local txt=_G[slider:GetName().."Text"]
  local low=_G[slider:GetName().."Low"]
  local hi=_G[slider:GetName().."High"]
  if low then low:SetText(tostring(minv)) end
  if hi then hi:SetText(tostring(maxv)) end
  slider:SetScript("OnValueChanged",function(_,v)
    if type(v)~="number" then return end
    local n=math.max(minv,math.min(maxv,math.floor(v/step+.5)*step))
    A.db.pro[field]=n
    if txt then txt:SetText(tostring(n)..(suffix or "")) end
    if A.UpdateMinimapButtons and (field=="minimapRadius" or field=="minimapAngle") then A.UpdateMinimapButtons() end
  end)
  parent.controls[#parent.controls+1]={kind="slider",object=slider,field=field}
  return slider
end
local function btn(parent,x,y,caption,action,w)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w or 170,25);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(caption);b:SetScript("OnClick",action)
  if A.StyleButton then A.StyleButton(b) end
  return b
end
local function registerOne(root,parent)
  parent.parent=root.name
  if root.category and Settings and type(Settings.RegisterCanvasLayoutSubcategory)=="function" then
    local c=Settings.RegisterCanvasLayoutSubcategory(root.category,parent,parent.name)
    Settings.RegisterAddOnCategory(c)
  elseif type(InterfaceOptions_AddCategory)=="function" then
    InterfaceOptions_AddCategory(parent)
  end
  parent:SetScript("OnShow",function(self)
    for i=1,#self.controls do
      local item=self.controls[i]
      local v=(item.group=="minimapTools" and A.db.pro.minimapTools or A.db.pro)[item.field]
      if item.kind=="cb" then item.object:SetChecked(v==true)
      else item.object:SetValue(tonumber(v) or 0) end
    end
  end)
end
function A.AddProOptions(root)
  if A.proOptions then return end
  A.Init()
  local panels={}
  local automation=panel(l("Scanner & alerts","Сканер и сигналы"),
    l("Filter observed offers and notify only after new Auctionator scans.",
      "Поиск интересных предложений и уведомления после новых сканирований Auctionator."))
  cb(automation,19,-92,l("Enable market scanner","Включить сканер рынка"),"scannerEnabled")
  cb(automation,19,-127,l("Enable price alerts","Включить ценовые сигналы"),"alertsEnabled")
  cb(automation,19,-162,l("Chat notifications","Уведомления в чат"),"alertChat")
  cb(automation,270,-162,l("Alert sound","Звук сигнала"),"alertSound")
  cb(automation,315,-93,l("Show unknown item IDs","Показывать предметы без названия"),"scannerShowUnknown")
  sl(automation,24,-207,l("Minimum discount to median","Минимальная скидка к медиане"),"scannerDiscount",1,75,1,"%")
  sl(automation,24,-287,l("Minimum observed price samples","Минимальное число замеров"),"scannerMinSamples",2,40,1,"")
  sl(automation,24,-367,l("Maximum price age (hours)","Максимальный возраст цены (ч)"),"scannerFreshHours",1,168,1,"")
  sl(automation,24,-447,l("Alert cooldown (seconds)","Пауза повторных сигналов (сек)"),"alertCooldown",60,3600,60,"")
  sl(automation,321,-207,l("Max observed volatility","Макс. волатильность"),"scannerMaxVolatility",5,150,5,"%")
  sl(automation,321,-287,l("Minimum available quantity","Мин. количество на рынке"),"scannerMinSupply",0,5000,50,"")
  sl(automation,321,-367,l("Minimum data quality score","Мин. качество данных"),"minQualityScore",0,100,5,"")
  panels[#panels+1]=automation
  local smart=panel(l("Smart Alerts 2.0", "Умные сигналы 2.0"),
    l("Conditions are checked only when Auctionator records a new observation.",
      "Условия проверяются только после новых наблюдений Auctionator."))
  cb(smart,20,-92,l("Enable smart alerts","Включить сигналы"),"alertsEnabled")
  cb(smart,20,-131,l("Messages in chat","Сообщения в чат"),"alertChat")
  cb(smart,292,-131,l("Play notification sound","Звуковое оповещение"),"alertSound")
  cb(smart,20,-170,l("Screen notifications","Оповещения на экране"),"alertPopup")
  sl(smart,24,-222,l("Minimum observations for advanced signals","Мин. замеров для сложных сигналов"),
    "alertMinSamples",3,40,1,"")
  sl(smart,324,-222,l("Min. data quality for Opportunity alerts","Мин. качество для Opportunity"),
    "alertMinQuality",0,100,5,"")
  sl(smart,24,-319,l("Alert journal size (events)","Размер журнала сигналов"),
    "alertHistoryLimit",25,500,25,"")
  sl(smart,324,-319,l("Default maximum Risk Score","Макс. риск по умолчанию"),
    "alertDefaultRisk",0,100,5,"")
  text(smart,l("Advanced conditions require sufficient history; price/quantity changes are ignored across long scan gaps. Supply decreases are not confirmed sales.",
    "Для сложных условий нужна история. При больших разрывах изменение цены и количества не сравнивается. Сокращение предложения не означает продажу."),24,-424,565)
  btn(smart,24,-500,l("Open alerts & history","Открыть сигналы и историю"),function()
    A.OpenProTool("alerts")
  end,230)
  panels[#panels+1]=smart
  local scanner20=panel(l("Market Scanner 2.0", "Сканер рынка 2.0"),
    l("Rank observed discounts by opportunity and uncertainty, not by discount alone.",
      "Оценка скидки и неопределённости по истории, а не только по размеру скидки."))
  sl(scanner20,24,-128,l("Minimum Opportunity Score","Минимальный Opportunity Score"),"scannerMinScore",0,100,5,"")
  sl(scanner20,321,-128,l("Maximum Risk Score","Максимальный Risk Score"),"scannerMaxRisk",0,100,5,"")
  sl(scanner20,24,-221,l("Maximum unit price in gold (0 = any)","Максимальная цена в золоте (0 = любая)"),"scannerMaxPriceGold",0,10000,100,"")
  text(scanner20,l("Opportunity Score ranks observed discounts using price deviation, data quality, freshness, volatility and available quantity. Risk Score summarizes missing or weak evidence.",
    "Opportunity Score учитывает скидку, качество данных, свежесть, волатильность и количество. Risk Score отражает нехватку или слабость наблюдений."),24,-330,560)
  text(scanner20,l("These scores are NOT sale probabilities and do not replace an independent check of the Auction House. Refresh the scanner after changing filters.",
    "Баллы НЕ означают вероятность продажи. Перед сделкой проверяйте аукцион. После изменения фильтров обновите сканер."),24,-411,555)
  btn(scanner20,24,-507,l("Open market scanner","Открыть сканер рынка"),function()A.OpenProTool("scanner")end,220)
  panels[#panels+1]=scanner20

  local candles=panel(l("Candlestick charts","Свечные графики"),
    l("Candles contain observed quotes only. Empty intervals are not filled.",
      "Свечи состоят только из реальных замеров. Пустые интервалы не заполняются."))
  cb(candles,20,-97,l("Enable candlestick charts","Включить свечные графики"),"candlesEnabled")
  sl(candles,24,-171,l("Candle interval (hours)","Интервал свечи (ч)"),"candleBucketHours",1,48,1,l(" h"," ч"))
  sl(candles,321,-171,l("Candle history (hours)","История свечей (ч)"),"candleHours",6,168,6,l(" h"," ч"))
  text(candles,l("EMA and Bollinger overlays are calculated from time-bucketed observed prices. Choose indicator settings in Technical Indicators.",
      "Наложения EMA и Боллинджера используют замеры с привязкой ко времени. Настройки находятся в разделе «Индикаторы»."),24,-308,558)
  panels[#panels+1]=candles

  local technical=panel(l("Technical indicators 2.0","Технические индикаторы 2.0"),
    l("EMA, RSI, MACD and Bollinger Bands based on real observed time buckets.",
      "EMA, RSI, MACD и полосы Боллинджера по реальным временным интервалам."))
  cb(technical,20,-92,l("Enable technical indicators","Включить технические индикаторы"),"indicatorsEnabled")
  cb(technical,20,-130,l("Display EMA","Показывать EMA"),"showEMA")
  cb(technical,280,-130,l("Display Bollinger Bands","Показывать полосы Боллинджера"),"showBollinger")
  cb(technical,20,-166,l("Display RSI","Показывать RSI"),"showRSI")
  cb(technical,280,-166,l("Display MACD","Показывать MACD"),"showMACD")
  cb(technical,20,-204,l("Preliminary RSI with fewer observations","Предварительный RSI при малой истории"),"indicatorRSIPreview")
  sl(technical,24,-254,l("Observation bucket (minutes)","Интервал наблюдений (мин)"),"indicatorBucketMinutes",5,120,5,l(" min"," мин"))
  sl(technical,321,-254,l("Reset after data gap (hours)","Сброс после пропуска (ч)"),"indicatorGapHours",1,48,1,l(" h"," ч"))
  sl(technical,24,-347,l("EMA period (observed buckets)","EMA: период (интервалов)"),"emaPeriod",2,50,1,"")
  sl(technical,321,-347,l("RSI period (observed buckets)","RSI: период (интервалов)"),"rsiPeriod",2,40,1,"")
  sl(technical,24,-438,l("Bollinger period (observed buckets)","Боллинджер: период (интервалов)"),"bollPeriod",5,60,1,"")
  text(technical,l("Preliminary RSI uses at least 4 real time buckets. It is labeled as preliminary until the full configured period is available. No prices are invented in missing intervals.",
      "Предварительный RSI требует минимум 4 реальных интервала. До накопления полного периода он явно отмечается как предварительный. Пустые интервалы не заполняются."),323,-447,288)
  panels[#panels+1]=technical

  local research=panel(l("Activity, quality & heatmap","Активность, качество, теплокарта"),
    l("Data coverage and observation-driven market patterns.",
      "Качество наблюдений и исторические изменения рынка."))
  cb(research,20,-99,l("Market activity index","Индекс рыночной активности"),"activityEnabled")
  cb(research,20,-135,l("Reliability score","Оценка надёжности данных"),"qualityEnabled")
  cb(research,20,-171,l("Price heatmap","Тепловая карта цен"),"heatmapEnabled")
  sl(research,24,-225,l("Activity window (hours)","Период активности (ч)"),"activityWindowHours",1,168,1,"")
  sl(research,24,-313,l("Heatmap history (days)","История теплокарты (дни)"),"heatmapDays",7,90,1,"")
  sl(research,24,-399,l("Minimum reliability score","Минимальный балл надёжности"),"minQualityScore",0,100,5,"")
  btn(research,24,-501,l("Open analysis","Открыть анализ"),function()A.OpenProTool("activity")end)
  panels[#panels+1]=research

  local accounting=panel(l("Trade journal & crafting","Журнал сделок и крафт"),
    l("Manual transactions and recipe costs; prices from Auctionator scans.",
      "Ручные сделки и себестоимость рецептов по ценам Auctionator."))
  cb(accounting,20,-96,l("Enable trading journal","Включить торговый журнал"),"journalEnabled")
  cb(accounting,20,-132,l("Enable crafting calculator","Включить калькулятор крафта"),"craftEnabled")
  cb(accounting,315,-132,l("Count bags and bank (opt-in)","Учитывать сумки и банк (опция)"),"craftInventoryEnabled")
  sl(accounting,24,-195,l("Auction fee for calculations","Комиссия аукциона для расчётов"),"journalFee",0,15,1,"%")
  text(accounting,l("Journal transactions are entered manually. Missing purchase lots are not treated as profit.",
    "Сделки вносятся вручную. Продажи без закупок не считаются прибылью."),24,-298,562)
  text(accounting,l("Own resources reduce extra purchases, but still have market value. Bank counts reflect the last bank visit.",
    "Свои материалы снижают расходы на докупку, но имеют рыночную стоимость. Банк — по последнему посещению."),24,-363,560)
  btn(accounting,24,-441,l("Open journal","Открыть журнал"),function()A.OpenProTool("journal")end)
  btn(accounting,210,-441,l("Open crafting","Открыть крафт"),function()A.OpenProTool("craft")end)
  panels[#panels+1]=accounting

  local craftscan=panel(l("Crafting recipe catalog","Каталог рецептов крафта"),
    l("Show all imported recipes, including losses and missing quotes.",
      "Все импортированные рецепты, включая убыточные и без цен."))
  cb(craftscan,20,-94,l("Enable recipe catalog","Включить каталог крафта"),"craftscanEnabled")
  cb(craftscan,20,-130,l("Profit-only filter (off by default)",
    "Фильтр: только прибыльные (по умолчанию выкл.)"),"craftScannerOnlyProfitable")
  text(craftscan,l("Profit and ROI thresholds apply only with the profit-only filter enabled.",
    "Минимальная прибыль и ROI действуют только при включённом фильтре."),24,-174,555)
  sl(craftscan,24,-210,l("Minimum profit per craft (gold)","Мин. прибыль за крафт (золото)"),"craftScannerMinProfitGold",0,100,1,"")
  sl(craftscan,24,-298,l("Minimum return on costs (%)","Минимальный ROI (%)"),"craftScannerMinROI",0,100,5,"%")
  sl(craftscan,24,-387,l("Maximum recipes imported per action","Макс. рецептов за один импорт"),"craftScannerImportLimit",100,1500,100,"")
  btn(craftscan,24,-492,l("Open craft catalog","Открыть каталог крафта"),function()A.OpenProTool("craftscan")end,205)
  panels[#panels+1]=craftscan

  local minimap=panel(l("Minimap shortcuts","Кнопки миникарты"),
    l("Expand or hide tool icons near the minimap. Drag the main icon to reposition.",
      "Показывайте инструменты возле миникарты и перемещайте главную кнопку."))
  cb(minimap,20,-90,l("Enable minimap launcher","Включить кнопку миникарты"),"minimapEnabled")
  cb(minimap,20,-127,l("Keep tool icons expanded","Показывать значки инструментов"),"minimapExpanded")
  local names={
    {"terminal",l("Market terminal","Рыночный терминал")},
    {"scanner",l("Market scanner","Сканер рынка")},
    {"alerts",l("Price alerts","Сигналы")},
    {"candles",l("Candles","Свечи")},
    {"activity",l("Activity","Активность")},
    {"journal",l("Trading journal","Журнал")},
    {"craft",l("Crafting","Крафт")},
    {"indicators",l("Indicators","Индикаторы")},
    {"heatmap",l("Heatmap","Теплокарта")},
    {"quality",l("Data quality","Качество")},
    {"craftscan",l("Profitable crafts","Выгодный крафт")},
    {"balance",l("Gold history","История золота")},
  }
  for i=1,#names do
    local col=(i-1)%2
    local row=math.floor((i-1)/2)
    cb(minimap,22+col*287,-171-row*43,names[i][2],names[i][1],"minimapTools")
  end
  btn(minimap,24,-498,l("Collapse buttons","Свернуть значки"),function()
    A.db.pro.minimapExpanded=false;A.UpdateMinimapButtons()
    for i=1,#minimap.controls do
      local c=minimap.controls[i]
      if c.field=="minimapExpanded" then c.object:SetChecked(false) end
    end
  end)
  btn(minimap,231,-498,l("Reset icon position","Сброс позиции значка"),function()
    if A.ResetMinimapPosition then A.ResetMinimapPosition() end
  end,198)
  text(minimap,l("Automatic rim alignment is used until you drag the icon.",
    "Кнопка автоматически выровнена по ободу, пока вы её не перетащите."),24,-537,570)
  panels[#panels+1]=minimap

  for i=1,#panels do registerOne(root,panels[i]) end
  A.proOptions=panels
end
