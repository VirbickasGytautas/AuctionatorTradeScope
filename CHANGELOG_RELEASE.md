## 4.6.0-beta2 - Combat Window Safety (local game test)
- Automatically closes all TradeScope windows, mini tool palettes and floating graphs when combat begins.
- Prevents the addon UI from opening via buttons, slash commands and tooltip previews during combat.
- Never restores closed windows after combat; native WoW windows are unaffected.
- Preserves Trading Strategies beta1 and previously saved data; publishing is deferred.

## 4.6.0-beta1 - Trading Strategies (local game test only)
- Read-only strategy research: value watch, exit review with known-cost scenarios, and stock concentration warnings.
- Transparent freshness/quality/risk gates; unknown data means no candidate, not a made-up signal.
- Dedicated localized page in the Pro workstation, directly selectable profile and item icons.
- No purchases, listings, automatic orders, profit guarantees or SavedVariables schema changes.
- No CurseForge upload.

## 4.5.0 - Stable Release

### Trading Portfolio
- Inventory view: current bag stock and a clearly labeled **last-observed bank snapshot**.
- Confirmed sales view: Auction House invoice receipts, gross amounts, fees and net revenue; unknown purchase cost is shown as unknown profit, **not** zero profit.
- Cost Basis view: open Journal positions, weighted-average purchase cost and realized/estimated P&L when an acquisition price is recorded.
- Allocation view: item shares by selected source, wide visual bars, market-price coverage, bank-age and concentration warnings. Inventory value, Journal cost and historical revenue are **not** added together.

### Auction mail and interface
- Optional automatic Journal import of verified completed auction-mail purchases and sales when the mailbox is opened. Strict invoice validation, source labels and repeated-mail protection. Enable in the Journal or with `/ats mail on`.
- Matching 21px item icons in Portfolio and Trading Journal, including late-load retries and visible placeholders; cleaner layout of localized names and amounts.
- Existing charts, scanner, crafting tools and history remain available.

### Important limitations and compatibility
- Import is **off by default** on a fresh installation; it cannot recover deleted mail and does not take items or gold. Incomplete or ambiguous invoices are not imported.
- Revenue cannot be treated as profit for items with unknown acquisition cost. Bank counts reflect the last visit; market values use recent local Auctionator observations, not guaranteed sale prices.
- Previously saved Journal, market history, recipes, watchlist and settings are preserved; new mail and inventory state is stored in separate namespaces.
- Built from the user-tested **4.5.0-beta6** without changes to the feature logic. WoW Forever 1.60.1 (Interface 16001).

## 4.5.0-beta6 - Item icons (local test)
- Trading Journal now shows an icon next to every recorded item, consistent with the Portfolio and Market Scanner.
- Portfolio and Journal retry missing icon textures even when item names are already cached.
- A visible question mark remains until client item metadata becomes available; late-loaded icons update on screen.
- No data/accounting schema changes and no CurseForge publication.

## 4.5.0-beta5 - Portfolio UI polish (local test)
- Item icons appear in Stock, Sales, Cost Basis, and Allocation, matching the scanner.
- Allocation now displays wide, thicker distribution bars and explicit percentages, with clearer row alignment.
- Fallback icons and page transitions are regression-tested. No accounting or saved-data changes.
- Testing build only; not published to CurseForge.

## 4.5.0-beta4 — Allocation & Concentration (local beta)
- Portfolio now shows how observed value or verified receipts are distributed across items.
- Choose bags, bank snapshot, Journal cost or confirmed sales from a dropdown, without double counting.
- Displays top-item shares, coverage and risk-of-concentration indicators; old bank data and missing quotes are flagged.
- SavedVariables and previous transaction accounting are unchanged. No CurseForge publication.

## 4.5.0-beta3 - Live Stock & Verified Revenue (local test)
- Automatically reads bag contents; last-known bank contents from bank visits.
- Portfolio tabs: Stock, Sales (confirmed mail receipts), Cost basis (Journal positions).
- Shows gross/net auction receipts and fees when cost basis is unknown; profit remains unknown.
- Market valuations exclude missing/stale observations; existing history and data are preserved.
- No automatic assumption of how inventory was acquired. No CurseForge publication.

## 4.5.0-beta2 - Auction mail import preview (local testing)
- Optional capture of confirmed Auction House BUY/SELL invoices when opening the mailbox.
- Imports only when item, quantity, actual price and seller fees can be verified.
- Persistent duplicate protection, no automatic item/gold collection, and diagnostics for skipped mail.
- Use the Trading Journal Auto-mail toggle or /ats mail on. Disabled by default.
- No automatic import of past deleted mail, pending sales or auction price/supply changes.
- Not published to CurseForge.

