-- WoW-free smoke test for the 5.0.0-beta4 single-window navigation.
ATS={version="5.0.0",locale="ruRU",db={pro={}}}
local A=ATS
local function widget(parent)
  local f={visible=true,scripts={},parent=parent}
  function f:SetSize(w,h) self.width=w;self.height=h end
  function f:SetAllPoints(...)self.allPoints={...}end
  function f:HookScript(k,fn)self.scripts[k]=fn end
  function f:SetPoint(...) self.point={...} end
  function f:SetWidth(w)self.width=w end
  function f:SetHeight(h)self.height=h end
  function f:SetTexture(v) self.texture=v end
  function f:SetText(v) self.text=v end
  function f:GetText() return self.text end
  function f:SetTextColor(...)self.textColor={...}end
  function f:SetVertexColor(...)self.vertexColor={...}end
  function f:SetJustifyH(v) self.align=v end
  function f:SetScript(k,fn)self.scripts[k]=fn end
  function f:EnableMouse()end
  function f:RegisterForDrag()end
  function f:SetFrameLevel()end
  function f:GetFrameLevel()return 250 end
  function f:SetFrameStrata()end
  function f:SetMovable()end
  function f:SetClampedToScreen()end
  function f:SetBackdrop()end
  function f:SetScale(s)self.scale=s end
  function f:CreateTexture()return widget(self)end
  function f:CreateFontString()return widget(self)end
  function f:Hide()
    self.visible=false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
  end
  function f:Show()self.visible=true end
  function f:IsShown()return self.visible end
  function f:GetParent()return self.parent end
  function f:SetEnabled()end
  function f:HasFocus()return false end
  return f
end
UIParent=widget();function UIParent:GetWidth()return 1365 end
function UIParent:GetHeight()return 997 end
function CreateFrame(_,_,parent) return widget(parent) end
function A.Init()end
function A.InCombat()return false end
function A.TrackBackgroundTexture()end
function A.StyleButton()end
function A.HideCraftPreview()end
assert(loadfile('UI/Pro/Shared.lua'))()
local C=A.ProUIShared
assert(C.WIDTH==1188 and C.HEIGHT==780,'expected expanded terminal frame')
assert(C.tr('strategies')=='Стратегии' and C.tr('portfolio')=='Портфель',
  'sidebar translations missing')
for _,key in ipairs({'scanner','strategies','portfolio','activity'}) do
 A.ProUIBuilders[key]=function(root)
  local p=widget(root.content);p.update=function()end
  p:Hide();return p
 end
end
assert(loadfile('UI/Pro/Window.lua'))()
A.OpenProTool('scanner')
local w=A.proWindow
assert(w and w.width==1188 and w.height==780 and w.visible,'window did not open')
assert(w.content.point[4]==219 and w.content.point[5]==-74,'content not aligned with sidebar')
assert(#w.navGroups==4,'should group navigation into four sections')
local total=0
local unique={}
for _,group in ipairs(w.navGroups) do
 for _,key in ipairs(group.items) do
  assert(not unique[key] and w.nav[key],'missing or duplicate nav: '..key)
  unique[key]=true;total=total+1
 end
end
assert(total==13,'combined activity and quality should leave 13 tabs')
assert(not w.nav.quality,'quality must not remain a separate tab')
assert(w.navGroups[1].items[1]=='terminal','market terminal must be the first entry')
assert(w.navGroups[3].items[4]=='balance','gold history belongs in trading')
assert(w.nav.activity and C.tr("activity")=="Активность и качество данных")
assert(w.nav.scanner.sideAccent.visible,'active scanner accent missing')
assert(w.contextTitle.point[4]==63 and w.contextTitle.point[5]==-42,
  'active page subtitle must be under TradeScope title')
assert(w.pages.scanner and not w.pages.scanner.helpPanel,'scanner help must be contextual')
w.nav.strategies.scripts.OnClick()
assert(w.active=='strategies' and w.contextTitle.text=='Стратегии')
assert(w.nav.strategies.sideAccent.visible and not w.nav.scanner.sideAccent.visible)
assert(not w.pages.strategies.helpPanel,'strategies help must be contextual')
w.nav.portfolio.scripts.OnClick()
assert(w.active=='portfolio' and w.contextTitle.text=='Портфель')
-- Old panels are still supported by the same page registration without clearing data.
assert(w.pages.scanner and w.pages.strategies)
-- Embedded pages are created once and reused by ordinary navigation.
local terminalFrame=widget();local walletFrame=widget()
function A.EmbedDashboard(page) terminalFrame.parent=page;return terminalFrame end
function A.EmbedBalanceHistory(page)walletFrame.parent=page;return walletFrame end
function A.RefreshDashboard()A.dashboardUpdates=(A.dashboardUpdates or 0)+1 end
function A.RefreshBalanceWindow()A.walletUpdates=(A.walletUpdates or 0)+1 end
A.OpenProTool('terminal')
assert(w.active=='terminal' and w.contextTitle.text=='Терминал')
assert(w.pages.terminal and terminalFrame.parent==w.pages.terminal)
assert(A.dashboardUpdates==1)
local firstTerminal=w.pages.terminal
w.nav.balance.scripts.OnClick()
assert(w.active=='balance' and w.contextTitle.text=='История золота')
assert(w.pages.balance and walletFrame.parent==w.pages.balance)
assert(A.walletUpdates==1)
assert(w.pages.terminal==firstTerminal and not w.pages.balance.helpPanel)
w.nav.terminal.scripts.OnClick()
assert(w.pages.terminal==firstTerminal and A.dashboardUpdates==2)
assert(w.helpButton.scripts.OnEnter,'each active tab needs the same ? tooltip')
A.OpenProTool("quality")
assert(w.active=="activity" and w.nav.activity.sideAccent.visible,"legacy quality route must open merged tab")
print('PASS unified beta5: 13 entries, merged activity and quality, Terminal and Gold history preserved')
