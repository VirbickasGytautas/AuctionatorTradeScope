# TradeScope 4.4.0-beta1: structural refactor

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
