-- Two full localizations: ruRU and enUS (fallback). WoW Forever / Lua 5.1.
local A = ATS
local en = {
  NAME = "Auctionator TradeScope",
  DESCRIPTION = "Advanced price, supply and market snapshot analytics for Auctionator",
  NO_DATA = "no data", MONEY_FORMAT = "%d g %d s %d c",
  GOLD = "g", SILVER = "s", COPPER = "c",
  LOADED = "v%s loaded. /ats opens market terminal; /ats options opens settings.",
  ERROR = "Error: ", SCAN_NOT_CONNECTED = "Auctionator scan tracking not connected",
  STATUS_POINTS = "Stored updates this session - scan: %s; tooltip: %s",
  HELP = "/ats - market terminal; /ats options - settings; /ats add - watch tooltip item; /ats status; /ats hours 48; /ats test",
  PERIOD = "Period", NO_SAMPLES = "No observations for this period",
  SELECT_ITEM = "Hover over an item or enter an item ID/link.",
  ADDED_WATCH = "Item added to the watchlist.", REMOVED_WATCH = "Item removed from the watchlist.",
  SCAN_DB_UNAVAILABLE = "Auctionator database is not ready",
  SCAN_HOOK_SECURE = "Reading Auctionator database updates",
  SCAN_HOOK_FALLBACK = "Reading Auctionator updates (compatibility mode)",
  OPTIONS_UNAVAILABLE = "AddOn options registration is unavailable in this client.",
  GENERAL = "General", CHARTS = "Charts", ANALYSIS = "Analysis",
  GENERAL_DESC = "Data collection, tooltip integration and storage",
  CHARTS_DESC = "Combine or arrange graphs; select their scale and indicators",
  ANALYSIS_DESC = "Configure indicators, market signals and display detail",
  ENABLE = "Enable TradeScope", COLLECT_SCAN = "Record Auctionator scan results",
  COLLECT_HOVER = "Also record hovered item prices (can reflect cached data)",
  SHOW_TOOLTIP = "Display charts under item tooltips",
  SHOW_INSIGHTS = "Display market indicators in chart header",
  COMPACT = "Compact header with samples, quantity and 24-hour decreases",
  DELAY = "Tooltip display delay", SECONDS = " sec.",
  INTERVAL = "Deduplicate unchanged snapshots for", RETENTION = "Store observations for",
  DAYS = " days", CLEAR = "Delete all local history", CLEAR_CONFIRM = "Permanently delete TradeScope history?",
  CLEARED = "History cleared.", OPEN_TERMINAL = "Open market terminal",
  GRAPH_PRICE = "Price history", GRAPH_MARKET = "Market quantity",
  GRAPH_SALES = "Estimated supply decreases", GRAPH_COMBINED = "Price + quantity (dual axis)",
  COMBINED_BARS = "Show estimated decreases as bars on the combined graph",
  DRAW_GRID = "Show grid", DRAW_DOTS = "Show observation markers",
  DRAW_MA = "Show price moving average", DRAW_TREND = "Show linear price trend",
  GRAPH_SELECTION = "Visible charts (any combination)", INDICATORS = "Overlay indicators",
  CHART_PERIOD = "Chart time scale", MODE_AUTO = "Auto", MODE_DAY = "24 hours",
  MODE_WEEK = "7 days", MODE_MONTH = "30 days", MODE_CUSTOM = "Custom",
  CUSTOM_HOURS = "Custom period (hours, 1-2160):",
  AUTO_CHANGES = "Auto-zoom: minimum observed price changes",
  PLOT_POINTS = "Maximum chart points per series", MA_PERIOD = "Moving average sample count",
  SIGNAL_THRESHOLD = "Price deviation from mean for market signal",
  SIGNAL_SAMPLES = "Minimum price observations for a signal",
  VOLATILITY = "Show estimated volatility (observed price dispersion)",
  METRIC_CURRENT = "Price", METRIC_MEAN = "Average", METRIC_MEDIAN = "Median",
  METRIC_MIN = "Low", METRIC_MAX = "High", METRIC_TREND = "Change",
  METRIC_VOLATILITY = "Volatility", METRIC_SUPPLY = "Available", METRIC_SUPPLY_CHANGE = "Supply change",
  METRIC_DECLINES = "24h decreases (est.)", METRIC_MA = "Moving avg.", METRIC_SIGNAL = "Compared to avg.",
  METRIC_SAMPLES = "Samples", METRIC_LAST = "Last snapshot",
  SIGNAL_BELOW = "Below typical", SIGNAL_ABOVE = "Above typical",
  SIGNAL_NORMAL = "Near typical", SIGNAL_INSUFFICIENT = "Not enough data",
  CHART_TITLE_COMBINED = "Price and quantity", CHART_TITLE_PRICE = "Price",
  CHART_TITLE_MARKET = "Available quantity", CHART_TITLE_SALES = "Estimated quantity decreases",
  CHART_EMPTY_PRICE = "No recorded prices", CHART_EMPTY_MARKET = "No quantity snapshots",
  CHART_EMPTY_SALES = "Not enough quantity observations",
  CHART_HEADER_SAMPLES = "Samples", CHART_HEADER_MARKET = "Available",
  CHART_HEADER_SALES = "24h decreases*", CHART_HEADER_CHANGE = "Price change",
  CHART_HEADER_MEAN = "Average", CHART_HEADER_VOL = "Volatility",
  CHART_LEGEND_PRICE = "Price", CHART_LEGEND_MARKET = "Available",
  CHART_LEGEND_SALES = "Decrease*", CHART_LEGEND_MA = "Moving avg.",
  FOOTNOTE = "*Quantity decreases may also be cancelled/expired listings, not verified sales.",
  TERMINAL = "TradeScope | Market terminal", SEARCH = "Name, ID or link",
  SEARCH_INDEXING = "Indexing AH...",
  OPEN_ITEM = "View item", PIN = "Watch", UNPIN = "Unwatch",
  WATCHLIST = "Watchlist", NO_WATCH = "No items watched yet.", WATCH_HINT = "Hover an item and type /ats add",
  DASHBOARD_NO_ITEM = "Choose an item ID, link, or a watched item.",
  DASHBOARD_HINT = "Samples and market indicators come from your own scans.",
  PAGE_PREV = "<", PAGE_NEXT = ">", CLOSE = "Close",
  TABS_COMBINED = "Combined", TABS_PRICE = "Price", TABS_MARKET = "Supply", TABS_SALES = "Decrease*",
  TEST = "Chart preview (no test data are saved)",
}
local ru = {
  NAME = "Auctionator TradeScope",
  DESCRIPTION = "Углублённая аналитика цен, предложения и рыночных наблюдений Auctionator",
  NO_DATA = "нет данных", MONEY_FORMAT = "%d з %d с %d м",
  GOLD = "з", SILVER = "с", COPPER = "м",
  LOADED = "v%s загружен. /ats - терминал; /ats options - настройки.",
  ERROR = "Ошибка: ", SCAN_NOT_CONNECTED = "Отслеживание сканирований не подключено",
  STATUS_POINTS = "Сохранено за сеанс: сканирований %s; наведений %s",
  HELP = "/ats - терминал; /ats options - настройки; /ats add - в избранное; /ats status; /ats hours 48; /ats test",
  PERIOD = "Период", NO_SAMPLES = "За этот период нет замеров",
  SELECT_ITEM = "Наведите курсор на предмет или введите его ID/ссылку.",
  ADDED_WATCH = "Предмет добавлен в список наблюдения.", REMOVED_WATCH = "Предмет удалён из списка наблюдения.",
  SCAN_DB_UNAVAILABLE = "База Auctionator ещё не готова",
  SCAN_HOOK_SECURE = "Получение обновлений базы Auctionator",
  SCAN_HOOK_FALLBACK = "Получение обновлений Auctionator (совместимый режим)",
  OPTIONS_UNAVAILABLE = "Не удалось зарегистрировать настройки в этом клиенте.",
  GENERAL = "Общие", CHARTS = "Графики", ANALYSIS = "Анализ",
  GENERAL_DESC = "Сбор истории, подсказки предметов и хранение данных",
  CHARTS_DESC = "Совмещайте графики, выбирайте масштаб и индикаторы",
  ANALYSIS_DESC = "Настройка рыночных показателей и детализации",
  ENABLE = "Включить TradeScope", COLLECT_SCAN = "Записывать результаты сканирований Auctionator",
  COLLECT_HOVER = "Также записывать цену при наведении (может быть из кэша)",
  SHOW_TOOLTIP = "Показывать графики рядом с подсказками предметов",
  SHOW_INSIGHTS = "Показывать рыночные показатели над графиками",
  COMPACT = "Краткая шапка: замеры, количество и снижение за 24 ч",
  DELAY = "Задержка появления графика", SECONDS = " сек.",
  INTERVAL = "Повторять запись неизменившихся данных раз в", RETENTION = "Хранить наблюдения",
  DAYS = " дней", CLEAR = "Удалить локальную историю", CLEAR_CONFIRM = "Навсегда удалить историю TradeScope?",
  CLEARED = "История очищена.", OPEN_TERMINAL = "Открыть терминал рынка",
  GRAPH_PRICE = "История цен", GRAPH_MARKET = "Количество на рынке",
  GRAPH_SALES = "Оценка уменьшения предложения", GRAPH_COMBINED = "Цена + количество (две оси)",
  COMBINED_BARS = "Показывать столбцы оценочного уменьшения на общем графике",
  DRAW_GRID = "Показывать сетку", DRAW_DOTS = "Показывать точки замеров",
  DRAW_MA = "Скользящая средняя цены", DRAW_TREND = "Линейный тренд цены",
  GRAPH_SELECTION = "Отображаемые графики (любое сочетание)", INDICATORS = "Наложение индикаторов",
  CHART_PERIOD = "Временной масштаб", MODE_AUTO = "Авто", MODE_DAY = "24 часа",
  MODE_WEEK = "7 дней", MODE_MONTH = "30 дней", MODE_CUSTOM = "Свой",
  CUSTOM_HOURS = "Свой период (часы, 1-2160):",
  AUTO_CHANGES = "Авто-масштаб: минимум изменений цены",
  PLOT_POINTS = "Максимум точек в графике", MA_PERIOD = "Количество замеров для средней",
  SIGNAL_THRESHOLD = "Отклонение от средней для сигнала",
  SIGNAL_SAMPLES = "Минимум замеров для сигнала",
  VOLATILITY = "Показывать волатильность (разброс наблюдаемых цен)",
  METRIC_CURRENT = "Цена", METRIC_MEAN = "Средняя", METRIC_MEDIAN = "Медиана",
  METRIC_MIN = "Мин.", METRIC_MAX = "Макс.", METRIC_TREND = "Изменение",
  METRIC_VOLATILITY = "Волатильность", METRIC_SUPPLY = "На рынке", METRIC_SUPPLY_CHANGE = "Изм. предложения",
  METRIC_DECLINES = "Снижение за 24 ч*", METRIC_MA = "Скольз. средняя", METRIC_SIGNAL = "К средней", 
  METRIC_SAMPLES = "Замеров", METRIC_LAST = "Последний замер",
  SIGNAL_BELOW = "Ниже среднего", SIGNAL_ABOVE = "Выше среднего",
  SIGNAL_NORMAL = "Около среднего", SIGNAL_INSUFFICIENT = "Мало данных",
  CHART_TITLE_COMBINED = "Цена и количество", CHART_TITLE_PRICE = "Цена",
  CHART_TITLE_MARKET = "Количество на рынке", CHART_TITLE_SALES = "Предполагаемое уменьшение предложения",
  CHART_EMPTY_PRICE = "Нет замеров цены", CHART_EMPTY_MARKET = "Нет наблюдений количества",
  CHART_EMPTY_SALES = "Недостаточно наблюдений количества",
  CHART_HEADER_SAMPLES = "Замеров", CHART_HEADER_MARKET = "На рынке",
  CHART_HEADER_SALES = "Снижение за 24 ч*", CHART_HEADER_CHANGE = "Цена",
  CHART_HEADER_MEAN = "Средняя", CHART_HEADER_VOL = "Волатильность",
  CHART_LEGEND_PRICE = "Цена", CHART_LEGEND_MARKET = "Количество",
  CHART_LEGEND_SALES = "Снижение*", CHART_LEGEND_MA = "Скользящая",
  FOOTNOTE = "*Снижение количества может означать снятие лотов, а не подтверждённую продажу.",
  TERMINAL = "TradeScope | Рыночный терминал", SEARCH = "Имя, ID или ссылка",
  SEARCH_INDEXING = "Индексирую базу...",
  OPEN_ITEM = "Открыть", PIN = "Следить", UNPIN = "Убрать",
  WATCHLIST = "Список наблюдения", NO_WATCH = "Пока нет выбранных предметов.", WATCH_HINT = "Наведи на предмет и введи /ats add",
  DASHBOARD_NO_ITEM = "Выбери ID, ссылку или предмет из списка.",
  DASHBOARD_HINT = "Показатели строятся по вашим собственным сканированиям.",
  PAGE_PREV = "<", PAGE_NEXT = ">", CLOSE = "Закрыть",
  TABS_COMBINED = "Совмещ.", TABS_PRICE = "Цена", TABS_MARKET = "Кол-во", TABS_SALES = "Снижение*",
  TEST = "Проверка графика (вымышленные данные не сохраняются)",
}
-- Market chart crosshair: same semantics as the character gold history.
en.CHART_CURSOR_REDUCTION = "Estimated decreases*"
en.CHART_CURSOR_LAST = "Last observation"
en.CHART_CURSOR_NO_DATA = "No previous observation"
ru.CHART_CURSOR_REDUCTION = "Оценка уменьшения*"
ru.CHART_CURSOR_LAST = "Последний замер"
ru.CHART_CURSOR_NO_DATA = "Нет предыдущих замеров"

