# TradeScope 5.0.0-beta4 — unified page geometry

- One window: 1188×780. Header has TradeScope above the active page name; version and ? remain at the right.
- All 14 pages now start at x=219,y=-74 in the shared 946×660 content canvas (previously y=-104).
- Market Terminal reanchors the original search, bag, watchlist, selection, chart tabs and plot directly into the content area at 1:1 scale. No old 70px title gap.
- Gold History uses a native 946×658 content frame with a 828×412 plot. Axes, hover capture, crosshair, zoom and period buttons are reflowed together. Removed the legacy opaque modal backing.
- OHLC plot starts higher, preserving room for input controls. Market data, trading maths, inventory and SavedVariables remain untouched.
- The existing combat lockdown and contextual '?' help remain.
- Beta build for in-game layout validation only. No tag or CurseForge publishing.
