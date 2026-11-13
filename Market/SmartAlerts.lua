-- TradeScope 4.2.1: opt-in, observation-driven alerts (WoW 1.60.1 / Lua 5.1).
-- Evaluated ONLY by Scan.lua after a NEW Auctionator database observation.
-- Supply changes describe listing decreases, not verified sales.
local A=ATS
local floor,abs,min,max=math.floor,math.abs,math.min,math.max
local function config() A.Init();return A.db.pro end
local function realm()return A.RealmKey()end
local definitions={
  below={en="Price at/below",ru="Цена не выше",unit="money"},
  above={en="Price at/above",ru="Цена не ниже",unit="money"},
  medianBelow={en="Below median by %",ru="Ниже медианы на %",unit="percent"},
  medianAbove={en="Above median by %",ru="Выше медианы на %",unit="percent"},
  priceDown={en="Price drop by %",ru="Падение цены на %",unit="percent"},
  priceUp={en="Price rise by %",ru="Рост цены на %",unit="percent"},
  supplyDrop={en="Supply decrease (qty)",ru="Сокращение лотов (шт.)",unit="quantity"},
  volatility={en="Volatility at least %",ru="Волатильность от %",unit="percent"},
  opportunity={en="Opportunity Score at least",ru="Opportunity Score от",unit="score"},
}
local order={"below","above","medianBelow","medianAbove","priceDown","priceUp","supplyDrop","volatility","opportunity"}
function A.SmartAlertKinds()return order,definitions end
local function label(kind)
  local d=definitions[kind]
  if not d then return tostring(kind) end
  return A.locale=="ruRU" and d.ru or d.en
end
function A.SmartAlertLabel(kind)return label(kind)end
function A.SmartAlertUnit(kind)return definitions[kind] and definitions[kind].unit end
local function alertMap()
  local p=config(); local r=realm()
  p.alerts[r]=type(p.alerts[r])=="table" and p.alerts[r] or {}
  return p.alerts[r]
end
local function validNumber(n,lower,upper)
  n=tonumber(n)
  return n and n==n and n>=lower and n<=upper and n<math.huge and n
end
local function ruleValue(kind,n)
  if not definitions[kind] then return nil end
  local unit=definitions[kind].unit
  if unit=="money" then return validNumber(n,1,999999999999) and floor(n+.5) end
  if unit=="quantity" then return validNumber(n,1,100000000) and floor(n+.5) end
  if unit=="score" then return validNumber(n,1,100) and floor(n+.5) end
  return validNumber(n,.1,1000)
end
function A.AddSmartAlert(key,kind,threshold,risk)
  if type(key)~="string" or not key:match("^db:[%w:]+$") then return false,"item" end
  local value=ruleValue(kind,threshold)
  if not value then return false,"threshold" end
  local rows=alertMap()
  local item=rows[key] or {}
  -- The new rule supersedes a legacy price threshold of the same kind,
  -- avoiding duplicate notifications when upgrading the old alert.
  if kind=="below" or kind=="above" then item[kind]=nil end
  item.rules=type(item.rules)=="table" and item.rules or {}
  -- A distinct threshold is one rule; replacing same kind retains the rule id.
  for i=1,#item.rules do
    local r=item.rules[i]
    if r.kind==kind then
      r.value=value;r.risk=kind=="opportunity" and max(0,min(100,tonumber(risk) or 80)) or nil
      r.enabled=true
      rows[key]=item
      return true,r.id
    end
  end
  local p=config()
  p.alertNextID=max(0,floor(tonumber(p.alertNextID) or 0))+1
  local id=p.alertNextID
  item.rules[#item.rules+1]={id=id,kind=kind,value=value,enabled=true,
    risk=kind=="opportunity" and max(0,min(100,tonumber(risk) or 80)) or nil}
  rows[key]=item
  return true,id
