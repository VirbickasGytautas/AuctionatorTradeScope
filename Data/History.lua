-- Auctionator TradeScope 3.0.0 - timestamped samples from Auctionator updates.
local A = ATS

local function safeCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if ok and A.Valid(value) then return value end
end

function A.LegacyKey(link)
  if type(link) ~= "string" then return nil end
  return string.match(link, "|H(item:[^|]+)|h") or string.match(link, "^(item:[^|]+)")
end

function A.Key(link)
  local legacy = A.LegacyKey(link)
  if not legacy then return nil end
  local id = string.match(legacy, "^item:(%d+)")
  if not id then return nil end
  local auctionator = _G.Auctionator
  local utils = type(auctionator) == "table" and auctionator.Utilities
  local derive = type(utils) == "table" and utils.DBKeyFromLink
  if type(derive) == "function" then
    local keys
    local ok = pcall(derive, link, function(result) keys = result end)
    if ok and type(keys) == "table" and type(keys[1]) == "string" then
      return "db:" .. keys[1]
    end
  end
  return "db:" .. id
end

function A.Price(link)
  if type(link) ~= "string" then return nil end
  local auctionator = _G.Auctionator
  local api = type(auctionator) == "table" and auctionator.API
  local v1 = type(api) == "table" and api.v1
  if type(v1) == "table" then
    local price = safeCall(v1.GetAuctionPriceByItemLink, "AuctionatorTradeScope", link)
    if price then A.source = "Auctionator API: itemLink"; return price end
    local id = tonumber(string.match(link, "item:(%d+)"))
    if id then
      price = safeCall(v1.GetAuctionPriceByItemID, "AuctionatorTradeScope", id)
      if price then A.source = "Auctionator API: itemID"; return price end
    end
  end
  local price = safeCall(_G.Atr_GetAuctionBuyout, link) or safeCall(_G.Atr_GetAuctionPrice, link)
  A.source = price and "Atr API" or "none"
  return price
end

function A.Days(key, create)
  A.Init()
  if not key then return nil end
  local realm = A.RealmKey()
  local realmData = A.db.realms[realm]
  if not realmData and create then
    realmData = {}
    A.db.realms[realm] = realmData
  end
  if not realmData then return nil end
  realmData.variants = type(realmData.variants) == "table" and realmData.variants or {}
  if not realmData.variants[key] and create then realmData.variants[key] = {} end
  return realmData.variants[key]
end

-- 4.1.0: normalised, bounded observations with an in-memory read-through cache.
-- Existing SavedVariables are normalised lazily, once per item. Nothing is reset.
local ENGINE_VERSION = 1
local CACHE_LIFETIME = 20
local CACHE_LIMIT = 192
local CACHE_POINTS = 12000 -- also cap memory for items with very long histories
local sampleCache, cacheCount, cachePoints = {}, 0, 0
local cachedKeys={}
A.dataEngineStats = {hits=0, misses=0, migrated=0, rejected=0, duplicates=0}

