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

function B.activity(root)
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

