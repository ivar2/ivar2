local func = function(self, data)
	self:privmsg(data.dst, '%s: %s.', data.nick, data.msg)
end

return {
	["^:(%S+) PRIVMSG (%S+) :!alarm (%S+)%s?(.*)"] = function(self, src, dest, time, msg)
		if(not time) then
			-- usage:
		else
			local timer = os.time()

			local hour = time:match'(%d+)h'
			local min = time:match'(%d+)m'
			local sec = time:match'(%d+)s'

			if(hour) then timer = timer + (hour * 60 * 60) end
			if(min) then timer = timer + (min * 60) end
			if(sec) then timer = timer + sec end

			if(timer ~= os.time()) then
				local timers = self.timers
				if(timers) then
					for index, timerData in pairs(timers) do
						if(timerData.name == src) then
							table.remove(timers, index)
							break;
						end
					end
				else
					timers = {}
					self.timers = timers
				end

				local nick = self:srctonick(src)
				table.insert(timers, {
					nick = nick,
					dst = dest,
					msg = (#msg > 0 and msg) or 'Timer finished',

					name = 'Alarm:' .. nick,
					func = func,
					callTime = timer,
					oneCall = true,
				})
			end
		end
	end
}
