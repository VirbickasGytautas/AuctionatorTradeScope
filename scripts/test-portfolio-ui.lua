-- Beta4 portfolio screen: four modes and direct allocation-source dropdown.
ATS={db={pro={journalFee=5}}}
local A=ATS
assert(loadfile("UI/Pro/Shared.lua"))()
local proIcons=A.ProUIShared
local function widget(text)
 local w={text=text or "",visible=true,scripts={}}
 function w:SetText(t)self.text=t end
 function w:GetText()return self.text end
 function w:SetEnabled(t)self.enabled=t end
 function w:SetScript(n,fn)self.scripts[n]=fn end
 function w:Show()self.visible=true end
 function w:Hide()self.visible=false end
 function w:GetFontString()return self end
 function w:SetTexture(t) self.texture=t end
 function w:SetVertexColor(...) self.vertexColor={...} end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:SetHeight(height) self.height=height end
 function w:SetPoint(...) self.point={...} end
 function w:ClearAllPoints()self.point=nil end
 function w:SetJustifyH(dir)self.justify=dir end
 function w:SetWordWrap(v)self.wordWrap=v end
 function w:SetTextColor(...)self.textColor={...}end
 function w:IsShown()return self.visible end
 function w:SetTexCoord(...)self.texCoord={...}end
 function w:CreateTexture()return widget()end
 function w:CreateFontString()return widget()end
 return w
