# Auctionator TradeScope 5.0.0 — stable package staged, not published

## Status / release gate

- Source is promoted directly from the 5.0.0-rc1 verified in-game by the user.
- All game-facing Lua behavior matches RC1 byte-for-byte except the `ATS.version` string (`5.0.0`).
- User confirmed all five RC1 in-game smoke checks on 2026-11-23.
- No SavedVariables migration or changes to purchase, journal, inventory, crafting, or pricing logic.
- **Lua 5.1 GitHub Actions CI for this exact codebase has not yet run**. Local TeX Lua tests are not a substitute.
- The Build Only workflow is configured to run 28 tests and luac5.1 syntax checks when branch `beta/5.0.0-ci` is pushed.
- No tag `v5.0.0` should be created until CI is verified, and CurseForge publication requires separate explicit permission.

## Before merge to GitHub main

1. Upload these exact source files to the nonpublishing branch `beta/5.0.0-ci` (a helper PowerShell script is included).
2. Confirm that the **TradeScope - Build Only** GitHub Actions run passes all 28 Lua 5.1 checks and its build/ZIP steps.
3. Compare the resulting package and verify the version is `5.0.0`.
4. Merge stable code to `main` only after green CI, keeping the publisher/tag gate closed.
5. Optional final in-game smoke check for the version string; RC1 gameplay functionality already tested.

## Stable 5.0.0 features

- One TradeScope window with a left sidebar and contextual `?` help.
- Market Terminal is a tab; trade Gold History is an embedded tab.
- Unified Activity and Data Quality page in two columns.
- Candlestick and chart layout corrections.
- Craft Catalog > Craft Calculator navigation and recipe picker fixes.
- Original analytics, manual Journal, Portfolio, history, mail import, charts, combat lockdown, and saved settings preserved.
