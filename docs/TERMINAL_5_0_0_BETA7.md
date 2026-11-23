# TradeScope 5.0.0-beta7 — Chart overlap hotfix

## User-visible fix

The candlestick chart had a fixed top coordinate at `-152`, overlapping the 42-unit-high selected-item identity strip whose top is `-117` (bottom `-159`). Chart geometry is now anchored to the actual **BOTTOMLEFT** of that strip with **24 UI units** of clearance. The chart is 390 units high and summary/legend fit below it within the page's 660-unit canvas.

## Regression scope

- Select an item with sparse quotes; candles, grid and EMA remain inside the plot and never cover the selected item icon or text.
- Change period, interval and item; verify bar labels, chart height and all navigation controls remain visible.
- Switch tabs back and forth; verify identity and chart remain separate.
- Check `/ats` in combat; all addon windows still close.

No computation changes, no SavedVariables migration, no CurseForge tag or publication. WoW Forever in-game verification required.
