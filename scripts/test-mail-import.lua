-- Auction mail importer regression: strict invoice validation and opt-in writes.
ATS={locale="enUS",db={pro={journal={},journalFee=5}}}
local A=ATS
local clock=1700001000
local frames={}
function time()return clock end
function GetRealmName()return "Realm" end
function UnitFactionGroup()return "Alliance" end
function UnitName()return "Tester" end
function A.RealmKey()return "Realm:Alliance" end
function A.Init()end
function A.CleanItemName(n)return n end
function A.ItemID(link) return type(link)=="string" and tonumber(link:match("item:(%d+)")) end
function A.Key(link) local id=A.ItemID(link);return id and "db:"..id end
function A.FindKnownItems(name)
  if name=="Iron Ore" then return {{id=2772,name="Iron Ore"}} end
  if name=="Ambiguous" then return {{id=1,name=name},{id=2,name=name}} end
  return {}
end
function CreateFrame()
  local f={events={}}
  function f:RegisterEvent(event)self.events[event]=true end
  function f:SetScript(_,fn)self.handler=fn end
  frames[#frames+1]=f;return f
end
local inbox={}
local function mail(kind,name,qty,bid,buyout,cut,deposit,money,expiry,link)
  return {kind=kind,name=name,qty=qty,bid=bid,buyout=buyout,cut=cut,deposit=deposit,
    money=money,expires=expiry,link=link,subject="Auction result: "..name,sender="Auction House"}
end
function GetInboxNumItems()return #inbox,#inbox end
function GetInboxHeaderInfo(i)
  local m=inbox[i]
  return nil,nil,m.sender,m.subject,m.money,0,(m.expires-clock)/86400
end
function GetInboxInvoiceInfo(i)
  local m=inbox[i]
  return m.kind,m.name,"Other",m.bid,m.buyout,m.deposit,m.cut,nil,nil,nil,m.qty
end
function GetInboxItemLink(i,slot)
  if slot==1 then return inbox[i].link end
end
assert(loadfile("Finance/Journal/Ledger.lua"))()
assert(loadfile("Finance/Journal/Analysis.lua"))()
assert(loadfile("Finance/Journal/MailImport.lua"))()
assert(#frames==1 and frames[1].events.MAIL_SHOW and frames[1].events.MAIL_INBOX_UPDATE)
local event=function(name)frames[1].handler(nil,name)end
local expiry=clock+22*86400
inbox={
  mail("buyer","Iron Ore",3,9000,9000,0,0,0,expiry,"item:2772"),
  mail("seller","Iron Ore",2,10000,0,500,200,9700,expiry+1200),
  mail("seller_temp_invoice","Iron Ore",2,2000,0,100,0,0,expiry+2400),
  mail("seller","Unknown Ore",1,7000,0,350,100,6750,expiry+3600),
  mail("seller","Ambiguous",1,7000,0,350,100,6750,expiry+4800),
  mail("buyer","Iron Ore",1,8000,10000,0,0,0,expiry+6000,"item:2772"),
  mail("seller","Iron Ore",1,6000,0,300,0,0,expiry+7200),
}
local success,err=xpcall(function()
local state=A.MailImportState()
assert(not state.enabled)
event("MAIL_SHOW")
assert(#A.ProJournal()==0)
local preview=A.ScanAuctionMail()
assert(preview.ready==2 and preview.pending==4 and preview.ignored==1)
assert(A.SetMailImportEnabled(true))
local saved=A.ProJournal()
assert(#saved==2 and saved[1].kind=="buy" and saved[2].kind=="sell")
assert(saved[1].price==3000 and saved[1].qty==3 and saved[1].source=="auction_mail")
assert(saved[2].price==5000 and saved[2].fee==5 and saved[2].qty==2)
assert(saved[1].mailRef and saved[2].mailRef)
local report=A.JournalAnalysis(saved)
assert(report.openUnits==1 and report.matched==2 and report.realized==3500)
local count=#saved
event("MAIL_INBOX_UPDATE")
assert(#saved==count and A.MailImportLastStatus().duplicate==2)
-- Restarts must not duplicate trades even if the same mail remains in the inbox.
A.db.pro.mailImport.seen={}
event("MAIL_INBOX_UPDATE")
assert(#saved==count and A.MailImportLastStatus().duplicate==2)
-- Two indistinguishable invoices must be quarantined, not double-counted.
local duplicate=mail("buyer","Iron Ore",1,1000,1000,0,0,0,expiry+8200,"item:2772")
inbox={duplicate,duplicate}
event("MAIL_INBOX_UPDATE")
assert(#saved==count)
assert(A.MailImportLastStatus().reasons.identical_mail_collision==2)
-- Invoice mismatch, missing fees, malformed amount and old/future metadata are rejected.
local record,err=A.ParseAuctionMail({money=6700},{invoiceType="seller",count=1,
  bid=7000,buyout=0,deposit=100,consignment=350},"db:1")
assert(not record and err=="payout_mismatch")
record,err=A.ParseAuctionMail({money=6750},{invoiceType="seller",count=1,
  bid=7000,buyout=0,deposit=100},"db:1")
assert(not record and err=="payout_pending")
record,err=A.ParseAuctionMail({money=0},{invoiceType="buyer",count=1,
  bid=1000,buyout=2000},"db:1")
assert(not record and err=="price_ambiguous")
-- Disable auto import: reading inbox must not change the journal.
A.SetMailImportEnabled(false)
inbox={mail("buyer","Iron Ore",1,1500,1500,0,0,0,expiry+9900,"item:2772")}
event("MAIL_INBOX_UPDATE")
assert(#saved==count)
local paused=A.ScanAuctionMail()
assert(paused.ready==1 and #saved==count)
event("MAIL_CLOSED")
assert(A.ScanAuctionMail().mailboxClosed)
assert(#saved==count)
print("PASS mail importer: opt-in, exact invoices, Russian-ready item IDs, duplicates, pending and read-only preview")

end,function(err) print(debug.traceback(err,2)); return err end)
if not success then error(err) end
