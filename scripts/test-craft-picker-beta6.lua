-- Beta6 interactive regression: programmatic selection must not reopen popup.
ATS={}
local A=ATS
local function widget()
  local w={shown=false,scripts={},hooks={},value="",focus=false}
  function w:SetText(s)
    self.value=s
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
  end
  function w:GetText()return self.value end
  function w:HasFocus()return self.focus end
  function w:ClearFocus()self.focus=false end
  function w:SetScript(k,fn)self.scripts[k]=fn end
  function w:GetScript(k)return self.scripts[k]end
  function w:HookScript(k,fn)self.hooks[k]=fn end
  function w:Show()self.shown=true end
  function w:Hide()self.shown=false end
  function w:IsShown()return self.shown end
  function w:SetTextColor(...)end
  function w:EnableMouseWheel(...)end
  function w:SetTexture(...)end
  return w
end
local p=widget();p.recipeQuery=widget();p.status=widget();p.recipeChoices={};p.recipeSelectedIndex=1;p.recipeOffset=0
local popup=widget();popup.status=widget();local choices={}
for i=1,6 do
  choices[i]=widget();choices[i].label=widget();choices[i].icon=widget()
  choices[i].detail=widget();choices[i].highlight=widget()
end
A.ProUIShared={l=function(en,ru)return ru end,
 normalizeRussian=function(s)return string.lower(s)end,
 button=function(_,caption,x,y,width,fn)
  local b=widget();b:SetScript("OnClick",fn);return b
 end}
A.FitItemName=function(name)return name end
A.ResolveItemInfo=function() return nil,"Interface\\Icons\\Spell_Holy_Heal" end
local recipe={product=7955,name="Медный клеймор",materials={{id=1,qty=2}}}
local selected=nil
local function load()
  p.recipeChoices={{name="Медный клеймор",product=7955,recipe=recipe}}
  return p.recipeChoices
end
local function select(candidate)
  selected=candidate.recipe
  p.applyingRecipe=true
  p.recipeSelected=true
  popup:Hide()
  p.recipeQuery:ClearFocus()
  p.recipeQuery:SetText(candidate.name)
  p.recipeQuery:ClearFocus()
  popup:Hide()
  p.applyingRecipe=false
end
assert(loadfile('UI/Pro/Craft/RecipePicker.lua'))()
A.AttachCraftRecipePicker({p=p,popup=popup,choices=choices,pageCount=6,
 loadRecipeChoices=load,selectRecipe=select})
-- Exactly the programmatic catalog case: field changes without focus.
p.recipeQuery:SetText("Медный клеймор")
assert(not popup:IsShown(),"programmatic selection opened a blocking popup")
-- User actively typing should still reveal matching recipes.
p.recipeQuery.focus=true
p.recipeQuery:SetText("Мед")
assert(popup:IsShown(),"manual search should show suggestions")
assert(choices[1].candidate and choices[1].candidate.product==7955)
select(choices[1].candidate)
assert(selected==recipe and not popup:IsShown(),"selection must dismiss popup")
assert(not p.recipeQuery:HasFocus(),"selection must clear focus")
-- Tab change may not leave a lingering FULLSCREEN_DIALOG overlay.
popup:Show();p.hooks.OnHide();assert(not popup:IsShown())
popup:Show();p.hooks.OnShow();assert(not popup:IsShown())
-- Explicit Saved Recipes button remains available without focus.
p.showSavedRecipes(true)
assert(popup:IsShown(),"explicit Saved Recipes action must still work")
print('PASS beta6 picker: catalog selection, manual search, hide/show, explicit list')
