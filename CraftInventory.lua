-- TradeScope 4.0.11: opt-in per-character bag/bank resource tracking.
-- WoW Forever: bank contents can change before BAG_UPDATE observers can read
-- the new state. Refresh after the event burst and repaint the open calculator.
local A=ATS
local bankOpen=false
local bagsDirty=true
local lastBags=-1
local bankKnownThisVisit=false

-- WoW Forever can expose C_Container alongside legacy global functions while
-- implementing only part of the modern API. Try both APIs for EACH operation,
-- not merely whichever function happens to exist.
local function containerFunctions(name)
  local modern=type(_G.C_Container)=="table" and _G.C_Container[name] or nil
  local legacy=_G[name]
  if type(modern)~="function" then modern=nil end
  if type(legacy)~="function" or legacy==modern then legacy=nil end
  return modern,legacy
end
local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
local function epoch()
  return type(time)=="function" and time() or 0
end
local function clock()
  return type(GetTime)=="function" and GetTime() or 0
end
local function stockEnabled()
  return A.db and A.db.pro and A.db.pro.craftInventoryEnabled==true
end
local function bankVisible()
  if bankOpen then return true end
  local b=_G.BankFrame
  return b and type(b.IsShown)=="function" and b:IsShown() or false
end
local function characterStore()
  A.Init()
  local d=A.db.pro
  d.craftStock=type(d.craftStock)=="table" and d.craftStock or {}
  local key=A.RealmKey()..":"..(UnitName and (UnitName("player") or "?") or "?")
  if type(d.craftStock[key])~="table" then d.craftStock[key]={} end
  return d.craftStock[key]
end
local function sameCounts(a,b)
  if type(a)~="table" or type(b)~="table" then return false end
  for id,v in pairs(a) do if b[id]~=v then return false end end
  for id,v in pairs(b) do if a[id]~=v then return false end end
  return true
end

local function slotsFor(index)
  local modern,legacy=containerFunctions("GetContainerNumSlots")
  local first=tonumber(safe(modern,index))
  local second=tonumber(safe(legacy,index))
  -- A partially implemented C_Container often returns zero for classic bags.
  -- A genuine empty container is still valid, hence the explicit boolean.
  if first==nil and second==nil then return nil end
  return math.max(0, math.floor(math.max(first or 0,second or 0)))
end
local function readSlot(index,slot)
  local getModern,getLegacy=containerFunctions("GetContainerItemInfo")
  local getIDModern,getIDLegacy=containerFunctions("GetContainerItemID")
  local getLinkModern,getLinkLegacy=containerFunctions("GetContainerItemLink")
  local id=tonumber(safe(getIDModern,index,slot)) or
    tonumber(safe(getIDLegacy,index,slot))
  local quantity
  for _,fn in ipairs({getModern or false,getLegacy or false}) do
    if type(fn)=="function" then
      local ok,first,second,third,fourth,fifth,sixth,seventh,eighth,ninth,tenth=
        pcall(fn,index,slot)
      if ok then
        local modern=type(first)=="table" and first or nil
        if modern then
          id=id or tonumber(modern.itemID)
          quantity=quantity or tonumber(modern.stackCount or modern.count or modern.quantity)
          local link=modern.hyperlink or modern.itemLink
          if not id and type(link)=="string" then id=tonumber(link:match("item:(%d+)")) end
        else
          -- Legacy GetContainerItemInfo returns texture, count, ..., itemLink.
          if first~=nil then quantity=quantity or tonumber(second) end
          if not id then
            for _,candidate in ipairs({seventh or false,eighth or false,ninth or false,tenth or false}) do
              if type(candidate)=="string" then
                id=tonumber(candidate:match("item:(%d+)"))
              elseif type(candidate)=="number" and candidate>0 then
                id=candidate
              end
              if id then break end
            end
          end
        end
      end
    end
  end
  if not id then
    for _,fn in ipairs({getLinkModern or false,getLinkLegacy or false}) do
      if type(fn)=="function" then
        local link=safe(fn,index,slot)
        if type(link)=="string" then id=tonumber(link:match("item:(%d+)")) end
        if id then break end
      end
    end
  end
  return id,quantity
end

local function readContainer(index,totals)
  local slots=slotsFor(index)
  -- Zero slots often means that a custom client has not exposed the bank
  -- container. Do not interpret that as a verified empty bank snapshot.
  if type(slots)~="number" or slots<=0 then return false end
  for slot=1,math.min(120,slots) do
    local id,count=readSlot(index,slot)
    if type(id)=="number" and id>0 then
      local quantity=tonumber(count) or 1
      if quantity>0 then totals[id]=(totals[id] or 0)+math.floor(quantity) end
    end
  end
  return true
