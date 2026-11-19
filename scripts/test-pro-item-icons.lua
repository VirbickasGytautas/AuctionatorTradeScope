-- Beta6: an item with cached localized NAME but missing TEXTURE must be retried.
local id=1206
local unknown="Interface\\Icons\\INV_Misc_QuestionMark"
local actual="Interface\\Icons\\INV_Misc_Gem_Emerald_02"
local loaded=false
local uptime=100
ATS={db={itemCache={[id]={name="Моховой агат"}},itemNameIndex={[id]={name="Моховой агат"}}}}
local A=ATS
function A.Init()end
function GetTime()return uptime end
function GetItemInfo(subject)
 local item=tonumber(type(subject)=="number" and subject or tostring(subject):match("item:(%d+)"))
 if item~=id then return nil end
 return "Моховой агат","item:"..id,nil,nil,nil,nil,nil,nil,nil,loaded and actual or nil
end
function GetItemIcon(item)return loaded and item==id and actual or nil end
local frames={}
function CreateFrame()
 local f={}
 function f:SetScript(event,fn)self[event]=fn end
 frames[#frames+1]=f
 return f
end
assert(loadfile("Data/ItemInfo.lua"))()
assert(loadfile("UI/Pro/Shared.lua"))()
local renderer=A.ProUIShared
A.ProItemMeta=function(key)
  local n,icon,ready=A.ResolveItemInfo(key)
  return n,icon,id,ready
end
local name,icon=A.ResolveItemInfo("item:"..id)
assert(name=="Моховой агат" and icon==unknown,"name-only cache improperly treated as icon-ready")
local function widget()
 local w={shown=true}
 function w:SetSize(x,y)self.width=x;self.height=y end
 function w:SetPoint(...)self.point={...}end
 function w:SetTexture(t)self.texture=t end
 function w:SetTexCoord(...)self.coords={...}end
 function w:SetText(v)self.text=v end
 function w:SetTextColor(...)self.colors={...}end
 function w:Show()self.shown=true end
 function w:Hide()self.shown=false end
 function w:IsShown()return self.shown end
 function w:CreateTexture(...)local o=widget();o.layer=select(2,...);return o end
 function w:CreateFontString(...)local o=widget();o.layer=select(2,...);return o end
 function w:SetScript(event,cb)self[event]=cb end
 return w
end
local row=widget()
renderer.attachProRowIcon(row,7,21)
assert(row.itemIcon.layer=="OVERLAY", "icon must be above normal button art")
assert(renderer.renderProRowItem(row,"db:"..id)=="Моховой агат")
assert(row.itemIcon.texture==unknown and row.itemIconFallback.shown)
assert(row._atsIconPending and row._atsIconRequested)
local page=widget()
renderer.watchProRowIcons(page,{row})
assert(type(page.OnUpdate)=="function")
loaded=true
uptime=uptime+4
page.OnUpdate(page,1.1)
assert(row.itemIcon.texture==actual,"icon did not refresh after client metadata arrived")
assert(row.itemIcon.shown and not row.itemIconFallback.shown)
local cached=A.db.itemCache[id]
assert(cached.name=="Моховой агат" and cached.icon==actual)
assert(not row._atsIconPending)
-- Hiding a paginated row must clear image and its unresolved overlay.
renderer.renderProRowItem(row,nil)
assert(not row.itemIcon.shown and not row.itemIconFallback.shown)
print("PASS item icons: cached name without icon, retry, texture refresh, overlay and row reuse")
