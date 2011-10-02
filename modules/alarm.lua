local ev = require'ev'

if(not ivar2.timers) then ivar2.timers = {} end

local dateFormat = '%Y-%m-%d %X %Z'

local alarm = function(self, source, destination, time, message)
	local weeks = time:match'(%d+)[w]'
	local days = time:match'(%d+)[d]'
	local hour = time:match'(%d+)[ht]'
	local min = time:match'(%d+)m'
	local sec = time:match'(%d+)s'

	local duration = 0
	if(weeks) then duration = duration + (weeks * 60 * 60 * 24 * 7) end
	if(days) then duration = duration + (days * 60 * 60 * 24) end
	if(hour) then duration = duration + (hour * 60 * 60) end
	if(min) then duration = duration + (min * 60) end
	if(sec) then duration = duration + sec end

	-- 60 days or more?
	local nick = source.nick
	if(duration >= (60 * 60 * 24 * 60) or duration == 0) then
		return self:Msg('privmsg', destination, source, "%s: :'(", nick)
	end

	local id = 'Alarm: ' .. nick
	local runningTimer = self.timers[id]
	if(runningTimer) then
		-- Send a notification if we are overriding an old timer.
		if(runningTimer.utimestamp > os.time()) then
			if(runningTimer.message) then
				self:Notice(
					nick,
					'Previously active timer set to trigger at %s with message "%s" has been removed.',
					os.date(dateFormat, runningTimer.utimestamp),
					runningTimer.message
				)
			else
				self:Notice(
					nick,
					'Previously active timer set to trigger at %s has been removed.',
					os.date(dateFormat, runningTimer.utimestamp)
				)
			end
		end

		-- message is probably changed.
		runningTimer:stop(ivar2.Loop)
	end

	local timer = ev.Timer.new(
		function(loop, timer, revents)
			if(#message == 0) then message = 'Timer finished.' end
			self:Msg('privmsg', destination, source, '%s: %s', nick, message or 'Timer finished.')
		end,
		duration
	)

	if(#message > 0) then timer.message = message end
	timer.utimestamp = os.time() + duration

	self:Notice(nick, "I'll poke you at %s.", os.date(dateFormat, timer.utimestamp))

	self.timers[id] = timer
	timer:start(ivar2.Loop)
end

return {
	PRIVMSG = {
		['^!alarm (%S+)%s?(.*)'] = alarm,
		['^!timer (%S+)%s?(.*)'] = alarm,
	},
}
