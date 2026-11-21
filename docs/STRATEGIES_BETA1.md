# 4.6.0-beta1 — Trading Strategies: source-based research

**This is not an automated trader or a prediction engine.** No AH orders or mail operations are triggered by these profiles.

## Profiles and strict gates

- **Value watch**: uses only the results of the *last user-triggered* Market Scanner 2.0 evaluation and verifies each item against its latest local Auctionator quote. Scanner results expire after 24 hours, quotes after 6 hours. Criteria: at least 12% below observed median; scanner quality >=55/100, risk <=55/100, score >=25/100, 8+ price observations; observed quantity >=3, volatility <=65%. These are initial conservative heuristics, not guarantees of resale potential. Scanning is never performed invisibly by this tab.
- **Exit review**: open current-character Journal lots with documented cost. The latest quote must be <=6h old; estimated proceeds account for configured Auction House fee, and candidates need estimated return on documented cost >=10%. No row for unknown-cost positions or stale prices. A positive estimate does not mean a completed auction sale.
- **Concentration**: only current physical bag contents with *priced, non-stale* Auctionator observations, using existing Portfolio Allocation data. Shows items with >=50% of that valued subset. This is not cost basis, bank valuation, or proof of confirmed demand. When unpriced items exist, shares may be incomplete.

## Data and compatibility

- Engine: `Market/Strategies.lua`. UI: `UI/Pro/Pages/Strategies.lua`. UI shortcut in `UI/Pro/Window.lua`.
- All profiles are **read-only**. The existing `scannerTime`, `savedScanner`, Journal portfolio and live bag snapshot remain the only inputs; evaluation does not modify records.
- Preserves existing TradeScope 4.5.0 SavedVariables, tabs, crafting and mail importer. Version changes to `4.6.0-beta1` in TOC and Core; no CurseForge or release tag.
- Lua test suites `scripts/test-strategies.lua` and `scripts/test-strategies-ui.lua` are added to build-only CI.

## In-game smoke checklist

1. Open Pro: Strategies shortcut is beside Portfolio; the original two rows of five tools are still intact.
2. Open Strategies, try all three profiles. Dropdown should select in one click; icon, name and metrics should not overlap in Russian.
3. Before running the Market Scanner, Value watch should clearly report missing/outdated results, not fabricate a candidate.
4. Run Market Scanner, then refresh Value watch. Confirm actual fresh quotes and evidence limits. It is acceptable to see zero matches.
5. Exit review should only show positions for known-cost journal purchases, not unmatched mail sales.
6. Concentration should use only recent priced bag stock, not stale bank contents; interpret missing-price warning.
7. Navigate multiple pages, verify item icons, click-to-chart, and no overlapping help panel or footer.
8. Test charts, crafting, portfolio, mail importer and SavedVariables after updating.

After these game checks, refine profiles, add user-configurable thresholds and backtest methodology **only when supported by sufficient historical observations**.