-- Terminal, graphics and balance extensions.
en.SELECT_ITEM_TITLE="Select an item"
en.DROP_ITEM="Drop an item here"
en.DROP_ITEM_TIP="Drag an item from your bags onto this slot. The item remains in your bags."
en.PICK_FROM_BAG="Select from bags"
en.CANCEL_PICK="Cancel selection"
en.PICK_HINT="Enter an item ID/link, drag an item, or select from bags."
en.PICK_ACTIVE="Move your mouse over the item in your bags to select it."
en.ZOOM_RESET="Reset zoom"
en.CHART_LEGEND_TREND="Trend"
en.CHART_LEGEND_MA="Average"
en.CHART_LEGEND_PRICE="Price"
en.CHART_LEGEND_MARKET="Supply"
en.CHART_LEGEND_SALES="Declines*"
en.APPEARANCE="Colors & legend"
en.APPEARANCE_DESC="Adjust series colors, grid, and the explanatory legend"
en.LEGEND_TOGGLE="Display color legend beside plots"
en.COLOR_PRICE="Price line"
en.COLOR_MARKET="Quantity line"
en.COLOR_SALES="Supply decreases"
en.COLOR_MA="Moving average"
en.COLOR_TREND="Trend line"
en.COLORS_RESET="Restore default colors"
en.PICK_COLOR="Click the square to choose a color"
en.WALLET="Character wallet"
en.WALLET_DESC="Optional personal coin balance history in the backpack"
en.WALLET_ENABLE="Record character coin balance (off by default)"
en.WALLET_TITLE="Coin balance history (7 days)"
en.WALLET_INFO="Open the separate wallet chart using /ats balance or the market terminal button. Recordings are kept per character; hover coins to open when recording is enabled."
en.WALLET_OPEN_BUTTON="Wallet chart"
en.WALLET_WINDOW_TITLE="TradeScope | Character gold history"
en.WALLET_CURRENT="Balance"
en.WALLET_CHANGE="Change in period"
en.WALLET_DISABLED="Gold history is disabled"
en.WALLET_DISABLED_HINT="Enable tracking to start recording your character's gold."
en.WALLET_ENABLE_NOW="Enable gold tracking"
en.WALLET_NO_SAMPLES="No balance records in this period yet."
en.WALLET_ZOOM_HINT="Mouse wheel: zoom in / out. Drag the window by its title."
en.WALLET_SCALE="Scale"
en.HOURS_SHORT="h"
en.DAYS_SHORT="d"
en.FOOTNOTE="*Availability decreases are estimates, not verified sales. Use mouse wheel to zoom."
en.TERMINAL="TradeScope  |  Market overview"
en.HELP="/ats - terminal; /ats balance - gold chart; /ats options - settings; /ats add - watch item; /ats status; /ats hours 48"
ru.SELECT_ITEM_TITLE="Выбор предмета"
ru.DROP_ITEM="Перетащи предмет сюда"
ru.DROP_ITEM_TIP="Перетащи предмет из сумки в эту ячейку. Предмет останется в сумке."
ru.PICK_FROM_BAG="Выбрать из сумки"
ru.CANCEL_PICK="Отменить выбор"
ru.PICK_HINT="Введи ID/ссылку, перетащи предмет или выбери его из сумки."
ru.PICK_ACTIVE="Наведи мышь на предмет в открытой сумке для выбора."
ru.ZOOM_RESET="Сброс"
ru.CHART_LEGEND_TREND="Тренд"
ru.CHART_LEGEND_MA="Средняя"
ru.CHART_LEGEND_PRICE="Цена"
ru.CHART_LEGEND_MARKET="Кол-во"
ru.CHART_LEGEND_SALES="Снижение*"
ru.APPEARANCE="Цвета и легенда"
ru.APPEARANCE_DESC="Цветовые схемы линий, сетка и легенда графика"
ru.LEGEND_TOGGLE="Показывать легенду цветов слева от графика"
ru.COLOR_PRICE="График цены"
ru.COLOR_MARKET="Количество товаров"
ru.COLOR_SALES="Уменьшение предложения"
ru.COLOR_MA="Скользящая средняя"
ru.COLOR_TREND="Линия тренда"
ru.COLORS_RESET="Сбросить цвета"
ru.PICK_COLOR="Нажми на квадратик, чтобы выбрать цвет"
ru.WALLET="Баланс персонажа"
ru.WALLET_DESC="Необязательная история монет в сумках персонажа"
ru.WALLET_ENABLE="Сохранять историю монет персонажа (по умолчанию выключено)"
ru.WALLET_TITLE="История баланса (7 дней)"
ru.WALLET_INFO="Отдельное окно истории золота: /ats balance или кнопка в терминале. Для каждого персонажа запись ведётся отдельно; при включённом учёте можно открыть наведением на монеты."
ru.WALLET_OPEN_BUTTON="История золота"
ru.WALLET_WINDOW_TITLE="TradeScope | История золота персонажа"
ru.WALLET_CURRENT="Баланс"
ru.WALLET_CHANGE="Изменение за период"
ru.WALLET_DISABLED="Учёт золота выключен"
ru.WALLET_DISABLED_HINT="Включите запись, чтобы начать собирать историю золота персонажа."
ru.WALLET_ENABLE_NOW="Включить учёт золота"
ru.WALLET_NO_SAMPLES="За выбранный период ещё нет замеров баланса."
ru.WALLET_ZOOM_HINT="Колесо мыши: масштаб. Перетаскивайте окно за заголовок."
ru.WALLET_SCALE="Масштаб"
ru.HOURS_SHORT="ч"
ru.DAYS_SHORT="дн"
ru.FOOTNOTE="*Снижение предложения не означает подтверждённые продажи. Масштаб: колесо мыши."
ru.TERMINAL="TradeScope  |  Обзор рынка"
ru.HELP="/ats - терминал; /ats balance - история золота; /ats options - настройки; /ats add - предмет; /ats status; /ats hours 48"
-- New terminal trading research tools (no unverified NPC resale integrations).
en.TOOLS_BUTTON = "Trader tools"
en.TOOLS_BACK = "Back to chart"
en.TOOLS_PRICE = "PRICE RESEARCH"
en.TOOLS_SUPPLY = "SUPPLY & DATA QUALITY"
en.TOOLS_DELTA24 = "24h price momentum"
en.TOOLS_MEDIAN_DEV = "Versus observed median"
en.TOOLS_POSITION = "Position in price range"
en.TOOLS_RANGE = "Price range / mean"
en.TOOLS_AGE = "Last price observation"
en.TOOLS_DROP24 = "24h supply reductions*"
en.TOOLS_PRESSURE = "Decreases / current supply*"
en.TOOLS_SAMPLES24 = "Observations in 24h"
en.TOOLS_CONFIDENCE = "Data coverage"
en.TOOLS_CONF_LOW = "Limited"
en.TOOLS_CONF_MEDIUM = "Moderate"
en.TOOLS_CONF_HIGH = "Good"
en.TOOLS_CALCULATOR = "TRADE CALCULATOR (based on latest auction quote)"
en.TOOLS_BUY = "Buy price, gold"
en.TOOLS_FEE = "Auction fee"
en.TOOLS_NET = "After fee"
en.TOOLS_PNL = "Estimated profit"
en.TOOLS_BREAKEVEN = "Break-even sell price"
en.TOOLS_ENTER_BUY = "Enter purchase cost and press Enter for net profit / ROI"
en.TOOLS_GUIDE_DISCOUNT = "Current quote is below the observed median; check stock and quote age."
en.TOOLS_GUIDE_PREMIUM = "Current quote is above the observed median; assess exit liquidity."
en.TOOLS_GUIDE_NEUTRAL = "Current quote is near the observed median."
en.TOOLS_GUIDE_INSUFFICIENT = "Not enough fresh observations for a market signal."
en.TOOLS_CAUTION = "* Supply reductions may be expired/withdrawn listings, not verified sales."
en.TRADING_CATEGORY = "Trader tools"
en.TRADING_DESC = "Market research, data coverage and trade cost calculator"
en.TRADING_ENABLED = "Show professional tools in the market terminal"
en.TRADING_ADVICE = "Show context-based price signals"
en.TRADING_FEE = "Estimated auction-house fee"
en.TRADING_MIN_SAMPLE = "Minimum observations for signals"
en.TRADING_CAVEAT = "* Calculations use Auctionator snapshots, not a live order book. Sales are not verified; recommendations do not guarantee profit."