function A.InvalidateHistoryCache(key)
  if not key then sampleCache={};cachedKeys={};cacheCount=0;cachePoints=0;return end
  -- Full-scan hooks update thousands of different items. Most keys are not
  -- currently cached, so avoid traversing the cache for each SetPrice call.
  if not cachedKeys[key] then return end
  for token, cached in pairs(sampleCache) do
    if cached.key==key or cached.legacy==key then
      sampleCache[token]=nil
      cacheCount=math.max(0,cacheCount-1)
      cachePoints=math.max(0,cachePoints-#cached.samples)
    end
  end
end

local function validTimestamp(t)
  return type(t)=="number" and t==t and t>0 and t<math.huge
end
local function cleanQuantity(value)
  local q=tonumber(value)
  if type(q)=="number" and q==q and q>=0 and q<math.huge then
    return math.floor(q+0.5)
  end
  return nil
end
local function migrate(history)
  if history._tsEngineVersion==ENGINE_VERSION then return end
  local rows={}
  for index,entry in pairs(history) do
    if type(entry)=="table" then
      local t=tonumber(entry.t or entry.observed)
      local p=tonumber(entry.p or entry.price)
      if validTimestamp(t) and A.Valid(p) then
        rows[#rows+1]={t=t,p=p,q=cleanQuantity(entry.q or entry.available),
          s=entry.s or "legacy",_index=type(index)=="number" and index or 0}
      else
        A.dataEngineStats.rejected=A.dataEngineStats.rejected+1
      end
    end
  end
  table.sort(rows,function(a,b)
    if a.t~=b.t then return a.t<b.t end
    return a._index<b._index
  end)
  -- Same timestamp means the latest incoming quote wins. If the price is
  -- identical, preserve a known quantity rather than replacing it with nil.
  local merged={}
  for i=1,#rows do
    local entry=rows[i]
    local previous=merged[#merged]
    if previous and previous.t==entry.t then
      if previous.p==entry.p and entry.q==nil then entry.q=previous.q end
      merged[#merged]=entry
      A.dataEngineStats.duplicates=A.dataEngineStats.duplicates+1
    else
      merged[#merged+1]=entry
    end
  end
  for k in pairs(history) do history[k]=nil end
  for i=1,#merged do
    local v=merged[i]
    history[i]={t=v.t,p=v.p,q=v.q,s=v.s}
  end
  history._apwMigrated=true
  history._tsEngineVersion=ENGINE_VERSION
  A.dataEngineStats.migrated=A.dataEngineStats.migrated+1
end

local function prune(history,now,days)
  local cutoff=now-days*86400
  local first=1
  local size=#history
  while first<=size and history[first].t<cutoff do first=first+1 end
  -- Preserve the configured retention window, while limiting memory and
  -- SavedVariables growth for players who scan frequently.
  first=math.max(first,size-1800+1)
  if first<=1 then return end
  local destination=1
  for i=first,size do history[destination]=history[i];destination=destination+1 end
  for i=destination,size do history[i]=nil end
end

function A.Record(key,price,origin,quantity)
  if not key or not A.Valid(price) then return false end
  A.Init()
  local history=A.Days(key,true)
  migrate(history)
  local now=time()
  local last=history[#history]
  local q=cleanQuantity(quantity)
  local sameQuantity=last and (q==nil or last.q==q)
  local samePrice=last and last.p==price
  if last and now==last.t then
    -- Several SetPrice notifications in a single second are one observation.
    -- Record the final price and latest known quantity without inventing time.
    local changed=not samePrice or (q~=nil and last.q~=q)
    if changed then
      last.p=price
      if q~=nil then last.q=q end
      last.s=(origin=="scan" or origin=="hover") and origin or last.s
      A.InvalidateHistoryCache(key)
    end
    return changed
  end
  if last and samePrice and sameQuantity and now>last.t and
      now-last.t < A.db.sampleInterval then return false end
  local point={t=now,p=price,q=q,s=origin=="scan" and "scan" or (origin=="hover" and "hover" or "unknown")}
  if not last or now>=last.t then
    history[#history+1]=point
  else
    -- System clock changed backward. Keep samples ordered without fabricating
    -- a later timestamp for the new scan.
    local i=#history
    while i>=1 and history[i].t>now do history[i+1]=history[i];i=i-1 end
    history[i+1]=point
  end
  prune(history,now,A.db.retentionDays)
  A.InvalidateHistoryCache(key)
  A.stats=A.stats or {scan=0,hover=0}
  if origin=="scan" then A.stats.scan=A.stats.scan+1
  elseif origin=="hover" then A.stats.hover=A.stats.hover+1 end
  return true
end

function A.AllSamples(key,legacyKey)
  A.Init()
  if not key then return {} end
  local now=time()
  local realm=A.RealmKey()
  local token=realm.."|"..tostring(key).."|"..tostring(legacyKey or "")
  local cached=sampleCache[token]
  if cached and now>=cached.time and now-cached.time<CACHE_LIFETIME then
    A.dataEngineStats.hits=A.dataEngineStats.hits+1
    return cached.samples
  end
  A.dataEngineStats.misses=A.dataEngineStats.misses+1
  local all={}
  local ordinal=0
  local function add(storageKey,priority)
    if not storageKey then return end
    local history=A.Days(storageKey,false)
    if not history then return end
    migrate(history)
    prune(history,now,A.db.retentionDays)
    for i=1,#history do
      local v=history[i]
      if v.t<=now and A.Valid(v.p) then
        ordinal=ordinal+1
        all[#all+1]={t=v.t,price=v.p,quantity=v.q,origin=v.s,
          _priority=priority,_ordinal=ordinal}
      end
    end
  end
  -- Merge duplicate legacy/canonical keys without double counting scans.
  add(legacyKey and legacyKey~=key and legacyKey or nil,1)
  add(key,2)
  table.sort(all,function(a,b)
    if a.t~=b.t then return a.t<b.t end
    if a._priority~=b._priority then return a._priority<b._priority end
    return a._ordinal<b._ordinal
  end)
  local result={}
  for i=1,#all do
    local e=all[i]
    local previous=result[#result]
    if previous and previous.t==e.t then
      if e.quantity==nil and e.price==previous.price then e.quantity=previous.quantity end
      result[#result]=e
    else result[#result+1]=e end
    e._priority=nil;e._ordinal=nil
  end
  if cached then
    sampleCache[token]=nil
    cacheCount=math.max(0,cacheCount-1)
    cachePoints=math.max(0,cachePoints-#cached.samples)
  end
  if cacheCount>=CACHE_LIMIT or cachePoints+#result>CACHE_POINTS then
    sampleCache={};cachedKeys={};cacheCount=0;cachePoints=0
  end
  cacheCount=cacheCount+1
  cachePoints=cachePoints+#result
  sampleCache[token]={time=now,samples=result,key=key,legacy=legacyKey}
  cachedKeys[key]=true
  if legacyKey then cachedKeys[legacyKey]=true end
  return result
end

-- Data coverage is not a probability of sale or a statement about unobserved
-- periods. Each time bucket is populated only by an actual saved observation.
function A.DataCoverage(samples,hours,now)
  now=now or time()
  hours=math.max(1,tonumber(hours) or 24)
  local span=hours*3600
  local bucketSeconds=hours<=24 and 3600 or (hours<=168 and 21600 or 86400)
  local bucketCount=math.max(1,math.ceil(span/bucketSeconds))
  local present={}
  local occupied=0
  local first,last,previous,maxGap=nil,nil,nil,0
  local count,scans,hover=0,0,0
  for i=1,#(samples or {}) do
    local s=samples[i]
    if s.t and s.t>=now-span and s.t<=now and A.Valid(s.price) then
      count=count+1
      if s.origin=="scan" then scans=scans+1
      elseif s.origin=="hover" then hover=hover+1 end
      local slot=math.max(1,math.min(bucketCount,math.floor((s.t-(now-span))/bucketSeconds)+1))
      if not present[slot] then present[slot]=true;occupied=occupied+1 end
      first=first or s.t
      if previous then maxGap=math.max(maxGap,s.t-previous) end
      previous=s.t
      last=s.t
    end
  end
  return {observations=count,scanObservations=scans,hoverObservations=hover,
    occupiedBuckets=occupied,totalBuckets=bucketCount,
    coveragePercent=100*occupied/bucketCount,
    lastAgeHours=last and math.max(0,(now-last)/3600) or nil,
    maxGapHours=maxGap/3600,
    spanHours=first and last and (last-first)/3600 or 0,
    bucketHours=bucketSeconds/3600}
end

-- A sparse timeline for future indicator revisions. Missing buckets stay nil.
function A.ObservedBuckets(samples,hours,bucketHours,now)
  now=now or time()
  hours=math.max(1,tonumber(hours) or 24)
  bucketHours=math.max(1,tonumber(bucketHours) or 1)
  local span=hours*3600
  local step=bucketHours*3600
  local count=math.max(1,math.ceil(span/step))
  local start=now-span
  local out={}
  for i=1,count do out[i]={t=start+(i-1)*step,count=0} end
  for i=1,#(samples or {}) do
    local s=samples[i]
    if s.t and s.t>=start and s.t<=now and A.Valid(s.price) then
      local ix=math.max(1,math.min(count,math.floor((s.t-start)/step)+1))
      local row=out[ix]
      row.first=row.first or s.price
      row.last=s.price
      row.min=math.min(row.min or s.price,s.price)
      row.max=math.max(row.max or s.price,s.price)
      row.count=row.count+1
    end
  end
  return out
end

function A.ChartHours(key, legacyKey, observations)
  A.Init()
  local mode = A.db.chartMode
  if mode == "day" then return 24 end
  if mode == "week" then return 168 end
  if mode == "month" then return 720 end
  if mode == "custom" then return A.db.customHours end

  local samples = observations or A.AllSamples(key, legacyKey)
  if #samples == 0 then return 24 end
  local now = time()
  local windows = { 3, 6, 12, 24, 72, 168, 336, 720, 2160 }
  local retentionHours = math.max(24, A.db.retentionDays * 24)
  for w = 1, #windows do
    local hours = windows[w]
    if hours <= retentionHours then
      local cutoff = now - hours * 3600
      local changes, previous = 0, nil
      for i = 1, #samples do
        local value = samples[i]
        if value.t >= cutoff then
          if previous and previous ~= value.price then changes = changes + 1 end
          previous = value.price
        end
      end
      if changes >= A.db.autoChanges then return hours end
    end
  end
  local oldestHours = math.max(0, (now - samples[1].t) / 3600)
  local fallbacks = { 24, 72, 168, 336, 720, 2160 }
  for i = 1, #fallbacks do
    if oldestHours <= fallbacks[i] and fallbacks[i] <= retentionHours then
      return fallbacks[i]
    end
  end
  return math.min(2160, retentionHours)
end

function A.Values(key, legacyKey, hours, observations)
  local samples = observations or A.AllSamples(key, legacyKey)
  hours = hours or A.ChartHours(key, legacyKey, samples)
  local now = time()
  local cutoff = now - hours * 3600
  local visible = {}
  for i = 1, #samples do
    local entry = samples[i]
    if entry.t >= cutoff and entry.t <= now then
      visible[#visible + 1] = entry
    end
  end
  if #visible <= 400 then return visible end

  local reduced = {}
  local bucketSize = math.ceil(#visible / 100)
  for first = 1, #visible, bucketSize do
    local last = math.min(#visible, first + bucketSize - 1)
    local lowest, highest = first, first
    for i = first + 1, last do
      if visible[i].price < visible[lowest].price then lowest = i end
      if visible[i].price > visible[highest].price then highest = i end
    end
    local selection = { first, lowest, highest, last }
    table.sort(selection)
    local previous
    for i = 1, #selection do
      local index = selection[i]
      if index ~= previous then
        reduced[#reduced + 1] = visible[index]
        previous = index
      end
    end
  end
  return reduced
end

function A.QuantityStats(key, legacyKey, observations)
  local samples = observations or A.AllSamples(key, legacyKey)
  local current, sold, hasQuantity = nil, 0, false
  for i = #samples, 1, -1 do
    if samples[i].quantity ~= nil then
      current = samples[i].quantity
      hasQuantity = true
      break
    end
  end

  local cutoff = time() - 24 * 3600
  local previousQty, previousTime = nil, nil
  local maxCompareSeconds=math.max(1,tonumber(A.db.maxCompareGapHours) or 12)*3600
  for i = 1, #samples do
    local quantity = samples[i].quantity
    if quantity ~= nil then
      hasQuantity = true
      if previousQty~=nil and previousTime and samples[i].t>=cutoff and
          previousTime>=cutoff and samples[i].t-previousTime<=maxCompareSeconds and
          quantity<previousQty then
        sold=sold+(previousQty-quantity)
      end
      previousQty=quantity
      previousTime=samples[i].t
    end
  end
  if not hasQuantity then return nil, nil end
  return current, sold
end
