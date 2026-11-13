-- Tooltip graph and delayed crafting preview lifecycle.
local A=ATS
local placeGraphAvoidingTooltips=assert(A.GraphPlacement, "GraphPlacement not loaded")
-- Crafting preview uses its own chart frame: it does not change the item's
-- normal tooltip state, watchlist selection, or the market terminal zoom.
-- The preview stays open when the pointer moves from a material onto its chart.
local function closeCraftPreview()
  local f=A.craftPreviewGraph
  local owner=f and f.previewSource
  if f then f:Hide();f.previewKey=nil;f.itemLink=nil;f.previewSource=nil end
  A.craftPreviewActive=false
  -- A protected item tooltip remains visible during graph interaction. Only
  -- dismiss it when the preview closes AND it still belongs to this item.
  if owner and owner.IsMouseOver and not owner:IsMouseOver() and
      GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner()==owner then
    GameTooltip:Hide()
  end
end
-- Crafting previews use the same graphDelay preference as inventory tooltips.
-- This one shared worker is intentionally used instead of one OnUpdate per
-- material; it is cheap even for recipes containing many ingredients.
local craftPreviewDelayWorker=CreateFrame("Frame")
craftPreviewDelayWorker:Hide()
local craftPreviewPending=nil
local function cancelPendingCraftPreview()
  craftPreviewPending=nil
  craftPreviewDelayWorker:Hide()
  if not (A.craftPreviewGraph and A.craftPreviewGraph:IsShown()) then
    A.craftPreviewActive=false
  end
end
function A.HideCraftPreview()
  cancelPendingCraftPreview()
  closeCraftPreview()
end
function A.DeferCraftPreview()
  cancelPendingCraftPreview()
  local f=A.craftPreviewGraph
  if f and f:IsShown() then f.leaveAt=GetTime()+0.85 end
end
function A.ShowCraftPreview(source,id)
  if not source or not id then return end
  A.Init()
  if A.db.enabled==false or A.db.showTooltip==false then return end
  local itemID=tonumber(id)
  if not itemID then return end
  local link="item:"..itemID
  local key=A.Key(link) or ("db:"..itemID)
  local f=A.craftPreviewGraph
  if not f then
    f=A.NewGraph(UIParent)
    A.craftPreviewGraph=f
    f:SetScript("OnUpdate",function(self,dt)
      self.checkElapsed=(self.checkElapsed or 0)+dt
      if self.checkElapsed<0.10 then return end
      self.checkElapsed=0
      local source=self.previewSource
      if source and source.IsShown and not source:IsShown() then
        closeCraftPreview()
      elseif source and source.IsMouseOver and source:IsMouseOver() then
        self.leaveAt=nil
      elseif self.IsMouseOver and self:IsMouseOver() then
        self.leaveAt=nil
      elseif self.leaveAt and GetTime()>=self.leaveAt then
        closeCraftPreview()
      end
    end)
    f:SetScript("OnLeave",function(self)
      self.leaveAt=GetTime()+0.35
    end)
    -- Depending on the WoW client, hovering a child hitbox does not always
    -- report IsMouseOver() on the containing frame. Track child entry too.
    for _, plot in pairs(f.charts or {}) do
      if plot.hitbox and plot.hitbox.HookScript then
        plot.hitbox:HookScript("OnEnter",function() f.leaveAt=nil end)
        plot.hitbox:HookScript("OnLeave",function() f.leaveAt=GetTime()+0.45 end)
      end
    end
  end
  A.craftPreviewActive=true
  if A.graph and A.graph:IsShown() then A.graph:Hide() end
  if f.previewKey~=key then f.zoomHours=nil end
  f.previewSource=source
  f.previewKey=key
  f.previewLegacy=link
  f.itemLink=link
  f.leaveAt=nil
  f.showItemHeader=true
  local ok,height=pcall(A.RenderGraph,f,key,link,nil)
  if not ok then
    A.lastError=tostring(height)
    closeCraftPreview()
    return
  end
  if not height or height<=0 then closeCraftPreview();return end
  -- The chart may be opened from a Pro row while the native tooltip and
  -- equipment comparison are already on screen. Keep all of them visible.
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(265)
  local anchor=(GameTooltip and GameTooltip.IsShown and GameTooltip:IsShown()
    and GameTooltip.GetOwner and GameTooltip:GetOwner()==source) and GameTooltip or source
  if not placeGraphAvoidingTooltips(f,anchor,1) then
    closeCraftPreview()
    return
  end
  f:Show()
end

-- Never show a new chart immediately when the pointer enters a recipe result
-- or ingredient. The normal WoW item tooltip is handled by ProUI and remains
-- available at once. The delayed graph opens only if the same source is still
-- hovered after the user's existing graphDelay setting has elapsed.
function A.ScheduleCraftPreview(source,id)
  if not source or not id then return end
  A.Init()
  if A.db.enabled==false or A.db.showTooltip==false then return end
  if not tonumber(id) then return end
  if not (source.IsShown and source:IsShown()) then return end
  cancelPendingCraftPreview()
  local f=A.craftPreviewGraph
  if f and f:IsShown() then closeCraftPreview() end
  local delay=tonumber(A.db.graphDelay) or 0.8
  if delay<=0 then
    A.ShowCraftPreview(source,id)
    return
  end
  craftPreviewPending={source=source,id=id,started=GetTime(),delay=delay}
  A.craftPreviewActive=true
  craftPreviewDelayWorker.elapsed=0
  craftPreviewDelayWorker:Show()
end
craftPreviewDelayWorker:SetScript("OnUpdate",function(self,dt)
  self.elapsed=(self.elapsed or 0)+dt
  if self.elapsed<0.05 then return end
  self.elapsed=0
  local pending=craftPreviewPending
  if not pending then self:Hide();return end
  local source=pending.source
  if not source or not source.IsShown or not source:IsShown() or
    (source.IsMouseOver and not source:IsMouseOver()) then
    cancelPendingCraftPreview()
    return
  end
  if GetTime()-pending.started < pending.delay then return end
  local id=pending.id
  cancelPendingCraftPreview()
  A.ShowCraftPreview(source,id)
end)

function A.Draw(tooltip,key,isTest,legacy)
  if not A.db.showTooltip and not isTest then A.Hide();return end
  if not A.graph then A.graph=A.NewGraph(UIParent) end
  local frame=A.graph
  frame.showItemHeader=true
  local height=A.RenderGraph(frame,key,legacy,nil)
  if not height or height==0 then return end
  -- Prefer the side of the item tooltip, then an unused region above/below.
  -- ShoppingTooltip1/2 and ItemRef comparisons are protected from overlap.
  if not placeGraphAvoidingTooltips(frame,tooltip,1) then
    frame:Hide()
  end
end
