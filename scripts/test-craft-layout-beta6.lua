-- Beta6 static layout contract + catalog-to-calculator protection.
local function read(path)
 local f=assert(io.open(path,'rb'))
 local txt=f:read('*a');f:close();return txt
end
local craft=read('UI/Pro/Pages/Craft.lua')
local picker=read('UI/Pro/Craft/RecipePicker.lua')
local catalog=read('UI/Pro/Pages/CraftCatalog.lua')
assert(craft:find('Saved recipes - choose to calculate',1,true))
assert(craft:find('for i=1,12 do',1,true))
assert(craft:find('p.recipeBrowse=browse',1,true))
assert(craft:find('if active then browse:Hide();return end',1,true))
assert(craft:find('local navY=-215-visible*37-15',1,true))
assert(craft:find('p.recipeQuery:ClearFocus()',1,true))
assert(picker:find('self.HasFocus and not self:HasFocus()',1,true))
assert(picker:find('p:HookScript("OnShow",function() popup:Hide() end)',1,true))
assert(catalog:find('craftPage.recipePopup:Hide()',1,true))
print('PASS beta6 craft layout: inline empty-state, material-aware results, modal focus guard')
