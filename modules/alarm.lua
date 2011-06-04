local func = function(self, data)
	self:msg(data.dst, data.src, '%s: %s', data.nick, data.msg)
end

local send = function(self, dst, fmt, ...)
	if(select('#', ...) > 0) then
		local succ, err = pcall(string.format, fmt, ...)
		if(not succ) then
			self:log('ERROR', 'Failed string.format: ' .. tostring(err) .. ' Traceback' .. debug.traceback())

			return
		end

		fmt = err
	end

	self:log('INFO', fmt)
	self:send('NOTICE %s :%s', dst, fmt)
end

local notice = function(self, dst, src, ...)
	local srcnick = self:srctonick(src)
	send(self, srcnick, ...)
end

local timeTable = {
	24 * 60 * 60, -- day
	60 * 60, -- hour
	60, -- minute
	1, -- seconds
}

local timeStrings = {
	'd', 'd', -- days, day
	'h', 'h', -- hours, hour
	'm', 'm', -- minutes, minute
	's', 's', -- seconds, second
}

local getRelativeTime = function(t1, t2, T, L)
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

	return out:sub(1, -2)
end

local alarm = function(self, src, dest, time, msg)
	if(not time) then
		-- usage:
	else
		local timer = os.time()

		local hour = time:match'(%d+)[ht]'
		local min = time:match'(%d+)m'
		local sec = time:match'(%d+)s'

		if(hour) then timer = timer + (hour * 60 * 60) end
		if(min) then timer = timer + (min * 60) end
		if(sec) then timer = timer + sec end

		if(timer ~= os.time()) then
			local timers = self.timers
			local nick = self:srctonick(src)
			local id = 'Alarm:' .. nick
			if(timers) then
				for index, timerData in pairs(timers) do
					if(timerData.name == id) then
						table.remove(timers, index)
						break;
					end
				end
			else
				timers = {}
				self.timers = timers
			end

			notice(self, dest, src, "I'll poke you in %s.", getRelativeTime(timer))

			table.insert(timers, {
				nick = nick,
				dst = dest,
				src = src,
				msg = (#msg > 0 and msg) or 'Timer finished.',

				name = id,
				func = func,
				callTime = timer,
				oneCall = true,
			})
		end
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!alarm (%S+)%s?(.*)"] = alarm,
	["^:(%S+) PRIVMSG (%S+) :!timer (%S+)%s?(.*)"] = alarm,
}
