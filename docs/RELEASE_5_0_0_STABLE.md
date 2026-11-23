# Auctionator TradeScope 5.0.0 — Stable release

**Released 23 November 2026.** WoW Forever 1.60.1 (`Interface 16001`), Lua 5.1.

## Confirmed release status

- All five final 5.0.0-rc1 in-game smoke checks and seven 5.0.0-beta7 gameplay checks were confirmed.
- The stable version includes the validated RC1 functionality; the only intended changes to game-facing Lua were version metadata.
- Version `5.0.0` is merged into `main` at commit [`986ced9`](https://github.com/VirbickasGytautas/AuctionatorTradeScope/commit/986ced9a2324f0880c580ae959ea4887cf37ff15) via [Pull Request #6](https://github.com/VirbickasGytautas/AuctionatorTradeScope/pull/6).
- GitHub Actions [Build Only run #45140016911](https://github.com/VirbickasGytautas/AuctionatorTradeScope/actions/runs/45140016911) passed all 28 Lua 5.1 regression suites, `luac5.1` syntax checks, packaging and ZIP integrity tests.
- Annotated tag [`v5.0.0`](https://github.com/VirbickasGytautas/AuctionatorTradeScope/tree/v5.0.0) points to `986ced9`.
- GitHub Actions [CurseForge publisher #45141207710](https://github.com/VirbickasGytautas/AuctionatorTradeScope/actions/runs/45141207710) succeeded, including uploading `AuctionatorTradeScope-v5.0.0-forever.zip` to CurseForge project 1796279. [Project page](https://www.curseforge.com/wow/addons/auctionator-tradescope).
- A separate GitHub Releases page was not created by the tag workflow; this does not invalidate the successful CurseForge publishing workflow.

## Features in 5.0.0

- Single TradeScope window and grouped sidebar; Market → Terminal is the entry point, Trading → Gold History is an embedded tab.
- Activity and Data Quality displayed side by side for the same selected item.
- Candlestick chart geometry, analytics layouts and contextual `?` help.
- Craft Catalog → Craft Calculator handoff, saved recipes and inline material/cost report.
- Previously available scanner, alerts, indicators, heatmap, strategies, journal, portfolio and market history.
- Combat protection closes TradeScope windows when combat begins and blocks reopening during combat.

## Compatibility and limitations

- WoW Forever 1.60.1; intended for use alongside Auctionator.
- No SavedVariables reset or migration; previously saved history, journal, watchlist and recipe records are retained.
- All prices and indicators are based on local Auctionator observations. Market supply is not confirmed sales. Estimates are not guaranteed returns.
- Confirmed revenue is not realized profit if acquisition cost is unknown.
- No automatic buy/list/sell functionality.

## Historical validation documents

[5.0.0-rc1 preparation notes](RELEASE_5_0_0_RC1.md) describe the earlier candidate stage. Any pending CI or publication steps in that historical file were completed before the stable release documented here.
