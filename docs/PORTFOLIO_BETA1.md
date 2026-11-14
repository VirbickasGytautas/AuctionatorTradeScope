# Trading Portfolio 4.5.0-beta1 — design and known limits

This beta is **local-test only**, branched from stable 4.4.0. `main` remains the stable release. No CurseForge upload should occur without a release tag.

## Accounting basis

- Portfolio positions are the **current character's manual** `Finance/Journal/Ledger.lua` entries; no auction events or bags are inferred as trades.
- Cost basis and remaining quantity are obtained from `Finance/Journal/Analysis.lua`, respecting insertion order and **weighted-average** matching for sales. Unmatched sale units do not create short positions or fictional profits.
- Mark-to-market uses the last real price observation stored by Auctionator TradeScope; prices over 7 days old are marked stale. No interpolations or fallback fictional prices.
- Estimated net value applies the configured journal auction fee. Unrealized profit is an **estimate**, not cash proceeds or actual sales.
- Missing and stale quotes do not contribute to market-value or unrealized-profit totals; unpriced cost remains in total invested cost. Therefore estimated totals may cover only a subset of positions.
- `PortfolioSnapshot(rows, quotes, opts)` is deterministic with supplied transactions and quotes, is read-only with respect to them, and does not change the SavedVariables schema.

## User interface

- Click **Portfolio / Портфель** in the Trading Workstation header, or in the Trading Journal action row.
- A list of open positions shows quantities, costs and valuation status, with tooltips for detail.
- The existing 10-tab navigation grid is unchanged to avoid overlapping the content area.

## Next milestone

Planned for later betas: allocation visuals, data-age controls, concentration warnings, and richer position drilldowns. There is deliberately **no automatic auction transaction capture** in beta1.

Run regression tests from repository root with `texlua scripts/test-portfolio.lua` and the existing full test suite.
