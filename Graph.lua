-- Auctionator TradeScope: four selectable graph panels; independent money/quantity axes.
-- Pure Blizzard Frame/Texture primitives; Lua 5.1 compatible.
local A = ATS
local WIDTH, LEFT, RIGHT = 654, 205, 546
local TOP_SPACE, GAP, FOOTER = 44, 7, 9
local ITEM_HEADER_HEIGHT = 38
local TICKS, TIME_TICKS = 4, 7
local PALETTE = {
  price = {0.20, 0.86, 1.00}, market = {0.33, 0.90, 0.52},
  sales = {1.00, 0.66, 0.24}, ma = {1.00, 0.82, 0.35},
  trend = {0.75, 0.57, 1.00},
}
local function color(key)
  local c=A.db and A.db.colors and A.db.colors[key]
  if type(c)=="table" and type(c[1])=="number" then return c end
  return PALETTE[key] or {0.8,0.8,0.8}
end
local SIZES = { combined = 246, price = 195, market = 177, sales = 181 }
local updateChartCursor, hideChartCursor

local function font(parent, width, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f:SetWidth(width)
  f:SetJustifyH(justify or "LEFT")
  return f
end
local function tex(parent, layer, color, alpha)
  local t = parent:CreateTexture(nil, layer)
  -- Two Lua backslashes in source are essential for WoW's actual texture path.
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(color[1], color[2], color[3], alpha or 1)
  return t
end
local function gridTexture(parent, w, h)
  local t = tex(parent, "BORDER", {0.31, 0.43, 0.56}, 0.29)
  t:SetSize(w, h)
  return t
end

local function itemQuality(subject)
  if type(GetItemInfo) ~= "function" or not subject then return nil end
  local ok, _, _, quality = pcall(GetItemInfo, subject)
  if ok and type(quality) == "number" then return quality end
end

local function qualityColor(quality)
  if type(GetItemQualityColor) == "function" and type(quality) == "number" then
    local ok, r, g, b = pcall(GetItemQualityColor, quality)
    if ok and type(r) == "number" then return r, g, b end
  end
  return 1, 0.85, 0.40
end

local function chart(parent, kind)
  local height = SIZES[kind]
  local c = CreateFrame("Frame", nil, parent)
  c.kind, c.height = kind, height
  c:SetSize(WIDTH, height)
  c.bottom, c.top = 34, kind == "combined" and height - 44 or height - 30
  c.series = {}
  c.vgrid, c.hgrid, c.ticks, c.rightTicks, c.dates = {}, {}, {}, {}, {}
  c.title = font(c, 245)
  c.title:SetPoint("TOPLEFT", c, "TOPLEFT", 12, -6)
  local accent = color(kind=="combined" and "price" or kind)
  c.title:SetTextColor(accent[1], accent[2], accent[3])
  local stripe = tex(c, "ARTWORK", accent, 0.75)
  stripe:SetSize(3, c.top - c.bottom)
  stripe:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", LEFT - 6, c.bottom)
  c.stripe=stripe
  c.legend = font(c, 330, "RIGHT")
  c.legend:SetPoint("TOPRIGHT", c, "TOPRIGHT", -13, -6)
  c.legend:SetTextColor(0.69, 0.85, 0.95)
  c.legend:Hide()
  c.legendRows={}
  for k=1,5 do
    local swatch=tex(c,"OVERLAY",color("price"),1)
    swatch:SetSize(9,9)
    swatch:SetPoint("TOPLEFT",c,"TOPLEFT",14,-61-(k-1)*24)
    local label=font(c,94,"LEFT")
    label:SetPoint("LEFT",swatch,"RIGHT",6,0)
    c.legendRows[k]={swatch=swatch,text=label}
  end
  c.empty = font(c, RIGHT - LEFT - 12, "CENTER")
  c.empty:SetPoint("CENTER", c, "BOTTOMLEFT", (LEFT + RIGHT)/2, (c.top + c.bottom)/2)
  c.empty:SetTextColor(0.67, 0.77, 0.84)
  for i = 1, TIME_TICKS do
    local x = LEFT + (i-1)*(RIGHT-LEFT)/(TIME_TICKS-1)
    local v = gridTexture(c, 1, c.top - c.bottom)
    v:SetPoint("BOTTOM", c, "BOTTOMLEFT", x, c.bottom)
    c.vgrid[i] = v
    local dateLabel = font(c, 54, "CENTER")
    dateLabel:SetPoint("BOTTOM", c, "BOTTOMLEFT", x, 7)
    c.dates[i] = dateLabel
  end
  for i = 1, TICKS + 1 do
    local y = c.bottom + (i-1)*(c.top-c.bottom)/TICKS
    local h = gridTexture(c, RIGHT - LEFT, 1)
    h:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", LEFT, y)
    c.hgrid[i] = h
    local l = font(c, LEFT-17, "RIGHT")
    l:SetPoint("RIGHT", c, "BOTTOMLEFT", LEFT-9, y)
    c.ticks[i] = l
    local r = font(c, WIDTH-RIGHT-11, "LEFT")
    r:SetPoint("LEFT", c, "BOTTOMLEFT", RIGHT+8, y)
    r:SetTextColor(PALETTE.market[1], PALETTE.market[2], PALETTE.market[3])
    c.rightTicks[i] = r
  end
  -- Plot-specific mouse capture keeps zoom on older WoW clients and makes
  -- each of the four charts interactive in both the tooltip and terminal.
  local hit = CreateFrame("Frame", nil, c)
  hit:SetSize(RIGHT-LEFT, c.top-c.bottom)
  hit:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", LEFT, c.bottom)
  hit:SetFrameLevel(c:GetFrameLevel()+1)
  hit:EnableMouse(true)
  if hit.EnableMouseWheel then hit:EnableMouseWheel(true) end
  hit:SetScript("OnMouseWheel", function(_,delta)
    if A.ZoomGraph then A.ZoomGraph(c:GetParent(),delta) end
  end)
  hit:SetScript("OnEnter", function()
    if c:GetParent() == A.graph then A.graphHovered=true end
    if updateChartCursor then updateChartCursor(c) end
  end)
  hit:SetScript("OnLeave", function()
    if hideChartCursor then hideChartCursor(c) end
    if c:GetParent() == A.graph and A.graph
       and (not A.graph.IsMouseOver or not A.graph:IsMouseOver()) then
      A.graphHovered=false
      A.graphLeftAt=GetTime()
    end
  end)
  hit:SetScript("OnUpdate", function(self,elapsed)
    self.elapsed=(self.elapsed or 0)+elapsed
    if self.elapsed>=0.04 then
      self.elapsed=0
      if updateChartCursor then updateChartCursor(c) end
    end
  end)
  c.hitbox=hit
  local overlay=CreateFrame("Frame",nil,c)
  overlay:SetAllPoints(c)
  overlay:SetFrameLevel(c:GetFrameLevel()+2)
  overlay:EnableMouse(false)
  c.cursorOverlay=overlay
  c.cursorLine=tex(overlay,"OVERLAY",{0.70,0.87,1.00},0.75)
  c.cursorLine:SetSize(1,c.top-c.bottom)
  c.cursorLine:Hide()
  c.cursorDots={}
  for _,name in ipairs({"price","market","sales"}) do
    local dot=tex(overlay,"OVERLAY",color(name),1)
    dot:SetSize(7,7)
    dot:Hide()
    c.cursorDots[name]=dot
  end
  local box=CreateFrame("Frame",nil,overlay)
  box:SetSize(282,108)
  box:EnableMouse(false)
  local background=tex(box,"BACKGROUND",{0.018,0.028,0.055},1)
  background:SetAllPoints(box)
  if A.TrackBackgroundTexture then A.TrackBackgroundTexture("tooltip",background) end
  local edge=tex(box,"BORDER",{0.66,0.55,0.30},0.85)
  edge:SetSize(282,1)
  edge:SetPoint("TOPLEFT",box,"TOPLEFT",0,0)
  c.cursorTexts={}
  for i=1,5 do
    local line=font(box,270,"LEFT")
    line:SetPoint("TOPLEFT",box,"TOPLEFT",7,-5-(i-1)*20)
    line:SetTextColor(i==1 and 1 or 0.80,i==1 and 0.84 or 0.88,i==1 and 0.38 or 0.95)
    c.cursorTexts[i]=line
  end
  box:Hide()
  c.cursorBox=box
  c:SetScript("OnHide",function(self) if hideChartCursor then hideChartCursor(self) end end)
  return c
end

function A.NewGraph(parent)
  local f = CreateFrame("Frame", nil, parent or UIParent)
  f:SetWidth(WIDTH)
  f:SetFrameStrata("TOOLTIP")
  f:SetFrameLevel(100)
  f:EnableMouse(true)
  if f.EnableMouseWheel then f:EnableMouseWheel(true) end
  f:SetScript("OnMouseWheel",function(self,delta) if A.ZoomGraph then A.ZoomGraph(self,delta) end end)
  f:SetScript("OnEnter",function(self) if self==A.graph then A.graphHovered=true end end)
  f:SetScript("OnLeave",function(self) if self==A.graph then A.graphHovered=false;A.graphLeftAt=GetTime() end end)
  f:SetScript("OnHide",function(self) if self==A.graph then A.graphHovered=false end end)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  local isTerminal=parent and parent.isTradeScopeTerminal
  local bg = tex(f, "BACKGROUND", {0.018, 0.025, 0.043}, isTerminal and 0 or 1)
  bg:SetAllPoints(f)
  -- Embedded charts share the terminal's single background. Floating item
  -- graphs still use the independent tooltip transparency setting.
  if not isTerminal and A.TrackBackgroundTexture then
    A.TrackBackgroundTexture("tooltip",bg)
  end
  f.itemIcon = f:CreateTexture(nil, "ARTWORK")
  f.itemIcon:SetSize(28, 28)
  f.itemIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
  f.itemIconBorder = tex(f, "BORDER", {0.78, 0.64, 0.22}, 0.95)
  f.itemIconBorder:SetSize(30, 30)
  f.itemIconBorder:SetPoint("CENTER", f.itemIcon, "CENTER", 0, 0)
  f.itemName = font(f, WIDTH - 60)
  f.itemName:SetPoint("TOPLEFT", f, "TOPLEFT", 48, -8)
  f.itemName:SetJustifyH("LEFT")
  f.itemName:SetTextColor(1, 0.82, 0.23)
  f.itemDetails = font(f, WIDTH - 60)
  f.itemDetails:SetPoint("TOPLEFT", f, "TOPLEFT", 48, -25)
  f.itemDetails:SetTextColor(0.70, 0.83, 0.90)
  f.itemIcon:Hide(); f.itemIconBorder:Hide(); f.itemName:Hide(); f.itemDetails:Hide()
  f.header = font(f, WIDTH - 20)
  f.header:SetTextColor(1, 0.85, 0.40)
  f.subheader = font(f, WIDTH - 20)
  f.subheader:SetTextColor(0.70, 0.83, 0.90)
  f.charts = {
    combined = chart(f, "combined"), price = chart(f, "price"),
    market = chart(f, "market"), sales = chart(f, "sales"),
  }
  f.separators = {}
  for i = 1, 3 do
    local line = gridTexture(f, WIDTH - 20, 1)
    line:Hide(); f.separators[i] = line
  end
  f:Hide()
  return f
end

function A.Hide() if A.graph then A.graph:Hide() end end

local function niceStep(n)
  if not n or n <= 1 then return 1 end
  local magnitude = 10 ^ math.floor(math.log(n) / math.log(10))
  local x = n / magnitude
  if x <= 1 then return magnitude end
  if x <= 2 then return 2*magnitude end
  if x <= 5 then return 5*magnitude end
  return 10*magnitude
end
local function bounds(low, high, money, fromZero)
  if low == nil or high == nil then return 0, TICKS, 1 end
  local pad
  if money then
    pad = high > low and math.max(1,(high-low)*0.09) or math.max(2,high*0.01)
  else
    pad = high > low and math.max(1,(high-low)*0.05) or 1
  end
  local bottom = fromZero and 0 or math.max(0, low - pad)
  local top = high + pad
  local step = niceStep((top-bottom)/TICKS)
  if not fromZero then bottom = math.max(0, math.floor(bottom/step)*step) end
  while bottom + step*TICKS < top do
    step = niceStep(step * 1.001)
    if not fromZero then bottom = math.max(0, math.floor(math.max(0,low-pad)/step)*step) end
  end
  return bottom, bottom + step*TICKS, step
end
local function hideSeries(c)
  for _, s in pairs(c.series) do
    for i = 1, #s.lines do s.lines[i]:Hide() end
    for i = 1, #s.dots do s.dots[i]:Hide() end
    for i = 1, #s.bars do s.bars[i]:Hide() end
  end
  c.empty:Hide()
end
local function seriesPool(c, key)
  local p = c.series[key]
  if not p then
    p = { lines = {}, dots = {}, bars = {} }
    c.series[key] = p
  end
  return p
end
local function drawDot(c, pool, index, x, y, color, small)
  if not A.db.showDots then return end
  local dot = pool.dots[index]
  if not dot then dot = tex(c, "OVERLAY", color, 1); pool.dots[index] = dot end
  dot:SetVertexColor(color[1],color[2],color[3],1)
  dot:SetSize(small and 3 or 5, small and 3 or 5)
  dot:ClearAllPoints()
  dot:SetPoint("CENTER", c, "BOTTOMLEFT", x, y)
  dot:Show()
end
local function drawSegment(c, pool, used, x1, y1, x2, y2, color, thickness)
  local dx,dy = x2-x1, y2-y1
  local length = math.sqrt(dx*dx + dy*dy)
  if length < 0.1 then return used end
  if not A.segmentMode then
    local probe = tex(c, "ARTWORK", color, 1)
    A.segmentMode = type(probe.SetRotation) == "function" and "rotation" or "pixels"
    probe:Hide()
  end
  if A.segmentMode == "rotation" then
    used = used + 1
    local line = pool.lines[used]
    if not line then line = tex(c, "ARTWORK", color, 0.95); pool.lines[used] = line end
    line:SetVertexColor(color[1],color[2],color[3],0.95)
    line:SetSize(length, thickness or 2)
    line:ClearAllPoints()
    line:SetPoint("CENTER", c, "BOTTOMLEFT", (x1+x2)/2, (y1+y2)/2)
    local angle
    if math.atan2 then angle = math.atan2(dy,dx)
    elseif dx == 0 then angle = dy > 0 and math.pi/2 or -math.pi/2
    else angle = math.atan(dy/dx); if dx < 0 then angle = angle + math.pi end end
    line:SetRotation(angle)
    line:Show()
  else
    -- Limited number of tiny pixels for old clients without Texture:SetRotation.
    local steps = math.min(32, math.max(1,math.ceil(length/4)))
    for j=1,steps do
      used = used+1
      local point = pool.lines[used]
      if not point then point = tex(c,"ARTWORK",color,0.94); pool.lines[used]=point end
      point:SetVertexColor(color[1],color[2],color[3],0.94)
      point:SetSize(2,2); point:ClearAllPoints()
      point:SetPoint("CENTER",c,"BOTTOMLEFT",x1+dx*j/steps,y1+dy*j/steps)
      point:Show()
    end
  end
  return used
end
local function pointsFor(samples, name, startTime, now)
  local out={}
  for i=1,#samples do
    local p=samples[i]
    local v=p[name]
    if type(v)=="number" and v>=0 and p.t>=startTime and p.t<=now then
      out[#out+1]={t=p.t,v=v}
    end
  end
  return out
end
local function reduce(points)
  local limit = A.db.maxPlotPoints
  if #points<=limit then return points end
  local out={}
  local bucket = math.ceil(#points / math.max(1, math.floor(limit/4)))
  for first=1,#points,bucket do
    local last=math.min(#points,first+bucket-1)
    local low,high=first,first
    for i=first+1,last do
      if points[i].v < points[low].v then low=i end
      if points[i].v > points[high].v then high=i end
    end
    local arr={first,low,high,last}
    table.sort(arr)
    local prev
    for i=1,#arr do
      if arr[i]~=prev then out[#out+1]=points[arr[i]]; prev=arr[i] end
    end
  end
  return out
end
local function minmax(points)
  local lo,hi
  for i=1,#points do
    local v=points[i].v
    lo=math.min(lo or v,v); hi=math.max(hi or v,v)
  end
  return lo,hi
end

-- Cursor values come from actual observations, NOT interpolated plot lines.
-- Price/supply use the last recorded value at or before the hovered time.
local function lastValueAt(values,t)
  local low,high,found=1,#values,nil
  while low<=high do
    local mid=math.floor((low+high)/2)
    if values[mid].t<=t then
      found=values[mid]
      low=mid+1
    else high=mid-1 end
  end
  return found
end

hideChartCursor=function(c)
  if c.cursorLine then c.cursorLine:Hide() end
  if c.cursorBox then c.cursorBox:Hide() end
  if c.cursorDots then
    for _,dot in pairs(c.cursorDots) do dot:Hide() end
  end
  c.cursorTime=nil
end

local function cursorDot(c,name,x,value,axis)
  local dot=c.cursorDots[name]
  if not dot then return end
  if type(value)~="number" or not axis then dot:Hide();return end
  local lo,hi=axis[1],axis[2]
  if type(lo)~="number" or type(hi)~="number" then dot:Hide();return end
  local y=c.bottom+math.max(0,math.min(1,(value-lo)/math.max(1,hi-lo)))*(c.top-c.bottom)
  local rgb=color(name)
  dot:SetVertexColor(rgb[1],rgb[2],rgb[3],1)
  dot:ClearAllPoints()
  dot:SetPoint("CENTER",c,"BOTTOMLEFT",x,y)
  dot:Show()
end

local function salesBucketAt(c,t)
  if not c.hoverBuckets or not c.hoverBucketSeconds then return nil end
  local index=math.floor((t-c.hoverStart)/c.hoverBucketSeconds)+1
  return c.hoverBuckets[index]
end

updateChartCursor=function(c)
  local hit=c.hitbox
  if not hit or not c:IsShown() or not c.hoverStart
     or not c.hoverSpan or type(GetCursorPosition)~="function" then
    hideChartCursor(c);return
  end
  local screenX,screenY=GetCursorPosition()
  local scale=hit:GetEffectiveScale()
  local x0,y0=hit:GetLeft(),hit:GetBottom()
  if not scale or scale<=0 or not x0 or not y0 or
     type(screenX)~="number" or type(screenY)~="number" then
    hideChartCursor(c);return
  end
  local x=screenX/scale-x0
  local y=screenY/scale-y0
  local w,h=RIGHT-LEFT,c.top-c.bottom
  if x<0 or x>w or y<0 or y>h then hideChartCursor(c);return end
  local t=math.floor(c.hoverStart+(x/w)*c.hoverSpan)
  local price=lastValueAt(c.hoverPrices or {},t)
  local qty=lastValueAt(c.hoverQuantities or {},t)
  local bucket=salesBucketAt(c,t)
  c.cursorLine:ClearAllPoints()
  c.cursorLine:SetPoint("BOTTOMLEFT",c,"BOTTOMLEFT",LEFT+x,c.bottom)
  c.cursorLine:Show()
  local kind=c.kind
  if kind=="combined" or kind=="price" then
    cursorDot(c,"price",LEFT+x,price and price.v,c.hoverPriceAxis)
  else c.cursorDots.price:Hide() end
  if kind=="combined" or kind=="market" then
    cursorDot(c,"market",LEFT+x,qty and qty.v,
      kind=="combined" and c.hoverQuantityAxis or c.hoverPriceAxis)
  else c.cursorDots.market:Hide() end
  if kind=="sales" then
    cursorDot(c,"sales",LEFT+x,bucket and bucket.value,c.hoverPriceAxis)
  else c.cursorDots.sales:Hide() end

  local content={date("%d.%m.%Y %H:%M:%S",t)}
  if kind=="combined" or kind=="price" then
    content[#content+1]=A.L.CHART_LEGEND_PRICE .. ": " .. (price and A.Money(price.v) or A.L.NO_DATA)
  end
  if kind=="combined" or kind=="market" then
    content[#content+1]=A.L.CHART_HEADER_MARKET .. ": " ..
      (qty and A.FmtCount(qty.v) or A.L.NO_DATA)
  end
  if kind=="sales" or (kind=="combined" and A.db.combinedSalesBars) then
    content[#content+1]=A.L.CHART_CURSOR_REDUCTION .. ": " ..
      (bucket and A.FmtCount(bucket.value) or A.L.NO_DATA)
  end
  local latest
  if kind=="market" then latest=qty and qty.t
  elseif kind=="sales" then latest=bucket and bucket.lastAt
  elseif kind=="combined" then latest=math.max(price and price.t or 0,qty and qty.t or 0)
  else latest=price and price.t end
  if latest and latest>0 then
    content[#content+1]=A.L.CHART_CURSOR_LAST .. ": " .. date("%d.%m %H:%M:%S",latest)
  else
    content[#content+1]=A.L.CHART_CURSOR_NO_DATA
  end
  for i=1,#c.cursorTexts do c.cursorTexts[i]:SetText(content[i] or "") end
  local box=c.cursorBox
  local boxX=LEFT+x+13
  if boxX+box:GetWidth()>WIDTH-7 then boxX=LEFT+x-box:GetWidth()-13 end
  boxX=math.max(4,math.min(WIDTH-box:GetWidth()-4,boxX))
  local boxY=math.max(3,math.min(c.height-box:GetHeight()-3,c.bottom+y+12))
  box:ClearAllPoints()
  box:SetPoint("BOTTOMLEFT",c,"BOTTOMLEFT",boxX,boxY)
  box:Show()
end
local function drawPoints(c, name, points, color, minValue, maxValue, startTime, now, thickness)
  local pool=seriesPool(c,name)
  local use=0; local previousX,previousY
  local span=math.max(1,now-startTime)
  points=reduce(points)
  for i=1,#points do
    local p=points[i]
    local x=LEFT+(p.t-startTime)/span*(RIGHT-LEFT)
    local y=c.bottom+(p.v-minValue)/math.max(1,maxValue-minValue)*(c.top-c.bottom)
    drawDot(c,pool,i,x,y,color,thickness==1)
    if previousX then use=drawSegment(c,pool,use,previousX,previousY,x,y,color,thickness) end
    previousX,previousY=x,y
  end
end
local function drawRegression(c, points, lo, hi, fromTime, now)
  if #points<2 or not A.db.showTrendLine then return end
  local n, sx,sy,sxx,sxy=0,0,0,0,0
  for i=1,#points do
    local x=points[i].t-fromTime
    local y=points[i].v
    n=n+1; sx=sx+x;sy=sy+y;sxx=sxx+x*x;sxy=sxy+x*y
  end
  local d=n*sxx-sx*sx
  if math.abs(d)<0.000001 then return end
  local m=(n*sxy-sx*sy)/d
  local b=(sy-m*sx)/n
  local y1=math.max(lo,math.min(hi,b+m*(points[1].t-fromTime)))
  local y2=math.max(lo,math.min(hi,b+m*(points[#points].t-fromTime)))
  local span=math.max(1,now-fromTime)
  local x1=LEFT+(points[1].t-fromTime)/span*(RIGHT-LEFT)
  local x2=LEFT+(points[#points].t-fromTime)/span*(RIGHT-LEFT)
  local cy1=c.bottom+(y1-lo)/math.max(1,hi-lo)*(c.top-c.bottom)
  local cy2=c.bottom+(y2-lo)/math.max(1,hi-lo)*(c.top-c.bottom)
  drawSegment(c,seriesPool(c,"trend"),0,x1,cy1,x2,cy2,color("trend"),1)
end
local function drawAverage(c, points, lo, hi, fromTime, now)
  if #points<2 or not A.db.showMA then return end
  local window=A.db.maWindow
  local moving={}
  local sum=0
  for i=1,#points do
    sum=sum+points[i].v
    if i>window then sum=sum-points[i-window].v end
    if i>=2 then moving[#moving+1]={t=points[i].t,v=sum/math.min(i,window)} end
  end
  drawPoints(c,"ma",moving,color("ma"),lo,hi,fromTime,now,1)
end
local function axes(c,leftBounds,rightBounds,hours,now)
  local startTime=now-math.max(3600,hours*3600)
  local l0,l1,lstep,lMoney=unpack(leftBounds)
  local r0,r1,rstep
  if rightBounds then r0,r1,rstep=rightBounds[1],rightBounds[2],rightBounds[3] end
  for i=1,TICKS+1 do
    local l=c.ticks[i]
    l:SetText(lMoney and A.MoneyAxis(l0+(i-1)*lstep) or A.FmtCount(l0+(i-1)*lstep))
    local right=c.rightTicks[i]
    if rightBounds then right:SetText(A.FmtCount(r0+(i-1)*rstep)); right:Show()
    else right:Hide() end
  end
  for i=1,TIME_TICKS do
    local t=startTime+(i-1)*(now-startTime)/(TIME_TICKS-1)
    c.dates[i]:SetText(date(hours<=48 and "%H:%M" or "%d.%m",math.floor(t)))
    if A.db.showGrid then c.vgrid[i]:Show() else c.vgrid[i]:Hide() end
  end
  for i=1,TICKS+1 do
    if A.db.showGrid then c.hgrid[i]:Show() else c.hgrid[i]:Hide() end
  end
  return startTime
end

local function drawBars(c, samples, hours, now, axisMax, combined)
  local bars,bucketSeconds,observed=A.SalesSeries(samples,hours,now)
  if observed<2 then return false end
  local maxBar=1
  for i=1,#bars do maxBar=math.max(maxBar,bars[i].value) end
  local pool=seriesPool(c,"sales")
  local startTime=now-hours*3600
  local span=hours*3600
  local width=math.max(2,math.min(24,bucketSeconds/span*(RIGHT-LEFT)*0.73))
  for i=1,#bars do
    local point=bars[i]
    local x=LEFT+(point.t-startTime)/span*(RIGHT-LEFT)
    local height
    if combined then
      -- Composite bars are scaled independently to 32px for readability.
      height=(point.value/maxBar)*32
    else
      height=point.value/math.max(1,axisMax)*(c.top-c.bottom)
    end
    local bar=pool.bars[i]
    if not bar then bar=tex(c,"ARTWORK",color("sales"),0.86);pool.bars[i]=bar end
    local col=color("sales")
    bar:SetVertexColor(col[1],col[2],col[3],0.86)
    bar:ClearAllPoints()
    bar:SetSize(width,math.max(2,height))
    bar:SetPoint("BOTTOM",c,"BOTTOMLEFT",x,c.bottom)
    bar:Show()
  end
  return true
end
local function setLegend(c,names)
  for i=1,#c.legendRows do
    local row=c.legendRows[i]
    local name=names[i]
    if name and A.db.showLegend then
      local rgb=color(name)
      row.swatch:SetVertexColor(rgb[1],rgb[2],rgb[3],1)
      row.text:SetText(A.L["CHART_LEGEND_"..string.upper(name)] or name)
      row.swatch:Show();row.text:Show()
    else
      row.swatch:Hide();row.text:Hide()
    end
  end
end
-- The legend takes its own column only while enabled. Reflow the plot area
-- dynamically, including axes, grid and data points, when the option changes.
-- Market Terminal has ONE chart size for every mode. Hover graphs keep their
-- natural height, preserving existing tooltip placement and scrolling.
local function setTerminalChartSize(c,graph)
  local height=graph and graph.terminalChartHeight
  if not height then return end
  local top=height-44
  if c.height==height and c.top==top then return end
  c.height=height
  c.top=top
  c:SetSize(WIDTH,height)
  local plotHeight=c.top-c.bottom
  c.stripe:SetHeight(plotHeight)
  c.cursorLine:SetHeight(plotHeight)
  for i=1,#c.vgrid do c.vgrid[i]:SetHeight(plotHeight) end
end
local function reflowChart(c)
  setTerminalChartSize(c,c:GetParent())
  LEFT = A.db.showLegend and 205 or 117
  RIGHT = A.db.showLegend and 546 or 562
  -- Terminal raises its graph frame level after creation; raise plot capture
  -- and overlay with it so mouse hover and the popup remain above the grid.
  local graph=c:GetParent()
  if graph then c:SetFrameLevel(graph:GetFrameLevel()+1) end
  if c.hitbox then c.hitbox:SetFrameLevel(c:GetFrameLevel()+1) end
  if c.cursorOverlay then c.cursorOverlay:SetFrameLevel(c:GetFrameLevel()+2) end
  if c.cursorBox and c.cursorOverlay then
    c.cursorBox:SetFrameLevel(c.cursorOverlay:GetFrameLevel()+1)
  end
  if c.hitbox then
    c.hitbox:ClearAllPoints()
    c.hitbox:SetPoint("BOTTOMLEFT",c,"BOTTOMLEFT",LEFT,c.bottom)
    c.hitbox:SetSize(RIGHT-LEFT,c.top-c.bottom)
  end
  c.stripe:ClearAllPoints()
  c.stripe:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", LEFT - 6, c.bottom)
  c.empty:SetWidth(RIGHT - LEFT - 12)
  c.empty:ClearAllPoints()
  c.empty:SetPoint("CENTER", c, "BOTTOMLEFT", (LEFT + RIGHT) / 2, (c.top + c.bottom) / 2)
  for i=1,TIME_TICKS do
    local x=LEFT + (i-1) * (RIGHT-LEFT) / (TIME_TICKS-1)
    c.vgrid[i]:ClearAllPoints()
    c.vgrid[i]:SetPoint("BOTTOM", c, "BOTTOMLEFT", x, c.bottom)
    c.dates[i]:ClearAllPoints()
    c.dates[i]:SetPoint("BOTTOM", c, "BOTTOMLEFT", x, 7)
  end
  for i=1,TICKS+1 do
    local y=c.bottom+(i-1)*(c.top-c.bottom)/TICKS
    c.hgrid[i]:SetWidth(RIGHT-LEFT)
    c.hgrid[i]:ClearAllPoints()
    c.hgrid[i]:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", LEFT, y)
    c.ticks[i]:SetWidth(LEFT-17)
    c.ticks[i]:ClearAllPoints()
    c.ticks[i]:SetPoint("RIGHT", c, "BOTTOMLEFT", LEFT-9, y)
    c.rightTicks[i]:SetWidth(WIDTH-RIGHT-11)
    c.rightTicks[i]:ClearAllPoints()
    c.rightTicks[i]:SetPoint("LEFT", c, "BOTTOMLEFT", RIGHT+8, y)
  end
end

local function drawOne(c,samples,hours,now)
  reflowChart(c)
  hideSeries(c)
  local accent=color(c.kind=="combined" and "price" or c.kind)
  c.title:SetTextColor(accent[1],accent[2],accent[3])
  c.stripe:SetVertexColor(accent[1],accent[2],accent[3],.75)
  for i=1,#c.rightTicks do
    local rgb=color("market")
    c.rightTicks[i]:SetTextColor(rgb[1],rgb[2],rgb[3])
  end
  local startTime=now-hours*3600
  local kind=c.kind
  local pp=pointsFor(samples,"price",startTime,now)
  local qq=pointsFor(samples,"quantity",startTime,now)
  local pLow,pHigh=minmax(pp)
  local qLow,qHigh=minmax(qq)
  local pm0,pm1,pmStep=bounds(pLow,pHigh,true,false)
  local qm0,qm1,qmStep=bounds(qLow,qHigh,false,false)
  c.hoverPrices=pointsFor(samples,"price",0,now)
  c.hoverQuantities=pointsFor(samples,"quantity",0,now)
  c.hoverStart=startTime
  c.hoverSpan=math.max(3600,hours*3600)
  c.hoverPriceAxis=kind=="market" and {qm0,qm1} or {pm0,pm1}
  c.hoverQuantityAxis={qm0,qm1}
  c.hoverBuckets=nil;c.hoverBucketSeconds=nil
  if kind=="sales" or (kind=="combined" and A.db.combinedSalesBars) then
    local buckets,seconds=A.SalesSeries(samples,hours,now)
    c.hoverBucketSeconds=seconds
    c.hoverBuckets={}
    for i=1,#buckets do
      local b=buckets[i]
      local index=math.floor((b.t-startTime)/seconds)+1
      -- Bucket data are observations, not values carried across empty intervals.
      c.hoverBuckets[index]=b
    end
    for i=1,#samples do
      local sample=samples[i]
      if type(sample.quantity)=="number" and sample.t>=startTime and sample.t<=now then
        local index=math.floor((sample.t-startTime)/seconds)+1
        local bucket=c.hoverBuckets[index]
        if bucket then bucket.lastAt=sample.t end
      end
    end
  end
  local hasData=false
  if kind=="combined" then
    axes(c,{pm0,pm1,pmStep,true},{qm0,qm1,qmStep},hours,now)
    c.title:SetText(A.L.CHART_TITLE_COMBINED)
    local names={"price","market"}
    if A.db.combinedSalesBars then names[#names+1]="sales" end
    if A.db.showMA then names[#names+1]="ma" end
    if A.db.showTrendLine then names[#names+1]="trend" end
    setLegend(c,names)
    if #pp>0 then
      drawPoints(c,"price",pp,color("price"),pm0,pm1,startTime,now,2)
      drawAverage(c,pp,pm0,pm1,startTime,now)
      drawRegression(c,pp,pm0,pm1,startTime,now)
      hasData=true
    end
    if #qq>0 then
      drawPoints(c,"market",qq,color("market"),qm0,qm1,startTime,now,2)
      hasData=true
    end
    if A.db.combinedSalesBars and drawBars(c,samples,hours,now,1,true) then hasData=true end
  elseif kind=="price" then
    axes(c,{pm0,pm1,pmStep,true},nil,hours,now)
    c.title:SetText(A.L.CHART_TITLE_PRICE)
    local names={"price"}
    if A.db.showMA then names[#names+1]="ma" end
    if A.db.showTrendLine then names[#names+1]="trend" end
    setLegend(c,names)
    if #pp>0 then
      drawPoints(c,"price",pp,color("price"),pm0,pm1,startTime,now,2)
      drawAverage(c,pp,pm0,pm1,startTime,now)
      drawRegression(c,pp,pm0,pm1,startTime,now)
      hasData=true
    end
  elseif kind=="market" then
    axes(c,{qm0,qm1,qmStep,false},nil,hours,now)
    c.title:SetText(A.L.CHART_TITLE_MARKET)
    setLegend(c,{"market"})
    if #qq>0 then drawPoints(c,"market",qq,color("market"),qm0,qm1,startTime,now,2);hasData=true end
  elseif kind=="sales" then
    local bars,_,count=A.SalesSeries(samples,hours,now)
    local high=0
    for i=1,#bars do high=math.max(high,bars[i].value) end
    local m0,m1,step=bounds(0,high,false,true)
    c.hoverPriceAxis={m0,m1}
    axes(c,{m0,m1,step,false},nil,hours,now)
    c.title:SetText(A.L.CHART_TITLE_SALES)
    setLegend(c,{"sales"})
    if count>=2 then hasData=drawBars(c,samples,hours,now,m1,false) end
  end
  if not hasData then
    local empty=kind=="market" and A.L.CHART_EMPTY_MARKET or
      (kind=="sales" and A.L.CHART_EMPTY_SALES or A.L.CHART_EMPTY_PRICE)
    c.empty:SetText(empty)
    c.empty:Show()
  end
  if c.cursorLine:IsShown() then updateChartCursor(c) end
end

local function updateTopLayout(frame, showItem)
  if showItem then
    frame.header:ClearAllPoints()
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -49)
    frame.subheader:ClearAllPoints()
    frame.subheader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -67)
  else
    frame.header:ClearAllPoints()
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -7)
    frame.subheader:ClearAllPoints()
    frame.subheader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -25)
  end
end

local function setItemHeader(frame, key, legacy, metrics)
  if not frame.showItemHeader then
    frame.itemIcon:Hide(); frame.itemIconBorder:Hide(); frame.itemName:Hide(); frame.itemDetails:Hide()
    updateTopLayout(frame, false)
    return 0
  end
  local link = frame.itemLink or (A.state and A.state.link) or legacy or key
  local fallback = A.ItemLinkForKey and A.ItemLinkForKey(key, legacy)
  local name, icon = A.ResolveItemInfo(link or fallback or legacy or key, nil)
  local quality = itemQuality(link or fallback or legacy) or itemQuality(key)
  local r, g, b = qualityColor(quality)
  if type(icon) == "number" and icon > 0 then
    frame.itemIcon:SetTexture(icon)
    frame.itemIcon:Show()
    frame.itemIconBorder:Show()
  else
    frame.itemIcon:Hide()
    frame.itemIconBorder:Hide()
  end
  frame.itemName:SetText(A.FitItemName(name or "?", frame.itemName, WIDTH - 82))
  frame.itemName:SetTextColor(r, g, b)
  frame.itemName:Show()
  frame.itemDetails:SetText(
    A.L.METRIC_CURRENT .. ": " .. A.Money(metrics.currentPrice) .. "    " ..
    A.L.CHART_HEADER_MEAN .. ": " .. A.Money(metrics.average) .. "    " ..
    A.L.CHART_HEADER_MARKET .. ": " .. A.FmtCount(metrics.currentQuantity))
  frame.itemDetails:Show()
  updateTopLayout(frame, true)
  return ITEM_HEADER_HEIGHT
end

local function layout(frame, active, extra)
  for _,c in pairs(frame.charts) do c:Hide() end
  for i=1,#frame.separators do frame.separators[i]:Hide() end
  local y=TOP_SPACE + (extra or 0)
  for i=1,#active do
    local c=frame.charts[active[i]]
    if i>1 then
      local divider=frame.separators[i-1]
      divider:ClearAllPoints()
      divider:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-y-GAP/2)
      divider:Show()
    end
    setTerminalChartSize(c,frame)
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-y)
    c:Show()
    y=y+c.height+GAP
  end
  frame:SetHeight(math.max(80,y+FOOTER))
  return frame:GetHeight()
end

local function header(frame,metrics)
  if A.db.compactSummary then
    frame.header:SetText(
      A.L.CHART_HEADER_SAMPLES .. ": " .. tostring(metrics.observations) .. "    " ..
      A.L.CHART_HEADER_MARKET .. ": " .. A.FmtCount(metrics.currentQuantity) .. "    " ..
      A.L.CHART_HEADER_SALES .. ": " .. A.FmtCount(metrics.estimatedDrops24))
  else
    frame.header:SetText(
      A.L.METRIC_MIN .. ": " .. A.Money(metrics.minPrice) .. "    " ..
      A.L.METRIC_MAX .. ": " .. A.Money(metrics.maxPrice) .. "    " ..
      A.L.METRIC_MEDIAN .. ": " .. A.Money(metrics.median))
  end
  if A.db.showInsights then
    frame.subheader:SetText(A.L.METRIC_CURRENT .. ": " .. A.Money(metrics.currentPrice)
      .. "    " .. A.L.CHART_HEADER_CHANGE .. ": " .. A.FmtPercent(metrics.changePct)
      .. "    " .. A.L.CHART_HEADER_MEAN .. ": " .. A.Money(metrics.average)
      .. (A.db.showVolatility and ("    " .. A.L.CHART_HEADER_VOL .. ": " .. A.FmtVolatility(metrics.volatility)) or ""))
  else frame.subheader:SetText("") end
end

-- frame = a graph created by NewGraph; singleKind used by the market terminal.
function A.RenderGraph(frame,key,legacy,singleKind)
  A.Init()
  local active={}
  if singleKind then active[1]=singleKind
  else
    if A.db.showCombinedChart then active[#active+1]="combined" end
    if A.db.showPriceChart then active[#active+1]="price" end
    if A.db.showMarketChart then active[#active+1]="market" end
    if A.db.showSalesChart then active[#active+1]="sales" end
  end
  if #active==0 then frame:Hide();return 0 end
  local all=A.AllSamples(key,legacy)
  local hours=frame.zoomHours or A.ChartHours(key,legacy,all)
  local metrics=A.MarketMetrics(key,legacy,all,hours)
  local topExtra=setItemHeader(frame,key,legacy,metrics)
  header(frame,metrics)
  local height=layout(frame,active,topExtra)
  local now=time()
  for i=1,#active do drawOne(frame.charts[active[i]],all,hours,now) end
  frame:Show()
  return height,metrics
end

-- Discrete steps prevent integer rounding from trapping a 1-hour zoom.
local ZOOM_LEVELS = {1,2,3,4,6,9,12,18,24,36,48,72,96,120,168,240,336,504,720,1080,1440,2160}
function A.ZoomGraph(frame, direction, reset)
  if not frame or not A.db then return end
  local key, legacy
  if frame == A.graph then
    if not A.state then return end
    key, legacy = A.state.key, A.state.legacy
  elseif A.dashboard and frame == A.dashboard.graph then
    key, legacy = A.dashboard.key, A.dashboard.legacy
    if not key then return end
  elseif frame == A.craftPreviewGraph then
    key, legacy = frame.previewKey, frame.previewLegacy
    if not key then return end
  else return end

  if reset then
    frame.zoomHours = nil
  elseif type(direction) == "number" and direction ~= 0 then
    local maximum = math.max(1, math.min(2160, A.db.retentionDays * 24))
    local base = frame.zoomHours or A.ChartHours(key, legacy)
    local nextValue = base
    if direction > 0 then
      for i = #ZOOM_LEVELS, 1, -1 do
        if ZOOM_LEVELS[i] < base then nextValue = ZOOM_LEVELS[i]; break end
      end
    else
      for i = 1, #ZOOM_LEVELS do
        if ZOOM_LEVELS[i] > base then nextValue = ZOOM_LEVELS[i]; break end
      end
    end
    frame.zoomHours = math.max(1, math.min(maximum, nextValue))
  end
  if A.dashboard and frame == A.dashboard.graph then
    A.RefreshDashboard()
  else
    A.RenderGraph(frame,key,legacy,nil)
  end
end

-- Tooltip-aware placement: protect Blizzard's actual item tooltip as well
-- as both item-comparison tooltips. Chart placement never hides or moves them.
-- Coordinates are normalized into UIParent units before collision checks.
local TOOLTIP_FRAMES={"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2",
  "ItemRefShoppingTooltip1","ItemRefShoppingTooltip2","CompareTooltip1","CompareTooltip2"}
local function frameBounds(frame)
  if not frame or not frame.IsShown or not frame:IsShown() or
     not frame.GetLeft or not frame.GetRight or not frame.GetTop or
     not frame.GetBottom then return nil end
  local left,right,top,bottom=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
  if type(left)~="number" or type(right)~="number" or
     type(top)~="number" or type(bottom)~="number" or
     right<=left or top<=bottom then return nil end
  local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local scale=frame.GetEffectiveScale and frame:GetEffectiveScale() or parentScale
  local f=scale/(parentScale>0 and parentScale or 1)
  return {l=left*f,r=right*f,b=bottom*f,t=top*f}
end
local function visibleItemTooltipBounds()
  local result,seen={},{}
  for i=1,#TOOLTIP_FRAMES do
    local frame=_G[TOOLTIP_FRAMES[i]]
    if frame and not seen[frame] then
      seen[frame]=true
      local r=frameBounds(frame)
      if r then result[#result+1]=r end
    end
  end
  return result
end
local function overlaps(a,b)
  return a.l < b.r-2 and a.r > b.l+2 and a.b < b.t-2 and a.t > b.b+2
end
local function placeGraphAvoidingTooltips(graph,anchor,desiredScale)
  local screenW,screenH=UIParent:GetWidth(),UIParent:GetHeight()
  if screenW<=0 or screenH<=0 then return false end
  local avoid=visibleItemTooltipBounds()
  local main=frameBounds(anchor)
  if not main then main=avoid[1] end
  if not main then
    main={l=screenW/2-10,r=screenW/2+10,
      b=screenH/2-10,t=screenH/2+10}
  end
  local minL,maxR,minB,maxT=main.l,main.r,main.b,main.t
  for i=1,#avoid do
    local a=avoid[i]
    minL=math.min(minL,a.l);maxR=math.max(maxR,a.r)
    minB=math.min(minB,a.b);maxT=math.max(maxT,a.t)
  end
  local firstScale=math.min(desiredScale or 1,1,
    (screenW-16)/WIDTH,(screenH-16)/math.max(1,graph:GetHeight()))
  local factors={1,.92,.84,.76,.68,.60,.52,.45}
  local gap=10
  for i=1,#factors do
    local scale=firstScale*factors[i]
    if scale>=.32 then
      local w,h=WIDTH*scale,graph:GetHeight()*scale
      local limitX,limitY=screenW-w-8,screenH-h-8
      if limitX>=8 and limitY>=8 then
        local candidates={
          {x=maxR+gap,y=main.t-h}, -- to the right of all shown tooltips
          {x=minL-w-gap,y=main.t-h},
          {x=maxR+gap,y=maxT-h},
          {x=minL-w-gap,y=maxT-h},
          {x=main.l,y=minB-h-gap}, -- beneath all item tooltips
          {x=main.l,y=maxT+gap},  -- above all item tooltips
          {x=8,y=8},{x=limitX,y=8},
          {x=8,y=limitY},{x=limitX,y=limitY},
        }
        for j=1,#candidates do
          local c=candidates[j]
          local x=math.max(8,math.min(limitX,c.x))
          local y=math.max(8,math.min(limitY,c.y))
          local r={l=x,r=x+w,b=y,t=y+h}
          local safe=true
          for k=1,#avoid do
            if overlaps(r,avoid[k]) then safe=false;break end
          end
          if safe then
            graph:SetScale(scale)
            graph:ClearAllPoints()
            graph:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
            return true
          end
        end
      end
    end
  end
  -- There is not enough free space. Never cover the native item/comparison
  -- tooltips just to display the optional analytics chart.
  return false
end

-- Crafting preview uses its own chart frame: it does not change the item's
-- normal tooltip state, watchlist selection, or the market terminal zoom.
-- The preview stays open when the pointer moves from a material onto its chart.
local function closeCraftPreview()
  local f=A.craftPreviewGraph
  local owner=f and f.previewSource
  if f then f:Hide();f.previewKey=nil;f.itemLink=nil;f.previewSource=nil end
  A.craftPreviewActive=false
  -- A protected item tooltip remains visible during graph interaction. Only
  -- dismiss it when the preview closes AND it still belongs to this item.
  if owner and owner.IsMouseOver and not owner:IsMouseOver() and
      GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner()==owner then
    GameTooltip:Hide()
  end
end
-- Crafting previews use the same graphDelay preference as inventory tooltips.
-- This one shared worker is intentionally used instead of one OnUpdate per
-- material; it is cheap even for recipes containing many ingredients.
local craftPreviewDelayWorker=CreateFrame("Frame")
craftPreviewDelayWorker:Hide()
local craftPreviewPending=nil
local function cancelPendingCraftPreview()
  craftPreviewPending=nil
  craftPreviewDelayWorker:Hide()
  if not (A.craftPreviewGraph and A.craftPreviewGraph:IsShown()) then
    A.craftPreviewActive=false
  end
end
function A.HideCraftPreview()
  cancelPendingCraftPreview()
  closeCraftPreview()
end
function A.DeferCraftPreview()
  cancelPendingCraftPreview()
  local f=A.craftPreviewGraph
  if f and f:IsShown() then f.leaveAt=GetTime()+0.85 end
end
function A.ShowCraftPreview(source,id)
  if not source or not id then return end
  A.Init()
  if A.db.enabled==false or A.db.showTooltip==false then return end
  local itemID=tonumber(id)
  if not itemID then return end
  local link="item:"..itemID
  local key=A.Key(link) or ("db:"..itemID)
  local f=A.craftPreviewGraph
  if not f then
    f=A.NewGraph(UIParent)
    A.craftPreviewGraph=f
    f:SetScript("OnUpdate",function(self,dt)
      self.checkElapsed=(self.checkElapsed or 0)+dt
      if self.checkElapsed<0.10 then return end
      self.checkElapsed=0
      local source=self.previewSource
      if source and source.IsShown and not source:IsShown() then
        closeCraftPreview()
      elseif source and source.IsMouseOver and source:IsMouseOver() then
        self.leaveAt=nil
      elseif self.IsMouseOver and self:IsMouseOver() then
        self.leaveAt=nil
      elseif self.leaveAt and GetTime()>=self.leaveAt then
        closeCraftPreview()
      end
    end)
    f:SetScript("OnLeave",function(self)
      self.leaveAt=GetTime()+0.35
    end)
    -- Depending on the WoW client, hovering a child hitbox does not always
    -- report IsMouseOver() on the containing frame. Track child entry too.
    for _, plot in pairs(f.charts or {}) do
      if plot.hitbox and plot.hitbox.HookScript then
        plot.hitbox:HookScript("OnEnter",function() f.leaveAt=nil end)
        plot.hitbox:HookScript("OnLeave",function() f.leaveAt=GetTime()+0.45 end)
      end
    end
  end
  A.craftPreviewActive=true
  if A.graph and A.graph:IsShown() then A.graph:Hide() end
  if f.previewKey~=key then f.zoomHours=nil end
  f.previewSource=source
  f.previewKey=key
  f.previewLegacy=link
  f.itemLink=link
  f.leaveAt=nil
  f.showItemHeader=true
  local ok,height=pcall(A.RenderGraph,f,key,link,nil)
  if not ok then
    A.lastError=tostring(height)
    closeCraftPreview()
    return
  end
  if not height or height<=0 then closeCraftPreview();return end
  -- The chart may be opened from a Pro row while the native tooltip and
  -- equipment comparison are already on screen. Keep all of them visible.
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(265)
  local anchor=(GameTooltip and GameTooltip.IsShown and GameTooltip:IsShown()
    and GameTooltip.GetOwner and GameTooltip:GetOwner()==source) and GameTooltip or source
  if not placeGraphAvoidingTooltips(f,anchor,1) then
    closeCraftPreview()
    return
  end
  f:Show()
end

-- Never show a new chart immediately when the pointer enters a recipe result
-- or ingredient. The normal WoW item tooltip is handled by ProUI and remains
-- available at once. The delayed graph opens only if the same source is still
-- hovered after the user's existing graphDelay setting has elapsed.
function A.ScheduleCraftPreview(source,id)
  if not source or not id then return end
  A.Init()
  if A.db.enabled==false or A.db.showTooltip==false then return end
  if not tonumber(id) then return end
  if not (source.IsShown and source:IsShown()) then return end
  cancelPendingCraftPreview()
  local f=A.craftPreviewGraph
  if f and f:IsShown() then closeCraftPreview() end
  local delay=tonumber(A.db.graphDelay) or 0.8
  if delay<=0 then
    A.ShowCraftPreview(source,id)
    return
  end
  craftPreviewPending={source=source,id=id,started=GetTime(),delay=delay}
  A.craftPreviewActive=true
  craftPreviewDelayWorker.elapsed=0
  craftPreviewDelayWorker:Show()
end
craftPreviewDelayWorker:SetScript("OnUpdate",function(self,dt)
  self.elapsed=(self.elapsed or 0)+dt
  if self.elapsed<0.05 then return end
  self.elapsed=0
  local pending=craftPreviewPending
  if not pending then self:Hide();return end
  local source=pending.source
  if not source or not source.IsShown or not source:IsShown() or
    (source.IsMouseOver and not source:IsMouseOver()) then
    cancelPendingCraftPreview()
    return
  end
  if GetTime()-pending.started < pending.delay then return end
  local id=pending.id
  cancelPendingCraftPreview()
  A.ShowCraftPreview(source,id)
end)

function A.Draw(tooltip,key,isTest,legacy)
  if not A.db.showTooltip and not isTest then A.Hide();return end
  if not A.graph then A.graph=A.NewGraph(UIParent) end
  local frame=A.graph
  frame.showItemHeader=true
  local height=A.RenderGraph(frame,key,legacy,nil)
  if not height or height==0 then return end
  -- Prefer the side of the item tooltip, then an unused region above/below.
  -- ShoppingTooltip1/2 and ItemRef comparisons are protected from overlap.
  if not placeGraphAvoidingTooltips(frame,tooltip,1) then
    frame:Hide()
  end
end
