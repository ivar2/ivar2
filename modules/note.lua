local date = require'date'
local ev = require'ev'
require'tokyocabinet'
local notes = tokyocabinet.hdbnew()

local handleOutput = function(self, source, destination)
	-- Only accept notes on channels.
	if(destination:sub(1,1) ~= '#') then return end

	notes:open('cache/notes', notes.OWRITER + notes.OCREAT)

	local nick = source.nick
	local key = destination .. ':' .. nick:lower()
	local numNotes = tonumber(notes:get(key .. ':n'))
	if(not numNotes) then return notes:close() end

	for i = 1, numNotes do
		local base = key ..':' .. i
		local note = notes:get(base)
		local time = tonumber(notes:get(base .. ':time'))
		local from = notes:get(base .. ':from')

		self:Msg('privmsg', destination, source, "%s: %s left a note %s ago: %s", nick, from, date.relativeTimeShort(time), note)

		notes:out(base)
		notes:out(base .. ':time')
		notes:out(base .. ':from')
	end

	local globalNumNotes = tonumber(notes:get('global:' .. nick:lower()))
	if(globalNumNotes) then
		notes:put('global:' .. nick:lower(), globalNumNotes - numNotes)
	end

	notes:out(key .. ':n')
	notes:close()
end

return {
	JOIN = {
		-- Check if we have notes for the person who joined the channel.
		handleOutput,
	},

	PRIVMSG = {
		-- Check if we have notes for the person who sent the message.
		handleOutput,

		['^!note (%S+)%s+(.+)$'] = function(self, source, destination, recipient, message)
			-- Only accept notes on channels.
			if(destination:sub(1,1) ~= '#') then return end

			notes:open('cache/notes', notes.OWRITER + notes.OCREAT)
			local globalNumNotes = tonumber(notes:get('global:' .. recipient:lower())) or 0
			if(globalNumNotes >= 5) then
				notes:close()
				return self:Msg('privmsg', destination, source, "I'm sorry, Dave. I'm afraid I can't do that.")
			end

			local key = destination .. ':' .. recipient:lower()
			local slot = (tonumber(notes:get(key .. ':n')) or 0) + 1

			notes:put(key .. ':' .. slot, message)
			notes:put(key .. ':' .. slot .. ':time', os.time())
			notes:put(key .. ':' .. slot .. ':from', source.nick)
			notes:put(key .. ':n', slot)
			notes:put('global:' .. recipient:lower(), globalNumNotes + 1)
			notes:close()
		end
	}
}
