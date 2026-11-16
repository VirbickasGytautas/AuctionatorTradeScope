-- TradeScope 4.5.0-beta2: opt-in confirmed auction-mail importer.
-- Requires a real auction invoice, unambiguous item, quantity and copper value.
-- No mailbox items/money are collected; mail body is never read or modified.
local A=ATS
local floor,min,max=math.floor,math.min,math.max
local SECONDS_PER_DAY=86400
local RETAIN_SECONDS=45*SECONDS_PER_DAY
local MAX_INBOX=50
local mailboxOpen=false

local function finite(n)
  if type(n)~="number" then n=tonumber(n) end
  if n and n==n and n>-math.huge and n<math.huge then return n end
end
local function copper(n)
  n=finite(n)
  return n and n>=0 and n==floor(n) and n or nil
end
local function whole(n)
  n=copper(n)
  return n and n>=1 and n<=1000000 and n or nil
end
local function charKey()
  return A.RealmKey()..":"..(UnitName and (UnitName("player") or "?") or "?")
end
function A.MailImportState()
  A.Init()
  local p=A.db.pro
  if type(p.mailImport)~="table" then p.mailImport={} end
  local state=p.mailImport
  if type(state.seen)~="table" then state.seen={} end
  state.enabled=state.enabled==true
  return state
end

-- Two independent rolling hashes keep player names out of SavedVariables keys.
local function fingerprint(fields)
  local s=table.concat(fields,"\031")
  local h1,h2=5381,8342
  for i=1,#s do
    local byte=string.byte(s,i)
    h1=(h1*131+byte)%2147483647
    h2=(h2*137+byte)%2147483629
  end
  return string.format("%08x%08x",h1,h2)
end
local function normal(name)
  if A.CleanItemName then name=A.CleanItemName(name) end
  if type(name)~="string" then return "" end
  name=string.lower(name)
  -- UTF-8 Cyrillic case folding used by ItemInfo.lua.
  name=string.gsub(name,"\208([\144-\159])",function(c)
    return "\208"..string.char(string.byte(c)+32)
  end)
  name=string.gsub(name,"\208([\160-\175])",function(c)
    return "\209"..string.char(string.byte(c)-32)
  end)
  name=string.gsub(name,"\208\129","\209\145")
  return name
end

local function itemKeyForMail(index,invoiceName)
  local id,foundLink
  if type(GetInboxItemLink)=="function" then
    for slot=1,12 do
      local ok,link=pcall(GetInboxItemLink,index,slot)
      local got=ok and A.ItemID and A.ItemID(link) or nil
      if got then
        if id and id~=got then return nil,"multiple_items" end
        id=got;foundLink=link
      end
    end
  end
  if id then
    if type(A.Key)=="function" then return A.Key(foundLink or ("item:"..id)) or ("db:"..id) end
    return "db:"..id
  end
  -- Sold mail normally has no attached item. Resolve ONLY a unique exact
  -- match from locally observed ItemInfo data, never a fuzzy search match.
  if type(A.FindKnownItems)~="function" or normal(invoiceName)=="" then
    return nil,"item_unknown"
  end
  local matches=A.FindKnownItems(invoiceName,500)
  local exactID,exactCount=nil,0
  for _,match in ipairs(matches or {}) do
    if normal(match.name)==normal(invoiceName) then
      exactCount=exactCount+1
      exactID=match.id
    end
  end
  if exactCount~=1 or not exactID then
    return nil,exactCount>1 and "item_ambiguous" or "item_unknown"
  end
  local link="item:"..tostring(exactID)
  return (A.Key and A.Key(link)) or ("db:"..tostring(exactID))
end

-- Pure validation of Blizzard's invoice; never derive prices from market history.
-- header: {money,subject,sender,daysLeft}; invoice fields use API names.
function A.ParseAuctionMail(header,invoice,key)
  if type(header)~="table" or type(invoice)~="table" then return nil,"invoice_missing" end
  local kind=invoice.invoiceType
  if kind~="buyer" and kind~="seller" then return nil,"not_completed" end
  if not key then return nil,"item_unknown" end
  local count=whole(invoice.count)
  if not count then return nil,"quantity_unknown" end
  local bid,buyout=copper(invoice.bid),copper(invoice.buyout)
  local paid
  if kind=="buyer" then
    if bid and bid>0 and buyout and buyout>0 and bid~=buyout then
      return nil,"price_ambiguous"
    end
    paid=(bid and bid>0 and bid) or (buyout and buyout>0 and buyout)
    if not paid then return nil,"price_unknown" end
    return {kind="buy",key=key,qty=count,price=paid/count,fee=0,gross=paid},nil
  end
  local money=copper(header.money)
  local deposit=copper(invoice.deposit)
  local cut=copper(invoice.consignment)
  if not money or money<=0 or deposit==nil or cut==nil then
    return nil,"payout_pending"
  end
  local gross=money+cut-deposit
  if gross<=0 then return nil,"price_unknown" end
  if not ((bid and bid>0 and bid==gross) or
    (buyout and buyout>0 and buyout==gross)) then
    return nil,"payout_mismatch"
  end
  return {kind="sell",key=key,qty=count,price=gross/count,
    fee=100*cut/gross,gross=gross,net=money-deposit,cut=cut},nil
end

