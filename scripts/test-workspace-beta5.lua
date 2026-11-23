-- Standalone 5.0.0-beta5 regression: one item, activity left, quality right.
local function widget()
 local w={text="",shown=true}
 function w:SetText(v)self.text=v end
 function w:GetText()return self.text end
 function w:SetTextColor(...)self.color={...}end
 function w:SetSize(wid,h)self.width=wid;self.height=h end
 function w:SetPoint(...)self.point={...}end
 function w:SetScript(name,fn)self[name]=fn end
 function w:Show()self.shown=true end
 function w:Hide()self.shown=false end
 return w
end
local key="db:2321"
ATS={locale="ruRU",db={pro={activityEnabled=true,qualityEnabled=true}}}
local A=ATS
local fieldCount=0
local hoverGroups={}
A.ProUIBuilders={}
A.ProUIShared={
 l=function(en,ru)return ru end,
 fs=function(_,text,x,y,width)
   local w=widget();w.text=text;w.x=x;w.y=y;w.width=width;return w
 end,
 tex=function(_,x,y,wid,h)return {x=x,y=y,width=wid,height=h} end,
 button=function(_,text,x,y,wid,fn)
   local w=widget();w.text=text;w.x=x;w.y=y;w.width=wid;w.OnClick=fn;return w
 end,
 newPage=function()return widget()end,
 heading=function()end,
 marketInput=function(_,x,y,wid)
   fieldCount=fieldCount+1
   return {x=x,y=y,width=wid}
 end,
 makeItemIdentity=function()
   return {showItem=function(self,selected)self.key=selected end}
 end,
 selectedKey=function()return key end,
 addMetricTooltips=function(_,rows,tips,width)
   assert(#rows==#tips and width==433)
   hoverGroups[#hoverGroups+1]=#rows
 end,
 attachHelp=function()end,
 currency=function(v)return tostring(v or "-") end,
 labelNumber=function(v)return v and string.format("%.1f",v) or "-" end,
}
local calls={activity=0,quality=0,samples=0}
function A.ProActivity(item)
 assert(item==key);calls.activity=calls.activity+1
 return {score=17,observations=2,priceChanges=1,quantityChanges=1,
  quality={score=53},metrics={currentPrice=10000,volatility=33.1,currentQuantity=1317}}
end
function A.ProSamples(item)
 assert(item==key);calls.samples=calls.samples+1
 return {1,2,3,4}
end
function A.ProQuality(samples)
 assert(#samples==4);calls.quality=calls.quality+1
 return {score=53,count=4,uniqueHours=4,age=1.4,coverage=56.9,maxGap=28.3,
  coveragePercent=30,coverageBucketHours=6,scanObservations=3,
  hoverObservations=0,unknownObservations=1,label="medium"}
end
function A.FmtVolatility(n)return string.format("%.1f%%",n or 0) end
function A.FmtCount(n)return tostring(n or 0)end
assert(loadfile('UI/Pro/Pages/Activity.lua'))()
local p=A.ProUIBuilders.activity({})
assert(fieldCount==1,'both columns must share exactly one item selector')
assert(#p.activityRows==8 and #p.qualityRows==11)
assert(p.activityRows[1].x==20 and p.qualityRows[1].x==490)
assert(p.activityRows[1].y==p.qualityRows[1].y)
assert(#hoverGroups==2 and hoverGroups[1]==8 and hoverGroups[2]==11)
p.update()
assert(p.identity.key==key)
assert(p.activityRows[1].text:find('17 / 100',1,true))
assert(p.qualityRows[1].text:find('53 / 100',1,true))
assert(p.qualityRows[7].text:find('30.0%',1,true))
assert(calls.activity==1 and calls.quality==1 and calls.samples==1)
p.analyze.OnClick()
assert(calls.activity==2 and calls.quality==2 and calls.samples==2)
A.db.pro.activityEnabled=false
p.update()
assert(p.activityRows[1].text:find('отключена',1,true))
assert(p.qualityRows[1].text:find('53 / 100',1,true))
A.db.pro.activityEnabled=true
A.db.pro.qualityEnabled=false
p.update()
assert(p.activityRows[1].text:find('17 / 100',1,true))
assert(p.qualityRows[1].text:find('отключено',1,true))
key=nil;p.update()
assert(p.identity.key==nil and p.activityRows[2].text=='')
assert(p.qualityRows[2].text=='')
print('PASS beta5 dual-column research: single item, two models, hover help and legacy preference gates')
