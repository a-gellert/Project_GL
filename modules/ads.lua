-- Thin wrapper over Poki SDK. Off-portal (desktop debug) everything succeeds instantly.
local M = {}

local function has_poki()
	return poki_sdk ~= nil
end

function M.gameplay_start()
	if has_poki() then poki_sdk.gameplay_start() end
end

function M.gameplay_stop()
	if has_poki() then poki_sdk.gameplay_stop() end
end

-- Interstitial between tournament series. callback() runs when the ad is over (or skipped).
function M.interstitial(callback)
	if not has_poki() then
		callback()
		return
	end
	poki_sdk.commercial_break(function(_, status)
		if status == poki_sdk.COMMERCIAL_BREAK_SUCCESS then
			callback()
		end
	end)
end

-- Rewarded video. callback(rewarded: boolean).
function M.rewarded(callback)
	if not has_poki() then
		callback(true)
		return
	end
	poki_sdk.rewarded_break("small", function(_, status)
		if status == poki_sdk.REWARDED_BREAK_SUCCESS then
			callback(true)
		elseif status == poki_sdk.REWARDED_BREAK_ERROR then
			callback(false)
		end
	end)
end

return M
