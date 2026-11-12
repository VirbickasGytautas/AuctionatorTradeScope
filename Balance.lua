-- TradeScope 3.5.2: balance chart crosshair with historical last-known values.
-- The wallet history remains optional and is never confused with auction prices.
local A=ATS
local WIDTH, HEIGHT=694,486
local LEFT,RIGHT,BOTTOM,TOP=140,641,133,351
local DIVS=4
local GOLD={0.98,0.75,0.22}
local GRID={0.25,0.34,0.47}

local function walletKey()
  return (UnitName("player") or "?") .. "@" .. (GetRealmName() or "?")
end
function A.BalanceSamples()
  A.Init()
  return A.db.balance[walletKey()] or {}
end
function A.RecordBalance()
  A.Init()
  if not A.db.trackBalance or type(GetMoney)~="function" then return false end
  local amount=GetMoney()
  if type(amount)~="number" or amount<0 then return false end
  local list=A.db.balance[walletKey()]
  if type(list)~="table" then list={};A.db.balance[walletKey()]=list end
  local now=time()
  local last=list[#list]
  if last and last.p==amount and now-(last.t or 0)<3600 then return false end
  list[#list+1]={t=now,p=amount}
  local cutoff=now-A.db.retentionDays*86400
  while #list>0 and (list[1].t<cutoff or #list>2500) do table.remove(list,1) end
  return true
end
local function tex(parent,layer,c,alpha)
  local t=parent:CreateTexture(nil,layer)
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(c[1],c[2],c[3],alpha or 1)
  return t
end
local function label(parent,w,justify,font)
  local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
  f:SetWidth(w); f:SetJustifyH(justify or "LEFT")
  return f
end
local function button(parent,text,w,x,y,callback)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,25); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(text); b:SetScript("OnClick",callback)
  if A.StyleButton then A.StyleButton(b) end
  return b
end
local function niceStep(n)
  if not n or n<=1 then return 1 end
  local magnitude=10^math.floor(math.log(n)/math.log(10))
  local factor=n/magnitude
  return (factor<=1 and 1 or (factor<=2 and 2 or (factor<=5 and 5 or 10)))*magnitude
end
local function drawSegment(f,idx,x1,y1,x2,y2)
  local dx,dy=x2-x1,y2-y1
  local len=math.sqrt(dx*dx+dy*dy)
  if len<0.1 then return idx end
  if f.canRotate then
    idx=idx+1
    local line=f.lines[idx]
    if not line then line=tex(f,"ARTWORK",GOLD,.98);f.lines[idx]=line end
    line:ClearAllPoints();line:SetSize(len,2)
    line:SetPoint("CENTER",f,"BOTTOMLEFT",(x1+x2)/2,(y1+y2)/2)
    local angle
    if math.atan2 then angle=math.atan2(dy,dx)
    elseif dx==0 then angle=dy>0 and math.pi/2 or -math.pi/2
    else angle=math.atan(dy/dx)+(dx<0 and math.pi or 0) end
    line:SetRotation(angle);line:Show()
  else
    local segments=math.min(160,math.max(1,math.ceil(len/3)))
    for i=1,segments do
      idx=idx+1
      local point=f.lines[idx]
      if not point then point=tex(f,"ARTWORK",GOLD,.98);point:SetSize(2,2);f.lines[idx]=point end
      point:ClearAllPoints();point:SetPoint("CENTER",f,"BOTTOMLEFT",x1+dx*i/segments,y1+dy*i/segments)
      point:Show()
    end
  end
  return idx
end
local function plotPoint(f,index,x,y)
  local dot=f.dots[index]
  if not dot then dot=tex(f,"OVERLAY",GOLD);dot:SetSize(5,5);f.dots[index]=dot end
  dot:ClearAllPoints();dot:SetPoint("CENTER",f,"BOTTOMLEFT",x,y);dot:Show()
end
local ZOOM_LEVELS={1,2,3,4,6,9,12,18,24,36,48,72,96,120,168,240,336,504,720,1080,1440,2160}
local function maxZoomHours()
  return math.max(1,math.min(2160,(A.db and A.db.retentionDays or 30)*24))
end
local function changeZoom(f,delta,reset)
  if reset then
    f.zoomHours=nil
  else
    local base=f.zoomHours or math.min(168,maxZoomHours())
    local maxHours=maxZoomHours()
    if delta>0 then
      local nextValue=base
      for i=#ZOOM_LEVELS,1,-1 do
        if ZOOM_LEVELS[i]<base then nextValue=ZOOM_LEVELS[i];break end
      end
      f.zoomHours=math.max(1,math.min(maxHours,nextValue))
    else
      local nextValue=base
      for i=1,#ZOOM_LEVELS do
        if ZOOM_LEVELS[i]>base then nextValue=ZOOM_LEVELS[i];break end
      end
      f.zoomHours=math.min(maxHours,nextValue)
    end
  end
  A.RefreshBalanceWindow()
end
local function setPreset(f,hours)
  f.zoomHours=math.max(1,math.min(maxZoomHours(),hours))
  A.RefreshBalanceWindow()
end
-- The cursor shows the last *observed* balance at the pointer's time.
-- No interpolation between transactions: a wallet balance changes in steps.
local function lastSampleAt(samples, timestamp)
  local left, right, found = 1, #samples, nil
  while left <= right do
    local mid = math.floor((left + right) / 2)
    local entry = samples[mid]
    if type(entry.t) == "number" and entry.t <= timestamp then
      found = entry
      left = mid + 1
    else
      right = mid - 1
    end
  end
  return found
end

local function hideCursor(f)
  if f.cursorLine then f.cursorLine:Hide() end
  if f.cursorDot then f.cursorDot:Hide() end
  if f.cursorBox then f.cursorBox:Hide() end
  f.cursorSecond = nil
  f.cursorObservedAt = nil
end

local function updateCursor(f)
  local plot = f.plotHitbox
  if not plot or not f:IsShown() or not A.db or not A.db.trackBalance
    or not f.hoverSamples or type(GetCursorPosition) ~= "function" then
    hideCursor(f)
    return
  end
  local screenX, screenY = GetCursorPosition()
  local scale = plot:GetEffectiveScale()
  local x0, y0 = plot:GetLeft(), plot:GetBottom()
  if type(screenX) ~= "number" or type(screenY) ~= "number"
    or not scale or scale <= 0 or not x0 or not y0 then
    hideCursor(f)
    return
  end
  local localX = screenX / scale - x0
  local localY = screenY / scale - y0
  local width, height = RIGHT - LEFT, TOP - BOTTOM
  if localX < 0 or localX > width or localY < 0 or localY > height then
    hideCursor(f)
    return
  end
  local cursorTime = math.floor(f.hoverStart + (localX / width) * f.hoverSeconds)
  local previous = lastSampleAt(f.hoverSamples, cursorTime)
  local line = f.cursorLine
  line:ClearAllPoints()
  line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LEFT + localX, BOTTOM)
  line:Show()
  if previous then
    local range = math.max(1, f.hoverMax - f.hoverMin)
    local fraction = math.max(0, math.min(1, (previous.p - f.hoverMin) / range))
    f.cursorDot:ClearAllPoints()
    f.cursorDot:SetPoint("CENTER", f, "BOTTOMLEFT", LEFT + localX, BOTTOM + fraction * height)
    f.cursorDot:Show()
  else
    f.cursorDot:Hide()
  end
  local box = f.cursorBox
  local bx = LEFT + localX + 13
  if bx + box:GetWidth() > WIDTH - 12 then bx = LEFT + localX - box:GetWidth() - 13 end
  bx = math.max(12, math.min(WIDTH - box:GetWidth() - 12, bx))
  local by = math.max(BOTTOM + 5, math.min(TOP - box:GetHeight() - 5, BOTTOM + localY + 15))
  box:ClearAllPoints()
  box:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", bx, by)
  if f.cursorSecond ~= cursorTime or f.cursorObservedAt ~= (previous and previous.t) then
    f.cursorTime:SetText(A.L.WALLET_CURSOR_AT .. ": " .. date("%d.%m %H:%M:%S", cursorTime))
    if previous then
      f.cursorValue:SetText(A.L.WALLET_CURRENT .. ": " .. A.Money(previous.p))
      f.cursorValue:SetTextColor(1, 0.84, 0.35)
      f.cursorSample:SetText(A.L.WALLET_CURSOR_LAST .. ": " .. date("%d.%m %H:%M:%S", previous.t))
    else
      f.cursorValue:SetText(A.L.WALLET_CURSOR_NO_DATA)
      f.cursorValue:SetTextColor(0.72, 0.77, 0.86)
      f.cursorSample:SetText("")
    end
    f.cursorSecond = cursorTime
    f.cursorObservedAt = previous and previous.t or nil
  end
  box:Show()
