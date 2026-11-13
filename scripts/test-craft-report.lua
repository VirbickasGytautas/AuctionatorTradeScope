-- Render smoke test with minimal WoW-independent widgets.
ATS={locale="enUS",db={pro={craftInventoryEnabled=true}}}
local A=ATS
function date(_,timestamp) return tostring(timestamp) end
local function widget()
  return {
    shown=true,
    SetText=function(self,v) self.text=v end,
    SetTextColor=function(self,...) self.color={...} end,
    SetTexture=function(self,v) self.texture=v end,
    SetChecked=function(self,v) self.checked=v end,
    Show=function(self) self.shown=true end,
    Hide=function(self) self.shown=false end,
  }
end
A.ProUIShared={l=function(en,ru) return en end,currency=function(n) return "G:"..tostring(n) end}
A.FitItemName=function(s) return s end
A.CraftStockInfo=function()return {bankKnown=true,bankTime=1700000000} end
A.EvaluateCraftBatch=function(recipe,batchCount)
  local rows={}
  for i,material in ipairs(recipe.materials) do
    rows[i]={qty=material.qty*batchCount,stock=3,buy=2,include=i~=2,
      unit=4,cost=material.qty*batchCount*4}
  end
  return {rows=rows,inventoryEnabled=true,marketCost=102,cashCost=49,
    net=200,marketProfit=98,cashProfit=151,outputQuote=220,roi=96.0784,
    excluded=1,missingMarket={},missingCash={}}
end
assert(loadfile("UI/Pro/Craft/Report.lua"))()
local p={materialRows={}}
for i=1,6 do
  p.materialRows[i]={}
  for _,k in ipairs({"background","icon","title","qty","owned","buy","unit","total","hotspot","include"}) do
    p.materialRows[i][k]=widget()
  end
end
for _,field in ipairs({"stockToggle","productName","productMade","summary1","summary2","summary3","info","pageLabel"}) do
  p[field]=widget()
end
local productHotspot=widget()
local productIcon=widget()
local recipe={product=99,made=2,materials={}}
for i=1,9 do recipe.materials[i]={id=i,qty=1,name="Material "..i} end
local active=recipe
local page=2
local batchCount=3
local render=A.CreateCraftReportRenderer({p=p,productHotspot=productHotspot,productIcon=productIcon,
  displayName=function(id,name) return name,"texture:"..id end,
  formatValue=function(n) return n and "G:"..tostring(n) or "No data" end,
  pageSize=6,
  getActive=function()return active end,
  getPage=function()return page end,
  setPage=function(n)page=n end,
  getBatchCount=function()return batchCount end})
render()
assert(page==2 and p.pageLabel.text=="Items: 9  2/2")
assert(p.materialRows[1].sourceIndex==7 and p.materialRows[1].hotspot.material.id==7)
assert(p.materialRows[3].sourceIndex==9)
assert(not p.materialRows[4].background.shown)
assert(p.productMade.text=="Per craft: 2   Batch output: 6")
assert(p.summary1.text:find("G:102",1,true))
assert(p.summary3.text:find("96.1%%")~=nil)
assert(productHotspot.shown)
page=99;render();assert(page==2)
active=nil;render()
assert(p.pageLabel.text=="" and not productHotspot.shown)
assert(not p.materialRows[1].background.shown)
print("PASS CraftReport renderer: pagination, rows, market summary, empty recipe")
