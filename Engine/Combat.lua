-- TradeScope 4.6.0-beta2: hide every TradeScope-owned window on combat entry.
-- No automatic reopening and no interception of Blizzard's native tooltips.
local A=ATS
local function combatFlag()
  if A._combatActive then return true end
  if type(InCombatLockdown)=="function" and InCombatLockdown() then return true end
  if type(UnitAffectingCombat)=="function" and UnitAffectingCombat("player") then return true end
  return false
end
function A.InCombat() return combatFlag() end
local function hide(frame)
  if frame and type(frame.Hide)=="function" then frame:Hide() end
end
local function isAddonOwner(owner)
  local bases={A.dashboard,A.proWindow,A.balanceFrame,A.graph,A.craftPreviewGraph,
    A.minimapFlyout}
  local steps=0
  while owner and steps<24 do
    for _,base in pairs(bases) do if owner==base then return true end end
    if not owner.GetParent then break end
    owner=owner:GetParent()
    steps=steps+1
  end
  return false
end
function A.CloseForCombat()
  A._combatActive=true
  -- Pro.OnHide normally restores the dashboard. Disable that BEFORE hiding.
  if A.proWindow then A.proWindow.restoreDashboard=false end
  if A.HideCraftPreview then A.HideCraftPreview() end
  hide(A.proWindow)
  hide(A.dashboard)
  hide(A.balanceFrame)
  hide(A.graph)
  hide(A.craftPreviewGraph)
  if A.dashboard and A.dashboard.suggestions then hide(A.dashboard.suggestions) end
  hide(A.minimapFlyout)
  if A.db and A.db.pro then A.db.pro.minimapExpanded=false end
  A.bagPicking=false
  A.graphHovered=false
  A.graphLeftAt=nil
  A.testUntil=nil
  A.state=nil
  -- Addon configuration panels may be embedded in Blizzard Settings. Hide only
  -- our own categories, not the entire native Settings interface.
  local settingsGroups={A.options,A.proOptions}
  for _,group in pairs(settingsGroups) do
    if type(group)=="table" then
      for _,panel in pairs(group) do
        if type(panel)=="table" or type(panel)=="userdata" then hide(panel) end
      end
    end
  end
  if type(StaticPopup_Hide)=="function" then StaticPopup_Hide("ATS_CLEAR") end
  -- Do not close ordinary WoW item/tooltips; only TradeScope-owned helpers.
  if GameTooltip and GameTooltip.GetOwner and isAddonOwner(GameTooltip:GetOwner()) then
    hide(GameTooltip)
  end
end
local watcher=CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_REGEN_DISABLED" then A.CloseForCombat()
  elseif event=="PLAYER_REGEN_ENABLED" then A._combatActive=false end
end)
