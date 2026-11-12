-- Run from repository root: texlua scripts/test-graph-cursor.lua
-- Lightweight UI stub: this tests chart data/cursor bookkeeping, not Blizzard rendering.
unpack = unpack or table.unpack
local now = 1794500000
local pointerX, pointerY = 0, 50
function time() return now end
function date(fmt, epoch) return os.date(fmt, epoch) end
function GetCursorPosition() return pointerX, pointerY end
function GetTime() return 100 end

local Widget = {}
Widget.__index = Widget
function Widget:new(parent)
  return setmetatable({parent = parent, visible = true, scripts = {}, level = 1}, Widget)
end
function Widget:GetParent() return self.parent end
function Widget:CreateFontString() return Widget:new(self) end
function Widget:CreateTexture() return Widget:new(self) end
function Widget:SetSize(w, h) self.width = w; self.height = h end
function Widget:SetWidth(w) self.width = w end
function Widget:SetHeight(h) self.height = h end
function Widget:GetWidth() return self.width or 0 end
function Widget:GetHeight() return self.height or 0 end
function Widget:GetFrameLevel() return self.level end
function Widget:SetFrameLevel(level) self.level = level end
function Widget:GetEffectiveScale() return 1 end
function Widget:GetLeft() return 0 end
function Widget:GetBottom() return 0 end
function Widget:SetPoint(...) self.point = {...} end
function Widget:ClearAllPoints() self.point = nil end
function Widget:SetScript(event, callback) self.scripts[event] = callback end
function Widget:Show() self.visible = true end
function Widget:Hide() self.visible = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function Widget:IsShown() return self.visible and (not self.parent or self.parent:IsShown()) end
function Widget:SetText(v) self.text = v end
function Widget:SetRotation(v) self.rotation = v end
function Widget:SetVertexColor(...) self.vertexColor = {...} end
for _, method in ipairs({"SetTexture", "SetTextColor", "SetJustifyH", "SetAlpha", "SetAllPoints", "EnableMouse", "EnableMouseWheel", "SetClampedToScreen", "SetScale", "SetFrameStrata"}) do
  Widget[method] = function() end
end
function CreateFrame(_, _, parent) return Widget:new(parent) end
UIParent = Widget:new(nil)

ATS = {
  db = {
    showLegend = true, showGrid = true, showDots = true,
    maxPlotPoints = 160, maWindow = 5, showMA = false,
    showTrendLine = false, combinedSalesBars = true,
    compactSummary = true, showInsights = false,
    maxCompareGapHours = 12, retentionDays = 30,
  },
  L = setmetatable({
    NO_DATA = "missing", CHART_CURSOR_REDUCTION = "decline",
    CHART_CURSOR_LAST = "last", CHART_CURSOR_NO_DATA = "no observation",
  }, {__index = function(_, k) return k end}),
}
local A = ATS
function A.Init() end
function A.Valid(x) return type(x) == "number" and x > 0 end
function A.Money(n) return tostring(n or "missing") end
function A.MoneyAxis(n) return tostring(n or "missing") end
function A.ChartHours() return 24 end
local observations = {}
function A.AllSamples() return observations end

assert(loadfile("Market/Analytics.lua"))()
function A.MarketMetrics()
  return {observations = 2, currentQuantity = 8, estimatedDrops24 = 4}
end
assert(loadfile("UI/Charts/Graph.lua"))()
local graph = A.NewGraph(UIParent)
graph.showItemHeader = false

-- The final observation occurs *exactly* at now (the right edge).
observations = {
  {t = now - 1800, price = 10000, quantity = 12},
  {t = now, price = 12000, quantity = 8},
}
A.RenderGraph(graph, "item:1", nil, "sales")
local sales = graph.charts.sales
assert(sales.hoverBucketCount == 24, "expected 24 sales buckets")
assert(sales.hoverBuckets[24] and sales.hoverBuckets[24].value == 4, "missing final decline")
assert(sales.hoverBuckets[24].lastAt == now, "last timestamp lost at right boundary")
pointerX, pointerY = sales.hitbox:GetWidth(), 50
sales.hitbox.scripts.OnUpdate(sales.hitbox, 0.1)
assert(sales.cursorTexts[2].text == "decline: 4", "right-edge hover lost the final bucket")
assert(sales.cursorTexts[3].text == "last: " .. date("%d.%m %H:%M:%S", now),
  "right-edge hover lost the final observation timestamp")
for _, bar in ipairs(sales.series.sales.bars) do
  if bar.visible then
    local x = bar.point[4]
    assert(x + bar:GetWidth() / 2 <= 546.01, "bar overlaps right-axis labels")
    assert(x - bar:GetWidth() / 2 >= 204.99, "bar exceeds left chart boundary")
  end
end

-- A single snapshot cannot prove a decline, even when it equals zero.
observations = {{t = now, price = 12000, quantity = 8}}
A.RenderGraph(graph, "item:1", nil, "sales")
sales.hitbox.scripts.OnUpdate(sales.hitbox, 0.1)
assert(sales.cursorTexts[2].text == "decline: missing", "one snapshot must not imply a zero decline")

-- Check the regular price graph is unaffected by the sale-cursor changes.
observations = {
  {t = now - 1800, price = 10000, quantity = 12},
  {t = now, price = 12000, quantity = 8},
}
A.RenderGraph(graph, "item:1", nil, "price")
local price = graph.charts.price
assert(price.series.price.lines[1] and price.series.price.lines[1].visible,
  "price line unexpectedly missing")
pointerX, pointerY = price.hitbox:GetWidth(), 50
price.hitbox.scripts.OnUpdate(price.hitbox, 0.1)
assert(price.cursorTexts[2].text == "CHART_LEGEND_PRICE: 12000",
  "price cursor is incorrect at the right boundary")
-- The 49-hour window has a partial final six-hour bucket: no 10th bucket.
graph.zoomHours = 49
A.RenderGraph(graph, "item:1", nil, "sales")
assert(sales.hoverBucketCount == 9 and sales.hoverBuckets[9].lastAt == now,
  "partial final bucket lost the boundary observation")
pointerX, pointerY = sales.hitbox:GetWidth(), 50
sales.hitbox.scripts.OnUpdate(sales.hitbox, 0.1)
assert(sales.cursorTexts[2].text == "decline: 4", "partial bucket hover has incorrect value")

-- The combined graph also reflows properly with the left legend hidden.
graph.zoomHours = nil
A.db.showLegend = false
A.RenderGraph(graph, "item:1", nil, "combined")
local combined = graph.charts.combined
assert(combined.hoverBucketCount == 24 and combined.hoverBuckets[24].lastAt == now,
  "combined chart lost the final observation")
pointerX, pointerY = combined.hitbox:GetWidth(), 50
combined.hitbox.scripts.OnUpdate(combined.hitbox, 0.1)
assert(combined.cursorTexts[4].text == "decline: 4", "combined chart right-edge decline is incorrect")
print("PASS: sale boundary, timestamp, no synthetic zero, plot clipping, price cursor, partial bucket, combined chart")
