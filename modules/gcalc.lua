package.path = table.concat(
	{
		'libs/?.lua',
		'libs/?/init.lua',

		'',
	}, ';'
) .. package.path

local httpclient = require'handler.http.client'
local html2unicode = require'html'

local ivar2 = ...
local client = httpclient.new(ivar2.Loop)

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+')
end

local parseData = function(self, source, destination, data)
	local ans = data:match('<h2 .-><b>(.-)</b></h2><div')
	if(ans) then
		ans = ans:gsub('<sup>(.-)</sup>', '^%1'):gsub('<[^>]+> ?', '')
		self:Msg('privmsg', destination, source, '%s: %s', source.nick, html2unicode(ans))
	else
		self:Msg('privmsg', destination, source, '%s: %s', source.nick, 'Do you want some air with that fail?')
	end
end

local handle = function(self, source, destination, input)
	local search = urlEncode(input)

	local sink = {}
	client:request{
		host ='www.google.com',
		port = 80,
		scheme = 'http',
		method = 'GET',
		path = ('/search?q=%s'):format(search),
		stream_response = true,

		on_data = function(request, response, data)
			if(data) then sink[#sink + 1] = data end
		end,

		on_finished = function()
			parseData(self, source, destination, table.concat(sink))
		end,
	}
end

return {
	PRIVMSG = {
		['!gcalc (.+)$'] = handle,
		['!calc (.+)$'] = handle,
		['!galc (.+)$'] = handle,
	},
}