end

local function createWindow()
  if A.balanceFrame then return A.balanceFrame end
  local f=CreateFrame("Frame","ATSTradeScopeWallet",UIParent)
  f:SetSize(WIDTH,HEIGHT);f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG");f:SetFrameLevel(250)
  f:SetMovable(true);f:EnableMouse(true)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  if f.SetBackdrop then
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,
      edgeSize=32,insets={left=11,right=11,top=12,bottom=11}})
    f:SetBackdropColor(.02,.035,.055,.99)
  end
  local back=tex(f,"BACKGROUND",{.025,.035,.060},.98)
  back:SetPoint("TOPLEFT",f,"TOPLEFT",9,-9)
  back:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-9,9)
  local heading=label(f,540,"LEFT","GameFontNormalLarge")
  heading:SetPoint("TOPLEFT",f,"TOPLEFT",19,-17)
  heading:SetText(A.L.WALLET_WINDOW_TITLE)
  f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
  f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-6)
  f.summary=label(f,610,"LEFT","GameFontHighlightSmall")
  f.summary:SetPoint("TOPLEFT",f,"TOPLEFT",20,-54)
  f.summary:SetTextColor(1,.86,.47)
  f.hint=label(f,608,"CENTER","GameFontHighlightSmall")
  f.hint:SetPoint("CENTER",f,"BOTTOMLEFT",(LEFT+RIGHT)/2,(TOP+BOTTOM)/2)
  f.lines={};f.dots={};f.yticks={};f.xticks={};f.vgrid={};f.hgrid={}
  local rotationProbe=tex(f,"ARTWORK",GOLD,1)
  f.canRotate=type(rotationProbe.SetRotation)=="function"
  rotationProbe:Hide()
  for i=1,DIVS+1 do
    local y=BOTTOM+(i-1)*(TOP-BOTTOM)/DIVS
    local grid=tex(f,"BORDER",GRID,.38)
    grid:SetSize(RIGHT-LEFT,1);grid:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",LEFT,y)
    f.hgrid[i]=grid
    local tick=label(f,LEFT-29,"RIGHT")
    tick:SetPoint("RIGHT",f,"BOTTOMLEFT",LEFT-10,y)
    f.yticks[i]=tick
  end
  for i=1,7 do
    local x=LEFT+(i-1)*(RIGHT-LEFT)/6
    local grid=tex(f,"BORDER",GRID,.30)
    grid:SetSize(1,TOP-BOTTOM);grid:SetPoint("BOTTOM",f,"BOTTOMLEFT",x,BOTTOM)
    f.vgrid[i]=grid
    local tick=label(f,71,"CENTER")
    tick:SetPoint("TOP",f,"BOTTOMLEFT",x,BOTTOM-7)
    f.xticks[i]=tick
  end
  f.enable=button(f,A.L.WALLET_ENABLE_NOW,210,30,-400,function()
    A.db.trackBalance=true
    A.RecordBalance()
    A.RefreshBalanceWindow()
  end)
  local controlY=-407
  f.presetDay=button(f,A.L.MODE_DAY,88,24,controlY,function()setPreset(f,24)end)
  f.presetWeek=button(f,A.L.MODE_WEEK,88,118,controlY,function()setPreset(f,168)end)
  f.presetMonth=button(f,A.L.MODE_MONTH,96,212,controlY,function()setPreset(f,720)end)
  f.zoomInfo=label(f,127,"CENTER","GameFontHighlightSmall")
  f.zoomInfo:SetPoint("TOPLEFT",f,"TOPLEFT",317,controlY-6)
  f.zoomIn=button(f,"+",38,448,controlY,function()changeZoom(f,1)end)
  f.zoomOut=button(f,"-",38,494,controlY,function()changeZoom(f,-1)end)
  f.zoomReset=button(f,A.L.ZOOM_RESET,114,540,controlY,function()changeZoom(f,0,true)end)
  local instruction=label(f,650,"LEFT")
  instruction:SetPoint("TOPLEFT",f,"TOPLEFT",22,-456)
  instruction:SetText(A.L.WALLET_ZOOM_HINT)
  instruction:SetTextColor(.72,.77,.86)
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel",function(_,delta)changeZoom(f,delta)end)
  -- A separate plotting child also accepts the wheel on clients that do not
  -- bubble mousewheel events to parent frames.
  local interactive=CreateFrame("Frame",nil,f)
  interactive:SetSize(RIGHT-LEFT,TOP-BOTTOM)
  interactive:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",LEFT,BOTTOM)
  interactive:EnableMouse(true);interactive:EnableMouseWheel(true)
  interactive:SetScript("OnMouseWheel",function(_,delta)changeZoom(f,delta)end)
  interactive:SetFrameLevel(f:GetFrameLevel()+1)
  f.plotHitbox = interactive
  -- This overlay is mouse-transparent, so it never interrupts zooming or dragging.
  local overlay=CreateFrame("Frame",nil,f)
  overlay:SetAllPoints(f)
  overlay:SetFrameLevel(f:GetFrameLevel()+3)
  overlay:EnableMouse(false)
  f.cursorLine=tex(overlay,"OVERLAY",{0.72,0.88,1.00},0.78)
  f.cursorLine:SetSize(1,TOP-BOTTOM)
  f.cursorLine:Hide()
  f.cursorDot=tex(overlay,"OVERLAY",{1.0,0.86,0.30},1)
  f.cursorDot:SetSize(8,8)
  f.cursorDot:Hide()
  local hover=CreateFrame("Frame",nil,overlay)
  hover:SetSize(256,68)
  hover:EnableMouse(false)
  local bg=tex(hover,"BACKGROUND",{0.02,0.03,0.06},0.97)
  bg:SetAllPoints(hover)
  local topBorder=tex(hover,"BORDER",GOLD,0.90)
  topBorder:SetSize(256,1)
  topBorder:SetPoint("TOPLEFT",hover,"TOPLEFT",0,0)
  local sideBorder=tex(hover,"BORDER",GOLD,0.65)
  sideBorder:SetSize(1,68)
  sideBorder:SetPoint("TOPLEFT",hover,"TOPLEFT",0,0)
  f.cursorTime=label(hover,246,"LEFT","GameFontNormalSmall")
  f.cursorTime:SetPoint("TOPLEFT",hover,"TOPLEFT",7,-7)
  f.cursorValue=label(hover,246,"LEFT","GameFontHighlightSmall")
  f.cursorValue:SetPoint("TOPLEFT",hover,"TOPLEFT",7,-27)
  f.cursorSample=label(hover,246,"LEFT","GameFontHighlightSmall")
  f.cursorSample:SetPoint("TOPLEFT",hover,"TOPLEFT",7,-47)
  f.cursorSample:SetTextColor(0.72,0.78,0.86)
  hover:Hide()
  f.cursorBox=hover
  interactive:SetScript("OnEnter",function()updateCursor(f)end)
  interactive:SetScript("OnLeave",function()hideCursor(f)end)
  interactive:SetScript("OnUpdate",function(self,elapsed)
    self.hoverElapsed=(self.hoverElapsed or 0)+elapsed
    if self.hoverElapsed>=0.035 then
      self.hoverElapsed=0
      updateCursor(f)
    end
  end)
  f:HookScript("OnHide",function()hideCursor(f)end)
  -- Move the window with the title strip, not the chart itself.
  local drag=CreateFrame("Frame",nil,f)
  drag:SetPoint("TOPLEFT",f,"TOPLEFT",14,-10)
  drag:SetSize(WIDTH-63,35)
  drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
  drag:SetScript("OnDragStart",function()f:StartMoving()end)
  drag:SetScript("OnDragStop",function()f:StopMovingOrSizing()end)
  f:Hide()
  A.balanceFrame=f
  return f