local function safeCall(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c,d,e,f,g,h,i,j,k,l=pcall(fn,...)
  if ok then return a,b,c,d,e,f,g,h,i,j,k,l end
end
local function readInvoice(index)
  local pkg,station,sender,subject,money,cod,daysLeft= safeCall(GetInboxHeaderInfo,index)
  local invoiceType,itemName,player,bid,buyout,deposit,consignment,delay,etaH,etaM,count=
    safeCall(GetInboxInvoiceInfo,index)
  if invoiceType~="buyer" and invoiceType~="seller" then return nil end
  local d=finite(daysLeft)
  if not d or d<=0 or d>35 then return nil,"expiry_unknown" end
  local current=time()
  local expiration=floor((current+d*SECONDS_PER_DAY)/900+0.5)
  local raw={invoiceType or "",itemName or "",player or "",sender or "",
    subject or "",tostring(money or ""),tostring(cod or ""),
    tostring(bid or ""),tostring(buyout or ""),tostring(deposit or ""),
    tostring(consignment or ""),tostring(count or ""),tostring(expiration)}
  return {header={sender=sender,subject=subject,money=money,daysLeft=d},
    invoice={invoiceType=invoiceType,itemName=itemName,playerName=player,
      bid=bid,buyout=buyout,deposit=deposit,consignment=consignment,count=count},
    id=fingerprint(raw)}
end

local last={checked=0,imported=0,duplicate=0,pending=0,ignored=0,reasons={}}
function A.MailImportLastStatus() return last end
local function announce(report)
  if report.imported>0 and A.Say then
    local text=A.locale=="ruRU" and "Почта: записано сделок " or
      "Auction mail: imported trades "
    A.Say(text..report.imported)
  end
end
function A.SetMailImportEnabled(enabled)
  local state=A.MailImportState()
  state.enabled=enabled==true
  if state.enabled and mailboxOpen then A.ScanAuctionMail() end
  return state.enabled
end
function A.ScanAuctionMail()
  local state=A.MailImportState()
  local report={checked=0,imported=0,duplicate=0,pending=0,ignored=0,reasons={}}
  last=report
  if not mailboxOpen then report.mailboxClosed=true;return report end
  if type(GetInboxNumItems)~="function" or type(GetInboxHeaderInfo)~="function" or
    type(GetInboxInvoiceInfo)~="function" then
    report.unavailable=true
    return report
  end
  local n=safeCall(GetInboxNumItems)
  if type(n)~="number" then n=tonumber(n) end
  n=n or 0
  n=max(0,min(MAX_INBOX,floor(n)))
  local char=charKey()
  state.seen[char]=type(state.seen[char])=="table" and state.seen[char] or {}
  local seen=state.seen[char]
  local now=time()
  for key,at in pairs(seen) do
    if type(at)~="number" or now-at>RETAIN_SECONDS then seen[key]=nil end
  end
  local invoices,occurrences={},{}
  for i=1,n do
    local invoice,reason=readInvoice(i)
    if invoice then
      report.checked=report.checked+1
      invoice.index=i
      invoices[#invoices+1]=invoice
      occurrences[invoice.id]=(occurrences[invoice.id] or 0)+1
    elseif reason then
      report.pending=report.pending+1
      report.reasons[reason]=(report.reasons[reason] or 0)+1
    else
      report.ignored=report.ignored+1
    end
  end
  for _,invoice in ipairs(invoices) do
    local reason,record
    if occurrences[invoice.id]>1 then
      reason="identical_mail_collision"
    elseif seen[invoice.id] then
      report.duplicate=report.duplicate+1
    else
      local key,resolveError=itemKeyForMail(invoice.index,invoice.invoice.itemName)
      if not key then reason=resolveError
      else record,reason=A.ParseAuctionMail(invoice.header,invoice.invoice,key) end
      if record and state.enabled then
        local rows=A.ProJournal()
        -- Storing the fingerprint with the saved row makes it auditable and
        -- protects against a rebuilt deduplication index.
        local already=false
        for _,row in ipairs(rows) do
          if row.mailRef==invoice.id then already=true;break end
        end
        if already then
          seen[invoice.id]=now
          report.duplicate=report.duplicate+1
        else
          record.t=now
          record.source="auction_mail"
          record.mailRef=invoice.id
          rows[#rows+1]=record
          seen[invoice.id]=now
          report.imported=report.imported+1
        end
      elseif record then
        report.ready=(report.ready or 0)+1
      end
    end
    if reason then
      report.pending=report.pending+1
      report.reasons[reason]=(report.reasons[reason] or 0)+1
    end
  end
  announce(report)
  if report.imported>0 and A.proWindow and A.proWindow.pages then
    for _,pageName in ipairs({"journal","portfolio"}) do
      local page=A.proWindow.pages[pageName]
      if page and page.IsShown and page:IsShown() and page.update then
        pcall(page.update)
      end
    end
  end
  return report
end

if type(CreateFrame)=="function" then
  local f=CreateFrame("Frame")
  f:RegisterEvent("MAIL_SHOW")
  f:RegisterEvent("MAIL_INBOX_UPDATE")
  f:RegisterEvent("MAIL_CLOSED")
  f:SetScript("OnEvent",function(_,event)
    if event=="MAIL_CLOSED" then mailboxOpen=false;return end
    if event=="MAIL_SHOW" then mailboxOpen=true end
    if mailboxOpen and A.MailImportState().enabled then A.ScanAuctionMail() end
  end)
end
