-- TradeScope UI palette: restrained Classic WoW gold trim with clear action roles.
-- This is presentation-only. It must not alter button handlers or saved data.
local A=ATS
local roles={
  action={.17,.125,.075, .68,.51,.26, 1,.88,.64},
  primary={.13,.24,.20, .41,.77,.59, .93,1,.86},
  danger={.31,.085,.080, .85,.39,.32, 1,.89,.85},
  warning={.29,.18,.065, .91,.67,.32, 1,.92,.74},
  secondary={.09,.135,.165, .38,.50,.55, .82,.89,.94},
  tab={.115,.135,.155, .45,.38,.26, .83,.85,.86},
  activeTab={.26,.19,.075, .97,.76,.32, 1,.88,.53},
}
local function labelRole(caption)
  if type(caption)~="string" then return "action" end
  -- Russian case handling uses explicit UTF-8 text fragments, avoiding a
  -- locale-dependent string.lower() conversion of Cyrillic characters.
  local text=string.lower(caption)
  if text=="<" or text==">" or caption:find("<",1,true) or caption:find(">",1,true)
    or text:find("previous",1,true) or text:find("next",1,true)
    or caption:find("Назад",1,true) or caption:find("Вперёд",1,true)
    or caption:find("Вперед",1,true) then return "secondary" end
  if text:find("remove",1,true) or text:find("delete",1,true)
    or text:find("clear",1,true) or caption:find("Удалить",1,true)
    or caption:find("Очистить",1,true) or caption:find("Стереть",1,true) then
    return "danger"
  end
  if text:find("undo",1,true) or text:find("reset",1,true)
    or caption:find("Отменить",1,true) or caption:find("Сброс",1,true) then
    return "warning"
  end
  if text=="save" or text:find("save ",1,true)==1 or text:find("record buy",1,true)
    or text:find("record sell",1,true) or caption:find("Сохранить",1,true)==1
    or caption:find("Записать",1,true) or text:find("confirm",1,true) then
    return "primary"
  end
  return "action"
end
A.ActionButtonRole=labelRole
local function colorTexture(t,r,g,b,a)
  if not t then return end
  if t.SetVertexColor then t:SetVertexColor(r,g,b,a or 1) end
end
function A.StyleButton(button,role)
  if not button then return button end
  role=roles[role] and role or labelRole(button.GetText and button:GetText())
  local c=roles[role] or roles.action
  if not button._atsStyled then
    button._atsStyled=true
    -- UIPanelButtonTemplate in WoW Forever uses independent red Left/Middle/Right
    -- textures, not just a normal texture. Hide those explicitly so each role
    -- has a predictable appearance on both legacy and newer clients.
    for _,piece in ipairs({"Left","Middle","Right"}) do
      local part=button[piece]
      if (type(part)=="table" or type(part)=="userdata") and part.Hide then part:Hide() end
    end
    if button.SetNormalTexture then button:SetNormalTexture("Interface\\Buttons\\WHITE8X8") end
    if button.SetPushedTexture then button:SetPushedTexture("Interface\\Buttons\\WHITE8X8") end
    if button.SetHighlightTexture then button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8") end
    if button.SetDisabledTexture then button:SetDisabledTexture("Interface\\Buttons\\WHITE8X8") end
    -- Inset colored fills so the thin ornamental WoW border stays visible.
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture", "GetHighlightTexture","GetDisabledTexture"}) do
      local part=button[getter] and button[getter](button)
      if part and part.ClearAllPoints and part.SetPoint then
        part:ClearAllPoints()
        part:SetPoint("TOPLEFT",button,"TOPLEFT",3,-3)
        part:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-3,3)
      end
    end
    if button.SetBackdrop then
      button:SetBackdrop({
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
        insets={left=2,right=2,top=2,bottom=2},
      })
    elseif button.CreateTexture then
      -- Optional support for clients without frame backdrops.
      button._atsEdges={}
      local layouts={
        {"TOPLEFT","TOPRIGHT",nil,1},
        {"BOTTOMLEFT","BOTTOMRIGHT",nil,1},
        {"TOPLEFT","BOTTOMLEFT",1,nil},
        {"TOPRIGHT","BOTTOMRIGHT",1,nil},
      }
      for i=1,#layouts do
        local edge=button:CreateTexture(nil,"OVERLAY")
        edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        edge:SetPoint(layouts[i][1],button,layouts[i][1],0,0)
        edge:SetPoint(layouts[i][2],button,layouts[i][2],0,0)
        if layouts[i][3] then edge:SetWidth(layouts[i][3]) end
        if layouts[i][4] then edge:SetHeight(layouts[i][4]) end
        button._atsEdges[i]=edge
      end
    end
  end
  colorTexture(button.GetNormalTexture and button:GetNormalTexture(),c[1],c[2],c[3],1)
  colorTexture(button.GetPushedTexture and button:GetPushedTexture(),c[1]*.65,c[2]*.65,c[3]*.65,1)
  colorTexture(button.GetHighlightTexture and button:GetHighlightTexture(),.36,.34,.22,.21)
  colorTexture(button.GetDisabledTexture and button:GetDisabledTexture(),.07,.08,.09,.80)
  if button.SetBackdropBorderColor then
    button:SetBackdropBorderColor(c[4],c[5],c[6],.94)
  elseif button._atsEdges then
    for i=1,#button._atsEdges do
      colorTexture(button._atsEdges[i],c[4],c[5],c[6],.94)
    end
  end
  if button._atsActionIcon and role~="primary" and role~="danger" then
    button._atsActionIcon:Hide()
  end
  local text=button.GetFontString and button:GetFontString()
  if text and text.SetTextColor then text:SetTextColor(c[7],c[8],c[9]) end
  button._atsRole=role
  return button
end
-- Add a compact native texture only where there is room for the localized text.
-- The icon is decorative: the underlying button remains the whole hit target.
function A.ButtonActionIcon(button,role)
  if not button or not button.CreateTexture then return end
  if role~="primary" and role~="danger" then return end
  local font=button.GetFontString and button:GetFontString()
  local width=button.GetWidth and button:GetWidth() or 0
  if width<130 then return end
  if font and font.GetStringWidth then
    local measured=font:GetStringWidth()
    if type(measured)=="number" and measured>width-38 then return end
  end
  if not button._atsActionIcon then
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetSize(13,13)
    icon:SetPoint("LEFT",button,"LEFT",9,0)
    button._atsActionIcon=icon
  end
  local icon=button._atsActionIcon
  if role=="primary" then
    icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    icon:SetVertexColor(.74,1,.75)
  else
    icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    icon:SetVertexColor(1,.75,.73)
  end
  icon:Show()
end
