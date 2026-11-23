-- Smoke UI for 4.6.0 strategy screen: three profiles, icons, paging and empty state.
ATS={locale="enUS"}
local A=ATS
local function widget()
  local w={text="",visible=true,scripts={}}
  function w:SetSize(x,y)self.width=x;self.height=y end
  function w:SetPoint(...)self.point={...}end
  function w:SetWidth(x)self.width=x end
  function w:SetText(x)self.text=x end
  function w:GetText()return self.text end
  function w:SetTextColor(...)self.color={...}end
  function w:SetVertexColor(...)self.color={...}end
  function w:SetTexture(t)self.texture=t end
  function w:SetJustifyH(v)self.justify=v end
  function w:SetWordWrap(v)self.wrap=v end
  function w:EnableMouse(v)self.mouse=v end
  function w:SetEnabled(v)self.enabled=v end
  function w:SetScript(n,fn)self.scripts[n]=fn end
  function w:CreateFontString()return widget()end
  function w:CreateTexture()return widget()end
  function w:Show()self.visible=true end
  function w:Hide()self.visible=false end
  function w:IsShown()return self.visible end
  return w
end
function CreateFrame()return widget()end
A.ProUIShared={
 l=function(en)return en end,
 fs=function(_,label)return (function()local w=widget();w:SetText(label);return w end)()end,
 tex=function()return widget()end,
 button=function(_,label,x,y,width,fn)
   local w=widget();w:SetText(label);w:SetScript("OnClick",fn);return w end,
 newPage=function()return widget()end,
 heading=function()end,
 currency=function(n)return tostring(n)end,
 dropdown=function(_,label,x,y,width,options,getSelected,onSelect)
   local w=widget();w.options=options
   function w:Choose(v)onSelect(v)end
   return w
 end,
 attachProRowIcon=function(row)
   row.itemIcon=widget();row.itemIconFallback=widget()
 end,
 renderProRowItem=function(row,key)
   if not key then
     row.itemIcon:Hide();row.itemIconFallback:Hide();return end
   row.itemIcon:SetTexture("icon:"..key);row.itemIcon:Show()
   row.itemIconFallback:Hide()
   return "Item "..key
 end,
 watchProRowIcons=function(p,rows)p.iconsWatched=#rows end,
 inspect=function(key)A.lastInspected=key end,
}
A.ProUIBuilders={}
A.ProItemName=function(key)return "Item "..key end
A.FitItemName=function(name)return name end
local currentMode
local rows={}
for i=1,11 do rows[i]={key="db:"..i,kind="discount",discount=i*2,
  score=65,risk=30,quality=70,median=2000,price=1000,
  priority=i,source="scanner_and_quote"}
end
A.StrategyKinds=function()
 return {"discount","exit","exposure"},{
  discount={en="Value watch",ru="Поиск скидки"},
  exit={en="Exit review",ru="Проверка выхода"},
  exposure={en="Concentration",ru="Концентрация"},
 }
end
A.StrategySnapshot=function(kind)
 currentMode=kind
 if kind=="discount" then
   return {kind=kind,rows=rows,sourceKnown=true,considered=11,excluded=4,reasons={}}
 elseif kind=="exit" then
   return {kind=kind,rows={{key="db:88",kind="exit",qty=2,cost=10000,
     net=14000,profit=4000,roi=40}},sourceKnown=true,considered=3,excluded=2,reasons={}}
 end
 return {kind=kind,rows={},sourceKnown=false,considered=0,excluded=0,reasons={stock_unknown=1}}
end
assert(loadfile("UI/Pro/Pages/Strategies.lua"))()
local p=A.ProUIBuilders.strategies({})
assert(p.mode=="discount" and p.iconsWatched==7)
assert(p.rows[1].visible and p.rows[1].itemIcon.texture=="icon:db:1")
assert(p.rows[7].itemIcon.texture=="icon:db:7")
assert(p.next.enabled and not p.prev.enabled)
assert(p.pageText.text=="Page 1 / 2")
p.next.scripts.OnClick();assert(p.pageIndex==2)
assert(p.rows[1].itemIcon.texture=="icon:db:8")
p.profile:Choose("exit")
assert(p.mode=="exit" and p.pageIndex==1)
assert(p.rows[1].itemIcon.texture=="icon:db:88")
assert(p.rows[1].metric.text:find("40.0%%"))
assert(not p.rows[2].visible and not p.rows[2].itemIcon.visible)
p.rows[1].scripts.OnClick(p.rows[1]);assert(A.lastInspected=="db:88")
p.profile:Choose("exposure")
assert(currentMode=="exposure" and not p.rows[1].visible)
assert(p.empty.visible and p.empty.text:find("No reliable source"))
assert(p.warning.text:find("unavailable"))
p.profile:Choose("discount")
assert(p.rows[1].itemIcon.texture=="icon:db:1" and p.pageText.text=="Page 1 / 2")
print("PASS strategies UI: profile dropdown, icon cleanup, pagination, safe empty states")