end
function A.AllSmartAlertRules()
  local all={}
  for key,item in pairs(alertMap()) do
    if type(item)=="table" then
      if type(item.below)=="number" and item.below>0 then
        all[#all+1]={key=key,id="old-below",kind="below",value=item.below,enabled=true,legacy=true}
      end
      if type(item.above)=="number" and item.above>0 then
        all[#all+1]={key=key,id="old-above",kind="above",value=item.above,enabled=true,legacy=true}
      end
      if type(item.rules)=="table" then
        for _,r in ipairs(item.rules) do
          if type(r)=="table" and definitions[r.kind] then
            all[#all+1]={key=key,id=r.id,kind=r.kind,value=r.value,risk=r.risk,
              enabled=r.enabled~=false,legacy=false}
          end
        end
      end
    end
  end
  table.sort(all,function(a,b)
    if a.key~=b.key then return a.key<b.key end
    return tostring(a.kind)<tostring(b.kind)
  end)
  return all
end
local function clearRuleStates(key,id)
  local p=config();local r=realm()
  if p.alertStates and p.alertStates[r] and p.alertStates[r][key] then
    p.alertStates[r][key][tostring(id)]=nil
  end
end
function A.RemoveSmartAlert(key,id)
  local rows=alertMap();local item=rows[key]
  if type(item)~="table" then return false end
  if id=="old-below" then item.below=nil
  elseif id=="old-above" then item.above=nil
  elseif type(item.rules)=="table" then
    for i=#item.rules,1,-1 do if tostring(item.rules[i].id)==tostring(id) then table.remove(item.rules,i) end end
  end
  if not item.below and not item.above and (not item.rules or #item.rules==0) then rows[key]=nil end
  clearRuleStates(key,id)
  return true
end
function A.SetSmartAlertEnabled(key,id,enabled)
  local item=alertMap()[key]
  if not item or type(item.rules)~="table" then return false end
  for i=1,#item.rules do
    local r=item.rules[i]
    if tostring(r.id)==tostring(id) then
      r.enabled=enabled and true or false
      clearRuleStates(key,id)
      return true
    end
  end
  return false
end
local function logTable()
  local p=config();local r=realm()
  p.alertHistory[r]=type(p.alertHistory[r])=="table" and p.alertHistory[r] or {}
  return p.alertHistory[r]
end
function A.GetSmartAlertHistory()return logTable() end
function A.ClearSmartAlertHistory()local p=config();p.alertHistory[realm()]={} end
local function stateTable(key)
  local p=config();local r=realm()
  p.alertStates[r]=type(p.alertStates[r])=="table" and p.alertStates[r] or {}
  local all=p.alertStates[r]
  all[key]=type(all[key])=="table" and all[key] or {}
  return all[key]
end
local function formatValue(kind,value)
  if kind=="below" or kind=="above" then return A.Money(value) end
  if kind=="supplyDrop" then return tostring(floor(value+.5)) end
  if kind=="opportunity" then return tostring(floor(value+.5)).."/100" end
  return string.format("%.1f%%",value)
end
function A.FormatSmartAlertValue(kind,value)return type(value)=="number" and formatValue(kind,value) or "-" end
local function getPrevious(samples,now)
  if type(samples)~="table" or #samples<2 then return nil end
  local curr=samples[#samples]
  for i=#samples-1,1,-1 do
    local prev=samples[i]
    if prev.t<curr.t then
      if now-prev.t<=max(1,tonumber(A.db.maxCompareGapHours) or 12)*3600 then return prev end
      return nil
    end
  end
end
local function checkRule(rule,ctx)
  local threshold=rule.value
  if not ruleValue(rule.kind,threshold) then return nil end
  local kind=rule.kind
  if kind=="below" then return ctx.price<=threshold and ctx.price or nil end
  if kind=="above" then return ctx.price>=threshold and ctx.price or nil end
  local samples=ctx.samples
  if not samples then
    samples=A.ProSamples(ctx.key)
    ctx.samples=samples
  end
  local count=#samples
  local p=config()
  local minimum=max(3,floor(tonumber(p.alertMinSamples) or 5))
  if count<minimum then return nil end
  if kind=="priceDown" or kind=="priceUp" or kind=="supplyDrop" then
    local previous=ctx.previous
    if previous==nil then previous=getPrevious(samples,ctx.now) or false;ctx.previous=previous end
    if previous==false then return nil end
    if kind=="supplyDrop" then
      if type(previous.quantity)~="number" or type(ctx.quantity)~="number" then return nil end
      local decrease=previous.quantity-ctx.quantity
      return decrease>=threshold and decrease or nil
    end
    if not A.Valid(previous.price) then return nil end
    local diff=100*(ctx.price-previous.price)/previous.price
    if kind=="priceUp" and diff>=threshold then return diff end
    if kind=="priceDown" and diff<=-threshold then return -diff end
    return nil
  end
  if not ctx.metrics then
    ctx.metrics=A.MarketMetrics(ctx.key,nil,samples,max(24,A.db.retentionDays*24))
  end
  local metrics=ctx.metrics
  if kind=="volatility" then
    return metrics.volatility and metrics.volatility>=threshold and metrics.volatility or nil
  end
  if not A.Valid(metrics.median) then return nil end
  local deviation=100*(ctx.price-metrics.median)/metrics.median
  if kind=="medianBelow" then return deviation<=-threshold and -deviation or nil end
  if kind=="medianAbove" then return deviation>=threshold and deviation or nil end
  if kind=="opportunity" then
    if not ctx.quality then ctx.quality=A.ProQuality(samples) end
    if ctx.quality.score<(tonumber(p.alertMinQuality) or 25) then return nil end
    if not ctx.opportunity then ctx.opportunity=A.ProOpportunity(metrics,ctx.quality,nil,samples) end
    local score=ctx.opportunity
    if score and score.score>=threshold and score.risk<=(tonumber(rule.risk) or 80) then
      return score.score,score.risk
    end
  end
end
local function addHistory(ctx,rule,measured,risk)
  local history=logTable()
  local entry={key=ctx.key,t=ctx.now,kind=rule.kind,value=rule.value,
    observed=measured,price=ctx.price,quantity=ctx.quantity,risk=risk}
  table.insert(history,1,entry)
  local cap=max(25,min(500,floor(tonumber(config().alertHistoryLimit) or 150)))
  while #history>cap do table.remove(history) end
  return entry
end
local function emit(entry)
  local p=config()
  local name=A.ProItemName(entry.key)
  local caption=label(entry.kind).." "..formatValue(entry.kind,entry.observed or 0)
  local message=name.." | "..caption.." | "..A.Money(entry.price)
  if p.alertChat then A.Say(message) end
  if p.alertPopup~=false and RaidNotice_AddMessage and RaidWarningFrame then
    pcall(RaidNotice_AddMessage,RaidWarningFrame,"TradeScope: "..name.." | "..caption,
      ChatTypeInfo and ChatTypeInfo.RAID_WARNING)
  end
  if p.alertSound and PlaySound then pcall(PlaySound,8959) end
end
-- Defers no work; every rule is checked in response to a changed scan observation.
-- Condition states persist, suppressing duplicate spam after reload or UI refresh.
function A.CheckMarketAlerts(key,price,quantity)
  local p=config()
  if not p.alertsEnabled or not A.Valid(price) then return end
  local entries=alertMap()[key]
  if type(entries)~="table" then return end
  local now=time()
  local rules={}
  if type(entries.below)=="number" and entries.below>0 then
    rules[#rules+1]={id="old-below",kind="below",value=entries.below,enabled=true}
  end
  if type(entries.above)=="number" and entries.above>0 then
    rules[#rules+1]={id="old-above",kind="above",value=entries.above,enabled=true}
  end
  if type(entries.rules)=="table" then
    for _,r in ipairs(entries.rules) do if definitions[r.kind] and r.enabled~=false then rules[#rules+1]=r end end
  end
  if #rules==0 then return end
  local ctx={key=key,price=price,quantity=quantity,now=now}
  local states=stateTable(key)
  local cooldown=max(60,tonumber(p.alertCooldown) or 600)
  local fresh=false
  for _,rule in ipairs(rules) do
    local id=tostring(rule.id or rule.kind)
    local state=states[id] or {}
    -- The cooldown is per rule and survives reloads. A single observation
    -- must never produce multiple messages for one rule.
    local measured,risk=checkRule(rule,ctx)
    if measured then
      if not state.lastAt or now-state.lastAt>=cooldown then
        local entry=addHistory(ctx,rule,measured,risk)
        state.lastAt=now;fresh=true
        emit(entry)
      end
    else
      -- Being out of condition does not remove the cooldown; an immediate
      -- subsequent scan must not flood notifications.
      state.lastFalse=now
    end
    states[id]=state
  end
  if fresh and A.RefreshSmartAlerts then pcall(A.RefreshSmartAlerts) end
end
