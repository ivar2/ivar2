local httpclient = require'handler.http.client'
local client = httpclient.new(ivar2.Loop)

local pattern = ('<td>[^<]+</td><td>([^<]+)</td>'):rep(3) .. '<td>([^<]+)</td>'
local parseData = function(self, source, destination, data, anime)
	data = data:match'Airing</h1>(.-)<h1>'
	data = data:gsub('<td.->', '<td>'):gsub('</?a.->', ''):gsub('[\r\n]+', '')
	-- FIXME: This match is _steps_ away from locking on the C side.
	for entry in data:gmatch'<tr.->(.-)</tr>' do
		for title, channel,airtime,eta in entry:gmatch(pattern) do
			if(title:lower():find(anime, 1, true)) then
				return self:Msg('privmsg', destination, source, '%s airs on %s on %s (ETA: %s)', title, channel, airtime, eta:sub(1, -2))
			end
		end
	end

	self:Msg('privmsg', destination, source, 'Fool! I found nothing by that name... :(')
end

return {
	PRIVMSG = {
		['^!airs%s*$'] = function(self, source, destination)
			self:Msg('privmsg', destination, source, 'Returns air time, ETA and channel for <anime>. Usage: !airs <anime>.', source.nick)
		end,

		['^!airs (.+)$'] = function(self, source, destination, anime)
			local sink = {}
			client:request{
				url = 'http://www.mahou.org/Showtime/',
				stream_response = true,

				on_data = function(request, response, data)
					if(data) then sink[#sink + 1] = data end
				end,

				on_finished = function()
					parseData(self, source, destination, table.concat(sink), anime:lower())
				end,
			}
		end,
	},
}
