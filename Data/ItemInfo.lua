-- TradeScope 3.3.0: localized item metadata with persistent SavedVariables cache.
-- Private-server GetItemInfo can arrive late; never overwrite a good icon with '?'.
local A = ATS
local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"
local session = {}
-- Separate priority requests for items opened from the market scanner.
-- These are small, bounded retries; bulk indexing never blocks the interface.
local transient, pending, attempted = {}, {}, {}
local priorityPending = {}

local function idOf(value)
  if type(value) == "number" then return value end
  if type(value) ~= "string" then return nil end
  return tonumber(string.match(value,"item:(%d+)"))
      or tonumber(string.match(value,"db:(%d+)"))
      or tonumber(string.match(value,"^%s*(%d+)%s*$"))
end
A.ItemID = idOf

local function clean(name)
  if type(name) ~= "string" then return nil end
  local linked = string.match(name,"|h%[([^%]]+)%]|h")
  if linked then name=linked end
  name=string.gsub(name,"|c%x%x%x%x%x%x%x%x", "")
  name=string.gsub(name,"|r", "")
  name=string.gsub(name,"[%c]", "")
  name=string.match(name,"^%s*(.-)%s*$") or name
  if name == "" or name == "?" or string.match(name, "^#%d+$") then return nil end
  return name
end
A.CleanItemName = clean

local function normalized(name)
  -- Lua 5.1 string.lower does not lower-case Cyrillic UTF-8 letters.
  name=string.lower(name or "")
  name=string.gsub(name,"\208([\144-\159])",function(c) return "\208"..string.char(string.byte(c)+32) end)
  name=string.gsub(name,"\208([\160-\175])",function(c) return "\209"..string.char(string.byte(c)-32) end)
  name=string.gsub(name,"\208\129","\209\145")
  return name
end
local function validIcon(icon)
  if type(icon)=="string" then
    return icon~="" and icon~=UNKNOWN and icon~="INV_Misc_QuestionMark"
  end
  return type(icon)=="number" and icon>0
end

local function info(subject)
  if not subject then return nil,nil,nil end
  local name,link,icon
  if type(GetItemInfo)=="function" then
    local ok,n,l,_,_,_,_,_,_,_,i=pcall(GetItemInfo,subject)
    if ok then name=n;link=l;icon=i end
  end
  local api=type(C_Item)=="table" and C_Item or nil
  if api and (not name or not validIcon(icon)) then
    if type(api.GetItemInfo)=="function" then
      local ok,n,l,_,_,_,_,_,_,_,i=pcall(api.GetItemInfo,subject)
      if ok then name=name or n;link=link or l;icon=validIcon(icon) and icon or i end
    end
    local id=idOf(subject)
    if id and not name and type(api.GetItemNameByID)=="function" then
      local ok,n=pcall(api.GetItemNameByID,id)
      if ok then name=n end
    end
    if id and not validIcon(icon) and type(api.GetItemIconByID)=="function" then
      local ok,i=pcall(api.GetItemIconByID,id)
      if ok then icon=i end
    end
  end
  return clean(name),validIcon(icon) and icon or nil,link
end

local function iconByID(id)
  if not id then return nil end
  if type(GetItemIcon)=="function" then
    local ok,icon=pcall(GetItemIcon,id)
    if ok and validIcon(icon) then return icon end
  end
  if type(GetItemInfoInstant)=="function" then
    local ok,_,_,_,_,icon=pcall(GetItemInfoInstant,id)
    if ok and validIcon(icon) then return icon end
  end
  if type(C_Item)=="table" then
    if type(C_Item.GetItemIconByID)=="function" then
      local ok,icon=pcall(C_Item.GetItemIconByID,id)
      if ok and validIcon(icon) then return icon end
    end
    if type(C_Item.GetItemInfoInstant)=="function" then
      local ok,_,_,_,_,icon=pcall(C_Item.GetItemInfoInstant,id)
      if ok and validIcon(icon) then return icon end
    end
  end
