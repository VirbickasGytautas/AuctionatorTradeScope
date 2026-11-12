## 4.3.0-beta2 - Crafting Intelligence 2.0: UI polish
- Craft calculator: aligned the helper hint under the recipe input field.
- Craft calculator: darkened the helper hint font slightly for better readability and lower glare.

## 4.3.0-beta1 - Crafting Intelligence 2.0: batch foundation
- Added editable batch size (1-999 crafts) to the crafting calculator, saved across sessions.
- Reagent quantities, market cost, additional cash expense and net auction revenue scale with the batch.
- Recipe output-per-craft is respected; market profit and ROI are calculated separately from cash-basis profit.
- Added a Buy column with needed purchasing quantities and a grouped Buy List for repeated reagents.
- Available bag/bank stock is allocated only once across repeated ingredient IDs; missing prices remain unknown.
- Single-recipe results remain backward-compatible when batch size is 1.
- This is a feature beta, not a verified in-game release.

## 4.2.1.7-beta1
- Test automatic CurseForge packaging.

## 4.2.1.6 - Unified Terminal & Pro Layout
- Unified Market Terminal and TradeScope Pro backgrounds, gold separators and frame borders.
- Removed stacking transparent backdrop layers; only one surface responds to each window transparency setting.
- Embedded market chart background and trade calculator now inherit terminal transparency rather than creating opaque rectangles.
- Standardized the Market Terminal plot viewport for combined price/quantity, price, quantity and supply-decline charts.
- Item-tooltip graph layouts, history, price calculations, alerts, recipes and SavedVariables are unchanged.

## 4.2.1.5 - Market Scanner dropdown and opacity controls
- Market Scanner sorting now uses a drop-down with Opportunity, Discount and Risk modes.
- Added independent background transparency settings for Market Terminal, TradeScope Pro and tooltip charts (0-100%, default 0%).
- Changes apply immediately without fading buttons, icons, chart lines or native WoW item tooltips.
- No changes to market calculations, data history or existing alert rules.

## 4.2.1.4 - 2026-11-12
Market research field synchronization and search popup fix

- Fixed the saved autocomplete popup reopening over restored item fields when returning to TradeScope Pro or changing tabs.
- Kept item suggestions visible only during active user typing; preserved mouse and Enter selection.
- Shared the last selected market item across Price Alerts, Candles, Market Activity, Trading Journal, Indicators, Heatmap and Data Quality.
- Persisted the shared market selection in existing settings without deleting historical data or saved recipes.
- Standardized all applicable item fields to Item / ID (Предмет / ID), and aligned the candlestick search and refresh button to the other research tabs.
- Crafting recipe search remains independent of market-item search.

## 4.2.1.3 - 2026-11-12
Market terminal layout adjustment

- Moved the Trader tools / Back to chart toggle from the top header to the bottom-right of the market terminal.
- Retained Alerts, TradeScope Pro and Gold History in the header.
- Reserved space for the bottom switch so the informational footnote does not overlap it.
- No changes to price history, graph calculations, trading logic, or SavedVariables.

## 4.2.1.2 - 2026-11-12
Smart Alerts condition selector polish

- Replaced cycle-through condition button with a nine-option, WoW-native popup selector.
- Grouped rules into price limits, price changes, and market analytics.
- Highlighted the active rule and added per-option units and brief RU/EN tooltips.
- Close the selector on selection, Escape, or switching tabs.
- Preserved saved rules, thresholds, event history and all market calculations.

## 4.2.1.1 - 2026-11-12
Classic WoW button and interface polish

- Added a shared Classic WoW-inspired visual style for action buttons throughout TradeScope Pro, market terminal, graph and balance controls, and add-on settings.
- Clear visual distinction between saving/confirming (green), deleting/clearing (red), navigation (muted blue), and standard actions (warm bronze).
- Smart Alerts now shows contextual Enable or Disable labels and button colors for the selected rule.
- Added native action icons where they fit to Save condition and Remove selected, with bilingual explanations for deletion.
- Active Pro tool tabs and graph mode tabs now have distinct gold highlights instead of resembling ordinary buttons.
- Standardized hover, pressed and disabled appearances, with fallback borders for clients without frame backdrops.
- No changes to alert triggers, price history, calculations, inventory tracking, or SavedVariables.

## 4.2.1 - 2026-11-12
Smart Alerts 2.0

