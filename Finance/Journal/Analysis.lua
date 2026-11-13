-- Read-only weighted-average journal accounting. SavedVariables is never modified.
-- Chronology follows manual insertion order; time filters affect display only.
local A=ATS
local min,max,floor=math.min,math.max,math.floor

local function positiveWhole(value)
  local n=tonumber(value)
  return n and n==floor(n) and n>=1 and n<=1000000 and n<math.huge and n or nil
end
local function safePrice(value)
  local n=tonumber(value)
  return n and n==n and n>=0 and n<math.huge and n or nil
end
local function safeFee(value)
  local n=tonumber(value) or 0
  if n~=n then n=0 end
  return max(0,min(100,n))/100
end

-- opts: {itemKey, kind="buy"|"sell", fromTime, toTime}.
-- Every earlier trade establishes its cost basis even when the display is filtered.
function A.JournalAnalysis(rows,opts)
  if rows==nil then rows=A.ProJournal() end
  opts=opts or {}
  if type(rows)~="table" then rows={} end
  local positions,byItem={},{}
  local result={entries={},byItem=byItem,positions=positions,
    realized=0,spent=0,proceeds=0,fees=0,matched=0,unmatched=0,
    buys=0,sells=0,openUnits=0,skipped=0,costBasis=0}
  local fromTime=tonumber(opts.fromTime)
  local toTime=tonumber(opts.toTime)
  for i=1,#rows do
    local row=rows[i]
    local qty=type(row)=="table" and positiveWhole(row.qty) or nil
    local price=type(row)=="table" and safePrice(row.price) or nil
    local key=type(row)=="table" and row.key or nil
    local kind=type(row)=="table" and row.kind or nil
    if (type(key)~="string" and type(key)~="number") or key=="" or
        (kind~="buy" and kind~="sell") or not qty or not price then
      result.skipped=result.skipped+1
    else
      local pos=positions[key] or {qty=0,cost=0}
      local fee=safeFee(row.fee)
      local matched,unmatched,pnl,net,fees,costBasis=0,0,nil,0,0,0
      if kind=="buy" then
        pos.qty=pos.qty+qty
        pos.cost=pos.cost+price*qty
      else
        matched=min(qty,pos.qty)
        unmatched=qty-matched
        fees=price*qty*fee
        net=price*qty-fees
        if matched>0 then
          local average=pos.cost/pos.qty
          costBasis=matched*average
          pnl=matched*price*(1-fee)-costBasis
          pos.qty=pos.qty-matched
          pos.cost=max(0,pos.cost-costBasis)
        end
      end
      positions[key]=pos
      local timestamp=type(row.t)=="number" and row.t==row.t and row.t or 0
      local selected=(not opts.itemKey or key==opts.itemKey) and
        (not opts.kind or opts.kind=="all" or kind==opts.kind) and
        (not fromTime or timestamp>=fromTime) and
        (not toTime or timestamp<=toTime)
      if selected then
        local entry={index=i,key=key,kind=kind,qty=qty,price=price,
          t=timestamp,fee=fee*100,matched=matched,unmatched=unmatched,
          pnl=pnl,net=net,fees=fees,costBasis=costBasis,
          roi=costBasis>0 and pnl/costBasis*100 or nil}
        result.entries[#result.entries+1]=entry
        local item=byItem[key]
        if not item then
          item={key=key,realized=0,spent=0,proceeds=0,fees=0,
            buys=0,sells=0,matched=0,unmatched=0,costBasis=0}
          byItem[key]=item
        end
        if kind=="buy" then
          result.buys=result.buys+qty
          item.buys=item.buys+qty
          result.spent=result.spent+price*qty
          item.spent=item.spent+price*qty
        else
          result.sells=result.sells+qty
          item.sells=item.sells+qty
          result.matched=result.matched+matched
          item.matched=item.matched+matched
          result.unmatched=result.unmatched+unmatched
          item.unmatched=item.unmatched+unmatched
          result.proceeds=result.proceeds+net
          item.proceeds=item.proceeds+net
          result.fees=result.fees+fees
          item.fees=item.fees+fees
          result.costBasis=result.costBasis+costBasis
          item.costBasis=item.costBasis+costBasis
          if pnl then
            result.realized=result.realized+pnl
            item.realized=item.realized+pnl
          end
        end
      end
    end
  end
  -- Global open positions are deliberately unaffected by the display filters.
  for key,pos in pairs(positions) do
    result.openUnits=result.openUnits+pos.qty
    if byItem[key] then
      byItem[key].openQty=pos.qty
      byItem[key].openCost=pos.cost
    end
  end
  result.roi=result.costBasis>0 and result.realized/result.costBasis*100 or nil
  return result
end

-- Most recent transactions first. Supports deterministic paging of filtered rows.
function A.JournalPage(entries,page,pageSize)
  entries=type(entries)=="table" and entries or {}
  pageSize=max(1,min(50,floor(tonumber(pageSize) or 8)))
  local pages=max(1,math.ceil(#entries/pageSize))
  page=max(1,min(pages,floor(tonumber(page) or 1)))
  local items={}
  for n=(page-1)*pageSize+1,min(#entries,page*pageSize) do
    items[#items+1]=entries[#entries-n+1]
  end
  return items,page,pages
end
