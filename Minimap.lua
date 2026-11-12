-- TradeScope 4.0.1: one minimap launcher and a compact, themed tool palette.
-- Avoids spraying twelve icons over other minimap addons.
local A=ATS
local TOOLS={
  {"terminal","Interface\\AddOns\\AuctionatorTradeScope\\Media\\Icon"},
  {"scanner","Interface\\Icons\\INV_Misc_Spyglass_03"},
  {"alerts","Interface\\Icons\\INV_Misc_Bell_01"},
  {"candles","Interface\\Icons\\INV_Misc_Coin_02"},
  {"activity","Interface\\Icons\\Ability_Hunter_MasterMarksman"},
  {"journal","Interface\\Icons\\INV_Misc_Book_09"},
  {"craft","Interface\\Icons\\INV_Misc_Gear_02"},
  {"indicators","Interface\\Icons\\Spell_Holy_MindVision"},
  {"heatmap","Interface\\Icons\\INV_Misc_Map_01"},
  {"quality","Interface\\Icons\\INV_Misc_EngGizmos_02"},
  {"craftscan","Interface\\Icons\\INV_Misc_Coin_17"},
  {"balance","Interface\\Icons\\INV_Misc_Coin_01"},
}
local function label(key)
  local ru={scanner="Сканер рынка",alerts="Ценовые сигналы",candles="Свечи",activity="Активность",
    journal="Журнал сделок",craft="Калькулятор",indicators="Индикаторы",heatmap="Тепловая карта",
    quality="Качество данных",craftscan="Выгодный крафт",balance="История золота",terminal="Терминал"}
  local en={scanner="Market scanner",alerts="Price alerts",candles="Candles",activity="Market activity",
    journal="Trade journal",craft="Crafting",indicators="Indicators",heatmap="Price heatmap",
    quality="Data quality",craftscan="Profitable crafts",balance="Gold history",terminal="Market terminal"}
  return ((A.locale=="ruRU" and ru) or en)[key] or key
end
local function enabled(key)
  local p=A.db and A.db.pro
  return p and p.minimapTools and p.minimapTools[key]~=false and p[key.."Enabled"]~=false
end
local function flat(parent,layer,r,g,b,alpha)
  local t=parent:CreateTexture(nil,layer)
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,alpha or 1)
  return t
end
local function mainButton()
  local b=CreateFrame("Button","ATSTradeScopeMinimap",Minimap)
  b:SetSize(32,32);b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel((Minimap:GetFrameLevel() or 0)+5)
  b:EnableMouse(true);b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  -- A custom 32-bit TGA has transparent corners and a circular gold rim.
  -- Avoid layering the large square tracking-border art over the map.
  local icon=b:CreateTexture(nil,"ARTWORK")
  icon:SetTexture("Interface\\AddOns\\AuctionatorTradeScope\\Media\\MinimapIcon")
  -- The bitmap is already centered within its transparent circular border.
  icon:SetSize(32,32)
  icon:SetPoint("CENTER",b,"CENTER",0,0)
  local glow=b:CreateTexture(nil,"OVERLAY")
  glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  glow:SetAllPoints(b)
  glow:SetBlendMode("ADD")
  glow:Hide()
  b:SetScript("OnEnter",function(self) glow:Show() end)
  b:SetScript("OnLeave",function(self) glow:Hide() end)
  b.iconGlow=glow
  return b
end
local function openTool(id)
  if id=="balance" then A.ToggleBalanceWindow()
  elseif id=="terminal" then A.ToggleDashboard()
  elseif A.OpenProTool then A.OpenProTool(id) end
