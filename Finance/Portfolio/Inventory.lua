-- TradeScope 4.5.0-beta3: independent, automatic per-character bag/bank snapshot.
-- Inventory is physical stock, NOT a confirmed purchase or known acquisition cost.
local A=ATS
local floor,min,max=math.floor,math.min,math.max
local bankOpen=false
local dirty=true
local settling=false
local elapsed=0
local lastRefresh=-1
local bankTimer=0

local function epoch() return type(time)=="function" and time() or 0 end
local function nowClock() return type(GetTime)=="function" and GetTime() or epoch() end
local function validCount(n)
  n=tonumber(n)
  return n and n==n and n>=0 and n<math.huge and floor(n) or nil
end
local function clientFunction(name)
  local mod=type(_G.C_Container)=="table" and _G.C_Container[name]
  local old=_G[name]
  if type(mod)~="function" then mod=nil end
  if type(old)~="function" or old==mod then old=nil end
  return mod,old
end
local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a=pcall(fn,...)
  if ok then return a end
end
local function getSlots(bag)
  local modern,legacy=clientFunction("GetContainerNumSlots")
  local a=validCount(safe(modern,bag))
  local b=validCount(safe(legacy,bag))
  if a==nil and b==nil then return nil end
  return min(120,max(a or 0,b or 0))
end
local function readSlot(bag,slot)
  local modern,legacy=clientFunction("GetContainerItemInfo")
  local getIDModern,getIDLegacy=clientFunction("GetContainerItemID")
  local linkModern,linkLegacy=clientFunction("GetContainerItemLink")
  local id=tonumber(safe(getIDModern,bag,slot)) or tonumber(safe(getIDLegacy,bag,slot))
  local count,link
  for _,fn in ipairs({modern or false,legacy or false}) do
    if type(fn)=="function" then
      local ok,a,b,c,d,e,f,g=pcall(fn,bag,slot)
      if ok then
        if type(a)=="table" then
          id=id or tonumber(a.itemID)
          count=count or validCount(a.stackCount or a.count)
          link=link or a.hyperlink or a.itemLink
        elseif a~=nil then
          count=count or validCount(b)
          link=link or (type(g)=="string" and g or nil)
        end
      end
    end
  end
  if not link then link=safe(linkModern,bag,slot) or safe(linkLegacy,bag,slot) end
  if not id and type(link)=="string" then id=tonumber(link:match("item:(%d+)")) end
  if not id or id<1 or not count or count<=0 then return nil end
  -- Normalize to the same key namespace used by the journal and price history.
  -- DBKeyFromLink may carry variant identity; preserve it when available.
  local key=type(A.Key)=="function" and A.Key(link or ("item:"..id)) or nil
  if not key then key="db:"..tostring(floor(id)) end
  return key,count
end
local function scan(containers)
  local counts={}
  local readable=false
  for _,bag in ipairs(containers) do
    local slots=getSlots(bag)
    if slots and slots>0 then
      readable=true
      for slot=1,slots do
        local key,qty=readSlot(bag,slot)
        if key then counts[key]=(counts[key] or 0)+qty end
      end
    end
  end
  return readable and counts or nil
end
local function state()
  A.Init()
  local pro=A.db.pro
  pro.portfolioStock=type(pro.portfolioStock)=="table" and pro.portfolioStock or {}
  local key=A.RealmKey()..":"..(UnitName and (UnitName("player") or "?") or "?")
  local s=pro.portfolioStock[key]
  if type(s)~="table" then s={};pro.portfolioStock[key]=s end
  return s
end
local function visibleBank()
  if bankOpen then return true end
  local b=_G.BankFrame
  return b and type(b.IsShown)=="function" and b:IsShown() or false
end
local function sameCounts(a,b)
  if type(a)~="table" or type(b)~="table" then return false end
  for key,v in pairs(a) do if b[key]~=v then return false end end
  for key,v in pairs(b) do if a[key]~=v then return false end end
  return true
end
local function repaint()
  local w=A.proWindow
  local p=w and w.pages and w.pages.portfolio
  if p and p.IsShown and p:IsShown() and type(p.update)=="function" then
    pcall(p.update)
  end
end
function A.RefreshPortfolioStock(force)
  local s=state()
  local current=nowClock()
  if force or dirty or lastRefresh<0 or current-lastRefresh>=5 then
    local bags={}
    for i=0,max(4,min(5,tonumber(_G.NUM_BAG_SLOTS) or 4)) do
      bags[#bags+1]=i
    end
    local fresh=scan(bags)
    if fresh then
      s.bags=fresh;s.bagsTime=epoch();s.bagsKnown=true
      dirty=false;lastRefresh=current
    end
  end
  if visibleBank() then
    local containers={tonumber(_G.BANK_CONTAINER) or -1}
    local bagCount=tonumber(_G.NUM_BAG_SLOTS) or 4
    local bankBags=tonumber(_G.NUM_BANKBAGSLOTS) or 7
    for i=bagCount+1,bagCount+min(12,max(0,bankBags)) do
      containers[#containers+1]=i
    end
    local fresh=scan(containers)
    if fresh then s.bank=fresh;s.bankTime=epoch();s.bankKnown=true end
  end
  return A.PortfolioStockSnapshot()
end
function A.PortfolioStockSnapshot()
  local s=state()
  return {bags=type(s.bags)=="table" and s.bags or {},
    bank=type(s.bank)=="table" and s.bank or {},
    bagsKnown=s.bagsKnown==true and type(s.bags)=="table",
    bankKnown=s.bankKnown==true and type(s.bank)=="table",
    bagsTime=s.bagsTime,bankTime=s.bankTime,bankOpen=visibleBank()}
end

if type(CreateFrame)=="function" then
  local f=CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","BAG_UPDATE",
    "BAG_UPDATE_DELAYED","BANKFRAME_OPENED","BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED","PLAYERBANKBAGSLOTS_CHANGED"}) do
    pcall(f.RegisterEvent,f,event)
  end
  f:SetScript("OnEvent",function(_,event)
    if event=="BANKFRAME_OPENED" then bankOpen=true end
    if event=="BANKFRAME_CLOSED" then bankOpen=false end
    dirty=true;settling=true;elapsed=0
  end)
  f:SetScript("OnUpdate",function(_,dt)
    if settling then
      elapsed=elapsed+(tonumber(dt) or 0)
      if elapsed>=0.30 then
        settling=false
        A.RefreshPortfolioStock(true)
        repaint()
      end
    end
    if visibleBank() then
      bankTimer=bankTimer+(tonumber(dt) or 0)
      if bankTimer>=2 then
        bankTimer=0
        local before=A.PortfolioStockSnapshot()
        local oldBags,oldBank=before.bags,before.bank
        local after=A.RefreshPortfolioStock(false)
        if not sameCounts(oldBags,after.bags) or not sameCounts(oldBank,after.bank) then
          repaint()
        end
      end
    else bankTimer=0 end
  end)
end
