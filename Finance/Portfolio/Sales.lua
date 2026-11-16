-- TradeScope 4.5.0-beta3: confirmed revenue, independent of known cost basis.
-- Mail import source is authoritative; an unmatched sale is real revenue but
-- UNKNOWN profit. All figures are in copper and derived read-only from journal.
local A=ATS
function A.PortfolioSalesReport(rows)
  local analysis=A.JournalAnalysis(rows)
  local report={sales={},count=0,units=0,gross=0,fees=0,net=0,
    matched=0,unmatched=0,realized=0,manualCount=0,manualNet=0}
  for _,entry in ipairs(analysis.entries) do
    if entry.kind=="sell" then
      if entry.source=="auction_mail" then
        report.count=report.count+1
        report.units=report.units+entry.qty
        report.gross=report.gross+entry.qty*entry.price
        report.fees=report.fees+entry.fees
        report.net=report.net+entry.net
        report.matched=report.matched+entry.matched
        report.unmatched=report.unmatched+entry.unmatched
        if entry.pnl then report.realized=report.realized+entry.pnl end
        report.sales[#report.sales+1]={index=entry.index,key=entry.key,
          qty=entry.qty,gross=entry.qty*entry.price,fees=entry.fees,
          net=entry.net,pnl=entry.pnl,costBasis=entry.costBasis,
          matched=entry.matched,unmatched=entry.unmatched,
          t=entry.t,source=entry.source}
      else
        report.manualCount=report.manualCount+1
        report.manualNet=report.manualNet+entry.net
      end
    end
  end
  -- Last manually entered/imported entry is first, matching journal ordering.
  local reversed={}
  for i=#report.sales,1,-1 do reversed[#reversed+1]=report.sales[i] end
  report.sales=reversed
  report.knownProfit=report.matched>0
  return report
end
