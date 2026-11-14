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
