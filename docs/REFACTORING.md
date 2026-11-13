# TradeScope 4.4.0-beta2: structural refactor

This beta reorganizes source paths and splits ProUI. It is **not** the roadmap's Trading Journal 2.0 feature implementation. The stable 4.3.0 behavior remains the baseline.

## Module graph / TOC order

The TOC in the addon root is the authoritative load manifest. Paths are relative to the `AuctionatorTradeScope` addon folder. No dynamically loaded Lua code or external Lua modules are required.

- `Engine/`: global addon state and initialization
- `Localization/`: translations
- `Data/`: price history and item metadata
- `Market/`: market analytics, scanner, alert rules and Pro research calculations
- `Finance/`: balance and manual trade ledger
- `Crafting/`: recipe inventory snapshots
- `UI/`: UI components, charts and controls
- `UI/Pro/Shared.lua`: all old ProUI helper closures, exported via `ATS.ProUIShared`
- `UI/Pro/Pages/`: ten independent tool builders registered in `ATS.ProUIBuilders`
- `UI/Pro/Window.lua`: workstation frame, tab routing, shared help panel, and public Pro entrypoints

## Regression

Run from repository root:

```powershell
texlua scripts/check-syntax.lua <every Lua source listed in the TOC>
texlua scripts/test-craft-batch.lua
texlua scripts/test-graph-cursor.lua
powershell -File scripts/verify-release.ps1
```

Always test the interface in WoW Forever before releasing. Never add a release tag for this branch while the user is testing. Preserve SavedVariables by keeping this refactor purely structural.

## Beta2 extract (no code logic redesign)

- `UI/Charts/Graph.lua`: rendering, scales, cursor and zoom
- `UI/Charts/Placement.lua`: positioning away from native item tooltips (`ATS.GraphPlacement`)
- `UI/Charts/Preview.lua`: crafting hover preview and regular floating graph lifecycle
- `Finance/Journal/Ledger.lua`: existing manual journal CRUD and P&L report API
- `Finance/Journal/Analysis.lua`: read-only weighted-cost analytics, filtering, per-item metrics

The journal analysis computes cost basis on **all** transactions before applying output filters. It deliberately excludes unmatched sale units from realized P&L. It does not infer confirmed real-money trades or auction activity. The existing `JournalReport` entrypoints continue to work.

New tests: `texlua scripts/test-journal-analysis.lua`; `texlua scripts/test-toc.lua`. No tag should be created for this branch.

## Beta3: Journal filters and Crafting UI components

- `Finance/Journal/Analysis.lua`: read-only matched-cost P&L, item/kind/time filters, item positions, deterministic `JournalPage` pagination; returns `entry.index` for future actions without modifying saved entries.
- `Finance/Journal/Ledger.lua`: legacy `JournalReport` no longer writes `_pnl` into saved trade records. Existing journal schema and APIs remain unchanged.
- `UI/Pro/Pages/Journal.lua`: user-visible filter controls and sale-detail tooltip; paging/filter preferences are in-memory only.
- `UI/Pro/Craft/RecipePicker.lua`: saved-recipe search, keyboard selection, profession import and popup events.
- `UI/Pro/Craft/Report.lua`: material rows, ingredient exclusions and batch economics, with page state injected by the calculator.
- `UI/Pro/Pages/Craft.lua`: composition and screen events; no new tooltip beneath the recipe search input.

Tests from the source root:

```sh
texlua scripts/test-toc.lua
texlua scripts/test-ui-modules.lua
texlua scripts/test-craft-batch.lua
texlua scripts/test-craft-report.lua
texlua scripts/test-graph-cursor.lua
texlua scripts/test-journal-analysis.lua
texlua scripts/test-journal-ui.lua
```

Only the main testable branch is packaged by GitHub Actions in build-only mode (`-d`). Do not push release tags for this beta. Run WoW Forever in-game regression tests before any promotion.

## Beta4: journal UI and terminal cleanup

Journal filters use the shared `ProUIShared.dropdown` for direct item/type/period selection. Filter choices are local UI state. The legacy watchlist UI and paging arrows were removed from the terminal, but `ATS.AddWatch`, `ATS.RemoveWatch` and persisted watchlist data remain. Search suggestions and graph zoom remain; bag item selection no longer writes a hidden watch entry.

## Beta5: restored terminal watchlist

The beta4 removal of the watchlist and its paging controls was reverted after in-game feedback. `UI/Dashboard.lua` again presents eight watch entries per page, prev/next pagination and the Pin/Unpin button. Layout uses a 25-unit row rhythm from y=-352, compact controls at y=-562 and an 8-unit lower Tools button at bottom-right. The watchlist data model and other UI modules are unchanged.

`scripts/test-dashboard-ui.lua` checks preserved watchlist/search/zoom functions, button anchors and separation from the footer. The game client remains the final authority on scaling and text overlap.

## Beta6: terminal footer polish

A 56-unit footer strip now gives the Tools button and footnote generous top/bottom inset. Watchlist rows use 24-unit spacing starting at y=-348; page arrows and Pin are at y=-549. All controls stay above the divider at y=-582. No new data schema or behavior changes. See `scripts/test-dashboard-ui.lua` for conservative geometry checks.

## Beta7: footer shadow removal

Only the secondary 56-unit translucent footer backing texture was removed. The single-pixel separator and all footer/watchlist coordinates from beta6 are unchanged. No data or API behavior changes.

## 4.4.0 stable promotion

Stable 4.4.0 is based on the game-tested 4.4.0-beta7 revision. Version metadata and release documentation changed; the gameplay Lua modules (beyond the Core version string) are identical to beta7. Current Trading Journal improvements apply to **manual** transactions; there is no automatic auction transaction detection. Existing SavedVariables are not migrated or rewritten by the release process.
