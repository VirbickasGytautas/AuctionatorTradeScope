# Auctionator TradeScope 4.4.0-beta7 — WoW Forever

### 4.4.0-beta7 - Remove footer background shadow (local testing)

Removed only the extra translucent footer backing added in beta6. The footer separator, spacing, Tools button, watchlist, paging arrows and all behaviors remain as before. No SavedVariables changes or CurseForge upload.

### 4.4.0-beta6 - Terminal footer polish (local testing)

The bottom footer is slightly taller and shaded. The Tools switch and hint are centered in it, and all watchlist rows, page arrows, and Pin/Unpin remain visible and aligned above the separator. No market or journal logic and no saved data changed. Not published to CurseForge.

### 4.4.0-beta5 - Watchlist restored and terminal alignment (local testing)

Restores the eight-row Market Terminal watchlist, previous/next arrows, and Pin/Unpin button. Watch rows and navigation now fit inside the left column above the footer, and the bottom-right Tools button sits eight UI pixels lower. Bag drag-and-drop can add the selected item to the watchlist again. The beta4 Trading Journal dropdowns and existing SavedVariables are unchanged. No release tag or CurseForge publication.

### 4.4.0-beta4 - Journal UI and terminal cleanup (testing only)

Aligned the Trading Journal form, actions, summary, filters and pagination. Item/type/period filters now have compact direct-selection dropdowns like the Scanner. The Market Terminal no longer shows the old watchlist panel or displaced paging arrows; name/ID search, bag item selection and charts remain. Legacy saved watch data are preserved. No changes to journal accounting or SavedVariables. Not published to CurseForge.

### 4.4.0-beta3 - Journal filters and Craft UI modules (testing only)

The manual Trading Journal now filters transactions by the selected market item, BUY/SELL and rolling 7/30/90-day windows, with eight rows per page. Hover a sale to see matched units, missing purchase units, weighted-average cost basis, fees, realized profit and ROI. Filters never change the cost-basis history and are not persisted to SavedVariables. Legacy report reads no longer attach temporary `_pnl` values to saved trades. The Crafting Calculator's recipe selector and results renderer are independent modules with unchanged behavior, and recipe usage instructions remain in the right HOW IT WORKS sidebar. Automatic trade capture is **not** included. This beta is for local testing and is not uploaded to CurseForge.

### 4.4.0-beta2 - Structural refactor: chart extraction and Journal 2.0 groundwork

Separated graph placement and crafting previews, extracted journal storage and added read-only weighted-cost analytics. A compact manual journal summary is available. No automatic trading event capture, migrations or release publication. The original Trading Journal 2.0 roadmap is not complete.

### 4.4.0-beta1 - Structural refactor (testing only)

Moved Lua source into modular directories and divided the Pro workstation into independent pages. No new features or SavedVariables changes. This is a local beta and is not an implementation of Trading Journal 2.0.

### 4.3.0 - Stable release

Promoted after in-game testing of 4.3.0-beta5. Includes Crafting Intelligence 2.0 batch planning, inventory-aware reagent purchase estimates, a grouped buy list, and the chart cursor/right-edge fixes. Historical prices, saved recipes, settings, and SavedVariables remain compatible. No market data or addon logic was changed for the stable promotion.


### 4.3.0-beta5 - Batch crafting preview

Under TradeScope Pro > Crafting Calculator, select a saved recipe and enter **Crafts in batch** (1–999). The reagent table shows total materials needed, stock in bags/bank (when enabled), and missing purchase quantities. Hover or click **Buy list** for a combined ingredient shopping list, including repeated reagents. The summary shows the complete batch's market cost, estimated purchases, auction net revenue, market profit, cash-basis profit and market ROI. A recipe producing two items per craft correctly produces twice the selected crafting count. Missing prices remain unknown instead of being treated as free resources. Existing recipes, inventory snapshots and history remain intact. The beta was tested in the game client before promotion to the stable 4.3.0 release.

### Version 4.2.1.6 - Scanner sorting and window backgrounds

The Trader tools / Back to chart switch now appears at the bottom-right of the Market Terminal. The header retains Alerts, TradeScope Pro, and Gold History. Chart behavior, trading calculations, historical data, and settings are unchanged.

### Version 4.2.1.2 - Smart Alerts condition dropdown

Smart Alerts now has a direct dropdown for all nine condition types, grouped by price limits, price changes, and market analysis. Choose a condition with one click; the required threshold fields update automatically. Saved alerts and calculations are unchanged.


**Author:** Gytautas Virbickas  
**Languages:** Russian (`ruRU`) and English (fallback)  
**License (original code and documentation):** MIT (`LICENSE`)

A companion for **Auctionator** offering price and supply histories, dual-axis charts, observed supply-decrease bars, and an optional trading research calculator. Prices and quantities are snapshots gathered locally from Auctionator; this addon does **not** provide an exchange order book or actual confirmed sales.