end

local function fromBags(id)
  if not id or type(GetContainerNumSlots)~="function" or type(GetContainerItemLink)~="function" then return end
  for bag=0,4 do
    local ok,count=pcall(GetContainerNumSlots,bag)
    if ok and type(count)=="number" then
      for slot=1,math.min(count,54) do
        local found,link=pcall(GetContainerItemLink,bag,slot)
        if found and idOf(link)==id then
          local name=type(link)=="string" and clean(link) or nil
          local icon
          if type(GetContainerItemInfo)=="function" then
            local good,tex=pcall(GetContainerItemInfo,bag,slot)
            if good and validIcon(tex) then icon=tex end
          end
          return name,icon,link
        end
      end
    end
  end
end

local function storage()
  if not A.db then A.Init() end
  A.db.itemCache = type(A.db.itemCache)=="table" and A.db.itemCache or {}
  return A.db.itemCache
end

function A.RememberItem(link,name,icon)
  local id=idOf(link)
  if not id then return end
  local old=session[id] or storage()[id] or {}
  local value={name=old.name,icon=old.icon,link=old.link}
  local proper=clean(name)
  if proper and proper~=("#"..id) then value.name=proper end
  if validIcon(icon) then value.icon=icon end
  if type(link)=="string" and string.find(link,"|Hitem:",1,true) then value.link=link end
  -- Keep normalized IDs as keys: SavedVariables survive /reload reliably.
  storage()[id]=value
  session[id]=value
end

function A.RememberTooltipItem(tip,link)
  local id=idOf(link)
  if not id then return end
  local name,fullLink
  if tip and type(tip.GetItem)=="function" then
    local ok,n,l=pcall(tip.GetItem,tip)
    if ok then name=n;fullLink=l end
  end
  local owner=tip and tip.GetOwner and tip:GetOwner()
  local icon
  if owner then
    for _,field in ipairs({"icon","Icon","iconTexture","IconTexture"}) do
      local tex=owner[field]
      if tex and type(tex.GetTexture)=="function" then
        local ok,value=pcall(tex.GetTexture,tex)
        if ok and validIcon(value) then icon=value;break end
      end
    end
  end
  A.RememberItem(fullLink or link,name,icon)
end

function A.ResolveItemInfo(link,fallback)
  local id=idOf(link)
  if not id then return clean(fallback) or "?",UNKNOWN,false end
  local persisted=storage()[id] or {}
  local known=session[id] or persisted
  local indexed=(A.db.itemNameIndex or {})[id] or {}
  local name=clean(known.name) or clean(indexed.name) or clean(fallback)
  local icon=validIcon(known.icon) and known.icon or (validIcon(indexed.icon) and indexed.icon or nil)
  local fullLink=type(link)=="string" and string.find(link,"|Hitem:",1,true) and link or known.link
  local parsed=type(link)=="string" and clean(string.match(link,"|h%[([^%]]+)%]|h"))
  if parsed then name=parsed end
  local directName,directIcon,directLink=info(fullLink or link)
  if not directName or not directIcon then
    local n,i,l=info(id)
    directName=directName or n
    directIcon=directIcon or i
    directLink=directLink or l
  end
  name=directName or name
  icon=directIcon or icon or iconByID(id)
  if not name or not icon then
    local bagName,bagIcon,bagLink=fromBags(id)
    name=name or bagName
    icon=icon or bagIcon
    directLink=directLink or bagLink
  end
  if name or icon or directLink then A.RememberItem(directLink or fullLink or ("item:"..id),name,icon) end
  if not name then
    -- Classic GetItemInfo queues an asynchronous load; retail API is optional.
    pending[id] = true
    priorityPending[id] = priorityPending[id] or {attempts=0,next=0}
    if C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
      pcall(C_Item.RequestLoadItemDataByID,id)
    end
  else
    priorityPending[id] = nil
  end
  -- A full Auctionator scan can include an ID not yet present in the client cache.
  -- Never assume RememberItem ran: use safe placeholders until item info arrives.
  local final=storage()[id] or known or indexed or {}
  local finalName=clean(final.name)
  local finalIcon=validIcon(final.icon) and final.icon or UNKNOWN
  return finalName or ("#"..id), finalIcon,
      finalName~=nil and validIcon(final.icon), final.link
