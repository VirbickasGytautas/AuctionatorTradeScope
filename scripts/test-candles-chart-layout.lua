-- Regression guard for a WoW 1.60.1 item identity/chart collision.
ATS={locale="ruRU",db={pro={candleBucketHours=1,candleHours=48}}}
local A=ATS
A.ProUIBuilders={}
local C={WIDTH=1188,HEIGHT=780}
local function dummy()return {GetText=function()return "48" end,SetText=function()end} end
C.newPage=function(root) return {root=root} end
C.heading=function()end
C.marketInput=function()return dummy()end
C.edit=function()return dummy()end
C.makeItemIdentity=function(page)
  local identity={top=-117,height=42}
  page.identity=identity
  return identity
end
C.newPlot=function(_,x,y,w,h)
  local plot={initial={x=x,y=y},width=w,height=h}
  function plot:ClearAllPoints()self.cleared=true end
  function plot:SetPoint(...)self.anchor={...}end
  return plot
end
C.fs=function(_,_,x,y,w)
  return {x=x,y=y,width=w,SetText=function()end}
end
C.button=function()return dummy()end
C.l=function(en,ru)return ru end
C.currency=function()return "-" end
A.ProUIShared=C
assert(loadfile("UI/Pro/Pages/Candles.lua"))()
local p=A.ProUIBuilders.candles({})
assert(p.plot.cleared and p.plot.anchor[1]=="TOPLEFT")
assert(p.plot.anchor[2]==p.identity and p.plot.anchor[3]=="BOTTOMLEFT")
local dx,dy=p.plot.anchor[4],p.plot.anchor[5]
assert(dx==9 and dy<=-20,"chart not safely below the identity strip")
local identityBottom=p.identity.top-p.identity.height
local plotTop=identityBottom+dy
local plotBottom=plotTop-p.plot.height
assert(plotTop<=identityBottom-20,"graph overlaps item title/icon")
assert(plotBottom< -550 and plotBottom> -590,"plot not within work area")
assert(p.info.y < plotBottom and p.hint.y < p.info.y,"chart captions overlap plot")
assert(p.hint.y > -645,"legend exceeds visible 660-unit page")
assert(p.plot.width==868,"unrelated horizontal geometry changed")
print("PASS candle chart below item identity, caption spacing and workspace bounds")
