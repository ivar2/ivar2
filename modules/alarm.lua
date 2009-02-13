local func = function(self, data)
	self:privmsg(data.dst, '%s: Timer finished.', data.nick)
end

return {
	["^:(%S+) PRIVMSG (%S+) :!alarm (%S+)$"] = function(self, src, dest, msg)
		if(not msg) then
			-- usage:
		else
			local timer = os.time()

			local hour = msg:match'(%d+)h'
			local min = msg:match'(%d+)m'
			local sec = msg:match'(%d+)s'

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

					name = 'Alarm:' .. nick,
					func = func,
					callTime = timer,
					oneCall = true,
				})
			end
		end
	end
}