end

-- UTF-8-safe shortening; use the actual WoW font width where available.
local function splitUTF8(s)
  local chars={}
  local i=1
  while i<=#s do
    local b=string.byte(s,i)
    local length=b<128 and 1 or (b>=240 and 4 or (b>=224 and 3 or (b>=192 and 2 or 1)))
    chars[#chars+1]=string.sub(s,i,i+length-1)
    i=i+length
  end
  return chars
end
function A.FitItemName(name,fontString,maxWidth)
  name=clean(name) or "?"
  local characters=splitUTF8(name)
  if #characters<3 then return name end
  if fontString and type(fontString.GetStringWidth)=="function" and type(fontString.SetText)=="function" then
    fontString:SetText(name)
    local ok,width=pcall(fontString.GetStringWidth,fontString)
    if ok and type(width)=="number" and width<=maxWidth then return name end
    for len=#characters-1,1,-1 do
      local trial=table.concat(characters,"",1,len).."..."
      fontString:SetText(trial)
      local good,w=pcall(fontString.GetStringWidth,fontString)
      if good and type(w)=="number" and w<=maxWidth then return trial end
    end
  end
  if #characters>21 then return table.concat(characters,"",1,18).."..." end
  return name
end

-- Searchable, incremental index of items known to the local Auctionator DB.
-- WoW has no general client API to enumerate every possible item on the server.
-- We therefore index all price-database entries plus previously cached items,
-- and progressively resolve item names from the client's item cache.
local persistedCount
local function persistIndexed(id,name,icon)
  if not clean(name) then return end
  local t=A.db.itemNameIndex
  if type(t)~="table" then t={};A.db.itemNameIndex=t end
  if persistedCount==nil then
    persistedCount=0
    for _ in pairs(t) do persistedCount=persistedCount+1 end
  end
  if t[id]==nil then
    if persistedCount>=20000 then return end
    persistedCount=persistedCount+1
  end
  t[id]={name=name,icon=validIcon(icon) and icon or nil}
end
local indexStats = { scanned = 0, resolved = 0, total = 0 }
A.itemIndexStats = indexStats

local function idFromDBKey(key)
  if type(key) == "number" then return key end
  if type(key) ~= "string" then return nil end
  return tonumber(string.match(key, "^(%d+)"))
      or tonumber(string.match(key, "^g:(%d+)"))
      or tonumber(string.match(key, "^gr:(%d+)"))
end

local function indexID(id)
  if not id or id <= 0 or attempted[id] then return end
  attempted[id] = true
  local saved=storage()[id] or (A.db.itemNameIndex and A.db.itemNameIndex[id])
  if saved and clean(saved.name) then return end
  local name, icon, link=info(id)
  if name then
    transient[id]={name=name,icon=icon or iconByID(id),link=link}
    persistIndexed(id,name,icon or iconByID(id))
    indexStats.resolved=indexStats.resolved+1
  else
    pending[id]=true -- Wait for GET_ITEM_INFO_RECEIVED; don't invent a name.
  end
end

function A.CacheIndexedItem(id)
  id=tonumber(id)
  if not id or (not pending[id] and not attempted[id] and not priorityPending[id]) then return end
  local name,icon,link=info(id)
  if name then
    if not transient[id] then indexStats.resolved=indexStats.resolved+1 end
    transient[id]={name=name,icon=icon or iconByID(id),link=link}
    persistIndexed(id,name,icon or iconByID(id))
    A.RememberItem(link or ("item:"..id),name,icon or iconByID(id))
    pending[id]=nil
    priorityPending[id]=nil
  end
end

-- On some custom clients GET_ITEM_INFO_RECEIVED is absent or late. Retry
-- only explicitly opened items, never the entire Auctionator price database.
function A.RetryPendingItemInfo(maxCount)
  local now = GetTime and GetTime() or 0
  local checked = 0
  for id, entry in pairs(priorityPending) do
    if checked >= (maxCount or 6) then break end
    if now >= entry.next then
      checked = checked + 1
      entry.attempts = entry.attempts + 1
      entry.next = now + 1.5 + math.min(10, entry.attempts)
      A.CacheIndexedItem(id)
      if entry.attempts >= 8 then priorityPending[id] = nil end
    end
  end
end

-- Newly scanned items are added without needing to rebuild the entire index.
function A.IndexScannedItem(key)
  local id=idFromDBKey(key)
  if id and not attempted[id] then indexID(id) end
end

function A.StartItemNameIndex()
  if A.itemIndexRunning or A.itemIndexFinished then return end
  local auctionator=_G.Auctionator
  local market=type(auctionator)=="table" and auctionator.Database
  local db=type(market)=="table" and market.db
  if type(db)~="table" then return end
  -- Re-run on reopening: the Auctionator DB may have grown since last time.
  A.itemIndexRunning=true
  A.itemIndexFinished=false
  local keyCursor=nil
  local scannedThisPass=0
  local worker=CreateFrame("Frame")
  worker:SetScript("OnUpdate",function(self,elapsed)
    self.elapsed=(self.elapsed or 0)+elapsed
    if self.elapsed<0.10 then return end
    self.elapsed=0
    for i=1,20 do
      local ok,key=pcall(next,db,keyCursor)
      if not ok then
        -- Auctionator can replace its database while scanning. Retry on open.
        self:SetScript("OnUpdate",nil)
        A.itemIndexRunning=false
        return
      end
      if key==nil or scannedThisPass>=100000 then
        self:SetScript("OnUpdate",nil)
        A.itemIndexRunning=false
        A.itemIndexFinished=true
        return
      end
      keyCursor=key
      scannedThisPass=scannedThisPass+1
      indexStats.scanned=indexStats.scanned+1
      local id=idFromDBKey(key)
      if id then indexID(id) end
    end
  end)
  A.itemIndexWorker=worker
end

-- A lightweight read-only lookup for scanner rendering. Do not request item
-- data for hundreds of rows every time the UI is redrawn.
function A.PeekItemMetadata(link)
  local id=idOf(link)
  if not id then return nil,nil,nil,false end
  local cached=storage()[id] or {}
  local indexed=(A.db.itemNameIndex or {})[id] or {}
  local fresh=session[id] or {}
  local name=clean(fresh.name) or clean(cached.name) or clean(indexed.name)
  local icon=(validIcon(fresh.icon) and fresh.icon) or
    (validIcon(cached.icon) and cached.icon) or
    (validIcon(indexed.icon) and indexed.icon) or UNKNOWN
  return name,icon,id,name~=nil
end

-- Explicitly visible scanner results need their localized item metadata.
-- Auctionator's price DB stores keys and numbers, not localized item names.
-- Query conservatively (one ID every 0.35 sec) to avoid spamming the server.
-- On clients without C_Item, a dedicated hidden tooltip can request the link.
local scanQueue,scanQueued,scanAt,scanWorker={}, {},1,nil
local probeTooltip
local function probeItem(id)
  local n,i,link=info(id)
  if n then
    A.RememberItem(link or ("item:"..id),n,i or iconByID(id))
    pending[id]=nil
    return
  end
  pending[id]=true
  local citem=type(C_Item)=="table" and C_Item or nil
  if citem and type(citem.RequestLoadItemDataByID)=="function" then
    pcall(citem.RequestLoadItemDataByID,id)
  end
  -- Some Forever client builds fetch item details through hyperlink tooltips.
  -- Use a private tooltip, never the tooltip currently under the mouse.
  if type(CreateFrame)=="function" and not probeTooltip then
    local ok,result=pcall(CreateFrame,"GameTooltip","ATSTradeScopeScannerProbe",UIParent,"GameTooltipTemplate")
    if ok then probeTooltip=result end
  end
  if probeTooltip and type(probeTooltip.SetHyperlink)=="function" then
    pcall(function()
      if type(probeTooltip.SetOwner)=="function" then probeTooltip:SetOwner(UIParent,"ANCHOR_NONE") end
      probeTooltip:SetHyperlink("item:"..id)
      local tooltipName
      if type(probeTooltip.GetItem)=="function" then
        local _,itemLink=probeTooltip:GetItem()
        local nn,ii,ll=info(itemLink)
        tooltipName=nn
        if tooltipName then A.RememberItem(ll or itemLink,nn,ii) end
      end
      probeTooltip:Hide()
    end)
  end
  A.CacheIndexedItem(id)
end

function A.QueueScannerItemMetadata(results, maximum)
  if type(results)~="table" then return end
  maximum=math.max(1,math.min(500,tonumber(maximum) or 250))
  local count=0
  for i=1,#results do
    if count>=maximum then break end
    local key=results[i] and results[i].key
    local id=idOf(key)
    if not id and A.ProItemLink then id=idOf(A.ProItemLink(key)) end
    if id and id>0 and not scanQueued[id] then
      local name,icon=A.PeekItemMetadata(id)
      if not name or not validIcon(icon) then
        scanQueued[id]=true
        scanQueue[#scanQueue+1]=id
        count=count+1
      end
    end
  end
  if not scanWorker then
    scanWorker=CreateFrame("Frame")
    scanWorker.elapsed=0
  end
  scanWorker:SetScript("OnUpdate",function(self,elapsed)
    self.elapsed=self.elapsed+(elapsed or 0)
    if self.elapsed<0.35 then return end
    self.elapsed=0
    local id=scanQueue[scanAt]
    if not id then
      self:SetScript("OnUpdate",nil)
      -- Reset queue bookkeeping; a later scan can retry newly available IDs.
      scanQueue={};scanQueued={};scanAt=1
      return
    end
    scanAt=scanAt+1
    probeItem(id)
  end)
end

-- Search by substring (including Cyrillic UTF-8) and item-ID prefix. All known
-- Auctionator entries participate, not just manually watched items.
function A.FindKnownItems(query,limit)
  local lower=normalized(clean(query) or "")
  if lower=="" then return {} end
  local matches,added={},{}
  local byID=string.match(lower,"^%d+$")~=nil
  local function collect(source)
    for rawID,meta in pairs(source) do
      local id=tonumber(rawID)
      if id and not added[id] and type(meta)=="table" then
        local name=clean(meta.name)
        local nameMatch=name and string.find(normalized(name),lower,1,true)
        local idMatch=byID and string.find(tostring(id),lower,1,true)==1
        if nameMatch or idMatch then
          matches[#matches+1]={id=id,name=name or ("#"..id),icon=meta.icon,link=meta.link or ("item:"..id)}
          added[id]=true
        end
      end
    end
  end
  collect(transient)
  collect(storage())
  collect(A.db.itemNameIndex or {})
  table.sort(matches,function(a,b)
    local aName,bName=normalized(a.name),normalized(b.name)
    local aExact,bExact=aName==lower and 0 or 1,bName==lower and 0 or 1
    if aExact~=bExact then return aExact<bExact end
    local aPrefix,bPrefix=string.sub(aName,1,#lower)==lower and 0 or 1,
                           string.sub(bName,1,#lower)==lower and 0 or 1
    if aPrefix~=bPrefix then return aPrefix<bPrefix end
    if aName~=bName then return aName<bName end
    return a.id<b.id
  end)
  local max=math.max(1,math.min(500,tonumber(limit) or 40))
  for i=#matches,max+1,-1 do matches[i]=nil end
  return matches
end
