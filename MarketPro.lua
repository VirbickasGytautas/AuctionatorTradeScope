-- TradeScope 4.0: observation-based market research and opt-in manual ledgers.
-- No claim of confirmed other-player sales or live server order book.
local A=ATS
local floor, min, max, abs, sqrt = math.floor, math.min, math.max, math.abs, math.sqrt

local function cfg() A.Init(); return A.db.pro end
local function itemID(key)
  return tonumber(type(key)=="string" and (key:match("^db:(%d+)") or
    key:match("^db:g:(%d+)") or key:match("^db:gr:(%d+)") or
    key:match("item:(%d+)")) or nil)
end
function A.ProItemLink(key)
  local id=itemID(key)
  return id and ("item:"..id) or nil
end
function A.ProItemMeta(key)
  local id=itemID(key)
  if not id then return tostring(key), "Interface\\Icons\\INV_Misc_QuestionMark", nil, false end
  local name,icon,ready=A.ResolveItemInfo("item:"..id)
  return name or ("#"..id),icon or "Interface\\Icons\\INV_Misc_QuestionMark",id,ready
end
function A.ProItemName(key)
  return (A.ProItemMeta(key))
end
function A.ProRealmHistories()
  local r=A.db.realms[A.RealmKey()]
  return r and r.variants or {}
end
function A.ProSamples(key)
  return A.AllSamples(key,nil)