### Smart Alerts 2.0 — 4.2.1

TradeScope Pro > Price Alerts now supports multiple rules per item: fixed price thresholds, percentage deviations from the recorded median, relative price changes, observed supply decreases, observed volatility, and Opportunity Score with a Risk Score ceiling. Configure a condition and a threshold, then save it. Existing below/above alerts are preserved. Individual new rules can be turned off and on.

Notifications are generated **only when Auctionator records fresh observations**. Settings include cooldown, chat messages, sound, screen notifications, minimum sample/quality requirements and journal size. The per-realm notification history can be inspected and opened directly in the market terminal. Supply reductions are *not verified sales*; scores are *not probabilities of a successful trade*.

## Install / update

1. Install a compatible Auctionator separately.
2. Remove or disable the obsolete `AuctionatorPriceWeek` addon folder if it exists. Keep only `AuctionatorTradeScope/` for TradeScope.
3. Extract `AuctionatorTradeScope/` to `Interface/AddOns/` and use `/reload`.
4. Existing TradeScope 3.0–3.2 `AuctionatorTradeScopeDB` data is preserved; back up SavedVariables before major updates.


### Technical Indicators 2.0 — 4.1.1

EMA, RSI, MACD and Bollinger Bands now use the last **actual observation per configured time bucket** (default 15 minutes). No prices are synthesized for missing time buckets. Long observation gaps (default 12 hours, configurable) restart the indicator calculation. The RSI chart includes 30/50/70 guide lines and labels, and MACD includes its histogram. Hover over either chart to inspect the nearest recorded value and its timestamp.

A full RSI(14) needs 15 distinct observed time buckets after the latest break. When only 4–14 buckets are available, **optional preliminary RSI** uses the available changes and is explicitly marked as preliminary. With fewer than four buckets, the chart explains the shortage instead of inventing values. MACD signal values are marked as warming up until at least 34 buckets in a continuous segment. Settings are in AddOns > Auctionator TradeScope > Technical indicators 2.0. Existing histories, recipes, and preferences are retained.

### Market Data Engine 4.1.0

Saved history is normalized lazily per item (no automatic data reset). Recent reads use a short in-memory cache that refreshes immediately after new scans. The data-quality panel shows real observation coverage by time bucket. Estimated market supply reductions ignore consecutive snapshots separated by more than the configured threshold (Options > History & Data Quality). Missing intervals remain unknown, and decline estimates are never confirmed sales.

## Market terminal (`/ats`)

- Enter an item ID, full item link, or a **known item name** into the left selection field; press Enter. Search suggestions appear for item names previously discovered by TradeScope or locally accessible from Auctionator's cache. Other items may need a first tooltip visit or item-data download before their names become searchable.
- Drag an item from a bag to the selection slot, or choose **Select from bags** and hover over an item.
- The field shows the **item name**, not an `item:...` hyperlink. Watchlist names and icons are cached in `AuctionatorTradeScopeDB`, including after `/reload`; long names use UTF-8-safe `...` truncation.
- Choose combined/price/supply/decrease charts. Use mouse wheel or `+` / `-` / Reset to zoom; the tooltip graph also zooms, with reliable steps in both directions starting from 1 hour.
- Charts support color customization, optional legend, moving average, trendline and multiple time ranges.

### Trader tools

The new **Trader tools** button switches the terminal between chart and research panel. It shows:

- Observed price change over the past 24 hours (requires a reasonably recent baseline), relative position within the period's low/high range, distance from median, price dispersion, and age of latest sample.
- Last recorded available quantity, 24-hour observed supply reductions, a supply-pressure *proxy*, scan coverage and data-confidence rating.
- **Deal calculator:** enter your own buy price **in gold** (e.g. `1.25` or `1,25`), press Enter and see net resale revenue after configurable auction commission, estimated gross profit, ROI and break-even sale price. The entered buy price is saved per item. The model does not include listing deposits or other costs.
- Price-position cues only when enough observations exist. These cues are not buy/sell instructions or guaranteed returns.

The feature and its optional price cues can be turned off in **Options → Trader tools**. Fee and minimum sample count are configurable.

## Other features

- Tooltip chart stays open when moving from an item tooltip onto the graph.
- Optional per-character money history in `/ats balance`, with draggable window, coin icons and reversible zoom steps.
- Auctionator scan data is collected when Auctionator updates the price database. Supply decreases may reflect purchases, cancellations, expired listings or partial scans. They are **not verified sales**.
- The attempted NPC vendor-resale overlay was **removed in v3.3.0** because it did not work reliably on the custom WoW Forever merchant interface. The market terminal's manual calculator replaces it for transparent, user-supplied purchase costs.

