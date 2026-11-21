# Stable 4.6.0 - release candidate and publication gate

Source: 4.6.0-beta2, with only TOC and Core version strings plus release docs changed. GitHub `main` is the stable source after approved PR merge.

## Must validate in game before publishing

- Enter combat with Market Overview, Pro terminal, standalone Gold History or popup graph open; all must close immediately and remain closed.
- Verify Pro.OnHide does **not** reopen the market dashboard during combat.
- Open a crafting recipe tooltip just before combat; no delayed graph preview should pop up after combat starts.
- While fighting, test /ats, /ats pro, /ats portfolio, /ats strategies, /ats wallet, /ats options, /ats test, minimap left/right and Shift-click, hover graphs and Journal/Scanner navigation; none may open TradeScope UI.
- While fighting, Blizzard's ordinary item tooltips, action bars and original Auctionator interface remain usable.
- After combat, no old windows reopen by themselves; all can be opened manually again.
- Confirm 3 Trading Strategies profiles and the old Market Scanner, Journal, Portfolio, crafting, alerts and charts still work.
- Verify SavedVariables, journal history, mail import and watchlists remain intact.

## Publishing contract

- The source branch merge **does not** publish.
- Do not push annotated `v4.6.0` until the user reports game validation and explicitly authorizes CurseForge.
- The existing GitHub Actions tag publisher should validate the final TOC and release project 1796279.
- Never add a duplicate tag or trigger separate webhook jobs.