- Added observation-based alerts for prices above/below thresholds, price deviation from historical median, price changes, listing quantity decreases, volatility and Opportunity Score with maximum Risk Score.
- Alerts are checked only after Auctionator records new market observations; they do not poll the auction house or claim confirmed sales.
- Added per-item configurable conditions, individual enable/disable controls, cooldown persistence across reloads and a bounded per-realm notification journal.
- Added quick access to alert configuration from the market terminal, clickable event history and separate controls for sound, chat and screen notifications.
- Added a Smart Alerts 2.0 settings section for history requirements, data quality, default risk ceiling and log retention.
- Preserved existing price threshold alerts and existing history, recipes, gold records and SavedVariables.

## 4.2.0.5 - 2026-11-11
- Apply the existing tooltip graph delay to crafting recipe output and ingredient hover charts.
- Show native item and equipment comparison tooltips immediately; display the TradeScope chart only after the configured delay.
- Cancel pending charts if the cursor leaves the row, the recipe changes or the Pro tab closes.
- No changes to price history, crafting calculations or SavedVariables.

## 4.2.0.4 — 2026-11-11
Recipe picker mouse selection fix

- Fixed saved-recipe dropdown selections being lost when the search input loses focus.
- Recipe rows now select on mouse-down, with click fallback and current-row bindings.
- Preserved Enter/Esc, filtering, scanning, and recipe history.

## 4.2.0.3 - 2026-11-11
- Simplified crafting calculator recipe selection: search input, scan available open-profession recipes, and saved-recipe dropdown.
- Removed unreliable live-profession selector and direct selected-recipe import buttons.
- Recovered readable names for legacy saved recipes from client item information when available; retain ID fallback if item data cannot be loaded.
- Search saved recipes by name or output item ID, with Enter/Esc and mouse-wheel support.
- Scan profession recipes in small batches and display completed/skipped counts.
- Preserved existing recipe/material records, market history and user settings.

## 4.2.0.2 - 2026-11-11
- Crafting Calculator: aligned recipe search, selection and import controls with other Pro research tabs.
- Replaced the old full-width seven-button recipe dropdown with a compact, scrollable, icon-based list.
- Added Open profession and Saved recipes modes, substring matching with exact/prefix matches first, keyboard selection, Enter and Esc handling, and dismissal on focus loss/outside click.
- Market graphs avoid overlapping the native item tooltip and equipped-item comparison tooltips; tooltips remain visible while moving from an ingredient or result to its interactive chart.
- Chart placement adapts to the available screen space; on exceptionally small displays the optional chart is withheld rather than covering the standard WoW tooltip.
- No SavedVariables migration; market calculations, historical data and recipes unchanged.

## 4.2.0.1 - 2026-11-11
- Market Scanner UI polish: all four scan/filter/name/sort actions now share a single aligned toolbar row.
- Replaced the scanner's red full-width result buttons with a continuous dark list and subtle hover highlighting.
- Unified the TradeScope Pro window background across header, navigation, content and footer; kept thin separators.
- Integrated the help panel into the main background without a separate opaque block.
- No changes to market scoring, sorting logic, scan data, settings or SavedVariables.

## 4.2.0 — 2026-11-11
- Market Scanner 2.0: Opportunity Score and Risk Score (0–100), both based on local observations, not guaranteed profit or sale probability.
- New scanner sorting: opportunity score, discount, or lowest uncertainty.
- New filters: minimum Opportunity Score, maximum Risk Score, maximum unit price in gold.
- Scanner result tooltips show score components, freshness and data limitations.
- Existing saved results remain valid and display unknown scores until rescanned; no SavedVariables reset required.
- Retains WoW Forever 16001, English/Russian UI and current history, recipes, and account balances.

## 4.1.1 - 2026-11-11
- Technical Indicators 2.0: EMA, RSI, MACD and Bollinger Bands use one observed closing quote per configurable time bucket. Missing buckets are not filled.
- Long gaps between market observations restart the indicator series without connecting disconnected values.
- Wilder RSI(14) on 15+ observed buckets; optional and explicitly marked preliminary RSI after at least four buckets. Clear messages explain insufficient history.
- RSI 30/50/70 guides, MACD histogram, vertical crosshairs and exact observed values on hover.
- Separate settings for time bucket, gap reset, periods, RSI warm-up and indicator visibility, in English and Russian.
- Applied the same gap-aware EMA/Bollinger approach to candlestick overlays. Existing data and settings are preserved.
- Tested calculations for monotonic, flat, duplicate, short and gapped histories; validated both UI localizations in a WoW API mock. Live WoW Forever testing remains necessary.

