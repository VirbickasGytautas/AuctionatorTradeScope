# TradeScope 5.0.0-rc1 — pre-release validation candidate

## Scope
- The game-facing Lua modules are **identical to the user-tested 5.0.0-beta7**, except `ATS.version` in `Engine/Core.lua`.
- TOC version is updated to `5.0.0-rc1`. No SavedVariables migration or schema change.
- Candidate is intended for a final smoke test, not automatic publication.
- GitHub Build Only workflow now runs **all** `scripts/test-*.lua` tests and checks Lua 5.1 syntax using `luac5.1` before building. Previously it selected 20 tests out of 27.
- The tag publisher currently only accepts stable and beta tags. **Do not create tags or publish any release to CurseForge.**

## Evidence and limitations
- User confirmed all 7 gameplay checks of 5.0.0-beta7 passed.
- Source tree was rechecked with TeX Lua locally; real Lua 5.1 CI validation requires pushing the candidate to a nonpublishing branch and checking the Build Only workflow.
- An RC needs smoke verification in the game for the correct version, unified window, chart, craft catalog transition, saved data, combat restriction and absence of Lua errors.

## Final publication gate (not executed)
1. Run and verify GitHub Build Only for 5.0.0 on the candidate branch with Lua 5.1.
2. Confirm in-game RC1 smoke tests and no regressions.
3. Only then promote to `5.0.0` and separately request permission for publication.
4. Tag publication is **never** implicit from finishing the build.
