-- Beta4 geometry regression. Simulated frames test re-anchoring; WoW visual
-- verification is still required on the 1.60.1 client.
local function widget()
  local w={shown=false}
  function w:SetSize(x,y)self.width=x;self.height=y end
  function w:SetWidth(x)self.width=x end
  function w:SetHeight(y)self.height=y end
  function w:SetPoint(...)self.point={...}end
  function w:ClearAllPoints()self.point=nil end
  function w:SetScale(v)self.scale=v end
  function w:SetFrameStrata(v)self.strata=v end
  function w:SetFrameLevel(v)self.level=v end
  function w:GetFrameLevel()return self.level or 10 end
  function w:SetBackdrop(v)self.backdrop=v end
  function w:SetParent(v)self.parent=v end
  function w:SetMovable(v)self.movable=v end
  function w:Hide()self.shown=false end
  function w:Show()self.shown=true end
  function w:IsShown()return self.shown end
  function w:SetScript()end
  function w:RegisterEvent()end
  return w
end
ATS={locale="ruRU"}
local A=ATS
local wallet=widget()
for _,k in ipairs({'close','drag','windowHeading','background','summary','hint',
  'plotHitbox','cursorLine','presetDay','presetWeek','presetMonth',
  'zoomInfo','zoomIn','zoomOut','zoomReset','enable','instruction'}) do wallet[k]=widget() end
wallet.hgrid={};wallet.yticks={};wallet.vgrid={};wallet.xticks={}
for i=1,5 do wallet.hgrid[i]=widget();wallet.yticks[i]=widget() end
for i=1,7 do wallet.vgrid[i]=widget();wallet.xticks[i]=widget() end
A.balanceFrame=wallet
function CreateFrame()return widget()end
assert(loadfile('Finance/Balance.lua'))()
local page=widget()
page.level=20
local result=A.EmbedBalanceHistory(page)
assert(result==wallet and wallet.parent==page and wallet.shown)
assert(wallet.scale==1 and wallet.width==946 and wallet.height==658)
assert(wallet.point[4]==0 and wallet.point[5]==-1)
assert(not wallet.windowHeading.shown and not wallet.background.shown)
assert(wallet.summary.point[4]==20 and wallet.summary.point[5]==-18)
assert(wallet.plotHitbox.width==828 and wallet.plotHitbox.height==412)
assert(wallet.plotHitbox.point[4]==88 and wallet.plotHitbox.point[5]==136)
assert(wallet.cursorLine.height==412)
assert(wallet.hgrid[1].point[4]==88 and wallet.hgrid[5].point[4]==88)
assert(wallet.hgrid[5].point[5]==548)
assert(wallet.vgrid[1].point[4]==88 and math.floor(wallet.vgrid[7].point[4])==916)
assert(wallet.presetDay.point[5]==-569 and wallet.zoomReset.point[4]==725)
assert(wallet.instruction.point[5]==-621 and wallet.instruction.width==900)
-- Repeat navigation does not alter axes and does not create another wallet.
local hit=wallet.plotHitbox
assert(A.EmbedBalanceHistory(page)==wallet and wallet.plotHitbox==hit)
local function source(path)
  local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local ui=source('UI/Pro/Window.lua')
assert(ui:find('f.contextTitle=fs(f,l("Terminal","Терминал"),63,-42,760,true)',1,true))
assert(ui:find('f.content:SetPoint("TOPLEFT",f,"TOPLEFT",219,-74)',1,true))
local dash=source('UI/Dashboard.lua')
for _,fragment in ipairs({
 'f:SetSize(944,654)', 'f:SetScale(1)', 'place(f.query,25,-61)',
 'place(f.dropTarget,25,-100)', 'place(f.watchTitle,25,-251)',
 'place(f.graph,261,-193)', 'f.graph.terminalChartHeight=312',
 'place(f.tradePanel,261,-227)', 'f:SetMovable(false)',
}) do assert(dash:find(fragment,1,true),'missing terminal reflow: '..fragment) end
print('PASS beta4 geometry: full canvas, native history plot & hitbox, terminal anchors and title')