## 4.1.0.2 - 2026-11-11
- Centered fixed-height hover highlights on their actual metric labels in Market Activity and Data Quality.
- Unified left alignment and highlight width for both tabs; tooltip contents and calculations unchanged.
- SavedVariables format unchanged.

## 4.1.0.1 - 2026-11-11
- Bilingual (ruRU/enUS) hover explanations for every result row in Market Activity and Data Quality.
- Explain sources, time coverage, price/supply changes and the meaning and limits of both indexes.
- Add subtle hover highlighting and update the Pro help panel instructions for those two tabs.
- Clear stale values when no item is selected; do not change stored data or market calculations.

## 4.1.0 - 2026-11-11
- Market Data Engine: lazily normalize stored price observations without deleting existing SavedVariables or rebuilding all item histories on login.
- Consolidate same-second updates and deduplicate legacy/canonical observations in the analysis view.
- Read-through in-memory cache for recent item histories (expires after 20 seconds and invalidates immediately on new observations).
- Preserve the distinction between observed scans, tooltip checks and older historical entries; report actual occupied time buckets and missing intervals in Data Quality.
- Limit estimated supply reductions to actual neighboring observations within a configurable maximum scan gap; unobserved hours remain unknown, not zero sales.
- New Options > History & Data Quality section for configuring the maximum gap and explaining coverage limitations.
- Bounded history storage and incremental work in the market scanner for large local Auctionator databases.
- New engine diagnostics in `/ats doctor`.
- No changes to saved market history, wallet history, recipe catalog, trade journal, or minimap settings required.

## 4.0.16 - 2026-11-11
- Automatic minimap bezel alignment adapts to map diameter; manual dragging preserves custom positioning. Added a reset-position button in minimap settings.
- Display addon version in Pro and keep the Pro status text inside a dedicated bottom bar.
- Stabilize crafting graph previews when switching recipes, hiding a tab, or encountering an unexpected graph rendering error; reset zoom only for a different item.
- Add `/ats doctor` diagnostics for WoW Forever API, bank events, crafting stock and minimap positioning. No SavedVariables are deleted.

## 4.0.15 - 2026-11-10
- Fixed a minimap radius clamp that kept the launcher inside the gold bezel.
- Minimap dragging now adjusts both position angle and distance for manual fine tuning.
- Added addon version to the minimap button tooltip and quick-tools panel.

## 4.0.14 - 2026-11-10
- Item chart previews when hovering over crafting output and reagent rows, with graph zoom and hover persistence.
- Adjusted minimap launcher outward to center it over the circular border.
- Contained the Pro workstation footer within the dark panel for consistent terminal styling.

## 4.0.13 - 2026-11-10
- Crafting calculator now shows one combined "In stock" amount rather than separate bag/bank counts; the calculation of needed purchases uses that same total.
- Display the timestamp of the latest bank check below the crafting cost table and inside material tooltips.
- Prefer reliable combined GetItemCount totals when available to avoid double counting a stale bank snapshot after transfers.
- Recenter the minimap launcher on the minimap gold rim and adjust the artwork alignment.

## 4.0.12 — 2026-11-10
- Fixed incorrect owned material totals after moving items from bank to bags on WoW Forever.
- Added legacy container API fallback when partially implemented C_Container methods return empty results.
- Cross-check bag and bank quantities using live GetItemCount when available, even when a replacement bank UI hides the Blizzard BankFrame.
- Preserved saved bank snapshots for times when the bank cannot be queried.
- Added /ats stock <itemID> to show bag, bank, and game API counts for debugging custom clients.

## 4.0.11 - 2026-11-10
- Refresh the crafting inventory display automatically after moving materials between bags and bank.
- Wait for bag update bursts to settle before recounting; refresh the bank snapshot on close.
- Poll stock while bank is open for custom WoW Forever bank interfaces that do not emit standard events.
- Manual Refresh prices / stock forces a new inventory scan; optional GetItemCount fallback for recently moved items.
- Retain previously saved bank counts and all SavedVariables.

## 4.0.10 — 2026-11-10
- Fixed bottom footer layout in Recipe Catalog: added stable spacing between paging buttons and informational text.