ru.TOOLS_BUTTON = "Инструменты"
ru.TOOLS_BACK = "К графику"
ru.TOOLS_PRICE = "АНАЛИЗ ЦЕНЫ"
ru.TOOLS_SUPPLY = "ПРЕДЛОЖЕНИЕ И КАЧЕСТВО ДАННЫХ"
ru.TOOLS_DELTA24 = "Динамика цены за 24 ч"
ru.TOOLS_MEDIAN_DEV = "Отклонение от медианы"
ru.TOOLS_POSITION = "Позиция в диапазоне"
ru.TOOLS_RANGE = "Разброс цен / средняя"
ru.TOOLS_AGE = "Последний замер цены"
ru.TOOLS_DROP24 = "Снижение предложения за 24 ч*"
ru.TOOLS_PRESSURE = "Снижение / доступное кол-во*"
ru.TOOLS_SAMPLES24 = "Наблюдений за 24 ч"
ru.TOOLS_CONFIDENCE = "Полнота наблюдений"
ru.TOOLS_CONF_LOW = "Низкая"
ru.TOOLS_CONF_MEDIUM = "Средняя"
ru.TOOLS_CONF_HIGH = "Хорошая"
ru.TOOLS_CALCULATOR = "КАЛЬКУЛЯТОР СДЕЛКИ (по последней цене аукциона)"
ru.TOOLS_BUY = "Закупка, золото"
ru.TOOLS_FEE = "Комиссия аукциона"
ru.TOOLS_NET = "После комиссии"
ru.TOOLS_PNL = "Оценка прибыли"
ru.TOOLS_BREAKEVEN = "Цена безубыточности"
ru.TOOLS_ENTER_BUY = "Введи цену закупки и нажми Enter для расчёта прибыли / ROI"
ru.TOOLS_GUIDE_DISCOUNT = "Цена ниже медианы наблюдений. Проверь объём и давность сканов."
ru.TOOLS_GUIDE_PREMIUM = "Цена выше медианы наблюдений. Учитывай возможность продажи."
ru.TOOLS_GUIDE_NEUTRAL = "Текущая цена близка к медиане наблюдений."
ru.TOOLS_GUIDE_INSUFFICIENT = "Недостаточно свежих замеров для рыночного сигнала."
ru.TOOLS_CAUTION = "* Уменьшение лотов может означать снятие, а не подтверждённые продажи."
ru.TRADING_CATEGORY = "Трейдинг"
ru.TRADING_DESC = "Анализ рынка, полнота данных и калькулятор доходности"
ru.TRADING_ENABLED = "Показывать инструменты трейдера в терминале рынка"
ru.TRADING_ADVICE = "Показывать сигналы о положении текущей цены"
ru.TRADING_FEE = "Оценочная комиссия аукциона"
ru.TRADING_MIN_SAMPLE = "Минимум наблюдений для сигналов"
ru.TRADING_CAVEAT = "* Расчёты используют сканы Auctionator, а не биржевой стакан. Продажи не подтверждены; сигналы не гарантируют прибыль."

