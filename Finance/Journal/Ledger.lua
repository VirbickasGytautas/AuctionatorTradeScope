-- Existing journal storage and realized P&L semantics; legacy entrypoints preserved.
local A=ATS
local floor,min,max=math.floor,math.min,math.max
local function cfg() A.Init(); return A.db.pro end

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