## 4.0.9 — 2026-11-10

- Fixed a WoW Forever startup error when registering unsupported `PLAYERBANKBAGSLOTS_CHANGED` event. All optional bank events are now registered safely without aborting addon loading.
- Refresh bank snapshots on `BAG_UPDATE` while the bank is open, improving compatibility with clients that use older bank update events.
- Preserves previous item histories, crafting recipes, inventory snapshots and settings.

## 4.0.8 — 2026-11-10

- The recipe catalog now lists all imported recipes, including loss-making and recipes with missing market prices. Profit/ROI sort applies to fully priced entries; the profit-only filter is optional and disabled by default.
- Per-ingredient checkboxes in the crafting calculator (enabled by default). Excluded reagents are clearly marked and their cost is omitted only at the user's request.
- Optional personal ingredient stock tracking for bags and the last accessible bank snapshot. Displays stock, additional material purchases, market-basis profit and cash-outlay profit separately. Bank quantities are labeled by observation time and may be stale.
- New related settings; existing TradeScope data and imported recipes are preserved.

## 4.0.7 — Profitable crafting scanner / Сканер выгодного крафта

- Replaced the optional Dashboard/Workspaces tab with Profitable Crafts in TradeScope Pro and the minimap palette. Old workspace SavedVariables are preserved but no longer shown.
- Ranks imported profession recipes by estimated profit after auction fees or by ROI; scans only fully known material costs and crafted-item quotes, without inventing missing prices.
- Click any ranked recipe to open its full material breakdown in the existing crafting calculator.
- Import available recipes from the currently open profession incrementally (five per frame) to avoid blocking the WoW interface; missing/unsupported recipes are skipped, with progress status.
- Added separate preferences for minimum profit, minimum ROI, import limit, and scanner visibility. English and Russian labels are included.
- Historic observations, recipe storage, trade journal, and other settings remain compatible.
- Rankings are estimates based on last known Auctionator quotes, not guaranteed sales or actual crafting profit.

## 4.0.6 — Read-only crafting recipe cost breakdown / Простой просмотр себестоимости крафта

- Replaced editable ingredient fields with a read-only recipe materials table: icon, localized name, quantity, last-known unit price, line total.
- Choosing a recipe or importing a selected profession recipe immediately displays resource costs, estimated sale revenue after auction fee, and profit/loss where all prices are available.
- Supports recipes with up to 40 materials across pages; no silent omission of materials.
- Missing Auctionator prices are shown explicitly. Incomplete material cost is never reported as a complete total or reliable profit.
- Keeps full recipe IDs and saved recipes internally; existing market, gold and settings SavedVariables remain compatible.
- Russian and English user interface supported.

## 4.0.5 — Crafting picker, reagent names and price alert guidance / Рецепты, имена ингредиентов и пояснения сигналов

- Recipe autocomplete closes after selection, including when text is updated programmatically.
- Imported crafted products and reagents display cached localized names while retaining their numeric IDs for cost calculations.
- The profession API reagent names and textures are saved to the local item cache when available; unresolved names are labeled as item IDs instead of guessed.
- Above/below alert buttons have RU/EN tooltips, clear comparisons, examples, and scan-only monitoring details.
- Existing SavedVariables and market history remain compatible.

## 4.0.4 — Profession import and unified research layout / Импорт профессий и единый интерфейс

- Unified the item-selection controls in Candles, Activity, Indicators, Heatmap and Data Quality; these tabs now show a matching item icon, localized name, quality tint, ID and number of observations.
- Aligned research inputs, action buttons and content positions across these tabs. Repeated item-name headings were removed from the results.
- Expanded indicator descriptions and hover help for EMA, RSI, MACD, MACD Histogram and Bollinger Bands in English and Russian.
- Rebuilt the crafting importer to support classic `GetTradeSkill*` and available `C_TradeSkillUI` profession APIs.
- Added an in-addon profession recipe picker, searchable by localized recipe name with a fallback to importing the recipe selected in the game's profession window.
- Recipe selection fills the crafted item, produced quantity, reagent IDs and reagent quantities. Imported data may be edited before saving the calculation.
- Safeguards reject unsupported alternative reagents, unresolvable ingredients and recipes larger than the six-field form rather than silently dropping material costs.
- Existing SavedVariables, market observations, watches and trading journal are preserved.
- Actual support for the profession window on customized WoW Forever client must be verified in game.