end

-- Prefer actual live GetItemCount values (both numeric ID and item link) to a
-- possibly stale bank snapshot. Keep the scanner as a fallback for clients
-- without GetItemCount, or implementations that return zero for linked items.
local function countByGameAPI(id,withBank)
  local fn=_G.GetItemCount
  if type(fn)~="function" then return nil end
  local choices={id,"item:"..id}
  if type(GetItemInfo)=="function" then
    local ok,_,link=pcall(GetItemInfo,id)
    if ok and type(link)=="string" then choices[#choices+1]=link end
  end
  local best
  for _,ref in ipairs(choices) do
    local value=safe(fn,ref,withBank)
    if type(value)=="number" and value>=0 and value<math.huge then
      best=math.max(best or 0,math.floor(value))
    end
  end
  return best
end
function A.RefreshCraftBags(force)
  A.Init()
  if not stockEnabled() then return nil end
  if not force and not bagsDirty and lastBags>=0 and clock()-lastBags<3 then
    return characterStore().bags
  end
  local counts={}
  local numBags=math.max(4,math.min(5,tonumber(_G.NUM_BAG_SLOTS) or 4))
  local valid=false
  for index=0,numBags do
    if readContainer(index,counts) then valid=true end
  end
  local store=characterStore()
  -- Do not overwrite a previous snapshot if the container API was unavailable.
  if valid then
    store.bags=counts;store.bagsTime=epoch()
    bagsDirty=false;lastBags=clock()
  end
  return store.bags or {}
end

function A.RefreshCraftBank()
  A.Init()
  if not stockEnabled() or not bankVisible() then return nil end
  local counts={}
  local bankContainer=tonumber(_G.BANK_CONTAINER) or -1
  local any=readContainer(bankContainer,counts)
  local first=tonumber(_G.NUM_BAG_SLOTS) or 4
  local bankBags=tonumber(_G.NUM_BANKBAGSLOTS) or 7
  for index=first+1,first+math.min(bankBags,12) do
    if readContainer(index,counts) then any=true end
  end
  if any then
    local store=characterStore()
    store.bank=counts;store.bankTime=epoch()
    bankKnownThisVisit=true
    return counts
  end
end

function A.RefreshCraftStock()
  if not stockEnabled() then return end
  bagsDirty=true
  A.RefreshCraftBags(true)
  if bankVisible() then A.RefreshCraftBank() end
end

function A.CraftOwnedCount(id)
  if not stockEnabled() then return nil,nil,nil end
  id=tonumber(id)
  if not id then return nil,nil,nil end
  -- Scan results and game counts are independent sources; the client may
  -- expose only legacy container functions or may lag after bank transfers.
  local bags=A.RefreshCraftBags(false) or {}
  local s=characterStore()
  local scannedBag=tonumber(bags[id]) or 0
  local liveBag=countByGameAPI(id,false)
  local bag=math.max(scannedBag,liveBag or 0)
  local savedBank=type(s.bank)=="table" and tonumber(s.bank[id]) or nil
  local bank=savedBank
  -- Some bank addons replace the default BankFrame; on these clients bank
  -- visibility may appear false even while native GetItemCount(..., true)
  -- returns accurate totals. Reconcile positive bank counts regardless.
  local visible=bankVisible()
  local liveTotal=countByGameAPI(id,true)
  -- A single stock count is used in all crafting calculations and displays.
  -- When GetItemCount(id,true) actually sees a bank quantity, it is the most
  -- reliable total on clients with custom bank UIs: summing an old snapshot
  -- with recently moved bag items would otherwise double-count materials.
  local total=bag+math.max(0,tonumber(bank) or 0)
  if type(liveTotal)=="number" and liveTotal>bag then
    total=liveTotal
    bank=liveTotal-bag
    s.bank=type(s.bank)=="table" and s.bank or {}
    s.bank[id]=bank>0 and bank or nil
    -- Keep the displayed last-bank-scan date honest: a GetItemCount lookup
    -- outside the bank is not a fresh visit to the bank.
    if visible then s.bankTime=epoch() end
  elseif type(liveTotal)=="number" and liveTotal==bag and
      (not bank or bank<=0) then
    total=liveTotal
  end
  return bag,bank,s.bankTime,total
end

-- Diagnostic command for WoW Forever custom bag/bank clients. It reveals
-- which source is missing without requiring a user to edit SavedVariables.
function A.DebugCraftStock(id)
  if not stockEnabled() then return "Own-material tracking is disabled." end
  id=tonumber(id)
  if not id or id<1 then return "Usage: /ats stock <itemID>" end
  local scanned=A.RefreshCraftBags(true) or {}
  if bankVisible() then A.RefreshCraftBank() end
  local store=characterStore()
  local gameBags=countByGameAPI(id,false)
  local gameTotal=countByGameAPI(id,true)
  local oldBank=store.bank and store.bank[id]
  local bag,bank=A.CraftOwnedCount(id)
  return "ID="..id.."  bag scan="..tostring(scanned[id] or 0)..
    "  bag API="..tostring(gameBags).."  total API="..tostring(gameTotal)..
    "  cached bank="..tostring(oldBank).."  displayed="..tostring(bag)..
    "/"..tostring(bank).."  bank open="..tostring(bankVisible() and true or false)
end

function A.CraftStockInfo()
  if not stockEnabled() then return nil end
  A.RefreshCraftBags(false)
  local s=characterStore()
  return {bankKnown=type(s.bank)=="table",bankTime=s.bankTime,
    bankOpen=bankVisible(),bagsTime=s.bagsTime}
end

local function redrawCalculator()
  local w=A.proWindow
  if w and type(w.IsShown)=="function" and w:IsShown() and w.active=="craft" then
    local p=w.pages and w.pages.craft
    if p and type(p.update)=="function" then
      local ok,err=pcall(p.update)
      if not ok then A.lastError=tostring(err) end
    end
  end
end

function A.SetCraftInventoryEnabled(value)
  A.Init()
  A.db.pro.craftInventoryEnabled=value==true
  if stockEnabled() then A.RefreshCraftStock() end
  redrawCalculator()
end

-- Events unavailable on a custom client must never prevent addon loading.
local f=CreateFrame("Frame")
A.craftEventSupport=A.craftEventSupport or {}
local function registerIfAvailable(event)
  local ok=pcall(f.RegisterEvent,f,event)
  A.craftEventSupport[event]=ok
  return ok
end
for _,event in ipairs({"BAG_UPDATE", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED",
  "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED",
  "PLAYER_LOGIN"}) do
  registerIfAvailable(event)
end

local settle=0
local pending=false
local bankPoll=0
local function schedule()
  pending=true
  settle=0
end
f:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then
    bagsDirty=true;lastBags=-1
    schedule()
  elseif event=="BANKFRAME_OPENED" then
    bankOpen=true;bankKnownThisVisit=false
    bagsDirty=true
    schedule()
  elseif event=="BANKFRAME_CLOSED" then
    -- Bank data may cease to be readable as soon as the frame closes.
    if stockEnabled() and bankOpen then A.RefreshCraftBank() end
    bankOpen=false;bagsDirty=true
    schedule()
  elseif event=="BAG_UPDATE" or event=="BAG_UPDATE_DELAYED" or
      event=="PLAYERBANKSLOTS_CHANGED" or event=="PLAYERBANKBAGSLOTS_CHANGED" then
    bagsDirty=true
    schedule()
  end
end)
f:SetScript("OnUpdate",function(_,elapsed)
  elapsed=tonumber(elapsed) or 0
  if pending then
    settle=settle+elapsed
    if settle>=0.25 then
      pending=false
      if stockEnabled() then
        A.RefreshCraftBags(true)
        if bankVisible() then A.RefreshCraftBank() end
        redrawCalculator()
      end
    end
  end
  -- Some custom bank frames do not emit the usual bank slot events. Polling
  -- only while the bank is open also catches transfers to and from custom bags.
  if stockEnabled() and bankVisible() then
    bankPoll=bankPoll+elapsed
    if bankPoll>=1.5 then
      bankPoll=0
      local store=characterStore()
      local oldBags=store.bags
      local oldBank=store.bank
      bagsDirty=true
      -- Keep old tables for comparison: RefreshCraftBags replaces the table.
      local newBags=A.RefreshCraftBags(true)
      local newBank=A.RefreshCraftBank()
      if not sameCounts(oldBags,newBags) or
         (newBank and not sameCounts(oldBank,newBank)) then redrawCalculator() end
    end
  else bankPoll=0 end
end)
