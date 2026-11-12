-- Smoke-test Pro UI module load and public registration without WoW widgets.
ATS={}
assert(loadfile("UI/Pro/Shared.lua"))()
local pages={"Scanner","Alerts","Candles","Activity","Journal","Craft","Indicators","Heatmap","Quality","CraftCatalog"}
for _,name in ipairs(pages) do
  assert(loadfile("UI/Pro/Pages/"..name..".lua"))()
end
assert(loadfile("UI/Pro/Window.lua"))()
for _,name in ipairs({"scanner","alerts","candles","activity","journal","craft","indicators","heatmap","quality","craftscan"}) do
  assert(type(ATS.ProUIBuilders[name])=="function", "missing Pro page "..name)
end
assert(type(ATS.OpenProTool)=="function")
assert(type(ATS.ShowProTab)=="function")
assert(type(ATS.OpenProAlertForItem)=="function")
assert(type(ATS.ToggleProTool)=="function")
print("PASS: all Pro UI modules loaded and registered")