## 4.0.3 — Scanner item identification / Распознавание предметов сканера

- Scanner shows only items with confirmed localized names by default. A toggle displays unknown IDs without inventing names.
- Added a throttled client item-information request queue and a manual "Load item names" action.
- The market price database alone cannot guarantee that the server can resolve every item ID. All scan results stay available, including unknown IDs when explicitly enabled.
- New scanner visibility preference in Scanner & Alerts options; both English and Russian supported.
- SavedVariables and existing market history remain compatible.

## 4.0.2 — Scanner item details and minimap launcher

- Scanner results now include item icons and open the exact stored item variant in the market terminal.
- Item names/icons load when the game client provides asynchronous metadata; unknown item IDs remain labeled as IDs rather than guessed.
- Improved retry and refresh of selected item details after client cache updates.
- Replaced the square minimap launcher with a small circular, transparent, gold-rimmed icon.
- Maintains all existing SavedVariables and bilingual labels.

## 4.0.1 — WoW Forever UI polish and reliability

- Fixed Lua error while scanning unknown item IDs (`ItemInfo.lua:153`); unknown items now safely show ID placeholders until item data becomes available.
- Rebuilt TradeScope Pro into two rows of icon-labeled tabs and a full-width content panel styled consistently with Market Terminal.
- Added contextual help panels to every Pro tab and hover descriptions on data input fields.
- Added item name/ID/link autocomplete with icon suggestions across item fields in Pro (alerts, candles, activity, journal, crafting, indicators, heatmap, reliability, workspaces).
- Item fields preserve selected item IDs internally even while displaying a readable name.
- Fixed Market Terminal / TradeScope Pro window overlap, with Market Terminal restored after closing Pro.
- Replaced sprawling minimap icons with a compact, collapsible, two-column tools palette and preserved per-tool visibility preferences.
- Kept existing price and gold history, settings, manual transactions and watchlists unchanged.

## 4.0.0 — Advanced trading workstation

- Added market deal scanner and scan-triggered price alerts with adjustable thresholds.
- Added OHLC chart, EMA/Bollinger overlays, RSI and MACD computations.
- Added observation-based activity score and data reliability scoring.
- Added manual trading journal with realized P&L and inventory cost basis.
- Added recipe cost calculator with optional profession import.
- Added weekday/hour price heatmap and three item workspaces.
- Added a dedicated tool window and individual settings categories.
- Added expandable, draggable minimap launcher with configurable tool shortcuts.
- All calculations are based on locally observed quotes; no verified sales claims.

## 3.6.0 — 2026-11-10
- Added mouse-following crosshair and last-known observation tooltip to every market chart: combined price/supply, price, quantity and estimated supply decreases.
- Crosshair works in both item-tooltip graphs and the separate market terminal, including multi-panel layouts.
- Values are drawn from recorded scans; price and quantity are not interpolated between scans.
- Supply reduction shows its own observed time bucket, not an invented persistent sales count.
- Zoom with mouse wheel remains usable over chart plotting areas.
- English and Russian crosshair labels; SavedVariables and existing history preserved.
- Removed the CurseForge publishing walkthrough from the release archive.

## 3.5.2 — 2026-11-10
- Added an interactive vertical crosshair to the character gold history only.
- Hovering displays exact known gold balance with native coin icons, cursor time and timestamp of the last actual observation.
- Between observations, the last known recorded amount is shown (not an interpolated estimate).
- Gold chart now uses stepped lines to reflect discrete changes in currency, and extends known balances across periods with no new observation.
- Crosshair and tooltip follow the mouse and hide on leave. Zoom and previous tracking data remain compatible.
- English and Russian labels added.

## 3.5.1 — 2026-11-10
- Fixed Lua error in break-even help tooltip on WoW Forever: GameTooltip:SetText now uses a client-compatible argument signature.
- No history, settings, or watchlist reset required.

## 3.5.0
- Redesigned trading calculator: separate gold, silver and copper fields prevent ambiguous decimal-gold entry.
- Added per-item purchase quantity and saved quantity per realm/item.
- Added unit sale price, unit net revenue, batch purchase total, batch sale revenue, total profit/loss and ROI.
- Fixed negative profit incorrectly showing as missing data; added break-even explanation in a hover tooltip.
- Added English and Russian translations for the extended calculator.
- Existing price history, watchlists and saved purchase costs are preserved.
- Results assume all units sell at the last observed Auctionator price; deposit losses and actual liquidity are not included.

