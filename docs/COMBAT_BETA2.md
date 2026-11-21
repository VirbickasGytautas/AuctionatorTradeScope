# 4.6.0-beta2 — Combat UX and safety

WoW Forever / Interface 16001, Lua 5.1.

## Contract

- **On entering combat**, immediately hide market overview (`A.dashboard`), Pro window (`A.proWindow`), wallet history (`A.balanceFrame`), floating graph (`A.graph`), crafting graph (`A.craftPreviewGraph`), all Pro dropdowns, minimap tool flyout, addon options categories and the addon-specific reset confirmation. The persistent minimap launcher icon itself remains visible.
- **Do not reopen** dashboard as a side effect of Pro.OnHide; clear `restoreDashboard` before hiding. Cancel the crafting-preview timer, any pending item picker, hover graph state and test preview.
- **While in combat** (PLAYER_REGEN_DISABLED or UnitAffectingCombat("player") or InCombatLockdown()), block UI launch APIs, slash UI actions, minimap clicks, coin-hover wallet, graph preview creation, option panels and popup graphs. No hidden or deferred window should appear until after combat.
- **After combat**, do not automatically restore windows. The user may reopen them normally.
- Do not alter Blizzard's regular windows or native item tooltips. The addon's GameTooltip-only helpers may hide if their owner is part of the addon.
- SavedVariables schema, scanner data capture, market history, journal accounting and strategy calculations are unchanged.

## Game checks

1. Open Pro > Strategies, Portfolio, and a floating graph; pull or enter combat. They all immediately disappear.
2. With the Pro window open, enter combat and verify it **does not restore the underlying market terminal**.
3. While fighting try the minimap icon (left/right/Shift-click), /ats, /ats pro, /ats strategies, /ats balance, /ats options, /ats test and the search/hover chart paths. No TradeScope window or graph opens.
4. Start a delayed crafting ingredient chart just before combat begins: the delayed popup must never open during combat.
5. Enter combat with Gold History, add-on options or minimap tools expanded. These addon-owned panels disappear without closing unrelated WoW frames.
6. Exit combat and ensure the old windows stay closed. Open Market Overview and Pro manually again. Existing profiles and saved data should remain intact.
7. Test when item tooltips are still visible during combat: normal Blizzard item tooltips remain.
8. Test WoW reload outside combat and regular use of Journal, mail import, Scanner, Portfolio, Strategies and crafting.

## Test coverage

The `scripts/test-combat.lua` Lua 5.1 suite exercises the event closures, nested tooltip ownership, idempotent hiding, combat state fallbacks, lack of automatic restoration and entry-point guards. The build-only GitHub Action runs it alongside the prior 17 suites and validates a packaged WoW Forever ZIP.

**Release plan:** beta2 is for game validation; stable 4.6.0 source can be prepared without triggering CurseForge (tag `v4.6.0` must be withheld until explicit publication approval).
