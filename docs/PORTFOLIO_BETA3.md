# Auctionator TradeScope 4.5.0-beta3 — Physical Stock & Confirmed Revenue

Local-only, opt-in testing release on `beta/4.5.0-portfolio`. **Do not create a release tag:** the CurseForge publish workflow is tag-triggered.

## Three separate accounting sources

1. **Confirmed auction sales**: `Finance/Portfolio/Sales.lua` derives sale count, quantities, gross receipts, auction fees, net revenue and matched cost-basis profit from `auction_mail` Journal entries only. Manual sales are not conflated with confirmed auction invoices. A sale without a known buy has real revenue, **unknown profit**. It does not generate an artificial negative position.
2. **Physical stock**: `Finance/Portfolio/Inventory.lua` reads the current character's bags (bag IDs 0–4, optional additional custom bag) through legacy and partial `C_Container` APIs. Bank bags and slots are scanned **only while the bank is open**, and are thereafter displayed as **last observed**, with the scan age shown. Events refresh bag data automatically. Bank snapshots are persisted per character under `AuctionatorTradeScopeDB.pro.portfolioStock`; existing SavedVariables are retained. An unavailable client API is never interpreted as a confirmed empty inventory.
3. **Open purchase lots**: the pre-existing weighted-average Journal accounting still tracks known-cost positions independent of physical inventory. It is **not** implicitly merged with bags, to avoid double-counting and false acquisition costs.

## Market prices and conservative valuation

`Finance/Portfolio/Holdings.lua` quotes items with the last actual Auctionator sample no older than seven days. Missing and stale quotes remain visible but are excluded from value totals. Bag values and last-known bank values are displayed separately; neither is a realized profit or sales figure. Source of items (gathered, crafted, purchased, gifted, etc.) is **unknown** unless proven by journal transactions; beta3 does not guess origin. Bank snapshots can go stale between visits.

## In-game check

- Inspect Portfolio → Stock after opening bags; quantities should match bag stacks, independently of the Crafting inventory checkbox.
- Open the bank and close it: bank counts appear explicitly labeled **last checked** and retain a timestamp, never shown as live while closed.
- Select Sales: confirmed invoice entries from beta2 appear with counts, gross, fees and net receipts, even when none have a known purchase cost. Manual sales remain in the Journal but do not inflate confirmed auction revenue.
- Select Cost basis: purchase lots and weighted average P&L remain from beta2.
- Test absence of local Auctionator quotes, stale quotes, bank not opened, repeated mailbox scans, and characters with different inventory/journals.
- Keep a backup of SavedVariables before beta testing. Legacy SavedVariables are preserved; only a new per-character `portfolioStock` namespace is added.

## Local tests

```
texlua scripts/test-portfolio-stock.lua
texlua scripts/test-portfolio-sales.lua
texlua scripts/test-portfolio-ui.lua
texlua scripts/test-portfolio.lua
texlua scripts/test-mail-import.lua
```

The same suites run under Lua 5.1 in GitHub Actions, in build-only mode. No CurseForge publication on branch pushes.
