# TradeScope 5.0.0-beta2 — Unified Terminal

Local test build, not a public CurseForge release.

## Single-window navigation
- Market: **Terminal**, Scanner, Price alerts, Candles, Activity.
- Analytics: Indicators, Heatmap, Data quality.
- Trading: Strategies, Portfolio, Journal, **Gold history**.
- Crafting: Calculator, Recipe catalog.
- All navigation and `/ats`, `/ats wallet`, `/ats strategies`, minimap shortcuts and item-history links route to the same TradeScope window. Legacy `/ats pro` remains a compatibility alias without presenting the old name.
- The historic market dashboard and gold history are embedded as child frames and cannot show their own top-level windows.
- All permanent "HOW IT WORKS" sidebars are removed; the contextual top-right `?` tooltips and control hover hints remain. Craft recipe scan feedback is now shown within its page, not in a deleted help panel.
- Existing business logic, SavedVariables, data history, UI combat protections and other research pages are untouched.

## Test in WoW Forever
1. Open `/ats`, verify `Рынок → Терминал` is selected and its search, bags, watchlist, graphs and Tools work.
2. Switch to another tab and back; no second window, no resurrected standalone terminal.
3. Open `/ats wallet`, use character gold history zoom; navigate to `Торговля → История золота`, then back.
4. Open scanner results then item history; history opens in the Terminal tab with the same selection.
5. Verify all 14 destinations, page `?` and field tooltips; no permanent "КАК ЭТО РАБОТАЕТ".
6. Crafting recipe scan displays feedback in the page; recipe/material calculations unchanged.
7. Combat immediately closes everything and blocks reopening. No auto-restore after combat.
8. No Lua errors; saved data survives the update.

### Validation limits
Automated source-level regressions and Lua interpreter tests run outside the game. Visual behavior, protected frames and actual WoW Forever compatibility need in-client confirmation.
