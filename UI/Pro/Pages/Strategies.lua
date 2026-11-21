-- TradeScope 4.6.0-beta1: read-only strategy evidence dashboard.
local A=ATS
local C=assert(A.ProUIShared)
local B=assert(A.ProUIBuilders)
local l,fs,tex,button,newPage,heading,currency=C.l,C.fs,C.tex,C.button,C.newPage,C.heading,C.currency
local PAGESIZE=5
local titles={
 discount={"Value watch","Поиск скидки"},
 exit={"Exit review","Проверка выхода"},
 exposure={"Concentration","Концентрация"},
}
local function desc(kind)
 if kind=="discount" then
   return l("Fresh scanner discounts with quality, risk and supply gates. Not a buy order.",
     "Скидки по свежему сканеру с проверкой качества, риска и предложения. Не приказ покупать.")
 elseif kind=="exit" then
   return l("Known-cost open lots with estimated 10%+ net ROI. Price is not a verified sale.",
     "Открытые лоты с себестоимостью и оценкой ROI от 10%. Цена не подтверждённая продажа.")
 end
 return l("One item with 50%+ of quoted bag value. Missing prices may distort shares.",
   "Один предмет занимает от 50% оценённой стоимости сумок. Неучтённые цены искажают доли.")
end
local function detail(entry)
 if entry.kind=="discount" then
   return string.format(l("Median discount %.1f%%   Quality %d/100   Risk %d/100",
     "Скидка к медиане %.1f%%   Качество %d/100   Риск %d/100"),
      entry.discount,entry.quality,entry.risk)
 elseif entry.kind=="exit" then
   return l("Cost ","Себест. ")..currency(entry.cost)..
     l("   Estimated NET ","   Оценка после комиссии ")..currency(entry.net)
 end
 return l("Share of valued bags: ","Доля в оценённых сумках: ")..
   string.format("%.1f%%",entry.share)..
   (entry.singleItem and l(" (only valued item)"," (единственный оценённый)") or "")
end
local function metric(entry)
 if entry.kind=="discount" then
   return string.format("%.1f%%   S:%d R:%d",entry.discount,entry.score,entry.risk)
 elseif entry.kind=="exit" then
   return string.format("ROI %.1f%%   ",entry.roi)..currency(entry.profit)
 end
 return string.format("%.1f%%   ",entry.share)..currency(entry.value)
end
local function tooltip(row,entry)
 if not GameTooltip then return end
 GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
 GameTooltip:SetText(A.ProItemName(entry.key))
 if entry.kind=="discount" then
   GameTooltip:AddLine(l("Last observed price: ","Последняя наблюдаемая цена: ")..currency(entry.price),.85,.92,1)
   GameTooltip:AddLine(l("Scanned median: ","Медиана сканирования: ")..currency(entry.median),.85,.92,1)
   GameTooltip:AddLine(string.format(l("Score: %d   Risk: %d   Samples: %d",
     "Рейтинг: %d   Риск: %d   Замеров: %d"),entry.score,entry.risk,entry.quality),1,.85,.43)
   GameTooltip:AddLine(l("Supply is historical listings, not confirmed demand.",
     "Предложение — наблюдаемые лоты, а не подтверждённый спрос."),1,.72,.46,true)
 elseif entry.kind=="exit" then
   GameTooltip:AddLine(l("Open units: ","Открытых единиц: ")..tostring(entry.qty),.85,.92,1)
   GameTooltip:AddLine(l("Known acquisition cost: ","Известная закупка: ")..currency(entry.cost),.85,.92,1)
   GameTooltip:AddLine(l("Est. net proceeds after auction fee: ",
     "Оценка поступления после комиссии: ")..currency(entry.net),.85,.92,1)
   GameTooltip:AddLine(l("Unrealized scenario, not a sale confirmation.",
     "Расчётный сценарий, а не подтверждённая продажа."),1,.72,.46,true)
 else
   GameTooltip:AddLine(l("Current bag market valuation only; acquisition cost unknown.",
     "Только оценка сумок; себестоимость неизвестна."),1,.74,.43,true)
 end
 GameTooltip:AddLine(l("Click to inspect this item's market history.",
   "Нажмите для просмотра рыночной истории предмета."),.70,.84,.93)
 GameTooltip:Show()
