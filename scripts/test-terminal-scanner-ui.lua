-- beta1 scanner smoke test: usable full-width columns and an actionable empty state.
ATS={locale='ruRU',db={pro={scannerShowUnknown=false,scannerSort='score'}}}
local A=ATS
local function widget()
 local w={visible=true,scripts={}}
 function w:SetSize(x,y)self.width=x;self.height=y end
 function w:SetPoint(...)self.point={...}end
 function w:SetWidth(x)self.width=x end
 function w:SetText(x)self.text=x end
 function w:GetText()return self.text or '' end
 function w:SetTextColor(...)self.color={...}end
 function w:SetVertexColor(...)self.vertexColor={...}end
 function w:SetTexture(t)self.texture=t end
 function w:SetJustifyH(v)self.justify=v end
 function w:EnableMouse(v)self.mouse=v end
 function w:SetEnabled(v)self.enabled=v end
 function w:SetScript(n,fn)self.scripts[n]=fn end
 function w:HookScript(n,fn)self.scripts[n]=fn end
 function w:CreateFontString()return widget()end
 function w:CreateTexture()return widget()end
 function w:SetFrameStrata()end
 function w:SetFrameLevel()end
 function w:GetFrameLevel()return 20 end
 function w:SetBackdrop()end
 function w:SetBackdropBorderColor()end
 function w:EnableKeyboard()end
 function w:Show()self.visible=true end
 function w:Hide()self.visible=false end
 function w:IsShown()return self.visible end
 return w
end
function CreateFrame()return widget()end
A.ProUIShared={
 l=function(_,ru)return ru end,
 fs=function(_,label)local w=widget();w:SetText(label);return w end,
 tex=function(_,x,y,width,height)local w=widget();w.width=width;return w end,
 button=function(_,label,x,y,width,fn)
  local w=widget();w:SetText(label);w:SetScript('OnClick',fn);return w end,
 newPage=function()return widget()end,
 heading=function()end,
 showHelp=function()end,
 currency=function(v)return tostring(v)..'c' end,
}
A.ProUIBuilders={}
A.StyleButton=function()end
A.InCombat=function()return false end
local rows={}
A.ProScanner=function()return rows end
A.StartProScanner=function(progress,done)progress(0,0);done(rows)end
A.QueueScannerItemMetadata=function()end
A.ProItemLink=function(key)return 'item:12' end
A.PeekItemMetadata=function()return 'Тестовый предмет','Interface\\Icons\\INV_Misc_QuestionMark',12,true end
A.SortScannerResults=function()end
A.FitItemName=function(name)return name end
assert(loadfile('UI/Pro/Pages/Scanner.lua'))()
local p=A.ProUIBuilders.scanner({})
p.update()
assert(p.empty.visible,'empty scanner state should be shown')
assert(p.emptyScan.visible,'scanner should offer refresh when empty')
assert(p.empty.text:find('Нет актуальных'), 'no useful empty-state message')
rows={{key='db:12',discount=25,price=1234,score=74,risk=22,quality=50,age=2,samples=10}}
p.update()
assert(not p.empty.visible and not p.emptyScan.visible,'nonempty list must hide empty message')
assert(p.rows[1].width==898,'results should use expanded canvas')
assert(p.rows[1].itemName.text=='Тестовый предмет')
assert(p.rows[1].discountText.text=='-25.0%')
assert(p.rows[1].priceText.text=='1234c')
assert(p.rows[1].scoreText.text=='74')
assert(p.rows[1].riskText.text=='22')
assert(p.rows[1].visible and not p.rows[2].visible)
print('PASS terminal beta1 scanner: clear columns, wide rows, empty state, refresh action')
