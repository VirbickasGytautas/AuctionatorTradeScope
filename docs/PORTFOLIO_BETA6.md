# TradeScope 4.5.0-beta6 — item icons in Portfolio and Trading Journal

WoW Forever beta UI patch only; stable main and CurseForge publication remain unchanged.

## Why icons were blank

`Data/ItemInfo.lua` previously queued metadata requests only when an item name was missing. Auctionator can have a localized name in its saved index while the WoW client has not yet loaded the associated item **texture**. In that case `ATS.ProItemMeta` returned the placeholder; name-only cache entries were considered complete. On the live UI this could show as a nearly invisible strip.

## Fix

- Missing textures are treated as incomplete metadata even when names are available. A bounded queue requests the corresponding item ID, and priority attempts resolve late WoW Forever client data.
- `UI/Pro/Shared.lua` provides one shared 21x21 **OVERLAY** item-icon renderer. Overlay placement keeps art above the stock button background; text receives an inset to avoid covering the icon.
- Until a valid texture arrives, a gold question mark appears over the placeholder; a newly resolved texture replaces it without needing to restart the game.
- Both `Portfolio.lua` and `Journal.lua` use the helper. The polling loop retries only visible rows with missing icons for a finite window; hidden rows clear their textures correctly.
- Journal entry source markers, dates, quantity, value and P&L remain unchanged. No new SavedVariables keys or financial calculations.

## In-game regression

1. Open **Portfolio > Sales** and look at Moss Agate, Heavy Leather and Jade previously missing icons. See whether proper icons appear after the client fetches metadata. Before that, a visible `?` must appear.
2. Switch between Stock, Sales, Cost basis and Allocation. Each item has an icon; the Allocation bar still appears only in Allocation mode.
3. Open Trading Journal, verify all visible purchase and sale rows have a 21px icon and remain readable with long Russian names.
4. Page through the Journal and Portfolio; icon keys and placeholders must not leak from the previous page.
5. Confirm auction-mail imports, cost basis, journal filters, and craft / market screens remain unchanged.

Automated tests: `scripts/test-pro-item-icons.lua` (name cached but icon initially absent), `scripts/test-journal-ui.lua`, `scripts/test-portfolio-ui.lua`, plus the whole build-only suite.

**Limit:** the addon cannot fabricate authentic item art if WoW Forever never provides that item's texture. It will keep a visible '?' instead.
