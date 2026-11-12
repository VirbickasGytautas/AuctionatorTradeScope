-- TradeScope 3.5.1: trader research and WoW Forever-compatible help tooltips.
local A=ATS
local function label(parent,width,x,y,font)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  t:SetWidth(width)
  t:SetJustifyH("LEFT")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  return t
end
local function texture(parent,x,y,w,h,r,g,b,a)
  local t=parent:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,a or 1)
  t:SetSize(w,h)
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  return t
end
local function formatPercent(n)
  return n and string.format("%+.1f%%",n) or A.L.NO_DATA
end
local function formatUnsigned(n)
  return n and string.format("%.1f%%",n) or A.L.NO_DATA
end
local function signedMoney(value)
  if type(value)~="number" then return A.L.NO_DATA end
  if value<0 then return "-"..A.Money(-value) end
  return A.Money(value)
end
local function coinIcon(offset)
  return "|TInterface\\MoneyFrame\\UI-MoneyIcons:14:14:0:0:64:16:" .. offset .. ":" .. (offset+16) .. ":0:16|t"
end
local function box(parent,name,x,y,width,maxLetters)
  local b=CreateFrame("EditBox",name,parent,"InputBoxTemplate")
  b:SetSize(width,23)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetAutoFocus(false)
  b:SetMaxLetters(maxLetters)
  if type(b.SetNumeric)=="function" then b:SetNumeric(true) end
  return b
end
local function helpButton(parent,x,y,descriptionKey)
  local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  button:SetSize(21,20)
  button:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  button:SetText("?")
  if A.StyleButton then A.StyleButton(button,"secondary") end
  button:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(A.L[descriptionKey] or "")
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  return button
end

function A.NewTradePanel(parent)
  local f=CreateFrame("Frame",nil,parent)
  f:SetSize(659,351)
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",261,-245)
  f:SetFrameLevel(parent:GetFrameLevel()+6)
  -- The host terminal already supplies the window background and opacity.
  texture(f,0,0,659,350,.035,.055,.077,0)
  texture(f,10,-167,639,1,.38,.31,.15,.95)
  texture(f,10,-322,639,1,.27,.33,.39,.78)
  f.leftTitle=label(f,306,13,-10,"GameFontNormal")
  f.rightTitle=label(f,311,340,-10,"GameFontNormal")
  f.left={};f.right={}
  for i=1,5 do
    f.left[i]=label(f,305,13,-37-(i-1)*24)
    f.right[i]=label(f,305,340,-37-(i-1)*24)
  end
  f.calcTitle=label(f,590,13,-178,"GameFontNormal")
  helpButton(f,627,-174,"TOOLS_PNL_HELP")
  f.buyCaption=label(f,132,13,-211)
  f.buyGold=box(f,"ATSTradeBuyGold",145,-203,51,9)
  f.goldIcon=label(f,18,201,-208)
  f.goldIcon:SetText(coinIcon(0))
  f.buySilver=box(f,"ATSTradeBuySilver",225,-203,43,2)
  f.silverIcon=label(f,18,271,-208)
  f.silverIcon:SetText(coinIcon(16))
  f.buyCopper=box(f,"ATSTradeBuyCopper",295,-203,43,2)
  f.copperIcon=label(f,18,342,-208)
  f.copperIcon:SetText(coinIcon(32))
  f.qtyCaption=label(f,75,370,-211)
  f.quantity=box(f,"ATSTradeQty",445,-203,64,7)
  f.feeCaption=label(f,140,517,-211)

  f.unitSale=label(f,300,13,-240)
  f.unitNet=label(f,307,338,-240)
  f.totalBuy=label(f,300,13,-264)
  f.totalNet=label(f,307,338,-264)
  f.result=label(f,394,13,-288)
  f.roi=label(f,234,411,-288)
  f.breakEven=label(f,560,13,-309)
  helpButton(f,627,-303,"TOOLS_BREAK_EVEN_HELP")
  f.advice=label(f,632,13,-330)
  f.advice:SetTextColor(1,.82,.37)

  local function commit()
    if f.committing then return end
    if not parent.key then return end
    f.committing=true
    local goldText=f.buyGold:GetText() or ""
    local silverText=f.buySilver:GetText() or ""
    local copperText=f.buyCopper:GetText() or ""
    local hadInput=goldText~="" or silverText~="" or copperText~=""
    if hadInput then
      local gold=math.max(0,math.min(100000000,math.floor(tonumber(goldText) or 0)))
      local silver=math.max(0,math.min(99,math.floor(tonumber(silverText) or 0)))
      local copper=math.max(0,math.min(99,math.floor(tonumber(copperText) or 0)))
      A.SetTradeBuy(parent.key,gold*10000+silver*100+copper)
    else
      A.SetTradeBuy(parent.key,nil)
    end
    local quantity=tonumber(f.quantity:GetText()) or 1
    quantity=math.max(1,math.min(1000000,math.floor(quantity)))
    A.SetTradeQuantity(parent.key,quantity)
    f.committing=false
    A.UpdateTradePanel(parent)
  end
  for _,edit in ipairs({f.buyGold,f.buySilver,f.buyCopper,f.quantity}) do
    edit:SetScript("OnEnterPressed",function(self)
      commit()
      self:ClearFocus()
    end)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusLost",function()
      if parent.showTools and not f.committing then commit() end
    end)
  end
  f:Hide()
  return f