end
local buttons={}
local function button(p,text,x,y,width,fn)
 local w=widget(text);w:SetScript("OnClick",fn);buttons[#buttons+1]=w;return w
end
local function fs(_,text)return widget(text)end
local function dropdown(_,_,_,_,_,options,selected,onSelect)
 local result=widget('');result.popup=widget('');result.popup:Hide()
 result.options=options;result.getSelected=selected
 function result:Choose(value)
   local found=false
   for _,opt in ipairs(self.options) do if opt.value==value then found=true end end
   assert(found,'missing allocation basis: '..tostring(value))
   onSelect(value)
 end
 return result
end
local function lineList(_,count)
 local list={};for i=1,count do list[i]=widget() end;return list
end
A.ProUIShared={l=function(en)return en end,fs=fs,button=button,dropdown=dropdown,
 attachProRowIcon=proIcons.attachProRowIcon,renderProRowItem=proIcons.renderProRowItem,
 watchProRowIcons=proIcons.watchProRowIcons,
 newPage=function()return {}end,heading=function()end,lineList=lineList,
 tex=function()end,currency=function(n)return tostring(n)end}
A.ProUIBuilders={}
function A.ProItemName(key)return "Item "..key end
function A.FitItemName(s)return s end
function A.ProItemMeta(key)
  return "Item "..key,"Interface\\Icons\\INV_Ore_Iron_01"
end
function A.ProItemLink()return "item:55"end
function A.OpenDashboardScanKey(key)A.lastKey=key end
function A.ShowProTab(t)A.tab=t end
function time()return 1700000000 end
local stock={items={},count=9,bagKnown=true,bankKnown=false,bagUnits=90,
  bankUnits=0,bankValue=0,bagValue=960,bagsTime=time(),pricedCount=9}
for i=1,9 do stock.items[i]={key="db:"..i,bagQty=i,bankQty=0,
  status="priced",bagValue=i*20,bankValue=0,price=20,quoteAge=0} end
A.PortfolioHoldings=function()return stock end
A.RefreshPortfolioStock=function()A.refreshed=(A.refreshed or 0)+1 end
local sales={sales={},count=2,units=21,gross=30000,fees=1500,net=28500,
  realized=0,matched=0,unmatched=21}
for i=1,2 do sales.sales[i]={key="db:"..i,qty=i,net=1000*i,
  unmatched=i,matched=0,gross=i*1500,fees=i*75,t=i,source="auction_mail"}end
A.PortfolioSalesReport=function()return sales end
local ledger={positions={{key="db:100",qty=2,cost=500,avgCost=250,
   pnl=100,status="priced",netValue=600,price=300,roi=20}},
 openCount=1}
A.PortfolioSnapshot=function()return ledger end
assert(loadfile("Finance/Portfolio/Allocation.lua"))()
assert(loadfile("UI/Pro/Pages/Portfolio.lua"))()
local p=A.ProUIBuilders.portfolio({})
assert(p.mode=="stock" and not p.allocationSource.visible and p.sales.text:find("Confirmed AH sales: 2",1,true))
assert(p.revenue.text:find("NET REVENUE: 28500",1,true))
assert(p.profit.text:find("unknown",1,true) and p.profit.text:find("21",1,true))
assert(p.stock.text:find("Bags: 90",1,true))
assert(p.rows[1].text=="Item db:1")
assert(p.rows[1].itemIcon.texture=="Interface\\Icons\\INV_Ore_Iron_01")
assert(p.rows[1].itemIcon.visible and p.rows[1].itemMetrics.text:find("Bags 1",1,true))
assert(not p.rows[1].itemIconFallback.visible)
assert(p.rows[1].itemTitle.point[4]==36 and p.rows[1].itemTitle.width==400)
assert(p.pageText.text=="Page 1 / 2")
assert(p.prev.enabled==false and p.next.enabled==true)
p.next.scripts.OnClick();assert(p.pageIndex==2)
assert(p.rows[1].itemIcon.visible and p.rows[1].itemIcon.texture:find("INV_Ore",1,true))
assert(not p.allocationBars[1].fill.visible)
p.salesMode.scripts.OnClick()
assert(p.mode=="sales" and p.pageIndex==1)
assert(p.rows[1].itemMetrics.text:find("COST UNKNOWN",1,true))
assert(p.rows[1].itemIcon.visible and p.rows[1].itemIcon.texture:find("INV_Ore",1,true))
assert(p.rows[3].visible==false)
p.ledgerMode.scripts.OnClick()
assert(p.mode=="ledger" and p.rows[1].itemMetrics.text:find("Cost 500",1,true))
assert(p.rows[1].itemIcon.visible and p.rows[1].itemIcon.texture:find("INV_Ore",1,true))
assert(p.rows[2].visible==false)
assert(p.realized==nil and p.profit.text:find("unknown",1,true))
p.stockMode.scripts.OnClick()
assert(p.mode=="stock")
p.allocationMode.scripts.OnClick()
assert(p.mode=="allocation" and p.allocationSource.visible)
assert(p.allocationBasis=="bags" and p.section.text:find("DISTRIBUTION",1,true))
assert(p.rows[1].itemMetrics.text:find("%",1,true))
assert(p.rows[1].itemIcon.visible and p.rows[1].itemIcon.texture:find("INV_Ore",1,true))
assert(p.allocationBars[1].width>=600 and p.allocationBars[1].height>=7)
assert(p.allocationBars[1].fill.visible and p.allocationBars[1].track.visible)
assert(p.allocationBars[1].fill.width>=1 and p.allocationBars[1].fill.width<=840)
local expectedFill=math.floor(840*stock.items[9].bagValue/(
  stock.items[1].bagValue+stock.items[2].bagValue+stock.items[3].bagValue+
  stock.items[4].bagValue+stock.items[5].bagValue+stock.items[6].bagValue+
  stock.items[7].bagValue+stock.items[8].bagValue+stock.items[9].bagValue)+.5)
assert(p.allocationBars[1].fill.width==expectedFill)
assert(p.subtitle.text:find("Valued:",1,true))
p.allocationSource:Choose("sales")
assert(p.allocationBasis=="sales" and p.pageIndex==1)
assert(p.rows[1].itemMetrics.text:find("%",1,true))
assert(p.allocationBars[1].fill.visible)
assert(p.note.text:find("Basis total:",1,true))
p.allocationSource:Choose("cost")
assert(p.allocationBasis=="cost" and p.rows[1].text:find("db:100",1,true))
p.allocationSource:Choose("bank")
assert(p.allocationBasis=="bank" and p.empty.visible)
assert(p.note.text:find("not been scanned",1,true))
p.stockMode.scripts.OnClick()
assert(p.mode=="stock" and not p.allocationSource.visible)
assert(not p.allocationBars[1].fill.visible and not p.allocationBars[1].track.visible)
assert(p.rows[1].itemIcon.visible)
for _,b in ipairs(buttons) do if b.text=="Refresh" then b.scripts.OnClick() end end
assert(A.refreshed>=2)
stock.items={};stock.count=0;stock.bagKnown=false;stock.bagUnits=0
p.update();assert(p.empty.visible and p.empty.text:find("unavailable",1,true))
assert(not p.rows[1].itemIcon.visible and not p.allocationBars[1].track.visible)
stock.items={{key="db:999",bagQty=1,bankQty=0,status="missing"}}
stock.count=1;stock.bagKnown=true;stock.bagUnits=1
A.ProItemMeta=function(key)return "Unknown "..key,nil end
p.update()
assert(p.rows[1].itemIcon.texture=="Interface\\Icons\\INV_Misc_QuestionMark")
assert(p.rows[1].itemIconFallback.visible)
assert(p.rows[1].itemIcon.visible and not p.allocationBars[1].track.visible)
-- Empty state after the item is removed: icon must be hidden again.
stock.items={};stock.count=0;p.update()
assert(not p.rows[1].itemIcon.visible)
print("PASS beta5 portfolio UI: 4 modes, item icons, wide allocation bars and paging")