end

function A.RefreshBalanceWindow()
  if not A.balanceFrame then return end
  local f=A.balanceFrame
  local zoomHours=f.zoomHours or 168
  if f.zoomInfo then
    local number=zoomHours<24 and (tostring(zoomHours).." "..A.L.HOURS_SHORT) or
      (zoomHours%24==0 and (tostring(math.floor(zoomHours/24)).." "..A.L.DAYS_SHORT)
       or tostring(zoomHours).." "..A.L.HOURS_SHORT)
    f.zoomInfo:SetText(A.L.WALLET_SCALE .. ": " .. number)
  end
  for i=1,#f.lines do f.lines[i]:Hide() end
  for i=1,#f.dots do f.dots[i]:Hide() end
  if not A.db.trackBalance then
    f.hoverSamples=nil
    hideCursor(f)
    for _, control in ipairs({f.presetDay,f.presetWeek,f.presetMonth,f.zoomIn,f.zoomOut,f.zoomReset,f.zoomInfo}) do control:Hide() end
    f.summary:SetText(A.L.WALLET_DISABLED)
    f.hint:SetText(A.L.WALLET_DISABLED_HINT)
    f.hint:Show();f.enable:Show()
    for i=1,DIVS+1 do f.yticks[i]:SetText("-") end
    for i=1,7 do f.xticks[i]:SetText("") end
    return
  end
  f.enable:Hide()
  for _, control in ipairs({f.presetDay,f.presetWeek,f.presetMonth,f.zoomIn,f.zoomOut,f.zoomReset,f.zoomInfo}) do control:Show() end
  A.RecordBalance()
  local samples=A.BalanceSamples()
  local hours=math.min(maxZoomHours(),f.zoomHours or 168)
  local seconds=math.max(3600,hours*3600)
  local now=time();local startTime=now-seconds
  local selected={};local minimum,maximum
  local baseline=nil
  for i=1,#samples do
    local p=samples[i]
    if type(p.t)=="number" and type(p.p)=="number" and p.p>=0 then
      if p.t<startTime then baseline=p
      elseif p.t<=now then
        selected[#selected+1]=p
        minimum=math.min(minimum or p.p,p.p)
        maximum=math.max(maximum or p.p,p.p)
      end
    end
  end
  if baseline then
    minimum=math.min(minimum or baseline.p,baseline.p)
    maximum=math.max(maximum or baseline.p,baseline.p)
  end
  local current=type(GetMoney)=="function" and GetMoney() or nil
  local delta=(#selected>=2) and selected[#selected].p-selected[1].p or nil
  local deltaText=delta and ((delta<0 and "-" or "+")..A.Money(math.abs(delta))) or "-"
  f.summary:SetText(A.L.WALLET_CURRENT .. ": " .. A.Money(current) .. "     "
    .. A.L.WALLET_CHANGE .. ": " .. deltaText .. "     "
    .. A.L.METRIC_SAMPLES .. ": " .. #selected)
  if #selected==0 and not baseline then f.hint:SetText(A.L.WALLET_NO_SAMPLES);f.hint:Show()
  else f.hint:Hide() end
  if minimum==nil then minimum=0;maximum=100 end
  local pad=math.max(100,maximum==minimum and maximum*0.02 or (maximum-minimum)*0.12)
  local step=niceStep((maximum-minimum+2*pad)/DIVS)
  local floor=math.max(0,math.floor(math.max(0,minimum-pad)/step)*step)
  while floor+step*DIVS<maximum+pad do
    step=niceStep(step*1.01)
    floor=math.max(0,math.floor(math.max(0,minimum-pad)/step)*step)
  end
  local ceiling=floor+step*DIVS
  for i=1,DIVS+1 do
    f.yticks[i]:SetText(A.MoneyAxis(floor+step*(i-1)))
  end
  for i=1,7 do
    local tickTime=startTime+(i-1)*seconds/6
    f.xticks[i]:SetText(date(hours<=48 and "%H:%M" or "%d.%m",math.floor(tickTime)))
  end
  -- Data for the cursor is the *complete* list, so hovering between scans
  -- always reports the latest known balance, even before the visible period.
  f.hoverSamples=samples
  f.hoverStart=startTime
  f.hoverSeconds=seconds
  f.hoverMin=floor
  f.hoverMax=ceiling
  local lastX,lastY,used=nil,nil,0
  if baseline then
    lastX=LEFT
    lastY=BOTTOM+(baseline.p-floor)/math.max(1,ceiling-floor)*(TOP-BOTTOM)
  end
  for i=1,#selected do
    local p=selected[i]
    local x=LEFT+(p.t-startTime)/seconds*(RIGHT-LEFT)
    local y=BOTTOM+(p.p-floor)/math.max(1,ceiling-floor)*(TOP-BOTTOM)
    plotPoint(f,i,x,y)
    if lastX then
      -- Wallet values are discrete, so draw horizontal then vertical steps;
      -- do not imply an unobserved fractional gold balance between samples.
      used=drawSegment(f,used,lastX,lastY,x,lastY)
      used=drawSegment(f,used,x,lastY,x,y)
    end
    lastX,lastY=x,y
  end
  if lastX then
    -- Extend the last known balance to the right edge of the time window.
    used=drawSegment(f,used,lastX,lastY,RIGHT,lastY)
  end
  -- Refresh cursor content immediately after zoom while hovered.
  f.cursorSecond=nil
  if f.cursorLine and f.cursorLine:IsShown() then updateCursor(f) end
end

function A.OpenBalanceWindow()
  A.Init()
  local f=createWindow()
  if UIParent and UIParent.GetWidth and UIParent.GetHeight then
    local target=math.min(1,(UIParent:GetWidth()-30)/WIDTH,(UIParent:GetHeight()-30)/HEIGHT)
    f:SetScale(math.max(0.6,target))
  end
  f:Show()
  A.RefreshBalanceWindow()
  return f
end
function A.ToggleBalanceWindow()
  if A.balanceFrame and A.balanceFrame:IsShown() then A.balanceFrame:Hide()
  else A.OpenBalanceWindow() end
end
function A.ShowBalance()
  -- Coin hover opens a *persistent* window: it remains until closed by user.
  if A.db and A.db.trackBalance then A.OpenBalanceWindow() end
end

local hooked={}
local function hookCoinFrames()
  if not A.db or not A.db.trackBalance then return end
  for i=1,13 do
    local parent=_G["ContainerFrame"..i.."MoneyFrame"]
    if parent then
      for _,suffix in ipairs({"GoldButton","SilverButton","CopperButton"}) do
        local child=_G[(parent.GetName and parent:GetName() or "")..suffix]
        if child and not hooked[child] and type(child.HookScript)=="function" then
          hooked[child]=true
          child:HookScript("OnEnter",function()A.ShowBalance()end)
        end
      end
    end
  end
end
local listener=CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_MONEY")
listener:RegisterEvent("BAG_UPDATE")
listener:SetScript("OnEvent",function(_,event)
  if A.db and A.db.trackBalance then
    A.RecordBalance()
    if A.balanceFrame and A.balanceFrame:IsShown() then A.RefreshBalanceWindow() end
  end
  if event~="PLAYER_MONEY" then hookCoinFrames() end
end)
listener:SetScript("OnUpdate",function(self,dt)
  if not A.db or not A.db.trackBalance then return end
  self.elapsed=(self.elapsed or 0)+dt
  self.focusElapsed=(self.focusElapsed or 0)+dt
  if self.elapsed>5 then self.elapsed=0;hookCoinFrames();A.RecordBalance() end
  if self.focusElapsed>=0.4 and type(GetMouseFocus)=="function" then
    self.focusElapsed=0
    local focus=GetMouseFocus()
    local name=focus and focus.GetName and focus:GetName() or ""
    local lower=string.lower(name)
    local coinBar=(string.find(lower,"money",1,true) or string.find(lower,"coin",1,true))
      and not string.find(lower,"ats",1,true)
    if coinBar and focus~=A.balanceFocus then
      A.balanceFocus=focus
      A.ShowBalance()
    elseif not coinBar then A.balanceFocus=nil end
  end
end)