end

function A.UpdateTradePanel(parent)
  local f=parent and parent.tradePanel
  if not f or not parent.key then return end
  local all=A.AllSamples(parent.key,parent.legacy)
  local hours=(parent.graph and parent.graph.zoomHours) or A.ChartHours(parent.key,parent.legacy,all)
  local data=A.TradeSnapshot(parent.key,parent.legacy,all,hours)
  local m=data.metrics
  f.leftTitle:SetText(A.L.TOOLS_PRICE)
  f.rightTitle:SetText(A.L.TOOLS_SUPPLY)
  f.left[1]:SetText(A.L.TOOLS_DELTA24..": "..formatPercent(data.dayChange))
  f.left[2]:SetText(A.L.TOOLS_MEDIAN_DEV..": "..formatPercent(data.medianDeviation))
  f.left[3]:SetText(A.L.TOOLS_POSITION..": "..formatUnsigned(data.position))
  f.left[4]:SetText(A.L.TOOLS_RANGE..": "..formatUnsigned(data.range))
  f.left[5]:SetText(A.L.TOOLS_AGE..": "..(data.ageHours and string.format("%.1f %s",data.ageHours,A.L.HOURS_SHORT) or "-"))
  f.right[1]:SetText(A.L.METRIC_SUPPLY..": "..A.FmtCount(m.currentQuantity))
  f.right[2]:SetText(A.L.TOOLS_DROP24..": "..A.FmtCount(m.estimatedDrops24))
  f.right[3]:SetText(A.L.TOOLS_PRESSURE..": "..formatUnsigned(data.depletion))
  f.right[4]:SetText(A.L.TOOLS_SAMPLES24..": "..tostring(data.total24))
  f.right[5]:SetText(A.L.TOOLS_CONFIDENCE..": "..(A.L["TOOLS_CONF_"..string.upper(data.confidence)] or "-"))
  f.calcTitle:SetText(A.L.TOOLS_CALCULATOR)
  f.buyCaption:SetText(A.L.TOOLS_BUY)
  f.qtyCaption:SetText(A.L.TOOLS_QUANTITY)
  f.feeCaption:SetText(A.L.TOOLS_FEE_SHORT..": "..tostring(A.db.tradeFee).."%")

  local buy=A.GetTradeBuy(parent.key)
  local quantity=A.GetTradeQuantity(parent.key)
  if f.loadedKey~=parent.key then
    f.loadedKey=parent.key
    if buy then
      f.buyGold:SetText(tostring(math.floor(buy/10000)))
      f.buySilver:SetText(tostring(math.floor(buy/100)%100))
      f.buyCopper:SetText(tostring(buy%100))
    else
      f.buyGold:SetText("");f.buySilver:SetText("");f.buyCopper:SetText("")
    end
    f.quantity:SetText(tostring(quantity))
  end

  local deal=A.CalculateTrade(buy,m.currentPrice,A.db.tradeFee,quantity)
  if deal then
    f.unitSale:SetText(A.L.TOOLS_UNIT_PRICE..": "..A.Money(deal.sell))
    f.unitNet:SetText(A.L.TOOLS_UNIT_NET..": "..A.Money(deal.net))
    f.totalBuy:SetText(A.L.TOOLS_TOTAL_BUY..": "..A.Money(deal.totalBuy))
    f.totalNet:SetText(A.L.TOOLS_TOTAL_NET..": "..A.Money(deal.totalNet))
    f.result:SetText(A.L.TOOLS_TOTAL_PNL..": "..signedMoney(deal.totalProfit))
    f.result:SetTextColor(deal.totalProfit>=0 and 0.35 or 1,deal.totalProfit>=0 and 1 or 0.43,deal.totalProfit>=0 and 0.55 or 0.43)
    f.roi:SetText("ROI: "..(deal.roi and string.format("%+.1f%%",deal.roi) or "-"))
    f.breakEven:SetText(A.L.TOOLS_BREAKEVEN..": "..A.Money(deal.breakEven))
  else
    f.unitSale:SetText(A.L.TOOLS_UNIT_PRICE..": "..A.Money(m.currentPrice))
    f.unitNet:SetText(A.L.TOOLS_UNIT_NET..": -")
    f.totalBuy:SetText(A.L.TOOLS_TOTAL_BUY..": -")
    f.totalNet:SetText(A.L.TOOLS_TOTAL_NET..": -")
    f.result:SetText(A.L.TOOLS_ENTER_BUY)
    f.result:SetTextColor(0.90,0.83,0.57)
    f.roi:SetText("")
    f.breakEven:SetText("")
  end
  local advice=A.L["TOOLS_GUIDE_"..string.upper(data.guidance)] or A.L.TOOLS_GUIDE_INSUFFICIENT
  if not A.db.showTradeAdvice then advice=A.L.TOOLS_CAUTION end
  f.advice:SetText(advice)
end
