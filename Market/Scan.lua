-- Auctionator TradeScope 3.0.0 - watch Auctionator's actual database writes.
-- Every full scan and ordinary AH search feeds Database:SetPrice, so we record
-- precisely the keys Auctionator updated, never its unrelated stale cached keys.
local A = ATS

local function observe(_, dbKey, price, available)
  if not A.db or not A.db.enabled or not A.db.collectOnScan then return end
  if type(dbKey) ~= "string" or not A.Valid(price) then return end
  local changed = A.Record("db:" .. dbKey, price, "scan", available)
  if A.IndexScannedItem then A.IndexScannedItem(dbKey) end
  if changed and A.CheckMarketAlerts then A.CheckMarketAlerts("db:" .. dbKey, price, available) end
end

function A.InstallScanHook()
  A.Init()
  local auctionator = _G.Auctionator
  local database = type(auctionator) == "table" and auctionator.Database
  if type(database) ~= "table" or type(database.SetPrice) ~= "function" then
    A.scanHookStatus = A.L.SCAN_DB_UNAVAILABLE
    return false
  end
  if A.hookedDatabase == database then return true end

  -- The client-native hook is non-invasive and preserves Auctionator's logic.
  if type(hooksecurefunc) == "function" then
    local ok = pcall(hooksecurefunc, database, "SetPrice", observe)
    if ok then
      A.hookedDatabase = database
      A.scanHookStatus = A.L.SCAN_HOOK_SECURE
      return true
    end
  end

  -- Custom WoW Forever clients may not implement table-method secure hooks.
  local original = database.SetPrice
  database.SetPrice = function(self, ...)
    local result = original(self, ...)
    local ok, err = pcall(observe, self, ...)
    if not ok and A.lastError ~= tostring(err) then A.lastError = tostring(err) end
    return result
  end
  A.hookedDatabase = database
  A.scanHookStatus = A.L.SCAN_HOOK_FALLBACK
  return true
end

local attempts = 0
local retryFrame = CreateFrame("Frame")
retryFrame:RegisterEvent("PLAYER_LOGIN")
retryFrame:SetScript("OnEvent", function(self)
  if A.InstallScanHook() then return end
  -- Defensive retry in case the server fork initialises its database later.
  self:SetScript("OnUpdate", function(frame, elapsed)
    frame.elapsed = (frame.elapsed or 0) + elapsed
    if frame.elapsed < 2 then return end
    frame.elapsed = 0
    attempts = attempts + 1
    if A.InstallScanHook() or attempts >= 20 then frame:SetScript("OnUpdate", nil) end
  end)
end)