## Commands

`/ats` market terminal · `/ats options` addon settings · `/ats balance` wallet history · `/ats 12345` select item by ID · `/ats add` watch tooltip item · `/ats status` diagnostics · `/ats clear` clear the local history (confirmation required).

**Compatibility:** Lua 5.1-style addon; `## Interface: 16001` for the WoW Forever client used to develop the addon. Test in the actual game before publishing. This archive does not contain Auctionator or Blizzard game resources.

### Item name search (v3.4.1)
The Market Terminal searches item IDs and localized names across the **locally known Auctionator price database and WoW item cache**, not only watched items. Results can be scrolled and grow while items are indexed. A bounded name index is preserved across /reload. The WoW client cannot enumerate every possible server item without a separate item-name database; uncached and never-scanned items may therefore be absent. Search by ID or drag an item to add it directly to your watchlist.

### Trading calculator (v3.5.2)

Enter the purchase cost **per item** in separate gold, silver and copper boxes. For example, 90 copper is **0 gold, 0 silver, 90 copper** (not 0.09 gold). Enter the number of units you plan to buy. TradeScope estimates per-item revenue using the latest observed Auctionator price, deducts the configured Auction House fee, and calculates batch purchase cost, batch net revenue, total profit/loss, ROI, and break-even price per item. This estimate assumes every item sells at the displayed auction quote; it does not include expired-auction deposits, price slippage, or relisting costs.

### Interactive Gold History (v3.5.2)
Hover over the `/ats balance` chart to see a vertical crosshair with the chosen time, the last known exact balance rendered with native coin icons, and when that balance was recorded. Values are never interpolated between observations; the gold graph uses steps and retains the previous observed balance through gaps. The crosshair disappears when leaving the chart.

### Interactive market chart crosshair
Hover over any price, supply, combined, or supply-reduction plot to view a time marker and exact locally recorded data. For prices and quantities, the popup uses the **last observed** value at or before that moment; it never interpolates values between scans. Reduction bars refer to their individual observed time buckets, and must not be interpreted as confirmed sales. Scroll over a chart to change its visible time scale.


## TradeScope 4: Trading Workstation

Use the **TradeScope Pro** button in the main terminal or `/ats pro` to open the workstation.

Use `/ats scanner`, `/ats alerts`, `/ats candles`, `/ats activity`, `/ats journal`,
`/ats craft`, `/ats indicators`, `/ats heatmap`, `/ats quality` or `/ats craftscan`.
The launcher next to the minimap opens a configurable ring of quick-access icons.
Shift-click the main icon for the original market terminal; right-click for settings.
Each individual icon can be hidden in the Minimap Shortcuts settings category.

Features:
- **Market scanner:** scans locally saved price histories for quotes below observed medians,
  with adjustable discount, age, volatility and observation-count filters. This is not
  a live server-wide auction search.
- **Price alerts:** optional notifications when new Auctionator scan results cross
  your per-item thresholds. No offline background monitoring.
- **Candlesticks:** OHLC from successive observed quotes, grouped by selected time
  intervals, not from actual completed transactions. Optional EMA / Bollinger overlay.
- **Market activity index:** a 0–100 heuristic for observed price/supply changes.
- **Trading journal:** manually record actual purchases/sales to estimate realized P&L
  using moving-average inventory costs. Trades exceeding recorded stock do not
  count as matched profit.
- **Crafting calculator:** choose or import a recipe from an open profession and review
  the ingredient cost breakdown. Prices come from Auctionator's local cache.
- **Profitable crafting scanner:** rank recipes imported from your professions by
  estimated profit after Auction House fees or return on material costs (ROI).
- **Technical indicators:** time-bucketed EMA, RSI, MACD, and Bollinger Bands with
  marked warm-up periods and explicit gaps. This is not a price forecast.
- **Heatmap:** average observed price by day of week and hour. Empty cells mean
  no observations, not zero prices.
- **Data quality:** freshness, independent hourly scan buckets, coverage and gaps.

The addon does not know verified sales or live auction availability outside scans.
Actual-profit journal records are user-entered; estimated market reductions are not
confirmed transactions. Individual advanced tools can be disabled in AddOns settings.


### Update 4.0.2

- TradeScope Pro now has two rows of native-style tabs and a contextual help panel. The Market Terminal is hidden while Pro is open and restored when Pro closes.
- Search by item name, ID or link in any Pro item field, using locally indexed Auctionator items and an icon suggestion dropdown.
- Hover over inputs for explanations; each tool includes tips and data limitations.
- A compact minimap tool palette replaces scattered shortcut icons; per-tool visibility settings remain available.
- Items missing client metadata display an ID placeholder instead of interrupting a database scan.

### Item names in Market Scanner