end
local function priced(samples)
  local t={}
  for i=1,#samples do
    if A.Valid(samples[i].price) then t[#t+1]=samples[i] end
  end
  return t
end
function A.ProQuality(samples)
  local t=priced(samples)
  local n=#t
  if n==0 then return {score=0,count=0,age=nil,coverage=0,maxGap=nil,
    uniqueHours=0,label="none",coveragePercent=0,scanObservations=0,hoverObservations=0} end
  local now=time()
  local newest=t[n].t
  local age=max(0,(now-newest)/3600)
  local coverage=max(0,(newest-t[1].t)/3600)
  local unique,gap,previous={},0,nil
  for i=1,n do
    unique[floor(t[i].t/3600)]=true
    if previous then gap=max(gap,(t[i].t-previous)/3600) end
    previous=t[i].t
  end
  local buckets=0
  for _ in pairs(unique) do buckets=buckets+1 end
  -- Coverage always means presence of REAL snapshots in a time bucket.
  -- It does not measure demand or the chance of a successful sale.
  local window=max(24,min(168,math.ceil(max(1,coverage))))
  local observed=A.DataCoverage(t,window,now)
  local score=100*(.35*min(1,buckets/20)+.25*min(1,coverage/168)+
    .30*max(0,1-min(1,age/72))+
    .10*min(1,observed.coveragePercent/35))
  if gap>48 then score=score*.82 end
  score=floor(max(0,min(100,score))+.5)
  return {score=score,count=n,age=age,coverage=coverage,maxGap=gap,
    uniqueHours=buckets,coveragePercent=observed.coveragePercent,
    coverageBucketHours=observed.bucketHours,
    scanObservations=observed.scanObservations,
    hoverObservations=observed.hoverObservations,
    unknownObservations=observed.observations-observed.scanObservations-observed.hoverObservations,
    coverageWindowHours=window,
    label=score>=75 and "high" or (score>=45 and "medium" or "low")}
end

-- Technical Indicators 2.0: one genuine observed closing quote per time bucket.
-- No interpolation of empty buckets, no fictitious traded volume and no
-- comparison across gaps beyond the selected maximum history gap.
function A.ProIndicators(samples, period)
  local p=cfg()
  local bucketMinutes=max(5,min(120,floor(tonumber(p.indicatorBucketMinutes) or 15)))
  local bucketSeconds=bucketMinutes*60
  local gapHours=max(1,min(48,tonumber(p.indicatorGapHours) or 12))
  local gapSeconds=gapHours*3600
  local ep=max(2,min(100,floor(tonumber(period) or tonumber(p.emaPeriod) or 10)))
  local rp=max(2,min(100,floor(tonumber(p.rsiPeriod) or 14)))
  local bp=max(2,min(100,floor(tonumber(p.bollPeriod) or 20)))
  local recent={}
  for i=1,#(samples or {}) do
    local sample=samples[i]
    if type(sample)=='table' and type(sample.t)=='number' and
      sample.t==sample.t and A.Valid(sample.price) then
      recent[#recent+1]={t=sample.t,p=sample.price}
    end
  end
  table.sort(recent,function(a,b)return a.t<b.t end)
  local buckets={}
  for i=1,#recent do
    local entry=recent[i]
    local slot=floor(entry.t/bucketSeconds)
    local last=buckets[#buckets]
    if last and last.slot==slot then
      -- Last actual quote in this bucket is its observed closing quote.
      last.t=entry.t
      last.p=entry.p
      last.count=last.count+1
    else
      buckets[#buckets+1]={slot=slot,t=entry.t,p=entry.p,count=1}
    end
  end
  local out={count=#recent,bucketCount=#buckets,bucketMinutes=bucketMinutes,
    bucketSeconds=bucketSeconds,gapHours=gapHours,values={},points=recent,
    requestedRSI=rp,requestedEMA=ep,requestedBollinger=bp,segments=0}
  if #buckets==0 then return out end
  local ema,emaFast,emaSlow,signal,gains,losses=nil,nil,nil,nil,0,0
  local segment=0
  local segmentCount=0
  local last
  local prices={}
  local rsiReady=false
  for i=1,#buckets do
    local b=buckets[i]
    local broken=last and b.t-last.t>gapSeconds
    if not last or broken then
      segment=segment+1;segmentCount=0
      ema=nil;emaFast=nil;emaSlow=nil;signal=nil
      gains=0;losses=0;rsiReady=false;prices={}
    end
    segmentCount=segmentCount+1
    local value=b.p
    local a=2/(ep+1)
    ema=ema and (ema+a*(value-ema)) or value
    emaFast=emaFast and (emaFast+2/13*(value-emaFast)) or value
    emaSlow=emaSlow and (emaSlow+2/27*(value-emaSlow)) or value
    local macd=emaFast-emaSlow
    signal=signal and (signal+2/10*(macd-signal)) or macd
    local rsi,rsiPreliminary,usedRsiChanges
    if segmentCount>1 and last then
      local delta=value-last.p
      local up=max(0,delta);local down=max(0,-delta)
      if not rsiReady then
        gains=gains+up;losses=losses+down
        if segmentCount-1>=rp then
          gains=gains/rp;losses=losses/rp
          rsiReady=true
        end
      else
        gains=(gains*(rp-1)+up)/rp
        losses=(losses*(rp-1)+down)/rp
      end
    end
    local changes=segmentCount-1
    local allowPreliminary=p.indicatorRSIPreview~=false
    if changes>=rp or (allowPreliminary and changes>=3) then
      local g=rsiReady and gains or gains/changes
      local loss=rsiReady and losses or losses/changes
      if g==0 and loss==0 then rsi=50
      elseif loss==0 then rsi=100
      elseif g==0 then rsi=0
      else rsi=100-100/(1+g/loss) end
      rsiPreliminary=not rsiReady
      usedRsiChanges=min(rp,changes)
    end
    prices[#prices+1]=value
    if #prices>bp then table.remove(prices,1) end
    local avg,upper,lower
    if #prices>=bp then
      local sum=0
      for j=1,#prices do sum=sum+prices[j] end
      avg=sum/#prices
      local variance=0
      for j=1,#prices do
        local diff=prices[j]-avg
        variance=variance+diff*diff
      end
      local deviation=sqrt(max(0,variance/#prices))
      upper=avg+2*deviation
      lower=avg-2*deviation
    end
    local current={t=b.t,p=value,slot=b.slot,observations=b.count,
      segment=segment,segmentCount=segmentCount,disconnected=broken and true or false,
      ema=ema,macd=macd,signal=signal,hist=macd-signal,
      macdPreliminary=segmentCount<26,signalPreliminary=segmentCount<34,
      rsi=rsi,rsiPreliminary=rsiPreliminary,rsiChanges=usedRsiChanges,
      upper=upper,lower=lower,bollMiddle=avg}
    out.values[#out.values+1]=current
    last=b
  end
  out.segments=segment
  out.latest=out.values[#out.values]
  out.latestSegmentBuckets=segmentCount
  out.missingRSI=max(0,rp-(segmentCount-1))
  out.missingBollinger=max(0,bp-segmentCount)
  return out
end

function A.ProCandles(samples,periodHours,bucketHours)
  local out,indices={},{}
  local endTime=time()
  local cutoff=endTime-max(1,periodHours)*3600
  local bucket=max(1,bucketHours)*3600
  for i=1,#samples do
    local s=samples[i]
    if s.t>=cutoff and s.t<=endTime and A.Valid(s.price) then
      local k=floor(s.t/bucket)
      if not indices[k] then
        local candle={t=k*bucket,open=s.price,high=s.price,low=s.price,close=s.price,count=0}
        out[#out+1]=candle;indices[k]=candle
      end
      local c=indices[k]
      c.high=max(c.high,s.price);c.low=min(c.low,s.price);c.close=s.price;c.count=c.count+1
    end
  end
  table.sort(out,function(a,b) return a.t<b.t end)
  return out
end

function A.ProHeatmap(samples,days)
  local cells={}
  local cutoff=time()-max(7,days or cfg().heatmapDays)*86400
  for weekday=1,7 do cells[weekday]={};for hour=0,23 do cells[weekday][hour]={count=0,sum=0,min=nil,max=nil} end end
  for i=1,#samples do
    local s=samples[i]
    if s.t>=cutoff and A.Valid(s.price) then
      local d=date("*t",s.t)
      if d and d.wday and d.hour then
        local w=(d.wday+5)%7+1 -- Mon=1, Sun=7
        local cell=cells[w][d.hour]
        cell.count=cell.count+1;cell.sum=cell.sum+s.price
        cell.min=min(cell.min or s.price,s.price)
        cell.max=max(cell.max or s.price,s.price)
      end
    end
  end
  return cells
end

function A.ProActivity(key,samples)
  local p=cfg();local all=samples or A.ProSamples(key)
  local m=A.MarketMetrics(key,nil,all,max(24,p.activityWindowHours))
  local q=A.ProQuality(all)
  local cutoff=time()-max(1,p.activityWindowHours)*3600
  local recent, priceChanges, qtyChanges, lastPrice, lastQuantity=0,0,0,nil,nil
  for i=1,#all do
    local s=all[i]
    if s.t>=cutoff then
      recent=recent+1
      if lastPrice and s.price~=lastPrice then priceChanges=priceChanges+1 end
      if lastQuantity and s.quantity and s.quantity~=lastQuantity then qtyChanges=qtyChanges+1 end
      lastPrice=s.price
      if s.quantity then lastQuantity=s.quantity end
    end
  end
  local score=floor(min(100,100*(.35*min(1,recent/24)+.3*min(1,priceChanges/8)+
    .2*min(1,qtyChanges/8)+.15*q.score/100))+.5)
  return {score=score,observations=recent,priceChanges=priceChanges,quantityChanges=qtyChanges,
    quality=q,metrics=m}
end

function A.ProScanner()
  return cfg().savedScanner
end
-- Process in small chunks to avoid freezing the WoW UI on a large history database.
-- Scanner 2.0 uses several independent indicators; neither score is a
-- probability of sale. Large discounts with weak data remain high-risk.
local function bounded(v,lo,hi)
  v=tonumber(v) or lo
  return max(lo,min(hi,v))
end
function A.ProOpportunity(quote,quality,discount,samples)
  local price=tonumber(quote and quote.currentPrice)
  local median=tonumber(quote and quote.median)
  local quantity=tonumber(quote and quote.currentQuantity)
  local volatility=tonumber(quote and quote.volatility)
  local q=quality or {}
  local count=max(0,tonumber(q.count) or #(samples or {}))
  local age=max(0,tonumber(q.age) or 9999)
  if not price or price<=0 or not median or median<=0 then return nil end
  local d=tonumber(discount) or 100*(median-price)/median
  local dNorm=bounded(d,0,60)/60
  local qualityNorm=bounded(q.score or 0,0,100)/100
  local freshness=1-bounded(age,0,72)/72
  local countNorm=bounded(count,0,25)/25
  local volNorm=volatility and bounded(volatility,0,150)/150 or 1
  -- Unknown market quantity is a risk, not evidence of liquidity.
  local supplyNorm=quantity and bounded(quantity,0,100)/100 or 0
  local supplyRisk=quantity and (quantity<2 and 1 or (quantity<5 and .7 or .2)) or 1
  local gapRisk=bounded(tonumber(q.maxGap) or 48,0,48)/48
  local risk=100*(.30*(1-qualityNorm)+.19*(1-freshness)+
    .18*volNorm+.13*(1-countNorm)+.12*supplyRisk+.08*gapRisk)
  risk=floor(bounded(risk,0,100)+.5)
  local score=100*(.44*dNorm+.22*qualityNorm+.14*freshness+
    .08*countNorm+.07*(1-volNorm)+.05*supplyNorm)
  -- Risk explicitly suppresses spectacular but poorly substantiated quotes.
  score=floor(bounded(score*(1-risk/175),0,100)+.5)
  return {score=score,risk=risk,discount=d,price=price,median=median,
    quantity=quantity,volatility=volatility,age=age,quality=q.score or 0,
    samples=count}
end
function A.SortScannerResults(rows,mode)
  mode=mode or 'score'
  table.sort(rows,function(a,b)
    local av,bv
    if mode=='discount' then av,bv=a.discount or -999,b.discount or -999
    elseif mode=='risk' then av,bv=-(a.risk or 100),-(b.risk or 100)
    else av,bv=a.score or 0,b.score or 0 end
    if av~=bv then return av>bv end
    if (a.score or 0)~=(b.score or 0) then return (a.score or 0)>(b.score or 0) end
    return tostring(a.key)<tostring(b.key)
  end)
  return rows
end
function A.StartProScanner(onProgress,onDone)
  if A.proScanFrame then A.proScanFrame:SetScript("OnUpdate",nil) end
  local keys={}
  for key in pairs(A.ProRealmHistories()) do if itemID(key) then keys[#keys+1]=key end end
  table.sort(keys)
  local f=A.proScanFrame or CreateFrame("Frame")
  A.proScanFrame=f
  local result,index,total={},1,#keys
  local settings=cfg()
  local started=time()
  local scanned=0
  f:SetScript("OnUpdate",function(self,elapsed)
    local limit=min(index+19,total)
    for i=index,limit do
      local key=keys[i]
      local samples=A.ProSamples(key)
      local q=A.ProQuality(samples)
      if #samples>=(settings.scannerMinSamples or 5) and q.age and
          q.age<=(settings.scannerFreshHours or 48) and
          q.score>=(settings.minQualityScore or 0) then
        local m=A.MarketMetrics(key,nil,samples,A.db.retentionDays*24)
        local metrics=A.ProOpportunity(m,q,nil,samples)
        if metrics and metrics.discount>=(settings.scannerDiscount or 0) and
            (not m.volatility or m.volatility<=(settings.scannerMaxVolatility or 150)) and
            ((settings.scannerMinSupply or 0)<=0 or
              (m.currentQuantity and m.currentQuantity>=settings.scannerMinSupply)) then
          metrics.key=key
          if metrics.score>=(settings.scannerMinScore or 0) and
              metrics.risk<=(settings.scannerMaxRisk or 100) and
              ((settings.scannerMaxPriceGold or 0)<=0 or metrics.price <= settings.scannerMaxPriceGold*10000) then
            result[#result+1]=metrics
          end
        end
      end
    end
    index=limit+1
    if onProgress then onProgress(min(total,index-1),total) end
    if index>total then
      self:SetScript("OnUpdate",nil)
      A.SortScannerResults(result,settings.scannerSort)
      settings.savedScanner=result
      settings.scannerTime=started
      if A.QueueScannerItemMetadata then A.QueueScannerItemMetadata(result,300) end
      if onDone then onDone(result) end
    end
  end)
  return #keys
end

local lastAlerts={}
function A.CheckMarketAlerts(key,price,available)
  local p=cfg()
  if not p.alertsEnabled then return end
  local conditions=p.alerts[A.RealmKey()] or {}
  local a=conditions[key]
  if not a then return end
  local triggered
  if a.below and price<=a.below then triggered="below" end
  if a.above and price>=a.above then triggered="above" end
  if not triggered then lastAlerts[key]=nil;return end
  local now=time();local token=A.RealmKey()..key..triggered
  if lastAlerts[token] and now-lastAlerts[token]<p.alertCooldown then return end
  lastAlerts[token]=now
  local caption=A.ProItemName(key).." "..A.Money(price)
  if p.alertChat then A.Say("! "..caption) end
  if RaidNotice_AddMessage and RaidWarningFrame then
    pcall(RaidNotice_AddMessage,RaidWarningFrame,"TradeScope: "..caption,
      ChatTypeInfo and ChatTypeInfo.RAID_WARNING)
  end
  if p.alertSound and PlaySound then pcall(PlaySound,8959) end
end
function A.SetProAlert(key,kind,value)
  if not key then return end
  local p=cfg();local realm=A.RealmKey()
  p.alerts[realm]=p.alerts[realm] or {}
  local entry=p.alerts[realm][key] or {}
  if kind=="below" or kind=="above" then entry[kind]=value end
  if not entry.below and not entry.above then p.alerts[realm][key]=nil
  else p.alerts[realm][key]=entry end
end
function A.GetProAlerts()
  return cfg().alerts[A.RealmKey()] or {}
end

local function characterKey()
  return A.RealmKey()..":"..(UnitName and (UnitName("player") or "?") or "?")
end
function A.ProJournal()
  local p=cfg();local key=characterKey()
  p.journal[key]=p.journal[key] or {}
  return p.journal[key]
end
function A.AddJournalTrade(itemKey,kind,quantity,unitPrice,fee)
  if not itemKey or (kind~="buy" and kind~="sell") then return false end
  local qty=floor(tonumber(quantity) or 0);local price=floor(tonumber(unitPrice) or -1)
  if qty<1 or qty>1000000 or price<0 then return false end
  local rows=A.ProJournal()
  rows[#rows+1]={key=itemKey,kind=kind,qty=qty,price=price,
    fee=max(0,min(100,tonumber(fee) or cfg().journalFee)),t=time()}
  return true
end
function A.JournalReport()
  local journal=A.ProJournal()
  local inventory,realized,spent,soldValue,unmatched={},0,0,0,0
  local entries={}
  for i=1,#journal do
    local row=journal[i]
    local position=inventory[row.key] or {qty=0,cost=0}
    local gross=(row.price or 0)*row.qty
    if row.kind=="buy" then
      position.cost=position.cost+gross;position.qty=position.qty+row.qty
      spent=spent+gross
    else
      local matched=min(row.qty,position.qty)
      local fee=max(0,min(100,row.fee or 0))/100
      soldValue=soldValue+gross*(1-fee)
      if position.qty>0 and matched>0 then
        local unitCost=position.cost/position.qty
        local pnl=matched*(row.price*(1-fee)-unitCost)
        realized=realized+pnl
        position.cost=max(0,position.cost-unitCost*matched)
        position.qty=position.qty-matched
        row._pnl=pnl
      else row._pnl=nil end
      unmatched=unmatched+(row.qty-matched)
    end
    inventory[row.key]=position
    entries[#entries+1]=row
  end
  return {inventory=inventory,realized=realized,spent=spent,soldValue=soldValue,
    unmatched=unmatched,entries=entries}
end
function A.DeleteJournalTrade(index)
  local journal=A.ProJournal()
  if journal[index] then table.remove(journal,index) end
end

function A.ProRecipes()
  local p=cfg();local realm=A.RealmKey()
  p.recipes[realm]=p.recipes[realm] or {}
  return p.recipes[realm]
end
-- Resolve a readable recipe label from existing SavedVariables and game item cache.
-- Some older versions saved only a numeric item ID as the recipe name.
-- Never replace a legitimate profession recipe name with an unknown placeholder.
local function meaningfulRecipeName(name,product)
  if type(name)~="string" then return false end
  local stripped=name:match("^%s*(.-)%s*$") or ""
  return stripped~="" and stripped~="?" and stripped~=tostring(product) and
    not stripped:match("^#?%d+$") and not stripped:match("^[Ii]tem%s*#?%d+$") and
    not stripped:match("^Предмет%s*#?%d+$")
end
function A.ProRecipeLabel(recipe)
  if type(recipe)~="table" then return "?" end
  local product=tonumber(recipe.product)
  if meaningfulRecipeName(recipe.name,product) then return recipe.name end
  if meaningfulRecipeName(recipe.productName,product) then
    recipe.name=recipe.productName
    return recipe.name
  end
  if product then
    local itemName,itemIcon
    if type(GetItemInfo)=="function" then
      local ok,name,_,_,_,_,_,_,_,texture=pcall(GetItemInfo,product)
      if ok then itemName=name;itemIcon=texture end
    end
    if not meaningfulRecipeName(itemName,product) and A.ResolveItemInfo then
      itemName,itemIcon=A.ResolveItemInfo("item:"..product)
    end
    if meaningfulRecipeName(itemName,product) then
      recipe.name=itemName
      recipe.productName=itemName
      if itemIcon then recipe.productIcon=itemIcon end
      return itemName
    end
  end
  return (A.locale=="ruRU" and "Предмет #" or "Item #")..tostring(product or "?")
end
function A.GetProAuctionPrice(item)
  if not item then return nil end
  local key=type(item)=="number" and tostring(item) or tostring(item)
  local db=_G.Auctionator and _G.Auctionator.Database
  if db and type(db.GetPrice)=="function" then
    local ok,v=pcall(db.GetPrice,db,key)
    if ok and A.Valid(v) then return v end
  end
  local s=A.ProSamples("db:"..key)
  return s[#s] and s[#s].price or nil
end
function A.EvaluateRecipe(recipe)
  if not recipe then return nil end
  local total,missing=0,{}
  for i=1,#(recipe.materials or {}) do
    local mat=recipe.materials[i]
    local p=A.GetProAuctionPrice(mat.id)
    if not p then missing[#missing+1]=mat.id
    else total=total+p*(tonumber(mat.qty) or 1) end
  end
  local market=A.GetProAuctionPrice(recipe.product)
  local made=max(1,tonumber(recipe.made) or 1)
  local net=market and (market*made*(1-cfg().journalFee/100)) or nil
  return {cost=#missing==0 and total or nil,net=net,profit=net and #missing==0 and net-total or nil,
    missing=missing,productPrice=market,quantity=made}
end
-- Profession bridge for both classic/legacy TradeSkill and modern C_TradeSkillUI.
-- No prices or missing ingredients are invented when an API cannot identify a reagent.
local function safe(fn, ...)
  if type(fn)~="function" then return nil end
  local ok, value = pcall(fn,...)
  if ok then return value end
end
local function activeRecipeID()
  local professions=_G.ProfessionsFrame
  local crafting=professions and professions.CraftingPage
  local form=crafting and crafting.SchematicForm
  local info=form and safe(form.GetRecipeInfo,form)
  local id=info and tonumber(info.recipeID or info.recipeId)
  if id and id>0 then return id end
  -- Different profession UI generations store selection in different widgets.
  local recipeList=crafting and crafting.RecipeList
  local fromList=recipeList and (safe(recipeList.GetSelectedRecipeID,recipeList)
    or (recipeList.selectedRecipeInfo and recipeList.selectedRecipeInfo.recipeID)
    or recipeList.selectedRecipeID)
  id=tonumber(fromList)
  if id and id>0 then return id end
  local tradeFrame=_G.TradeSkillFrame
  if tradeFrame then
    local selected=tonumber(tradeFrame.selectedRecipeID)
    if selected and selected>0 then return selected end
    local details=tradeFrame.DetailsFrame
    local dt=details and (safe(details.GetRecipeInfo,details) or details.recipeInfo)
    id=type(dt)=="table" and tonumber(dt.recipeID) or nil
    if id and id>0 then return id end
  end
end

local function rememberProfessionName(id,name,icon)
  if not id then return end
  if A.RememberItem and (type(name)=="string" and name~="" or icon) then
    A.RememberItem("item:"..tostring(id),name,icon)
  end
end
local function modernRecipe(recipeID)
  local api=_G.C_TradeSkillUI
  if type(api)~="table" then return nil end
  recipeID=tonumber(recipeID)
  if not recipeID then return nil end
  local schematic=safe(api.GetRecipeSchematic,recipeID,false)
  local info=safe(api.GetRecipeInfo,recipeID)
  if type(schematic)~="table" then
    -- Intermediate clients expose C_TradeSkillUI but not the modern schematic.
    if type(api.GetRecipeNumReagents)~="function" then return nil end
    local link=safe(api.GetRecipeItemLink,recipeID)
    local product=itemID(link)
    if not product then return nil,"missing-product" end
    local count=tonumber(safe(api.GetRecipeNumReagents,recipeID))
    if not count or count<1 then return nil,"missing-reagents" end
    local mats={}
    for i=1,math.min(40,count) do
      local reagentLink=safe(api.GetRecipeReagentItemLink,recipeID,i)
      local reagent=itemID(reagentLink)
      if not reagent then return nil,"missing-reagent-id" end
      local qty,name,icon=1,nil,nil
      if type(api.GetRecipeReagentInfo)=="function" then
        local ok,n,texture,required=pcall(api.GetRecipeReagentInfo,recipeID,i)
        if ok then name=n;icon=texture;qty=tonumber(required) or 1 end
      end
      rememberProfessionName(reagent,name,icon)
      mats[#mats+1]={id=reagent,qty=math.max(1,math.floor(qty)),name=name,icon=icon}
    end
    if count>40 then return nil,"too-many-reagents" end
    return {name=type(info)=="table" and info.name or nil,
      product=product,made=math.max(1,math.floor(type(info)=="table" and tonumber(info.numProduced) or 1)),
      materials=mats,source="C_TradeSkillUI-legacy",recipeID=recipeID}
  end
  local product=tonumber(schematic.outputItemID)
  if not product then
    local output=safe(api.GetRecipeItemLink,recipeID)
    product=itemID(output)
  end
  if not product and type(schematic.outputItemInfo)=="table" then
    product=tonumber(schematic.outputItemInfo.itemID)
  end
  if not product then return nil,"missing-product" end
  local slots=schematic.reagentSlotSchematics
  if type(slots)~="table" then return nil,"missing-reagents" end
  local mats={}
  for i=1,#slots do
    local slot=slots[i]
    if type(slot)=="table" and slot.required~=false and not slot.hiddenInCraftingForm then
      local options=slot.reagents
      local reagentID=type(options)=="table" and #options==1 and tonumber(options[1].itemID) or nil
      local qty=tonumber(slot.quantityRequired)
      if not reagentID or not qty or qty<1 then return nil,"optional-reagents" end
      local entry=options and options[1]
      local reagentName=type(entry)=="table" and (entry.name or entry.itemName) or nil
      local reagentIcon=type(entry)=="table" and (entry.icon or entry.iconTexture) or nil
      rememberProfessionName(reagentID,reagentName,reagentIcon)
      mats[#mats+1]={id=reagentID,qty=math.max(1,math.floor(qty)),name=reagentName,icon=reagentIcon}
    end
  end
  if #mats==0 then return nil,"missing-reagents" end
  local amount=math.max(1,math.floor(tonumber(schematic.quantityMin) or 1))
  return {name=(info and info.name) or schematic.name,product=product,made=amount,materials=mats,
    source="C_TradeSkillUI",recipeID=recipeID}
end

local function legacyRecipe(index)
  if type(GetTradeSkillNumReagents)~="function" then return nil,"legacy-unavailable" end
  index=tonumber(index)
  if not index or index<1 then return nil,"no-selection" end
  local link=safe(_G.GetTradeSkillItemLink,index)
  local product=itemID(link)
  if not product then return nil,"missing-product" end
  local count=tonumber(safe(GetTradeSkillNumReagents,index))
  if not count or count<1 then return nil,"missing-reagents" end
  local mats={}
  for i=1,math.min(count,40) do
    local reagentLink=safe(_G.GetTradeSkillReagentItemLink,index,i)
    local id=itemID(reagentLink)
    if not id then return nil,"missing-reagent-id" end
    local qty,reagentName,reagentIcon=1,nil,nil
    if type(GetTradeSkillReagentInfo)=="function" then
      local ok,n,texture,required=pcall(GetTradeSkillReagentInfo,index,i)
      if ok then reagentName=n;reagentIcon=texture;qty=tonumber(required) or 1 end
    end
    rememberProfessionName(id,reagentName,reagentIcon)
    mats[#mats+1]={id=id,qty=math.max(1,math.floor(qty)),name=reagentName,icon=reagentIcon}
  end
  if count>40 then return nil,"too-many-reagents" end
  local name=safe(_G.GetTradeSkillInfo,index)
  local amount=safe(_G.GetTradeSkillNumMade,index)
  return {name=name,product=product,made=math.max(1,math.floor(tonumber(amount) or 1)),
    materials=mats,source="GetTradeSkill*",skillIndex=index}
end

function A.GetAvailableProfessionRecipes()
  local choices={}
  local api=_G.C_TradeSkillUI
  if type(api)=="table" and (type(api.GetAllRecipeIDs)=="function" or type(api.GetFilteredRecipeIDs)=="function") then
    local ids=safe(api.GetFilteredRecipeIDs) or safe(api.GetAllRecipeIDs)
    if type(ids)=="table" then
      for i=1,math.min(5000,#ids) do
        local id=tonumber(ids[i])
        if id then
          local info=safe(api.GetRecipeInfo,id)
          local name=type(info)=="table" and info.name
          if name and name~="" then
            choices[#choices+1]={id=id,name=name,kind="modern"}
          end
        end
      end
    end
  end
  if #choices==0 and type(_G.GetNumTradeSkills)=="function" then
    local count=safe(GetNumTradeSkills)
    for index=1,math.min(1500,tonumber(count) or 0) do
      local name,kind
      if type(_G.GetTradeSkillInfo)=="function" then
        local ok,a,b=pcall(GetTradeSkillInfo,index)
        if ok then name=a;kind=b end
      end
      if type(name)=="string" and name~="" and kind~="header" then
        choices[#choices+1]={id=index,name=name,kind="legacy"}
      end
    end
  end
  return choices
end

function A.ImportSelectedTradeSkill(choice)
  local recipe,why
  if type(choice)=="table" then
    if choice.kind=="legacy" then recipe,why=legacyRecipe(choice.id)
    else recipe,why=modernRecipe(choice.id) end
  else
    local id=activeRecipeID()
    if id then recipe,why=modernRecipe(id) end
    if not recipe and type(_G.GetTradeSkillSelectionIndex)=="function" then
      local index=safe(GetTradeSkillSelectionIndex)
      if index and index>0 then recipe,why=legacyRecipe(index) end
    end
    if not recipe and _G.TradeSkillFrame then
      local index=tonumber(_G.TradeSkillFrame.selectedSkill or _G.TradeSkillFrame.selectedSkillIndex)
      if index then recipe,why=legacyRecipe(index) end
    end
  end
  if recipe and #recipe.materials>0 then
    return recipe
  end
  return nil,why or "no-selection"
end


-- Craft costs and inventory-aware cash expenses. Excluded ingredients are
-- deliberate, visible omissions; they are NEVER silently treated as fully priced.
function A.RecipeExclusions(recipe)
  local p=cfg()
  p.craftExcluded=type(p.craftExcluded)=="table" and p.craftExcluded or {}
  local realm=A.RealmKey()
  p.craftExcluded[realm]=p.craftExcluded[realm] or {}
  local key=tostring(recipe.recipeID or "")..":"..tostring(recipe.product)
  local t=p.craftExcluded[realm][key]
  if type(t)~="table" then t={};p.craftExcluded[realm][key]=t end
  return t
end
function A.SetRecipeIngredientIncluded(recipe,index,include)
  if not recipe or not index then return end
  local flags=A.RecipeExclusions(recipe)
  if include then flags[index]=nil else flags[index]=true end
end

function A.EvaluateRecipeWithInventory(recipe)
  if not recipe then return nil end
  local settings=cfg()
  local flags=A.RecipeExclusions(recipe)
  local inventoryEnabled=settings.craftInventoryEnabled==true
  local marketCost,cashCost,missingMarket,missingCash,excluded=0,0,{}, {},0
  local rows,used={},{}
  for index=1,#(recipe.materials or {}) do
    local mat=recipe.materials[index]
    local id=tonumber(mat.id)
    local qty=max(1,floor(tonumber(mat.qty) or 1))
    local include=flags[index]~=true
    local unit=A.GetProAuctionPrice(id or mat.id)
    local bag,bank,bankTime,ownedTotal
    if inventoryEnabled then bag,bank,bankTime,ownedTotal=A.CraftOwnedCount(id) end
    local stock=inventoryEnabled and (ownedTotal or ((bag or 0)+(bank or 0))) or 0
    local already=used[id] or 0
    local own=include and min(qty,max(0,stock-already)) or 0
    if include and inventoryEnabled and id then used[id]=already+own end
    if include then
      local purchase=qty-own
      if type(unit)=="number" and unit>0 then
        marketCost=marketCost+unit*qty
        cashCost=cashCost+unit*purchase
      else
        missingMarket[#missingMarket+1]=id or tostring(mat.id)
        if purchase>0 then missingCash[#missingCash+1]=id or tostring(mat.id) end
      end
    else
      excluded=excluded+1
    end
    rows[#rows+1]={id=id,qty=qty,unit=unit,include=include,
      bag=bag,bank=bank,stock=stock,bankTime=bankTime,
      own=own,buy=include and (qty-own) or 0,
      cost=include and unit and unit*qty or nil,
      cash=include and unit and unit*(qty-own) or nil}
  end
  local made=max(1,tonumber(recipe.made) or 1)
  local quote=A.GetProAuctionPrice(recipe.product)
  local fee=max(0,min(15,tonumber(settings.journalFee) or 5))
  local net=quote and quote*made*(1-fee/100) or nil
  local completeMarket=#missingMarket==0
  local completeCash=#missingCash==0
  return {rows=rows,net=net,outputQuote=quote,
    marketCost=completeMarket and marketCost or nil,
    cashCost=completeCash and cashCost or nil,
    knownMarketSubtotal=marketCost,knownCashSubtotal=cashCost,
    marketProfit=completeMarket and net and net-marketCost or nil,
    cashProfit=completeCash and net and net-cashCost or nil,
    missingMarket=missingMarket,missingCash=missingCash,
    excluded=excluded,inventoryEnabled=inventoryEnabled,quantity=made}
end

-- All imported recipes are listed, even losses and those missing Auctionator
-- prices. The profit-only filter is strictly optional and OFF by default.
function A.ProCraftOpportunities(sortBy, minProfitGold, minROI, onlyProfitable)
  local recipes=A.ProRecipes()
  local results={}
  local statistics={saved=0,priced=0,profitable=0,loss=0,missing=0,shown=0}
  local profitFloor=max(0,tonumber(minProfitGold) or 0)*10000
  local roiFloor=max(0,tonumber(minROI) or 0)
  for _, recipe in pairs(recipes) do
    if type(recipe)=="table" and tonumber(recipe.product) and
       type(recipe.materials)=="table" and #recipe.materials>0 then
      statistics.saved=statistics.saved+1
      local ok,price=pcall(A.EvaluateRecipe,recipe)
      local good=ok and type(price)=="table" and type(price.cost)=="number" and
        type(price.net)=="number" and type(price.profit)=="number"
      if good then
        statistics.priced=statistics.priced+1
        local roi=price.cost>0 and 100*price.profit/price.cost or nil
        if price.profit>0 then statistics.profitable=statistics.profitable+1
        elseif price.profit<0 then statistics.loss=statistics.loss+1 end
        if not onlyProfitable or (price.profit>0 and
            price.profit>=profitFloor and roi and roi>=roiFloor) then
          results[#results+1]={recipe=recipe,cost=price.cost,net=price.net,
            profit=price.profit,roi=roi,price=price.productPrice,
            product=recipe.product,made=price.quantity,status="priced"}
        end
      else
        statistics.missing=statistics.missing+1
        if not onlyProfitable then
          results[#results+1]={recipe=recipe,product=recipe.product,
            cost=price and price.cost or nil,net=price and price.net or nil,
            made=price and price.quantity or nil,status="missing"}
        end
      end
    end
  end
  local field=sortBy=="roi" and "roi" or "profit"
  table.sort(results,function(a,b)
    if a.status~=b.status then return a.status=="priced" end
    local av,bv=a[field],b[field]
    if av~=bv then return type(av)=="number" and (type(bv)~="number" or av>bv) end
    if a.profit~=b.profit then
      return type(a.profit)=="number" and (type(b.profit)~="number" or a.profit>b.profit)
    end
    return tostring(a.recipe.name or a.product)<tostring(b.recipe.name or b.product)
  end)
  statistics.shown=#results
  return results,statistics
end

-- Import the selected profession's recipes in small per-frame batches.
-- Saving only complete, ordinary recipes prevents false craft opportunities.
function A.ImportProfessionRecipeCatalog(progress,complete)
  if A.proRecipeImportActive then return false,"running" end
  local choices=A.GetAvailableProfessionRecipes and A.GetAvailableProfessionRecipes() or {}
  if #choices==0 then return false,"no-profession" end
  local limit=math.max(20,math.min(1500,math.floor(tonumber(cfg().craftScannerImportLimit) or 500)))
  local total=math.min(limit,#choices)
  local recipes=A.ProRecipes()
  local worker=A.proRecipeImportWorker or CreateFrame("Frame")
  A.proRecipeImportWorker=worker
  A.proRecipeImportActive=true
  local index,stored,skipped=1,0,0
  worker:SetScript("OnUpdate",function(self)
    for _=1,5 do
      if index>total then break end
      local entry=choices[index]
      -- When the profession API distinguishes learned from unlearned recipes,
      -- never recommend crafting something the character cannot currently make.
      local learned=true
      local api=_G.C_TradeSkillUI
      if entry and entry.kind=="modern" and type(api)=="table" and
          type(api.GetRecipeInfo)=="function" then
        local okInfo,details=pcall(api.GetRecipeInfo,entry.id)
        if okInfo and type(details)=="table" and details.learned==false then
          learned=false
        end
      end
      local ok,recipe=false,nil
      if learned then ok,recipe=pcall(A.ImportSelectedTradeSkill,entry) end
      if ok and type(recipe)=="table" and tonumber(recipe.product) and
         type(recipe.materials)=="table" and #recipe.materials>0 then
        -- Keep the profession name whenever the output item is not yet cached.
        if not meaningfulRecipeName(recipe.name,recipe.product) and entry and
            meaningfulRecipeName(entry.name,recipe.product) then
          recipe.name=entry.name
        end
        A.ProRecipeLabel(recipe)
        -- Key by output item for compatibility with recipes previously imported.
        recipes[tostring(recipe.product)]=recipe
        stored=stored+1
      else
        skipped=skipped+1
      end
      index=index+1
    end
    if index>total then
      self:SetScript("OnUpdate",nil)
      A.proRecipeImportActive=false
      if type(complete)=="function" then pcall(complete,stored,skipped,total) end
    elseif type(progress)=="function" then
      pcall(progress,index-1,total,stored)
    end
  end)
  return true,total
end