## 4.5.0-beta1 - Trading Portfolio (local test)
- Portfolio for open manually recorded positions, with weighted-average purchase cost.
- Unrealized estimates after fees, separate realized result, missing/stale price flags and per-item details.
- Accessible via Portfolio in the Workstation header or Trading Journal.
- No auto-imported trades, no SavedVariables migration, and no CurseForge publication.

## 4.4.0 - Stable Release
- Modular source layout and independently maintained Pro workstation pages, chart placement and crafting preview.
- Trading Journal: manual BUY/SELL entries, filter by selected item/type/date, eight-row history pagination, per-sale cost basis, auction fees, realized profit and ROI.
- Partial and unmatched sales are labeled; unmatched units are excluded from realized P&L.
- Market Terminal: corrected watchlist/paging button alignment, restored watchlist and Pin/Unpin, improved footer spacing without an extra shadow.
- All existing saved prices, trades, recipes and settings remain compatible; no SavedVariables migration.
- Built from tested 4.4.0-beta7; no automatic import of auction transactions.

## 4.4.0-beta7 - Footer shadow removal (local test)
- Removed the extra dark footer panel; kept the bottom separator and controls in place.
- No functional or saved-data changes; not published to CurseForge.

## 4.4.0-beta6 - Footer layout (local game test)
- A taller, shaded footer separates terminal controls from the window border.
- Tools button and caption are vertically centered; watchlist arrows and Pin fit above the footer.
- Watchlist, journal, charts and saved data remain unchanged. Not published.

## 4.4.0-beta5 - Terminal Layout Correction (local test)
- Restored watchlist, pagination arrows and Pin/Unpin controls.
- Realigned the watchlist and its navigation to avoid footer overlap.
- Lowered the Tools button slightly.
- Trading Journal dropdowns and saved data are unchanged. Not published.

## 4.4.0-beta4 - Journal and Terminal UI Patch (local testing)
- Aligned the journal entry form, summaries, filter row and navigation.
- Direct selection dropdowns for item, transaction type and period.
- Improved empty state, page arrows and Undo button placement.
- Removed the old terminal watchlist panel and displaced pagination arrows.
- No changes to saved data or trading calculations; not published.

## 4.4.0-beta3 - Local Testing Build
- Trading journal: filter by item, transaction type, and time range; browse older entries with pagination.
- Sale details: per-trade average cost, matching status, commission, realized P&L and ROI.
- Refactored crafting calculator: independent recipe picker and material report renderer.
- Opening journal reports no longer changes saved trade rows.
- No automatic trade collection or SavedVariables schema migration. Test only, not published.

## 4.4.0-beta2 - Internal test build
- Split graph tooltip placement and crafting preview into separate Lua modules.
- Extracted manual journal persistence and added read-only per-item analytics.
- Added a small journal summary and automated regression checks.
- No data migration, automatic trade capture, or CurseForge publication.

## 4.4.0-beta1 - Code organization preview
- Modularized source files and decomposed the Pro workstation interface into separate pages.
- Retained prior stable 4.3.0 market and crafting behavior and saved data.
- Test-only local beta; not published to CurseForge.

## 4.3.0 - Stable Release
- Crafting Intelligence 2.0: batch crafting quantities, inventory-aware reagent requirements, and grouped material shopping lists.
- Estimated batch costs, auction proceeds, profit and ROI, respecting unknown market prices and multi-output recipes.
- Fixed supply-decline cursor and last-sample hover on the right chart boundary.
- Improved chart bar clipping and kept crafting instructions in the right sidebar.
- Tested in-game after 4.3.0-beta5; existing history, recipes, settings and SavedVariables are preserved.

## 4.3.0-beta5
- Fixed the supply-decline graph cursor at the final time interval.
- Prevented decline bars from overlapping the right-hand chart axis.
- Kept the crafting help in its sidebar; no history or settings were reset.

## 4.3.0-beta4 - Craft recipe help in right panel
- Removed the misplaced helper line below the recipe search field.
- Recipe usage instructions now appear under HOW IT WORKS.
- Dynamic scan and recipe status text is also shown there.
- No changes to crafting calculations or saved data.

## 4.3.0-beta3 - Crafting Intelligence 2.0 (UI polish)
- Craft calculator: aligned the helper text below the recipe search field.
- Craft calculator: reduced the brightness of the helper text for a cleaner look.

## 4.3.0-beta1 - Crafting Intelligence 2.0 (Batch Preview)
- Added batch crafting quantities (1-999) with live recalculation.
- New buy quantities and grouped shopping list for missing ingredients.
- Full-batch market cost, additional purchase cost, output revenue, profit and ROI.
- Respects multiple outputs per recipe, shared reagent stock and missing quotes.
- Existing saved data remains compatible; game-client verification pending.
