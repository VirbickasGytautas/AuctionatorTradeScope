## 4.4.0-beta2 - Internal test build
- Split graph tooltip placement and crafting preview into separate Lua modules.
- Extracted manual journal persistence and added read-only per-item analytics.
- Added a small journal summary and automated regression checks.
- No data migration, automatic trade capture, or CurseForge publication.

## 4.4.0-beta1 - Code organization preview
- Modularized source files and decomposed the Pro workstation interface into separate pages.
- Retained prior stable 4.3.0 market and crafting behavior and saved data.
- Test-only local beta; not published to CurseForge.

## 4.3.0 - Stable Release
- Crafting Intelligence 2.0: batch crafting quantities, inventory-aware reagent requirements, and grouped material shopping lists.
- Estimated batch costs, auction proceeds, profit and ROI, respecting unknown market prices and multi-output recipes.
- Fixed supply-decline cursor and last-sample hover on the right chart boundary.
- Improved chart bar clipping and kept crafting instructions in the right sidebar.
- Tested in-game after 4.3.0-beta5; existing history, recipes, settings and SavedVariables are preserved.

## 4.3.0-beta5
- Fixed the supply-decline graph cursor at the final time interval.
- Prevented decline bars from overlapping the right-hand chart axis.
- Kept the crafting help in its sidebar; no history or settings were reset.

## 4.3.0-beta4 - Craft recipe help in right panel
- Removed the misplaced helper line below the recipe search field.
- Recipe usage instructions now appear under HOW IT WORKS.
- Dynamic scan and recipe status text is also shown there.
- No changes to crafting calculations or saved data.

## 4.3.0-beta3 - Crafting Intelligence 2.0 (UI polish)
- Craft calculator: aligned the helper text below the recipe search field.
- Craft calculator: reduced the brightness of the helper text for a cleaner look.

## 4.3.0-beta1 - Crafting Intelligence 2.0 (Batch Preview)
- Added batch crafting quantities (1-999) with live recalculation.
- New buy quantities and grouped shopping list for missing ingredients.
- Full-batch market cost, additional purchase cost, output revenue, profit and ROI.
- Respects multiple outputs per recipe, shared reagent stock and missing quotes.
- Existing saved data remains compatible; game-client verification pending.
