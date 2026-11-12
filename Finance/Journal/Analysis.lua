-- TradeScope 4.4.0: read-only journal analytics for future Journal 2.0 UI.
-- No SavedVariables migrations, writes, or automatic transaction tracking.
local A=ATS
local min,max,floor=math.min,math.max,math.floor

-- @param rows optional list of manually recorded journal trades; defaults to current character.
-- @param opts optional filters: itemKey, fromTime, toTime (inclusive).
-- Historical buys always establish cost basis before a filtered sale is reported.
function A.JournalAnalysis(rows,opts)
  rows=rows or A.ProJournal()
  opts=opts or {}
  local positions,byItem={},{}
  local result={entries={},byItem=byItem,realized=0,spent=0,proceeds=0,
    fees=0,matched=0,unmatched=0,buys=0,sells=0,openUnits=0,
    skipped=0}
  for i=1,#rows do
    local row=rows[i]
    local qty=type(row)=="table" and tonumber(row.qty) or nil
    local price=type(row)=="table" and tonumber(row.price) or nil
    local valid=type(row)=="table" and row.key~=nil and
      (row.kind=="buy" or row.kind=="sell") and
      qty and qty==floor(qty) and qty>=1 and qty<=1000000 and
      price and price>=0 and price<math.huge
    if not valid then
      result.skipped=result.skipped+1
    else
      local pos=positions[row.key] or {qty=0,cost=0}
      local fee=max(0,min(100,tonumber(row.fee) or 0))/100
      local matched,unmatched,pnl,net,fees=0,0,nil,0,0
      if row.kind=="buy" then
        pos.qty=pos.qty+qty
        pos.cost=pos.cost+price*qty
      else
        matched=min(qty,pos.qty)
        unmatched=qty-matched
        fees=price*qty*fee
        net=price*qty-fees
        if matched>0 then
          local unitCost=pos.cost/pos.qty
          pnl=matched*(price*(1-fee)-unitCost)
          pos.qty=pos.qty-matched
          pos.cost=max(0,pos.cost-matched*unitCost)
        end
      end
      positions[row.key]=pos
      local timestamp=type(row.t)=="number" and row.t or 0
      local selected=(not opts.itemKey or row.key==opts.itemKey) and
        (not opts.fromTime or timestamp>=opts.fromTime) and
        (not opts.toTime or timestamp<=opts.toTime)
      if selected then
        local entry={key=row.key,kind=row.kind,qty=qty,price=price,
          t=timestamp,fee=fee*100,matched=matched,unmatched=unmatched,
          pnl=pnl,net=net,fees=fees}
        result.entries[#result.entries+1]=entry
        local item=byItem[row.key]
        if not item then
          item={key=row.key,realized=0,spent=0,proceeds=0,fees=0,
            buys=0,sells=0,matched=0,unmatched=0}
          byItem[row.key]=item
        end
        if row.kind=="buy" then
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
          if pnl then
            result.realized=result.realized+pnl
            item.realized=item.realized+pnl
          end
        end
      end
    end
  end
  -- Open units reflect the entire journal, regardless of display filters.
  for key,pos in pairs(positions) do
    result.openUnits=result.openUnits+pos.qty
    if byItem[key] then
      byItem[key].openQty=pos.qty
      byItem[key].openCost=pos.cost
    end
  end
  return result
end
