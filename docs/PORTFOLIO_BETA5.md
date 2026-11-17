# Portfolio UI — 4.5.0-beta5

Build-only WoW Forever beta. This is a UI/UX patch over the in-game-tested 4.5.0-beta4; no changes to data sources, journal formulas, SavedVariables or mail import.

## Layout

Each Portfolio list item has a **21×21 icon** from `ATS.ProItemMeta(key)` (the same resolver as Market Scanner), with an uncached-item question-mark fallback. Left column is reserved for the localized item name; transaction/cost/stock metrics are right-aligned. There are four supported modes: Stock, Sales, Cost basis and Allocation.

The Allocation mode uses a **640×7 bar** under the top text row, extending across the list width. A golden fill indicates the item share of the *chosen source's eligible priced total*; the percentage and money amount remain printed in the upper row. This is not an ROI meter, risk forecast or actual sales count.

Each row retains its original click-to-market and hover-detail behavior. Leaving the Allocation mode hides all bars; empty paginated slots hide icons, bars, and stale metrics. No changes to the per-source market valuation rules.

## Checks

1. Open Portfolio → Stock, Sales, Cost Basis and Allocation. Each visible row should have its own icon.
2. Check items with short and long Russian names: names and metrics should not overlap.
3. Under Allocation, view a small and a large item share; compare the printed percentage with the fill length.
4. Paginate; icons and bar fills must refresh for the new items, never remain from the old page.
5. Select an item without loaded metadata and check the question-mark fallback.
6. Switch out of Allocation: bars disappear without altering values.
7. Reopen the Portfolio and verify the Journal/mail import and other Pro pages still work.

Regression suite: `texlua scripts/test-portfolio-ui.lua` plus the complete 14-script workflow. GitHub Actions performs build-only packaging (`-d`) on the beta branch. Do not publish this beta on CurseForge.
