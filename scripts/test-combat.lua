-- Combat lockdown regression: all TradeScope-owned windows close immediately;
-- new windows and popup graphs cannot be opened until leaving combat.
ATS={}
local A=ATS
local events={}
local combat=false
local lockdown=false
function UnitAffectingCombat(unit)assert(unit=='player');return combat end
function InCombatLockdown()return lockdown end
function CreateFrame()
 local f={}
 function f:RegisterEvent(name)events[name]=self end
 function f:SetScript(kind,callback)self[kind]=callback end
 return f
end
local function frame()
 local f={shown=true,hides=0}
 function f:Hide()self.shown=false;self.hides=self.hides+1
   if self.OnHide then self:OnHide() end end
 function f:Show()self.shown=true end
 function f:IsShown()return self.shown end
 function f:GetParent()return self.parent end
 return f
end
A.dashboard=frame()
A.dashboard.suggestions=frame()
A.proWindow=frame()
A.proWindow.restoreDashboard=true
A.proWindow.OnHide=function(self)
 if self.restoreDashboard then A.dashboard:Show() end
end
A.balanceFrame=frame()
A.graph=frame()
A.craftPreviewGraph=frame()
A.minimapFlyout=frame()
A.options={main=frame(),charts=frame()}
A.proOptions={finance=frame()}
A.db={pro={minimapExpanded=true}}
A.bagPicking=true
A.graphHovered=true
A.state={key='db:1'}
A.testUntil=15
A.HideCraftPreview=function()
 A.craftPreviewGraph:Hide()
 A.previewCancelled=true
end
local owner=frame();owner.parent=A.proWindow
local nativeOwner=frame()
GameTooltip=frame()
function GameTooltip:GetOwner()return self.owner end
GameTooltip.owner=owner
local popupHidden
function StaticPopup_Hide(id)popupHidden=id end
assert(loadfile('Engine/Combat.lua'))()
assert(events.PLAYER_REGEN_DISABLED and events.PLAYER_REGEN_ENABLED)
assert(A.InCombat()==false)
combat=true
assert(A.InCombat()==true)
combat=false
lockdown=true
assert(A.InCombat()==true)
lockdown=false
assert(A.InCombat()==false)
events.PLAYER_REGEN_DISABLED.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(A.InCombat()==true and A._combatActive)
for _,f in ipairs({A.dashboard,A.proWindow,A.balanceFrame,A.graph,A.craftPreviewGraph,
 A.minimapFlyout,A.options.main,A.options.charts,A.proOptions.finance,
 A.dashboard.suggestions}) do
 assert(not f.shown,'visible addon window during combat')
end
assert(not A.proWindow.restoreDashboard and A.dashboard.hides==1)
assert(not A.bagPicking and not A.graphHovered and A.state==nil and A.testUntil==nil)
assert(A.db.pro.minimapExpanded==false and popupHidden=='ATS_CLEAR')
assert(A.previewCancelled and GameTooltip.shown==false)
A.CloseForCombat();assert(not A.dashboard.shown)
GameTooltip.owner=nativeOwner;GameTooltip:Show()
A.CloseForCombat();assert(GameTooltip.shown)
events.PLAYER_REGEN_ENABLED.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(not A.InCombat() and not A.dashboard.shown and not A.proWindow.shown)
combat=true;assert(A.InCombat())
combat=false
local checks={
 ['UI/Dashboard.lua']={'function A.SelectItem(raw)','local function show()',
  'function A.ToggleDashboard()','function A.OpenDashboardItem(raw)',
  'function A.OpenDashboardScanKey(key)'},
 ['UI/Pro/Window.lua']={'function A.ShowProTab(id)','function A.OpenProTool(id)',
  'function A.OpenProAlertForItem(key)','function A.ToggleProTool(id)'},
 ['Finance/Balance.lua']={'function A.OpenBalanceWindow()','function A.ToggleBalanceWindow()',
  'function A.ShowBalance()'},
 ['UI/Charts/Preview.lua']={'function A.ShowCraftPreview(source,id)',
  'function A.ScheduleCraftPreview(source,id)','function A.Draw(tooltip,key,isTest,legacy)'},
 ['UI/Charts/Graph.lua']={'function A.RenderGraph(frame,key,legacy,singleKind)'},
 ['UI/Options.lua']={'function A.OpenOptions()','function A.ShowClearConfirmation()'},
 ['UI/Minimap.lua']={'local function openTool(id)','function A.UpdateMinimapButtons()'},
}
for path,functions in pairs(checks) do
 local file=assert(io.open(path,'r'))
 local src=file:read('*a');file:close()
 for _,fn in ipairs(functions) do
  local start=assert(src:find(fn,1,true),'missing entrypoint '..fn)
  local block=src:sub(start,start+#fn+145)
  assert(block:find('A.InCombat',1,true),'missing combat guard '..path..':'..fn)
 end
end
print('PASS combat: event closes all windows, no restoration, combat status fallbacks and opening guards')