end
function A.UpdateMinimapButtons()
  if not A.minimapMain then return end
  local p=A.db.pro
  if not p.minimapEnabled then
    A.minimapMain:Hide()
    if A.minimapFlyout then A.minimapFlyout:Hide() end
    return
  end
  A.minimapMain:Show()
  local rad=(p.minimapAngle or 190)*math.pi/180
  local radius=tonumber(p.minimapRadius) or 84
  -- Auto-position follows the actual minimap diameter after UI scale changes.
  -- Legacy releases saved a radius smaller than the center line of the rim.
  -- Players who manually drag the button keep their own custom distance.
  if Minimap.GetWidth then
    local w=Minimap:GetWidth()
    if type(w)=="number" and w>80 then
      local target=(w/2)+12
      if p.minimapAutoPosition~=false then
        radius=target
      else
        radius=math.max(w/2-4,math.min(radius,w/2+27))
      end
    end
  end
  A.minimapMain:ClearAllPoints()
  A.minimapMain:SetPoint("CENTER",Minimap,"CENTER",math.cos(rad)*radius,math.sin(rad)*radius)
  local panel=A.minimapFlyout
  if not panel then return end
  if not p.minimapExpanded then panel:Hide();return end
  local shown={}
  for i=1,#TOOLS do
    local key=TOOLS[i][1]
    if enabled(key) then shown[#shown+1]=key end
  end
  if #shown==0 then panel:Hide();return end
  local rows=math.ceil(#shown/2)
  panel:SetHeight(43+rows*40)
  panel:ClearAllPoints()
  local centerX=Minimap.GetCenter and Minimap:GetCenter() or nil
  if centerX and centerX<UIParent:GetWidth()/2 then
    panel:SetPoint("TOPLEFT",Minimap,"TOPRIGHT",9,12)
  else
    panel:SetPoint("TOPRIGHT",Minimap,"TOPLEFT",-9,12)
  end
  local placed={}
  for i=1,#shown do
    local key=shown[i]
    local b=A.minimapTools[key]
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",panel,"TOPLEFT",10+((i-1)%2)*132,-37-math.floor((i-1)/2)*40)
    b:Show();placed[key]=true
  end
  for key,b in pairs(A.minimapTools) do if not placed[key] then b:Hide() end end
  panel:Show()
end
function A.ResetMinimapPosition()
  A.Init()
  A.db.pro.minimapAngle=220
  A.db.pro.minimapRadius=84
  A.db.pro.minimapAutoPosition=true
  if A.UpdateMinimapButtons then A.UpdateMinimapButtons() end
end

function A.RegisterMinimap()
  A.Init()
  if A.minimapMain or not Minimap then return end
  local main=mainButton();A.minimapMain=main
  local panel=CreateFrame("Frame","ATSTradeScopeQuickTools",UIParent)
  panel:SetSize(282,280);panel:SetFrameStrata("DIALOG");panel:SetFrameLevel(220)
  panel:EnableMouse(true)
  if panel.SetBackdrop then
    panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=15,
      tile=true,tileSize=16,insets={left=5,right=5,top=5,bottom=5}})
    panel:SetBackdropColor(.035,.048,.065,1)
  end
  local bg=flat(panel,"BACKGROUND",.035,.048,.065,.97)
  bg:SetAllPoints(panel)
  local header=flat(panel,"BORDER",.17,.14,.085,.99)
  header:SetPoint("TOPLEFT",panel,"TOPLEFT",5,-5);header:SetSize(271,27)
  local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
  title:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-12)
  title:SetText("TradeScope v"..tostring(A.version or "?")..(A.locale=="ruRU" and "  |  Инструменты" or "  |  Tools"))
  local x=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
  x:SetPoint("TOPRIGHT",panel,"TOPRIGHT",3,3)
  x:SetScript("OnClick",function()
    A.db.pro.minimapExpanded=false
    A.UpdateMinimapButtons()
  end)
  panel:Hide();A.minimapFlyout=panel
  A.minimapTools={}
  for i=1,#TOOLS do
    local key,path=TOOLS[i][1],TOOLS[i][2]
    local b=CreateFrame("Button","ATSTradeScopeMini"..key,panel)
    b:SetSize(126,35);b:EnableMouse(true)
    local background=flat(b,"BACKGROUND",.085,.105,.125,1)
    background:SetAllPoints(b)
    local border=flat(b,"BORDER",.44,.34,.13,.7)
    border:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0);border:SetSize(126,1)
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetTexture(path);icon:SetSize(25,25)
    icon:SetPoint("LEFT",b,"LEFT",5,0);icon:SetTexCoord(.08,.92,.08,.92)
    local text=b:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    text:SetPoint("LEFT",b,"LEFT",34,0);text:SetWidth(87)
    text:SetJustifyH("LEFT");text:SetText(label(key))
    b:SetScript("OnClick",function()
      A.db.pro.minimapExpanded=false;A.UpdateMinimapButtons()
      openTool(key)
    end)
    b:SetScript("OnEnter",function(self)
      background:SetVertexColor(.19,.18,.11,1)
      if GameTooltip then
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(label(key))
        GameTooltip:AddLine(A.locale=="ruRU" and "Нажмите для открытия инструмента" or
          "Click to open this tool",1,1,1)
        GameTooltip:Show()
      end
    end)
    b:SetScript("OnLeave",function()
      background:SetVertexColor(.085,.105,.125,1)
      if GameTooltip then GameTooltip:Hide() end
    end)
    A.minimapTools[key]=b
  end
  main:SetScript("OnClick",function(_,button)
    if button=="RightButton" then A.OpenOptions()
    elseif IsShiftKeyDown and IsShiftKeyDown() then A.ToggleDashboard()
    else
      A.db.pro.minimapExpanded=not A.db.pro.minimapExpanded
      A.UpdateMinimapButtons()
    end
  end)
  main:RegisterForDrag("LeftButton")
  main:SetScript("OnDragStart",function(self)self.dragging=true end)
  main:SetScript("OnDragStop",function(self)self.dragging=false end)
  main:SetScript("OnUpdate",function(self)
    if not self.dragging or not GetCursorPosition or not Minimap.GetCenter then return end
    local x,y=GetCursorPosition()
    local scale=Minimap:GetEffectiveScale()
    local centerX,centerY=Minimap:GetCenter()
    if not scale or not centerX or not centerY then return end
    local dx=x/scale-centerX;local dy=y/scale-centerY
    if dx==0 and dy==0 then return end
    local angle
    if math.atan2 then angle=math.atan2(dy,dx)
    else angle=math.atan(dy/dx);if dx<0 then angle=angle+math.pi end end
    A.db.pro.minimapAngle=angle*180/math.pi
    -- Dragging can now fine-tune the distance from the edge, not just angle.
    -- This is useful with custom minimap borders and nonstandard UI scales.
    local distance=math.sqrt(dx*dx+dy*dy)
    local width=Minimap.GetWidth and Minimap:GetWidth() or nil
    if type(width)=="number" and width>80 then
      distance=math.max(width/2-5,math.min(distance,width/2+22))
    end
    A.db.pro.minimapRadius=distance
    A.db.pro.minimapAutoPosition=false
    A.UpdateMinimapButtons()
  end)
  main:SetScript("OnEnter",function(self)
    if self.iconGlow then self.iconGlow:Show() end
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_LEFT")
    GameTooltip:SetText("Auctionator TradeScope")
    GameTooltip:AddLine((A.locale=="ruRU" and "Версия: " or "Version: ")..tostring(A.version or "?"), 1, .82, .36)
    GameTooltip:AddLine(A.locale=="ruRU" and
      "ЛКМ: панель инструментов | Shift+ЛКМ: терминал" or
      "Left: tool palette | Shift+Left: terminal",1,1,1,true)
    GameTooltip:AddLine(A.locale=="ruRU" and
      "ПКМ: настройки | Перетаскивание: переместить" or
      "Right: settings | Drag: move",.85,.85,.85,true)
    GameTooltip:Show()
  end)
  main:SetScript("OnLeave",function(self)
    if self.iconGlow then self.iconGlow:Hide() end
    if GameTooltip then GameTooltip:Hide() end
  end)
  A.UpdateMinimapButtons()
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function()
  local ok,err=pcall(A.RegisterMinimap)
  if not ok then A.lastError=tostring(err);A.Say(err) end
end)