end
function B.strategies(root)
 local p=newPage(root)
 p.mode="discount";p.pageIndex=1
 heading(p,l("Trading strategies: evidence, not automated trading",
   "Торговые стратегии: аналитика, не автоторговля"),-12)
 local kinds,defs=A.StrategyKinds()
 local options={}
 for _,kind in ipairs(kinds) do options[#options+1]={value=kind,text=l(defs[kind].en,defs[kind].ru)} end
 p.profile=C.dropdown(p,l("Strategy profile","Профиль стратегии"),20,-54,240,options,
   function()return p.mode end,function(value)p.mode=value;p.pageIndex=1;p.update()end)
 button(p,l("Refresh","Обновить"),275,-54,124,function()p.update()end)
 button(p,l("Market scanner","Сканер рынка"),414,-54,170,function()A.ShowProTab("scanner")end)
 p.counter=fs(p,"",20,-97,692,true)
 p.description=fs(p,"",20,-126,700)
 tex(p,20,-160,698,1,.48,.37,.17,.75)
 p.column=fs(p,l("CANDIDATES / REVIEW QUEUE","КАНДИДАТЫ / СПИСОК НА ПРОВЕРКУ"),20,-171,695,true)
 p.rows={}
 for i=1,PAGESIZE do
   local row=CreateFrame("Button",nil,p)
   row:SetSize(697,45)
   row:SetPoint("TOPLEFT",p,"TOPLEFT",20,-197-(i-1)*48)
   row:EnableMouse(true)
   local bg=tex(row,0,0,697,44,.075,.106,.128,.9)
   local line=tex(row,0,-43,697,1,.43,.33,.17,.60)
   C.attachProRowIcon(row,8,23)
   row.title=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
   row.title:SetPoint("TOPLEFT",row,"TOPLEFT",40,-6)
   row.title:SetWidth(282);row.title:SetJustifyH("LEFT")
   if row.title.SetWordWrap then row.title:SetWordWrap(false) end
   row.metric=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
   row.metric:SetPoint("TOPRIGHT",row,"TOPRIGHT",-11,-7)
   row.metric:SetWidth(357);row.metric:SetJustifyH("RIGHT")
   row.more=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
   row.more:SetPoint("TOPLEFT",row,"TOPLEFT",40,-26)
   row.more:SetWidth(640);row.more:SetJustifyH("LEFT")
   if row.more.SetWordWrap then row.more:SetWordWrap(false) end
   row.bg=bg
   row:SetScript("OnEnter",function(self)
      self.bg:SetVertexColor(.18,.18,.14,.98)
      if self.entry then tooltip(self,self.entry) end
   end)
   row:SetScript("OnLeave",function(self)
      self.bg:SetVertexColor(.075,.106,.128,.9)
      if GameTooltip then GameTooltip:Hide() end
   end)
   row:SetScript("OnClick",function(self)
     if self.entry and C.inspect then C.inspect(self.entry.key) end
   end)
   row:Hide()
   p.rows[i]=row
 end
 p.empty=fs(p,"",30,-293,676)
 p.warning=fs(p,"",20,-446,696)
 p.warning:SetTextColor(1,.78,.46)
 p.prev=button(p,l("< Back","< Назад"),20,-499,122,function()
   p.pageIndex=math.max(1,p.pageIndex-1);p.update()
 end)
 p.pageText=fs(p,"",157,-506,390)
 p.next=button(p,l("Next >","Вперёд >"),589,-499,125,function()
   p.pageIndex=p.pageIndex+1;p.update()
 end)
 p.update=function()
   local result=A.StrategySnapshot(p.mode)
   p.profile:SetText(l(titles[p.mode][1],titles[p.mode][2]))
   p.description:SetText(desc(p.mode))
   p.counter:SetText(l("Qualified: ","Прошли проверку: ")..#result.rows..
     l("   Reviewed: ","   Рассмотрено: ")..(result.considered or 0)..
     l("   Rejected: ","   Отклонено: ")..(result.excluded or 0))
   local warnings={}
   if not result.sourceKnown then
     warnings[#warnings+1]=(p.mode=="discount") and
       l("Scanner results are missing or older than 24h: rescan in Market Scanner.",
         "Нет сканирования или оно старше 24 ч: обновите «Сканер рынка».") or
       l("Source is unavailable; open bags or refresh history.",
         "Источник недоступен; проверьте сумки или историю.")
   end
   if result.reasons and (result.reasons.partial_quotes or 0)>0 then
     warnings[#warnings+1]=l("Valuation excludes stale/missing prices.",
       "Оценка исключает устаревшие или отсутствующие цены.")
   end
   warnings[#warnings+1]=l("No automated orders. Neither signals nor prices guarantee a sale.",
     "Автосделок нет. Сигналы и цены не гарантируют продажу.")
   p.warning:SetText(table.concat(warnings,"   |   "))
   local total=#result.rows
   local pages=math.max(1,math.ceil(total/PAGESIZE))
   p.pageIndex=math.max(1,math.min(p.pageIndex,pages))
   p.pageText:SetText(l("Page ","Страница ")..p.pageIndex.." / "..pages)
   if p.prev.SetEnabled then p.prev:SetEnabled(p.pageIndex>1) end
   if p.next.SetEnabled then p.next:SetEnabled(p.pageIndex<pages) end
   if total==0 then
     p.empty:SetText(result.sourceKnown and
       l("No candidates meet the profile's evidence and risk requirements.",
         "Нет кандидатов, прошедших фильтры данных и риска.") or
       l("No reliable source data yet.","Пока нет надёжных исходных данных."))
     p.empty:Show()
   else p.empty:Hide() end
   for i,row in ipairs(p.rows) do
     local entry=result.rows[(p.pageIndex-1)*PAGESIZE+i]
     row.entry=entry
     if entry then
       local name=C.renderProRowItem(row,entry.key) or A.ProItemName(entry.key)
       if A.FitItemName then name=A.FitItemName(name,row.title,282) or name end
       row.title:SetText(name)
       row.metric:SetText(metric(entry))
       row.more:SetText(detail(entry))
       row:Show()
     else
       C.renderProRowItem(row,nil)
       row.title:SetText("");row.metric:SetText("");row.more:SetText("")
       row:Hide()
     end
   end
 end
 p.update()
 if C.watchProRowIcons then C.watchProRowIcons(p,p.rows) end
 return p
end
