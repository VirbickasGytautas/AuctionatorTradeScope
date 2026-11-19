# Trading Portfolio 4.5.0-beta4 — Allocation and concentration

**Build for WoW Forever testing, not CurseForge.** Source: beta/4.5.0-portfolio.

## Scope

The Portfolio > Allocation screen presents four **mutually exclusive** reporting bases in a dropdown: current bags by fresh observed Auctionator market value; last-known bank by fresh observed value; Journal open purchase cost, or confirmed AH-mail **net** sale receipts. Totals **must never be added**: stock and journal lots overlap, and sales revenue is a historical flow rather than current inventory.

- Rows show item value, percentage of the eligible/valued subset and a small relative bar; clicking opens the usual market context, hovering explains the source and exclusions.
- Market valuations require a real recent observed price (default 7 days). Missing and stale quotes are excluded from shares and their count appears as coverage. A price isn't a guaranteed sale.
- Bank counts represent only the last visit. A snapshot older than 24 hours or with unknown timestamp is flagged even if the market quote is fresh. Neither bags nor bank establish acquisition costs.
- Share of largest item >=50% among >=2 valued items triggers a **concentration** warning. A single-valued-item source has a separate warning; a top-three share >=85% among >=4 valued items is also highlighted. These are exposure cues, not predictions.
- Confirmed net sale revenue is grouped by item for the observed mail-invoice history. Only `source=auction_mail` rows count; manual sales remain in the Journal. Historical sales are not open positions.
- Journal cost-based allocation uses the remaining weighted-average purchase basis; it does not automatically reconcile bags to purchases.
- All calculations are read-only and do not change existing SavedVariables. Dropdown selection is session-local.

## In-game validation

1. Open Portfolio > Allocation and select each of the four options directly from the dropdown.
2. Verify bag value and bank value are separate, and no price means no contribution to the total; coverage numerator/denominator reflects the excluded items.
3. Wait 24+ hours since the last bank open or simulate older bank data; the warning must appear. A bank never opened is shown as unavailable, not empty.
4. Check one very high-value item: the concentration indicator appears; tooltip clarifies the percentage's basis.
5. Check confirmed AH sales: net receipts are grouped by item, including sales with unknown acquisition cost, but profit remains unknown.
6. Confirm charts, Journal/mail import, craft screens, saved data and old portfolio modes still work.

GitHub build-only workflow includes `scripts/test-portfolio-allocation.lua` and the Portfolio UI smoke tests.