## 3.4.1 — 2026-11-10
- Search/autocomplete indexes items known to the Auctionator price database and item information cached by WoW; not limited to watched items.
- Search accepts partial Russian/English item names and numeric item IDs. Results have a scrollable, opaque dropdown.
- After selection, the search field remains empty; chosen item is displayed separately.
- Dropping an item automatically adds it to the watchlist and resets the drop target.
- Added native gold-coin icon by the buy-price entry in the trade calculator.
- Aligned the "Linear price trend" checkbox in chart settings.
- Reduced repetitive UI refresh events while indexing item info.
- No SavedVariables reset; compatible with 3.3.x.

## 3.3.0 — WoW Forever — 2026-11-10

- Replaced tooltip/terminal zoom multiplication with reversible discrete hours (1h to 90d); no longer stuck at a rounded 1-hour minimum.
- Item names and icons survive `/reload` through a small SavedVariables metadata cache; item selection displays human-readable names rather than internal links.
- Added UTF-8-safe truncation with `...`, local item-name autocomplete and gradual discovery of resolvable Auctionator database item names.
- New market-terminal **Trader tools** page: price/median deviations, range position, observed 24h momentum, stale data age, supply-pressure proxy, data coverage and confidence.
- New editable trade calculator for buy price, net after fee, expected P/L, ROI and break-even, with per-item saved buy costs and configurable fee.
- Added ruRU/enUS translations and a separate **Trader tools** settings category.
- Removed the unreliable NPC vendor resale overlay and merchant settings; other charts and wallet history are unchanged.
- Compatible with existing `AuctionatorTradeScopeDB` data; no reset required.

## 3.2.0 — 2026-11-10

- Improved NPC merchant cost lookup across custom merchant frames and paged inventory; added merchant tooltip hook, search diagnostics and session caching.
- Item selection retains the original hyperlink; item names and icons refresh after cache loading and can fall back to bag item textures.
- Character wallet zoom uses reversible preset steps (including 1 -> 2 hours); repositioned the controls below the graph and added a scale label.
- Compatible with existing 3.x TradeScope history and settings.

# Changelog

## 3.1.0 — WoW Forever — 2026-11-10

- Fixed NPC resale lookup by matching hovered item IDs against the merchant item list instead of relying on a specific merchant button name; calculates ordinary coin cost per unit and preserves demand warnings.
- Added a dedicated draggable character-gold window accessible by `/ats balance`, the market terminal, and the settings panel; includes 24h / 7d / 30d presets, mouse-wheel zoom, zoom buttons, time/coin axes, and persistent presentation after coin hover.
- Gold tracking remains opt-in. If it is disabled, the wallet window offers an explicit Enable button. Histories are saved per character.
- Hiding the chart legend now reallocates the unused left column to the graph; grid, both axes, tick labels, all series and date marks reflow together.
- Updated Russian/English UI strings, help, installation notes and CurseForge checklist.
- No deletion or conversion of TradeScope 3.0 saved data is required.


## 3.0.0 — WoW Forever — 2026-11-10

- Renamed addon folder and TOC to `AuctionatorTradeScope`; fresh saved variables `AuctionatorTradeScopeDB` (no migration by design).
- Redesigned market terminal with WoW dialog styling, selected item icon, bag item drop target, direct bag-hover selection, watchlist and compact chart tabs.
- Added mouse-wheel zoom for tooltip and terminal graphs, plus zoom/reset buttons in the terminal.
- Added tooltip/chart hover handoff, retaining the floating chart while the cursor is over it.
- Added configurable plot legend and five independent series colors.
- Replaced text currency abbreviations with Blizzard native money coin icons, including axis labels.
- Added optional per-character coin balance history shown over money amounts in the backpack.
- Added optional NPC purchase-to-auction resale estimate, configurable auction fee, and heuristic demand score that never treats availability decreases as confirmed sales.
- Added General, Charts, Analysis, Colors & Legend, Wallet and NPC Resale options sections; maintained ruRU and enUS translations.
- Retained price, supply, estimated-decrease and dual-axis combined charts, trend and moving-average overlays.
- License and CurseForge publishing metadata updated for Gytautas Virbickas.

Note: No version is claimed to be tested in a live WoW Forever client until real in-game validation has been performed.
