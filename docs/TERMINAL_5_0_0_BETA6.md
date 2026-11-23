# TradeScope 5.0.0-beta6 — Craft Calculator polish

## Reproduced user symptoms in beta5
1. Empty Craft Calculator kept a 900-unit blank material table with control buttons floating in the middle.
2. Clicking a recipe in Craft Catalog navigated to calculator but could leave the saved-recipes suggestion overlay covering the selected report.

## Fix
- Inline non-modal saved recipe browser, up to 12 shortcuts in two columns, visible only before selecting a recipe. Longer lists remain accessible through recipe search and saved-recipes popup.
- Conditional headings: ingredients table appears only after selection; finance summary and paging follow the last visible ingredient row.
- Explicit query focus guard prevents programmatic SetText after catalog navigation from re-opening suggestions.
- Popup dismissed on page show/hide, catalog choice and before/after applying a recipe. Manual search remains functional.
- No data schema or economic calculations changes.

## In-game checks
- Open calculator with no selected recipe; verify saved-recipe shortcuts and absence of empty material table.
- Click saved recipe; verify data, ingredient counts, cost and ROI.
- Click recipe in Catalog; popup must stay hidden, selected recipe calculation visible without further action.
- Manual typing still opens search suggestions; Esc and direct choice dismiss them.
- Switch tabs and return; no stale popup.
- Verify no UI is opened while in combat; after combat no auto-reopening.

Not a public release; do not tag or publish to CurseForge.
