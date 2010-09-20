module(..., package.seeall)

do
	local timeTable = {
		12 * 30 * 24 * 60 * 60, -- year
		30 * 24 * 60 * 60, --month
		7 * 24 * 60 * 60, --week
		24 * 60 * 60, -- day
		60 * 60, -- hour
		60, -- minute
		1, -- second
	}

	local timeStrings = {
		'years', 'year',
		'months', 'month',
		'weeks', 'week',
		'days', 'day',
		'hours', 'hour',
		'minutes', 'minute',
		'seconds', 'second',
	}

	function relativeTime(t1,t2, T, L)
		if(not t1) then return end
		if(not t2) then t2 = os.time() end
		if(t2 > t1) then t2, t1 = t1, t2 end

		-- Fallbacks
		T = T or timeTable
		L = L or timeStrings

		local out
		local diff = t1 - t2
		for i=1, #T do
			local div = T[i]
			local n = math.modf(diff / div)
			if(n > 0) then
				out = string.format(
				'%s%d%s ',
				out or '', n, L[(n ~= 1 and i * 2) or (i * 2) - 1])
				diff = diff % div
			end
		end

		if(out) then
			return out:sub(1, -2)
		end
	end
end

do
	local timeTable = {
		7 * 24 * 60 * 60, --week
		24 * 60 * 60, -- day
		60 * 60, -- hour
		60, -- minute
		1, -- second
	}

	local timeStrings = {
		'w', 'w', -- weeks, week
		'd', 'd', -- days, day
		'h', 'h', -- hours, hour
		'm', 'm', -- minutes, minute
		's', 's', -- seconds, second
	}

	function relativeTimeShort(t1, t2)
		return relativeTime(t1, t2, timeTable, timeStrings)
	end
end
