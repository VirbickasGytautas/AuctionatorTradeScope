-- Craft recipe dropdown, keyboard navigation and explicit profession scanning.
-- The popup lifecycle deliberately does not use OnEditFocusLost for dismissal.
local A=ATS
local C=assert(A.ProUIShared)
local l=C.l
local button=C.button
local normalizeRussian=C.normalizeRussian

function A.AttachCraftRecipePicker(ctx)
  local p=assert(ctx.p)
  local popup=assert(ctx.popup)
  local choices=assert(ctx.choices)
  local pageCount=assert(ctx.pageCount)
  local loadRecipeChoices=assert(ctx.loadRecipeChoices)
  local selectRecipe=assert(ctx.selectRecipe)
  local function refreshChoices()
    local query=normalizeRussian(p.recipeQuery:GetText() or "")
    local ranked={}
    for i=1,#p.recipeChoices do
      local c=p.recipeChoices[i]
      local name=normalizeRussian(c.name or "")
      local itemID=tostring(c.product or "")
      local npos=query=="" and 1 or name:find(query,1,true)
      if npos or (query~="" and itemID:find(query,1,true)) then
        local rank=(name==query or itemID==query) and 0 or
          (npos==1 and 1 or 2)
        ranked[#ranked+1]={value=c,rank=rank,original=i}
      end
    end
    table.sort(ranked,function(a,b)
      if a.rank~=b.rank then return a.rank<b.rank end
      return a.original<b.original
    end)
    local filtered={}
    for i=1,#ranked do filtered[i]=ranked[i].value end
    p.filteredRecipes=filtered
    p.recipeSelectedIndex=math.max(1,math.min(p.recipeSelectedIndex,#filtered))
    p.recipeOffset=math.max(0,math.min(p.recipeOffset,math.max(0,#filtered-pageCount)))
    if p.recipeSelectedIndex<p.recipeOffset+1 then
      p.recipeOffset=math.max(0,p.recipeSelectedIndex-1)
    elseif p.recipeSelectedIndex>p.recipeOffset+pageCount then
      p.recipeOffset=math.max(0,p.recipeSelectedIndex-pageCount)
    end
    for i=1,pageCount do
      local row=choices[i]
      local index=p.recipeOffset+i
      local candidate=filtered[index]
      if candidate then
        row.candidate=candidate
        row.label:SetText(A.FitItemName and
          A.FitItemName(candidate.name or "?",row.label,365) or candidate.name)
        if candidate.product and A.ResolveItemInfo then
          local _,texture=A.ResolveItemInfo("item:"..tostring(candidate.product),nil)
          row.icon:SetTexture(texture or candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        else
          row.icon:SetTexture(candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        row.detail:SetText("#"..tostring(candidate.product))
        row.keyboardSelected=index==p.recipeSelectedIndex
        if row.keyboardSelected then row.highlight:Show() else row.highlight:Hide() end
        -- The click handler reads row.candidate dynamically; rebuilding
        -- suggestions must not leave a callback pointing to an old entry.
        row:Show()
      else row.candidate=nil;row:Hide() end
    end
    popup.status:SetText(string.format(l(
      "Found: %d  |  Wheel / Up-Down / Enter / Esc",
      "Найдено: %d  |  Колесо / Вверх-Вниз / Enter / Esc"),#filtered))
    popup:Show()
  end
  p.refreshRecipeChoices=refreshChoices
  popup:EnableMouseWheel(true)
  popup:SetScript("OnMouseWheel",function(_,delta)
    if not p.filteredRecipes or #p.filteredRecipes==0 then return end
    p.recipeSelectedIndex=math.max(1,math.min(#p.filteredRecipes,
      p.recipeSelectedIndex-(delta>0 and 1 or -1)))
    refreshChoices()
  end)
  local function showSaved(clearSearch)
    p.recipeSelectedIndex=1;p.recipeOffset=0
    if clearSearch then
      p.applyingRecipe=true
      p.recipeQuery:SetText("")
      p.applyingRecipe=false
    end
    local all=loadRecipeChoices()
    refreshChoices()
    if #all==0 then
      p.status:SetText(l("No saved recipes yet. Open a profession and scan it.",
        "Сохранённых рецептов пока нет. Откройте профессию и выполните сканирование."))
    end
  end
  p.showSavedRecipes=showSaved
  button(p,l("Scan recipes","Сканировать рецепты"),340,-82,180,function()
    popup:Hide()
    if A.proRecipeImportActive then
      p.status:SetText(l("Recipe scan is already running.","Сканирование уже выполняется."))
      return
    end
    if not A.ImportProfessionRecipeCatalog then
      p.status:SetText(l("Recipe scanner unavailable.","Сканер рецептов недоступен."))
      return
    end
    local ok,count=A.ImportProfessionRecipeCatalog(function(done,total,stored)
      if p:IsShown() then
        p.status:SetText(string.format(l("Scanning %d/%d, saved: %d",
          "Сканирование %d/%d, сохранено: %d"),done,total,stored))
      end
    end,function(stored,skipped,total)
      if not p:IsShown() then return end
      p.status:SetText(string.format(l(
        "Scan complete: %d saved, %d skipped (of %d).",
        "Сканирование завершено: сохранено %d, пропущено %d (из %d)."),stored,skipped,total))
      -- Refresh saved list but do not obscure the calculator by reopening it.
      loadRecipeChoices()
      if popup:IsShown() then refreshChoices() end
    end)
    if ok then p.status:SetText(string.format(l("Scanning %d profession recipes...",
      "Сканирование %d рецептов профессии..."),tonumber(count) or 0))
    else p.status:SetText(l("Open a profession window first, then scan its recipes.",
      "Сначала откройте окно профессии, затем нажмите «Сканировать рецепты».")) end
  end)
  button(p,l("Saved recipes","Сохранённые рецепты"),536,-82,172,function()
    showSaved(true)
  end)
  p.recipeQuery:SetScript("OnTextChanged",function(self)
    if p.applyingRecipe then return end
    p.recipeSelectedIndex=1;p.recipeOffset=0
    if self:GetText()=="" then popup:Hide();return end
    loadRecipeChoices()
    refreshChoices()
  end)
  p.recipeQuery:SetScript("OnEscapePressed",function(self)
    popup:Hide();self:ClearFocus()
  end)
  p.recipeQuery:SetScript("OnEnterPressed",function(self)
    local candidate=p.filteredRecipes and p.filteredRecipes[p.recipeSelectedIndex]
    if popup:IsShown() and candidate then selectRecipe(candidate)
    else
      p.status:SetText(l("Recipe not saved. Open a profession and scan available recipes.",
        "Рецепт не найден. Откройте профессию и просканируйте доступные рецепты."))
    end
    popup:Hide();self:ClearFocus()
  end)
  if p.recipeQuery.SetScript then
    pcall(p.recipeQuery.SetScript,p.recipeQuery,"OnArrowPressed",function(_,key)
      if not popup:IsShown() or not p.filteredRecipes or #p.filteredRecipes==0 then return end
      if key=="UP" then p.recipeSelectedIndex=math.max(1,p.recipeSelectedIndex-1)
      elseif key=="DOWN" then p.recipeSelectedIndex=math.min(#p.filteredRecipes,p.recipeSelectedIndex+1)
      else return end
      refreshChoices()
    end)
  end
  -- Deliberately do not dismiss the popup on OnEditFocusLost.  Some
  -- WoW Forever clients report the old mouse focus here, even when the
  -- pointer is over a suggestion, which used to cancel the row click.
  -- The list closes after selection, Esc, page background click, or tab hide.
  p:HookScript("OnHide",function()
    popup:Hide()
    if A.HideCraftPreview then A.HideCraftPreview() end
  end)
end
