# Stable 4.5.0 release checklist

Source revision: in-game-tested `4.5.0-beta6` plus **version / release-documentation only**. This file is not part of the game package.

## Before publishing

- Verify the latest main branch and run the build-only GitHub Actions workflow (Lua 5.1 tests, package verification).
- Confirm `AuctionatorTradeScope.toc` and `Engine/Core.lua` are both `4.5.0`; WoW Forever interface remains `16001`.
- Confirm there is no pre-existing tag `v4.5.0`.
- Optionally verify CurseForge project 1796279 configuration and the `CF_API_KEY` GitHub secret.
- Only a **tag push** should trigger the existing CurseForge publish workflow. A push/merge to `main` alone must not publish.
- Tag the checked stable `main` commit as `v4.5.0` **only when ready to publish**; do not create a tag during preparation.

## Game regression already confirmed on beta6

- Journal & Portfolio item icons, including missing-icon retries and localization.
- Allocation progress bars, row pagination, inventory/sales/cost views.
- Journal mail import and unchanged financial calculations.

## Explicit limitations

- Mail import requires opt-in and opening the mailbox; it only accepts confirmed, unambiguous invoices.
- Unknown acquisition cost means unknown profit; confirmed revenue remains separately reportable.
- Bank quantities are last-seen snapshots, not live when closed; stale market observations are excluded from value totals.
- Released build preserves existing SavedVariables and adds separate, per-character stock/import state.
