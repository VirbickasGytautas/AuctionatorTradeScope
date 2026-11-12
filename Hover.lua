-- TradeScope 3.0: persistent interactive tooltip charts and bag item picker.
local A=ATS
local worker=CreateFrame("Frame")
local elapsedTotal=0
local GRACE=1.15
local function tooltipItem(tip)
  if not tip or not tip.IsShown or not tip:IsShown() or type(tip.GetItem)~="function" then return nil end
  local ok,_,link=pcall(tip.GetItem,tip)
  if ok and A.LegacyKey(link) then return link end
end
local function clearState()
  A.state=nil;A.graphHovered=false
  if A.graph then A.graph.zoomHours=nil end
  A.Hide()
end
local function tick()
  A.Init()
  if A.craftPreviewActive then return end
  if not A.db.enabled then clearState();return end
  local now=GetTime()
  if A.testUntil and now<A.testUntil then return end
  A.testUntil=nil
  local tip,link=GameTooltip,tooltipItem(GameTooltip)
  if not link then tip=ItemRefTooltip;link=tooltipItem(ItemRefTooltip) end
  if link then
    if A.RememberTooltipItem then A.RememberTooltipItem(tip,link) end
    if A.bagPicking and A.TryPickBagTooltip then A.TryPickBagTooltip(tip,link) end
    A.missingSince=nil
    local key=A.Key(link)
    if not key then return end
    local legacy=A.LegacyKey(link)
    local owner=tip.GetOwner and tip:GetOwner()
    local state=A.state
    if not state or state.key~=key or state.legacy~=legacy or state.owner~=owner then
      A.Hide()
      if A.graph then A.graph.zoomHours=nil end
      state={tip=tip,key=key,legacy=legacy,link=link,owner=owner,since=now,nextPrice=0,nextDraw=0}
      A.state=state
    end
    state.link=link
    if A.db.collectOnHover and now>=state.nextPrice then
      A.Record(key,A.Price(link),"hover")
      state.nextPrice=now+5
    end
    if now-state.since>=A.db.graphDelay and now>=state.nextDraw then
      A.Draw(tip,key,false,legacy)
      state.nextDraw=now+0.40
    end
  else
    if not A.state then return end
    if not A.missingSince then A.missingSince=now end
    -- Keep chart alive while pointer moves from item tooltip into the chart.
    -- Once chart itself is left, the grace window ends and chart vanishes.
    if A.graphHovered or (A.graph and A.graph.IsMouseOver and A.graph:IsMouseOver()) then
      return
    end
    if A.graphLeftAt and A.graphLeftAt >= A.missingSince then
      if now-A.graphLeftAt>0.15 then clearState() end
    elseif now-A.missingSince > GRACE then
      clearState()
    end
  end
end
worker:SetScript("OnUpdate",function(_,dt)
  elapsedTotal=elapsedTotal+dt
  if elapsedTotal<0.10 then return end
  elapsedTotal=0
  local ok,err=pcall(tick)
  if not ok and A.lastError~=tostring(err) then
    A.lastError=tostring(err)
    A.Say(A.L.ERROR..A.lastError)
  end
end)