Auctionator price records contain item IDs but not always localized names or icons. TradeScope requests item metadata from the game in small batches. The scanner shows named items by default; use **Show unknown IDs** to inspect results whose names the server has not supplied. **Load item names** retries the client lookup. An unresolved ID is not proof that the addon has a real sellable item name; it is a price record with missing metadata.


### Version 4.0.6 — recipe picker and alert descriptions

- Selecting a recipe closes its suggestion list and keeps the chosen recipe selected.
- Imported reagents show localized names whenever the profession API or client item cache provides them. Their internal IDs are retained for price calculations.
- Price alerts now explain the above/below thresholds with examples and contextual tooltips. Alerts only check new Auctionator scan results.

### Version 4.0.4 — research item headers and profession imports

Candles, Activity, Indicators, Heatmap and Data Quality now share aligned item input controls and a selected-item strip with icon, name, ID and observation count. EMA, RSI, MACD and Bollinger Bands have concise descriptions and hover help.

In the **Crafting Calculator**, open a profession in game, select a recipe and click **Import selected**, or type a recipe name and use **Choose recipe** to select one from the client's available profession recipes. The selected recipe fills the product ID, output quantity, reagent IDs and required amounts; you can review the fields before calculating. Both available `C_TradeSkillUI` and classic `GetTradeSkill*` APIs are supported as far as the game client exposes them. If the client does not supply the selection or reagents, enter them manually. Alternative ingredients or recipes with more than six materials cannot be imported into this compact form without losing costs and are explicitly rejected. No old market or wallet data needs to be reset.


### Crafting recipe cost breakdown (4.0.6)

Open a WoW profession, select a recipe and use Import selected, or choose it by name from the profession recipe picker. No manual ingredient fields are required. TradeScope displays each material's icon, localized name, quantity, last known Auctionator unit quote, and extended cost, along with total estimated crafting cost and potential auction net/profit. Missing material prices prevent a complete cost or reliable profit estimate. Multiple pages support long recipes.

### Profitable Crafts (4.0.9)

Use `/ats craftscan` to rank recipes saved from your professions. Open a profession window and click **Import profession**; available recipes are imported in batches and saved by realm. The catalog uses last-known Auctionator ingredient and output prices, subtracts the configured Auction House fee, and lists all imported recipes, including losses and entries with missing prices. Sort fully priced recipes by estimated profit or ROI, and click a row to open its detailed breakdown in Crafting Calculator. An optional profit-only filter, minimum profit/ROI, and the import limit can be configured in AddOns > Crafting recipe catalog. Estimates are not completed sales, and deposits and auction liquidity are not modeled. The former Dashboard tab has been replaced; its saved data is not deleted.


### Recipe catalog and owned materials (4.0.9)

- `/ats craftscan` lists **all imported recipes**, including loss-making recipes and recipes with missing market prices. Profit/ROI sorting applies where prices are available. The optional “Profit only” filter is **off by default**.
- `/ats craft` displays an **Include** checkbox for each reagent, enabled by default. Deliberately excluded reagents are labeled; the resulting cost/profit is incomplete.
- **Optional bag/bank tracking** is off by default. Bag counts update from the current character; bank counts are cached only when the bank is opened. The UI shows owned quantities, additional purchases, market-basis profit and estimated cash-outlay profit. Bank data may be stale and is timestamped.
- Owned ingredients still have a market value: cash-outlay profit is **not** the same as economic profit. Missing quotes remain unknown rather than being invented.


### Version 4.1.0 - stability and WoW Forever diagnostics

- Minimap launcher aligns automatically with the bezel on different minimap sizes. Drag to set a custom position; use AddOns > Minimap shortcuts > Reset icon position to restore automatic placement.
- Improved crafting material chart hover stability: zoom remains when returning to the same item, while switching items resets zoom. If a graph cannot render, it closes safely instead of stopping tooltip updates.
- TradeScope Pro has an in-frame footer status bar and displays its version number.
- `/ats doctor` reports client API availability, bank event support, minimap positioning and recent Lua errors. `/ats stock <itemID>` inspects the individual stock sources. Both commands are diagnostic and do not modify historical data.


### Market Scanner 2.0 (4.2.0)

The scanner ranks historical Auctionator quotes by Opportunity Score and Risk Score. Opportunity considers discount against the historical median, data quality, freshness, price volatility, available supply and observation count. Risk measures uncertainty, not the chance of an item failing to sell. Set the filters in the Market Scanner 2.0 options category. Re-run the scanner after changing settings.

### 4.2.1.6 Interface settings
The Market Scanner offers a dropdown to sort by Opportunity Score, discount, or lowest risk. In AddOns options > Auctionator TradeScope > Window Transparency, adjust the background of the Market Terminal, TradeScope Pro, and TradeScope tooltip graphs independently. 0% is opaque by default; normal item tooltips remain unchanged.
