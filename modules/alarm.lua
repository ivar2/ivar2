local ev = require'ev'
local date = require'date'

if(not ivar2.timers) then ivar2.timers = {} end

local alarm = function(self, source, destination, time, message)
	local hour = time:match'(%d+)[ht]'
	local min = time:match'(%d+)m'
	local sec = time:match'(%d+)s'

	local duration = 0
	if(hour) then duration = duration + (hour * 60 * 60) end
	if(min) then duration = duration + (min * 60) end
	if(sec) then duration = duration + sec end

	-- 60 days or more?
	local nick = source.nick
	if(duration >= (60 * 60 * 24 * 60) or duration == 0) then
		return self:Msg(dest, src, "%s: :'(", nick)
	end

	local id = 'Alarm: ' .. nick
	if(self.timers[id]) then
		-- message is probably changed.
		self.timers[id]:stop(ivar2.Loop)
	end

	local timer = ev.Timer.new(
		function(loop, timer, revents)
			if(#message == 0) then message = 'Timer finished.' end
			self:Msg('privmsg', destination, source, '%s: %s', nick, message or 'Timer finished.')
		end,
		duration
	)

	-- I implemented getRelativeTimeShort and was like... FFFUUUuu this is just
	-- the input all over again!
	self:Notice(source.nick, "I'll poke you in %s.", date.relativeTimeShort(os.time() + duration))

	self.timers[id] = timer
	timer:start(ivar2.Loop)
end

return {
	PRIVMSG = {
		['^!alarm (%S+)%s?(.*)'] = alarm,
		['^!timer (%S+)%s?(.*)'] = alarm,
	},
}
