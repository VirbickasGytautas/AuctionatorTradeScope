-- 5.0.0-beta5: One market research screen, one selection, two independent
-- read-only evidence summaries. The underlying market models are unchanged.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l,fs,tex,button,newPage,heading=C.l,C.fs,C.tex,C.button,C.newPage,C.heading
local currency,labelNumber=C.currency,C.labelNumber

local activityHelp={
  {"Index of observed activity (0-100), not volume of completed trades.",
   "Индекс наблюдаемой активности (0–100), а не объём завершённых продаж."},
  {"Number of recent market snapshots in the configured activity window.",
   "Количество рыночных замеров за выбранный в настройках период."},
  {"Number of observed price changes, not completed sales.",
   "Количество изменений наблюдаемой цены, не число продаж."},
  {"Number of changes in observed auction supply; auctions may expire or be cancelled.",
   "Изменения наблюдаемого предложения; лоты могут истечь или быть сняты."},
  {"Reliability of the local observations, not a probability of a sale.",
   "Надёжность локальных замеров, не вероятность продажи."},
  {"Last observed Auctionator price; may have changed since the last scan.",
   "Последняя цена Auctionator; после сканирования она могла измениться."},
  {"Variation in recorded prices, not proof of demand.",
   "Разброс записанных цен, а не подтверждение спроса."},
  {"Last observed quantity on the Auction House, not live availability.",
   "Последнее наблюдаемое количество на аукционе, не показатель в реальном времени."},
}
local qualityHelp={
  {"Quality score based on recency, coverage and time span, not sale probability.",
   "Оценка полноты, свежести и длительности истории, не вероятность продажи."},
  {"All valid price snapshots stored for this item.",
   "Все сохранённые действительные наблюдения цены предмета."},
  {"Number of distinct clock-hours with observations.",
   "Число отдельных часов, в которых были замеры."},
  {"Hours since the last observed price, smaller is fresher.",
   "Часы после последней цены: чем меньше, тем свежее."},
  {"Hours between the earliest and latest saved observations.",
   "Часы между первым и последним сохранёнными замерами."},
  {"Longest gap between consecutive scans; the intervening market is unknown.",
   "Самый длинный перерыв между замерами; данные внутри перерыва неизвестны."},
  {"Share of observed time intervals within the recent coverage window.",
   "Доля временных интервалов с реальными наблюдениями за недавний период."},
  {"Recent observations attributed to Auctionator scans.",
   "Недавние наблюдения из сканирований Auctionator."},
  {"Recent observations attributed to tooltip captures, not transactions.",
   "Недавние наблюдения из подсказок, не подтверждённые сделки."},
  {"Observations lacking a recorded source, often imported older history.",
   "Замеры без записанного источника, часто более старая история."},
  {"Classification of observed data quality: high, medium or low.",
   "Категория качества наблюдений: высокое, среднее либо низкое."},
}
local function setRows(rows,values)
  for i=1,#rows do rows[i]:SetText(values[i] or "") end
end
local function number(n)
  return tonumber(n) or 0
end

