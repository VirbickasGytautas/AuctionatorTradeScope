-- Auctionator TradeScope 4.1.0 -- WoW Forever / Lua 5.1
-- A fresh standalone addon; no legacy history is imported.
ATS = { version = "4.3.0-beta4", source = "none" }
local A = ATS
_G.AuctionatorTradeScope = A


function A.Valid(value)
  return type(value) == "number" and value > 0 and value < math.huge
end
-- Background-only transparency, preserving the readability of controls,
-- item icons, chart lines and tooltips belonging to the WoW client.
local opacitySurfaces={terminal={},pro={},tooltip={}}
local opacityFields={terminal="terminalTransparency",pro="proTransparency",tooltip="tooltipTransparency"}
local function opacityFactor(kind)
  local field=opacityFields[kind]
  local percentage=field and A.db and tonumber(A.db[field]) or 0
  percentage=math.max(0,math.min(100,percentage or 0))
  return 1-percentage/100
end
function A.TrackBackgroundTexture(kind,texture)
  if not opacitySurfaces[kind] or not texture then return end
  opacitySurfaces[kind][#opacitySurfaces[kind]+1]={texture=texture}
  if texture.SetAlpha then texture:SetAlpha(opacityFactor(kind)) end
end
function A.TrackBackgroundBackdrop(kind,frame,r,g,b)
  if not opacitySurfaces[kind] or not frame then return end
  opacitySurfaces[kind][#opacitySurfaces[kind]+1]={frame=frame,color={r,g,b}}
  if frame.SetBackdropColor then frame:SetBackdropColor(r,g,b,opacityFactor(kind)) end
end
function A.UpdateBackgroundTransparency(kind)
  local function apply(group)
    for i=1,#opacitySurfaces[group] do
      local entry=opacitySurfaces[group][i]
      if entry.texture and entry.texture.SetAlpha then
        entry.texture:SetAlpha(opacityFactor(group))
      elseif entry.frame and entry.frame.SetBackdropColor then
        local rgb=entry.color
        entry.frame:SetBackdropColor(rgb[1],rgb[2],rgb[3],opacityFactor(group))
      end
    end
  end
  if kind and opacitySurfaces[kind] then apply(kind)
  else apply("terminal");apply("pro");apply("tooltip") end
end

function A.Say(value)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff24d9e9TradeScope:|r " .. tostring(value))
  end
end
-- Native Blizzard money icons. GetCoinTextureString exists on supported clients;
-- a cropped Blizzard UI-MoneyIcons atlas is used when that helper is absent.
local function denomination(number, offset, iconSize)
  local size = iconSize or 12
  -- The atlas contains gold, silver, copper at x=0/16/32 of a 64x16 texture.
  local icon = "|TInterface\\MoneyFrame\\UI-MoneyIcons:" .. size .. ":" .. size .. ":0:0:64:16:" .. offset .. ":" .. (offset + 16) .. ":0:16|t"
  return tostring(number) .. icon
end
function A.Money(value)
  if type(value) ~= "number" or value < 0 or value >= math.huge then
    return (A.L and A.L.NO_DATA) or "-"
  end
  local n = math.floor(value + 0.5)
  if type(GetCoinTextureString) == "function" then
    local ok, result = pcall(GetCoinTextureString, n, 12)
    if ok and type(result) == "string" and result ~= "" then return result end
  end
  local gold, silver, copper = math.floor(n/10000), math.floor(n/100)%100, n%100
  local parts = {}
  if gold > 0 then parts[#parts+1] = denomination(gold,0) end
  if silver > 0 or (gold > 0 and copper > 0) then parts[#parts+1] = denomination(silver,16) end
  if copper > 0 or #parts == 0 then parts[#parts+1] = denomination(copper,32) end
  return table.concat(parts, " ")
end
function A.MoneyAxis(value)
  if type(value) ~= "number" or value < 0 then return "-" end
  local n=math.floor(value + .5)
  local g,s,c=math.floor(n/10000),math.floor(n/100)%100,n%100
  if g>0 then
    if s>0 then return denomination(g,0,11).." "..denomination(s,16,11) end
    return denomination(g,0,11)
  end
  if s>0 then
    if c>0 then return denomination(s,16,11).." "..denomination(c,32,11) end
    return denomination(s,16,11)
  end
  return denomination(c,32,11)
end
function A.RealmKey()
  return (GetRealmName() or "?") .. ":" .. (UnitFactionGroup("player") or "?")
end
function A.Init()
  if A.db then return end
  if type(AuctionatorTradeScopeDB) ~= "table" then AuctionatorTradeScopeDB = {} end
  A.db = AuctionatorTradeScopeDB
  local d = A.db
  d.realms = type(d.realms) == "table" and d.realms or {}
  d.watchlist = type(d.watchlist) == "table" and d.watchlist or {}
  d.enabled = d.enabled ~= false
  d.collectOnScan = d.collectOnScan ~= false
  d.collectOnHover = d.collectOnHover == true
  d.showTooltip = d.showTooltip ~= false
  -- 4.2.1.5: zero means fully opaque. Stored separately so changing one
  -- window never changes other windows or native Blizzard item tooltips.
  for _,field in ipairs({"terminalTransparency","proTransparency","tooltipTransparency"}) do
    d[field]=math.max(0,math.min(100,math.floor((tonumber(d[field]) or 0)+.5)))
  end
  d.showLegend = d.showLegend ~= false
  d.trackBalance = d.trackBalance == true
  -- Vendor-specific integration is retired on WoW Forever; no fake estimates.
  d.vendorAnalysis = false
  d.tradeFee = math.max(0, math.min(15, tonumber(d.tradeFee) or 5))
  d.showTradeTools = d.showTradeTools ~= false
  d.showTradeAdvice = d.showTradeAdvice ~= false
  d.tradeMinSamples = math.max(2, math.min(30, tonumber(d.tradeMinSamples) or 5))
  d.tradeBuys = type(d.tradeBuys) == "table" and d.tradeBuys or {}
  d.tradeQuantities = type(d.tradeQuantities) == "table" and d.tradeQuantities or {}
  d.itemCache = type(d.itemCache) == "table" and d.itemCache or {}
  d.itemNameIndex = type(d.itemNameIndex) == "table" and d.itemNameIndex or {}
  d.colors = type(d.colors) == "table" and d.colors or {}
  local defaults = {price={0.20,0.86,1.00},market={0.33,0.90,0.52},sales={1.00,0.66,0.24},ma={1.00,0.82,0.35},trend={0.75,0.57,1.00}}
  for name, rgb in pairs(defaults) do
    if type(d.colors[name]) ~= "table" then d.colors[name]={rgb[1],rgb[2],rgb[3]} end
  end
  d.showPriceChart = d.showPriceChart ~= false
  d.showMarketChart = d.showMarketChart == true
  d.showSalesChart = d.showSalesChart == true
  d.showCombinedChart = d.showCombinedChart == true
  d.combinedSalesBars = d.combinedSalesBars == true
  d.showGrid = d.showGrid ~= false
  d.showDots = d.showDots ~= false
  d.showMA = d.showMA == true
  d.showTrendLine = d.showTrendLine == true
  d.showInsights = d.showInsights ~= false
  d.showVolatility = d.showVolatility ~= false
  d.compactSummary = d.compactSummary ~= false
  d.maWindow = math.max(2, math.min(20, math.floor(tonumber(d.maWindow) or 5)))
  d.signalThreshold = math.max(1, math.min(30, tonumber(d.signalThreshold) or 8))
  d.minSignalSamples = math.max(3, math.min(20, math.floor(tonumber(d.minSignalSamples) or 5)))
  d.autoChanges = math.max(2, math.min(12, math.floor(tonumber(d.autoChanges) or 4)))
  d.maxPlotPoints = math.max(60, math.min(300, math.floor(tonumber(d.maxPlotPoints) or 160)))
  d.graphDelay = math.max(0, math.min(10, tonumber(d.graphDelay or d.delay) or 0.8))
  d.sampleInterval = math.max(30, math.min(3600, tonumber(d.sampleInterval) or 300))
  -- Largest safe interval for interpreting decreases in observed auction supply.
  -- Longer gaps have unknown activity and must never imply actual sales.
  d.maxCompareGapHours = math.max(1,math.min(48,tonumber(d.maxCompareGapHours) or 12))
  d.retentionDays = math.max(1, math.min(90, math.floor(tonumber(d.retentionDays) or 30)))
  d.customHours = math.max(1, math.min(2160, math.floor(tonumber(d.customHours) or 48)))
  local mode = d.chartMode
  if mode ~= "auto" and mode ~= "day" and mode ~= "week" and mode ~= "month" and mode ~= "custom" then mode = "auto" end
  d.chartMode = mode
  d.balance = type(d.balance) == "table" and d.balance or {}
  -- TradeScope 4: independent research, alert and workspace preferences.
  d.pro = type(d.pro) == "table" and d.pro or {}
  local p = d.pro
  local function default(name,value)
    if p[name] == nil then p[name] = value end
  end
  default("scannerEnabled",true)
  default("scannerShowUnknown",false)
  default("alertsEnabled",true)
  default("candlesEnabled",true)
  default("activityEnabled",true)
  default("journalEnabled",true)
  default("craftEnabled",true)
  default("indicatorsEnabled",true)
  default("heatmapEnabled",true)
  default("qualityEnabled",true)
  default("workspaceEnabled",true) -- Retained in SavedVariables for backward compatibility.
  default("craftscanEnabled",true)
  default("craftScannerMinProfitGold",0)
  default("craftScannerMinROI",0)
  default("craftScannerImportLimit",500)
  default("craftScannerSort","profit")
  default("craftScannerOnlyProfitable",false)
  default("craftInventoryEnabled",false)
  p.craftBatchCount = math.max(1,math.min(999,math.floor(
    tonumber(p.craftBatchCount) or 1)))
  p.craftExcluded = type(p.craftExcluded)=="table" and p.craftExcluded or {}
  p.craftStock = type(p.craftStock)=="table" and p.craftStock or {}
  -- 4.2.0: quality-aware opportunity scoring. Old scan results are preserved,
  -- and will be replaced on the next explicit scanner refresh.
  default("scannerMinScore",20)
  default("scannerMaxRisk",85)
  default("scannerMaxPriceGold",0) -- zero = no maximum
  default("scannerSort","score")
  default("scannerDiscount",15)
  default("scannerMinSamples",5)
  default("scannerFreshHours",48)
  default("scannerMaxVolatility",80)
  default("scannerMinSupply",0)
  default("alertCooldown",600)
  default("alertSound",true)
  default("alertChat",true)
  default("alertPopup",true)
  default("candleHours",24)
  default("candleBucketHours",1)
  default("showEMA",true)
  default("showBollinger",false)
  default("showRSI",true)
  default("showMACD",true)
  default("emaPeriod",10)
  default("rsiPeriod",14)
  default("bollPeriod",20)
  -- 4.1.1: indicator calculations use actual observed closing quotes per
  -- time slot. Existing observations and old preferences remain unchanged.
  default("indicatorBucketMinutes",15)
  default("indicatorGapHours",12)
  default("indicatorRSIPreview",true)
  default("activityWindowHours",24)
  default("journalFee",5)
  default("heatmapDays",30)
  default("minQualityScore",25)
  default("minimapEnabled",true)
  default("minimapExpanded",false)
  default("minimapAngle",220)
  default("minimapRadius",84)
  -- Migrate the old default radius to automatic rim alignment, but respect
  -- a non-default radius that the player deliberately set in a prior version.
  if p.minimapAutoPosition==nil then
    p.minimapAutoPosition=math.abs((tonumber(p.minimapRadius) or 84)-84)<0.5
  end
  default("workspaceShowPrice",true)
  default("workspaceShowSupply",true)
  default("workspaceShowQuality",false)
  default("workspaceShowPnl",true)
  default("workspaceShowWallet",false)
  p.minimapTools = type(p.minimapTools) == "table" and p.minimapTools or {}
  p.workspaces = type(p.workspaces) == "table" and p.workspaces or {}
  p.journal = type(p.journal) == "table" and p.journal or {}
  p.recipes = type(p.recipes) == "table" and p.recipes or {}
  p.alerts = type(p.alerts) == "table" and p.alerts or {}
  p.alertHistory = type(p.alertHistory) == "table" and p.alertHistory or {}
  p.alertStates = type(p.alertStates) == "table" and p.alertStates or {}
  default("alertMinSamples",5)
  default("alertMinQuality",25)
  default("alertHistoryLimit",150)
  default("alertDefaultRisk",80)

  p.savedScanner = type(p.savedScanner) == "table" and p.savedScanner or {}
  A.stats = A.stats or {scan = 0, hover = 0}
end

function A.HoveredItem()
  return A.state and A.state.key, A.state and A.state.legacy, A.state and A.state.link
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
  A.Init()
  local ok, err = pcall(A.RegisterOptions)
  if not ok then A.lastError = tostring(err); A.Say(A.L.ERROR .. tostring(err)) end
  A.Say(string.format(A.L.LOADED, A.version))
end)

-- /ats opens the market terminal; previous prefixes remain for old users.
SLASH_AUCTIONATORTRADESCOPE1 = "/ats"

SlashCmdList.AUCTIONATORTRADESCOPE = function(message)
  A.Init()
  local command, argument = string.match(message or "", "^(%S*)%s*(.-)$")
  if command == "options" or command == "config" then
    A.OpenOptions()
  elseif command == "balance" or command == "wallet" then
    A.ToggleBalanceWindow()
  elseif command == "scanner" or command == "alerts" or command == "candles" or
         command == "activity" or command == "journal" or command == "craft" or
         command == "indicators" or command == "heatmap" or command == "quality" or
         command == "workspace" or command == "craftscan" then
    if A.OpenProTool then A.OpenProTool(command == "workspace" and "craftscan" or command) end
  elseif command == "pro" or command == "tools" then
    if A.OpenProTool then A.OpenProTool("scanner") end
  elseif command == "test" then
    A.testUntil = GetTime() + 8
    A.Draw(nil, nil, true)
  elseif command == "stock" then
    if type(A.DebugCraftStock)=="function" then
      A.Say(A.DebugCraftStock(argument))
    end
  elseif command == "doctor" or command == "diagnostics" then
    local auctionatorLoaded=type(_G.IsAddOnLoaded)=="function" and _G.IsAddOnLoaded("Auctionator") or "unknown"
    A.Say("TradeScope v"..tostring(A.version).." | "..tostring(A.locale)..
      " | Auctionator loaded: "..tostring(auctionatorLoaded))
    A.Say("Auctionator scan state: "..tostring(A.scanHookStatus or "not reported"))
    A.Say("Market terminal: "..tostring(A.dashboard and A.dashboard.IsShown and A.dashboard:IsShown() or false)..
      ", Pro: "..tostring(A.proWindow and A.proWindow.IsShown and A.proWindow:IsShown() or false))
    A.Say("Craft stock: "..tostring(A.db.pro.craftInventoryEnabled)..
      ", legacy bags: "..tostring(type(_G.GetContainerItemInfo)=="function")..
      ", C_Container: "..tostring(type(_G.C_Container)=="table")..
      ", GetItemCount: "..tostring(type(_G.GetItemCount)=="function"))
    local support=A.craftEventSupport or {}
    A.Say("Bank events: OPEN="..tostring(support.BANKFRAME_OPENED)..
      ", CLOSE="..tostring(support.BANKFRAME_CLOSED)..
      ", SLOTS="..tostring(support.PLAYERBANKSLOTS_CHANGED))
    local stock=type(A.CraftStockInfo)=="function" and A.CraftStockInfo() or nil
    A.Say("Bank snapshot: "..tostring(stock and stock.bankTime or "unavailable")..
      ", bank open: "..tostring(stock and stock.bankOpen or false))
    A.Say("Minimap: "..(A.db.pro.minimapAutoPosition==false and "manual" or "auto")..
      ", angle="..tostring(A.db.pro.minimapAngle)..
      ", radius="..tostring(A.db.pro.minimapRadius))
    local engine=A.dataEngineStats or {}
    A.Say("Market data cache: "..tostring(engine.hits or 0).." hits / "..
      tostring(engine.misses or 0).." misses; normalised: "..
      tostring(engine.migrated or 0).." histories")
    A.Say("Max supply comparison gap: "..tostring(A.db.maxCompareGapHours).." hours")
    A.Say("Last Lua error: "..tostring(A.lastError or "none"))
  elseif command == "status" then
    A.Say(tostring(A.scanHookStatus or A.L.SCAN_NOT_CONNECTED))
    A.Say(string.format(A.L.STATUS_POINTS, tostring(A.stats.scan), tostring(A.stats.hover)))
    A.Say("Graph mode: " .. tostring(A.db.chartMode) .. "; error: " .. tostring(A.lastError))
  elseif command == "hours" then
    local h = tonumber(argument)
    if h and h >= 1 and h <= 2160 then
      A.db.customHours = math.floor(h); A.db.chartMode = "custom"
    end
    A.Say(A.L.PERIOD .. ": " .. tostring(A.ChartHours()) .. " h")
  elseif command == "add" or command == "watch" then
    local key, legacy, link = A.HoveredItem()
    if argument ~= "" then
      link = string.match(argument, "^%d+$") and ("item:" .. argument) or argument
      key = A.Key(link)
      legacy = A.LegacyKey(link)
    end
    if key then A.AddWatch(key, legacy, link); A.Say(A.L.ADDED_WATCH)
    else A.Say(A.L.SELECT_ITEM) end
  elseif command == "clear" then
    A.ShowClearConfirmation()
  elseif command == "help" then
    A.Say(A.L.HELP)
  elseif type(A.ToggleDashboard) == "function" then
    if command == "" or command == "show" or command == "toggle" then
      A.ToggleDashboard()
    else
      -- ID / item link is accepted directly for the market terminal.
      A.OpenDashboardItem(command .. (argument ~= "" and (" " .. argument) or ""))
    end
  end
end
