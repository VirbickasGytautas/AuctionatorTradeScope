-- Floating graph placement, collision avoidance for native WoW tooltips.
local A=ATS
local WIDTH=654
-- Tooltip-aware placement: protect Blizzard's actual item tooltip as well
-- as both item-comparison tooltips. Chart placement never hides or moves them.
-- Coordinates are normalized into UIParent units before collision checks.
local TOOLTIP_FRAMES={"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2",
  "ItemRefShoppingTooltip1","ItemRefShoppingTooltip2","CompareTooltip1","CompareTooltip2"}
local function frameBounds(frame)
  if not frame or not frame.IsShown or not frame:IsShown() or
     not frame.GetLeft or not frame.GetRight or not frame.GetTop or
     not frame.GetBottom then return nil end
  local left,right,top,bottom=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
  if type(left)~="number" or type(right)~="number" or
     type(top)~="number" or type(bottom)~="number" or
     right<=left or top<=bottom then return nil end
  local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local scale=frame.GetEffectiveScale and frame:GetEffectiveScale() or parentScale
  local f=scale/(parentScale>0 and parentScale or 1)
  return {l=left*f,r=right*f,b=bottom*f,t=top*f}
end
local function visibleItemTooltipBounds()
  local result,seen={},{}
  for i=1,#TOOLTIP_FRAMES do
    local frame=_G[TOOLTIP_FRAMES[i]]
    if frame and not seen[frame] then
      seen[frame]=true
      local r=frameBounds(frame)
      if r then result[#result+1]=r end
    end
  end
  return result
end
local function overlaps(a,b)
  return a.l < b.r-2 and a.r > b.l+2 and a.b < b.t-2 and a.t > b.b+2
end
local function placeGraphAvoidingTooltips(graph,anchor,desiredScale)
  local screenW,screenH=UIParent:GetWidth(),UIParent:GetHeight()
  if screenW<=0 or screenH<=0 then return false end
  local avoid=visibleItemTooltipBounds()
  local main=frameBounds(anchor)
  if not main then main=avoid[1] end
  if not main then
    main={l=screenW/2-10,r=screenW/2+10,
      b=screenH/2-10,t=screenH/2+10}
  end
  local minL,maxR,minB,maxT=main.l,main.r,main.b,main.t
  for i=1,#avoid do
    local a=avoid[i]
    minL=math.min(minL,a.l);maxR=math.max(maxR,a.r)
    minB=math.min(minB,a.b);maxT=math.max(maxT,a.t)
  end
  local firstScale=math.min(desiredScale or 1,1,
    (screenW-16)/WIDTH,(screenH-16)/math.max(1,graph:GetHeight()))
  local factors={1,.92,.84,.76,.68,.60,.52,.45}
  local gap=10
  for i=1,#factors do
    local scale=firstScale*factors[i]
    if scale>=.32 then
      local w,h=WIDTH*scale,graph:GetHeight()*scale
      local limitX,limitY=screenW-w-8,screenH-h-8
      if limitX>=8 and limitY>=8 then
        local candidates={
          {x=maxR+gap,y=main.t-h}, -- to the right of all shown tooltips
          {x=minL-w-gap,y=main.t-h},
          {x=maxR+gap,y=maxT-h},
          {x=minL-w-gap,y=maxT-h},
          {x=main.l,y=minB-h-gap}, -- beneath all item tooltips
          {x=main.l,y=maxT+gap},  -- above all item tooltips
          {x=8,y=8},{x=limitX,y=8},
          {x=8,y=limitY},{x=limitX,y=limitY},
        }
        for j=1,#candidates do
          local c=candidates[j]
          local x=math.max(8,math.min(limitX,c.x))
          local y=math.max(8,math.min(limitY,c.y))
          local r={l=x,r=x+w,b=y,t=y+h}
          local safe=true
          for k=1,#avoid do
            if overlaps(r,avoid[k]) then safe=false;break end
          end
          if safe then
            graph:SetScale(scale)
            graph:ClearAllPoints()
            graph:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
            return true
          end
        end
      end
    end
  end
  -- There is not enough free space. Never cover the native item/comparison
  -- tooltips just to display the optional analytics chart.
  return false
end


A.GraphPlacement=placeGraphAvoidingTooltips