function B.activity(root)
  local p=newPage(root)
  heading(p,l("Activity and data quality", "Активность рынка и качество данных"),-12)
  p.selection=C.marketInput(p,20,-59,232)
  p.analyze=button(p,l("Analyze","Анализировать"),282,-82,150,function()p.update()end)
  C.attachHelp(p.analyze,l("Update analysis","Обновить аналитику"),
    l("Refresh both columns for the same selected item; no scans or trades are performed.",
      "Обновить обе колонки для одного выбранного предмета; сканирования и сделки не выполняются."))
  p.identity=C.makeItemIdentity(p)
  -- One identity strip and one selector; the metrics are deliberately two
  -- columns, not two old 946px pages scaled down to half size.
  tex(p,472,-174,1,399,.40,.32,.18,.60)
  p.activityTitle=fs(p,l("MARKET ACTIVITY","АКТИВНОСТЬ РЫНКА"),20,-177,433,true)
  p.qualityTitle=fs(p,l("DATA QUALITY","КАЧЕСТВО ДАННЫХ"),491,-177,433,true)
  tex(p,20,-200,435,1,.47,.36,.18,.75)
  tex(p,490,-200,435,1,.47,.36,.18,.75)
  p.activityRows={}
  p.qualityRows={}
  for i=1,#activityHelp do
    p.activityRows[i]=fs(p,"",20,-213-(i-1)*32,435,i==1)
  end
  for i=1,#qualityHelp do
    p.qualityRows[i]=fs(p,"",490,-213-(i-1)*32,435,i==1)
  end
  -- Text-bound hover areas reuse the shared help system. No right-side panel.
  C.addMetricTooltips(p,p.activityRows,activityHelp,433)
  C.addMetricTooltips(p,p.qualityRows,qualityHelp,433)
  p.note=fs(p,l("Both scores describe observed Auctionator history; neither proves sales or demand.",
    "Оба индекса отражают замеры Auctionator, а не подтверждённые продажи или спрос."),20,-591,906)
  p.note:SetTextColor(.78,.81,.84)
  p.update=function()
    local key=C.selectedKey(p)
    p.identity:showItem(key)
    local prefs=A.db and A.db.pro or {}
    if not key then
      setRows(p.activityRows,{l("Select a scanned item.","Выберите отсканированный предмет.")})
      setRows(p.qualityRows,{l("The same item is used in both columns.",
        "Обе колонки используют один выбранный предмет.")})
      return
    end
    if prefs.activityEnabled==false then
      setRows(p.activityRows,{l("Activity is disabled in settings.",
        "Активность отключена в настройках.")})
    else
      local data=A.ProActivity(key)
      local m=data.metrics or {}
      setRows(p.activityRows,{
        l("Activity index","Индекс активности")..": "..number(data.score).." / 100",
        l("Recent snapshots","Недавние замеры")..": "..number(data.observations),
        l("Price changes","Изменения цены")..": "..number(data.priceChanges),
        l("Supply changes","Изменения предложения")..": "..number(data.quantityChanges),
        l("Reliability","Надёжность")..": "..number(data.quality and data.quality.score).." / 100",
        l("Latest price","Последняя цена")..": "..currency(m.currentPrice),
        l("Volatility","Волатильность")..": "..A.FmtVolatility(m.volatility),
        l("On market","На рынке")..": "..A.FmtCount(m.currentQuantity),
      })
    end
    if prefs.qualityEnabled==false then
      setRows(p.qualityRows,{l("Data quality is disabled in settings.",
        "Качество данных отключено в настройках.")})
    else
      local q=A.ProQuality(A.ProSamples(key))
      setRows(p.qualityRows,{
        l("Quality score","Оценка качества")..": "..number(q.score).." / 100",
        l("Total snapshots","Всего замеров")..": "..number(q.count),
        l("Observed hours","Часов с замерами")..": "..number(q.uniqueHours),
        l("Latest quote age (h)","Возраст цены (ч)")..": "..labelNumber(q.age),
        l("Observation span (h)","Период наблюдений (ч)")..": "..labelNumber(q.coverage),
        l("Longest gap (h)","Самый большой пропуск (ч)")..": "..labelNumber(q.maxGap),
        l("Time coverage","Покрытие окон")..": "..string.format("%.1f%%",q.coveragePercent or 0)..
          " ("..tostring(q.coverageBucketHours or 1)..l("h buckets)","ч интервалы)"),
        l("Auction scans","Замеры сканера")..": "..number(q.scanObservations),
        l("Tooltip snapshots","Замеры подсказок")..": "..number(q.hoverObservations),
        l("Unknown source","Источник неизвестен")..": "..number(q.unknownObservations),
        l("Quality class","Класс данных")..": "..(q.label=="high" and l("High","Высокое") or
          (q.label=="medium" and l("Medium","Среднее") or l("Low","Низкое"))),
      })
    end
  end
  return p
end
