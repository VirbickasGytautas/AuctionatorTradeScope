# TradeScope 5.0.0-beta1 — Professional Terminal UX

## Scope

This is the first *interactive in-game implementation*, not just a concept image.

- Frame 1188x780 (scales down using the existing WoW screen-size logic).
- Left navigation with four sections and all 12 original tools:
  Market: Scanner, Candles, Activity, Alerts.
  Analytics: Indicators, Heatmap, Quality.
  Trading: Strategies, Portfolio, Journal.
  Crafting: Calculator, Recipe Catalog.
- Current tool name and `?` contextual description in the header.
- Scanner and Strategies use the old 946x557 page interface unchanged at the module level, but their results occupy ~900 px instead of ~700 px; no permanent help column.
- Scanner has separate columns and an actionable empty state; Strategies has a clearer empty state and wide results.
- Other ten page builders and their existing right-side panels remain intact for the next iteration.

## Safety and compatibility

- Based directly on 4.6.0 stable; economic engines are unchanged.
- Combat gating in Engine/Combat.lua, ShowProTab and OpenProTool remains active.
- WoW Forever Interface 16001. Only Lua 5.1 compatible syntax was introduced.
- No SavedVariables fields were added, removed or rewritten.
- No CurseForge tag, release or upload is part of this beta.

## Required in-game checks

1. Open `/ats pro` on 1366x768 and 1920x1080 resolutions; confirm sidebar is legible and controls are not clipped.
2. Click each of twelve sidebar tools and verify the correct page opens and the active menu state changes.
3. On Scanner, verify list columns, cursor tooltips, pagination, sort dropdown, empty-state refresh and market-history link.
4. On Strategies, switch three profiles and verify item icons, navigation and absence of overlapping tips or warning text.
5. Check legacy Portfolio, Journal, Candles, Craft Calculator and Recipe Catalog pages; all controls should remain reachable.
6. Start combat with Pro, Scanner dropdown or Strategies open; all addon UI must close, none may reopen in combat.
7. Verify previous history, recipes, journal, portfolio and settings remain after restart.

## Test reporting

The local build can run source-level regression tests using `texlua` (Lua 5.3).
This **does not** replace a native Lua 5.1 or actual in-game test.
