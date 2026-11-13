-- Historical market indicators; all indicators derive from locally observed snapshots.
local A = ATS

local function pct(from, to)
  if not A.Valid(from) or type(to) ~= "number" then return nil end
  return 100 * (to - from) / from
end

function A.MarketMetrics(key, legacyKey, samples, hours)
  local all = samples or A.AllSamples(key, legacyKey)
  local span = math.max(1, hours or A.ChartHours(key, legacyKey, all)) * 3600
  local now = time()
  local cutoff = now - span
  local recent, prices, sums = {}, {}, {price = 0, sq = 0}
  local minPrice, maxPrice, firstPrice, lastPrice
  local lastPriceTime = nil
  local quantityFirst, quantityLast, quantityTime = nil, nil, nil
  local qty24First, qty24Last, qty24Samples, drops24 = nil, nil, 0, 0
  local previous24 = nil
  local previous24Time = nil
  local maxCompareSeconds = math.max(1,tonumber(A.db.maxCompareGapHours) or 12)*3600
  local cutoff24 = now - 86400
  local previousAll = nil
  for i = 1, #all do
    local point = all[i]
    if point.t >= cutoff and point.t <= now then
      recent[#recent + 1] = point
      if A.Valid(point.price) then
        prices[#prices + 1] = point.price
        firstPrice = firstPrice or point.price
        lastPrice = point.price
        lastPriceTime = point.t
        minPrice = math.min(minPrice or point.price, point.price)
        maxPrice = math.max(maxPrice or point.price, point.price)
        sums.price = sums.price + point.price
        sums.sq = sums.sq + point.price * point.price
      end
      if type(point.quantity) == "number" then
        quantityFirst = quantityFirst or point.quantity
        quantityLast, quantityTime = point.quantity, point.t
      end
    end
    if point.t >= cutoff24 and point.t <= now and type(point.quantity) == "number" then
      qty24Samples = qty24Samples + 1
      qty24First = qty24First or point.quantity
      qty24Last = point.quantity
      if previous24 ~= nil and previous24 > point.quantity and previous24Time and
          point.t - previous24Time <= maxCompareSeconds then
        drops24 = drops24 + previous24 - point.quantity
      end
      previous24 = point.quantity
      previous24Time = point.t
    end
    if point.t <= now and type(point.quantity) == "number" then previousAll = point end
  end
  -- Current quantity = last known, not necessarily current live order-book depth.
  if previousAll then quantityLast, quantityTime = previousAll.quantity, previousAll.t end
  local count = #prices
  local avg = count > 0 and sums.price / count or nil
  local median
  if count > 0 then
    local sorted = {}
    for i = 1, count do sorted[i] = prices[i] end
    table.sort(sorted)
    if count % 2 == 0 then median = (sorted[count/2] + sorted[count/2+1]) / 2
    else median = sorted[math.floor(count/2)+1] end
  end
  local volatility
  if count >= 2 and avg > 0 then
    local variance = math.max(0, sums.sq / count - avg * avg)
    volatility = math.sqrt(variance) / avg * 100
  end
  local movingAverage
  if count > 0 then
    local n = math.min(count, A.db.maWindow)
    local total = 0
    for i = count-n+1, count do total = total + prices[i] end
    movingAverage = total / n
  end
  local lastVsMean = pct(avg, lastPrice)
  local trend = pct(firstPrice, lastPrice)
  local supplyChange = pct(quantityFirst, quantityLast)
  local signal = "insufficient"
  if count >= A.db.minSignalSamples and lastVsMean then
    if lastVsMean <= -A.db.signalThreshold then signal = "below"
    elseif lastVsMean >= A.db.signalThreshold then signal = "above"
    else signal = "normal" end
  end
  return {
    observations = #recent, priceObservations = count,
    currentPrice = lastPrice, lastPriceTime = lastPriceTime,
    minPrice = minPrice, maxPrice = maxPrice, average = avg, median = median,
    changePct = trend, meanDeviation = lastVsMean, volatility = volatility,
    movingAverage = movingAverage, signal = signal,
    currentQuantity = quantityLast, lastQuantityTime = quantityTime,
    firstQuantity = quantityFirst, supplyPct = supplyChange,
    estimatedDrops24 = qty24Samples >= 2 and drops24 or nil,
    quantitySamples24 = qty24Samples,
    periodHours = hours,
  }
end

function A.SalesSeries(samples, hours, now)
  -- Only *observed* consecutive decreases count, and not necessarily sales.
  local span = math.max(3600, hours * 3600)
  local startTime = now - span
  local bucketHours = hours <= 48 and 1 or (hours <= 168 and 6 or (hours <= 720 and 24 or math.max(24, math.ceil(hours / 40))))
  local seconds = bucketHours * 3600
  local bucketCount = math.ceil(span / seconds)
  local buckets, observed = {}, 0
  local lastQty, lastQtyTime = nil, nil
  local maxCompareSeconds = math.max(1,tonumber(A.db.maxCompareGapHours) or 12)*3600
  for i = 1, #samples do
    local p = samples[i]
    if p.quantity ~= nil then
      if p.t >= startTime and p.t <= now then
        observed = observed + 1
        local bucket = math.max(1, math.min(bucketCount, math.floor((p.t - startTime) / seconds) + 1))
        buckets[bucket] = buckets[bucket] or { observed = 0, declines = 0 }
        buckets[bucket].observed = buckets[bucket].observed + 1
        if lastQty and lastQtyTime and p.t-lastQtyTime<=maxCompareSeconds and
            lastQty > p.quantity then
          buckets[bucket].declines = buckets[bucket].declines + lastQty - p.quantity
        end
      end
      -- Never bridge a long gap or compare against a stale pre-window count.
      if p.t >= startTime then lastQty=p.quantity;lastQtyTime=p.t end
    end
  end
  local result = {}
  for i = 1, bucketCount do
    local entry = buckets[i]
    if entry then
      result[#result + 1] = {
        t = math.min(now, startTime + (i-0.5)*seconds),
        value = entry.declines, observations = entry.observed,
      }
    end
  end
  return result, seconds, observed
end

function A.FmtCount(n)
  return n ~= nil and tostring(math.floor(n + 0.5)) or "-"
end
function A.FmtPercent(n)
  if n == nil then return "-" end
  return string.format("%+.1f%%", n)
end
function A.FmtVolatility(n)
  if n == nil then return "-" end
  return string.format("%.1f%%", n)
end
function A.SignalText(name)
  return A.L["SIGNAL_" .. string.upper(name or "insufficient")] or A.L.NO_DATA
end
