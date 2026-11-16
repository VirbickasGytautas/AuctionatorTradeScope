# TradeScope 4.5.0-beta2: confirmed auction-mail importer

TEST BUILD ONLY. The importer is disabled by default; enable it with the Trading Journal Auto-mail toggle or /ats mail on.

## Safe operation
- Listens to MAIL_SHOW, MAIL_INBOX_UPDATE and MAIL_CLOSED. Reads the mailbox header, the auction invoice and item attachment link, never the body.
- Does not collect items or gold, delete mail, or infer sales from market activity.
- Imports completed buyer/seller invoices only when item ID, quantity and actual copper amount can be verified.
- Seller payout, deposit, commission and auction bid/buyout must reconcile. Pending payouts and disputed values are skipped.
- Buyer invoices with conflicting positive bid and buyout values are skipped.
- All imported records are labeled auction_mail and share the existing character-specific Journal/Portfolio.
- Deduplication markers are persisted by character. Identical-looking mail without a unique ID is skipped for review rather than double-counted.
- Old SavedVariables and manual journal rows are not reset.

## In-game test
1. Back up your AuctionatorTradeScopeDB SavedVariables file.
2. Open TradeScope Pro > Trading Journal, click Auto-mail: OFF to enable it.
3. Open the mailbox and check actual completed purchase and sale letters.
4. Run /ats mail scan to see counts and reasons for skipped mail.
5. Check [MAIL] rows, quantities, exact prices and portfolio results.
6. Close and reopen the mailbox; previously imported rows must not duplicate.
7. Disable with /ats mail off.

Limitations: deleted mail cannot be recovered, similar concurrent invoices may be ambiguous, item names sometimes cannot be uniquely mapped, and invoice data can arrive after the first mailbox update. Manual journal editing remains available.

References: https://warcraft.wiki.gg/wiki/API:GetInboxInvoiceInfo ; https://warcraft.wiki.gg/wiki/API_GetInboxHeaderInfo.
