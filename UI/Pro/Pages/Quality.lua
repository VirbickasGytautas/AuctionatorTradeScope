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

function B.quality(root)
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