-- TradeScope 3.5.0: purchase money input is now in separate denominations.
-- The last known Auctionator quote is the assumed unit sale price.
en.TOOLS_BUY = "Buy / item"
en.TOOLS_QUANTITY = "Quantity"
en.TOOLS_FEE_SHORT = "Fee"
en.TOOLS_UNIT_PRICE = "Sale / item"
en.TOOLS_UNIT_NET = "Net / item"
en.TOOLS_TOTAL_BUY = "Total purchase"
en.TOOLS_TOTAL_NET = "Total revenue"
en.TOOLS_TOTAL_PNL = "Estimated batch profit"
en.TOOLS_BREAKEVEN = "Break-even sell price / item"
en.TOOLS_ENTER_BUY = "Enter the purchase cost in gold / silver / copper and press Enter"
en.TOOLS_BREAK_EVEN_HELP = "Break-even selling price per item: the lowest listed price that covers your purchase after the Auction House fee."
en.TOOLS_PNL_HELP = "Assumes every purchased item sells at the latest known Auctionator price. No deposit loss, relisting, or price slippage included."
en.TOOLS_COIN_NOTE = "Enter whole gold, silver and copper separately (90 copper = 0g 0s 90c)."
en.TOOLS_CALCULATOR = "TRADE CALCULATOR (latest observed auction price)"
ru.TOOLS_BUY = "Закупка / шт."
ru.TOOLS_QUANTITY = "Количество"
ru.TOOLS_FEE_SHORT = "Комиссия"
ru.TOOLS_UNIT_PRICE = "Продажа / шт."
ru.TOOLS_UNIT_NET = "Чистая / шт."
ru.TOOLS_TOTAL_BUY = "Закупка всего"
ru.TOOLS_TOTAL_NET = "Выручка всего"
ru.TOOLS_TOTAL_PNL = "Прибыль за партию"
ru.TOOLS_BREAKEVEN = "Безубыточность / шт."
ru.TOOLS_ENTER_BUY = "Введи сумму в золоте, серебре и меди и нажми Enter"
ru.TOOLS_BREAK_EVEN_HELP = "Минимальная цена продажи одной штуки для возврата закупочной стоимости после комиссии аукциона."
ru.TOOLS_PNL_HELP = "Расчёт предполагает продажу всей партии по последней цене Auctionator. Потери депозита, перевыставление и изменение цен не учтены."
ru.TOOLS_COIN_NOTE = "Золото, серебро и медь вводятся отдельно (90 медных = 0з 0с 90м)."
ru.TOOLS_CALCULATOR = "КАЛЬКУЛЯТОР СДЕЛКИ (по последней цене Auctionator)"

-- Balance chart cursor: observed values, never interpolated amounts.
en.WALLET_CURSOR_AT = "Time"
en.WALLET_CURSOR_LAST = "Last recorded"
en.WALLET_CURSOR_NO_DATA = "No earlier balance recorded"
ru.WALLET_CURSOR_AT = "Время"
ru.WALLET_CURSOR_LAST = "Последний замер"
ru.WALLET_CURSOR_NO_DATA = "Нет предыдущего замера"

A.locale = (type(GetLocale) == "function" and GetLocale() or "enUS") == "ruRU" and "ruRU" or "enUS"
A.L = A.locale == "ruRU" and ru or en

-- TradeScope 4.0 help: market workstation commands.
en.HELP="/ats - market terminal; /ats pro - professional tools; /ats scanner | alerts | candles | activity | journal | craft | indicators | heatmap | quality | craftscan; /ats balance; /ats options"
ru.HELP="/ats - терминал; /ats pro - инструменты; /ats scanner | alerts | candles | activity | journal | craft | indicators | heatmap | quality | craftscan; /ats balance; /ats options"
