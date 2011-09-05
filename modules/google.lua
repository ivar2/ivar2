-- Google Search over the AJAX API.
--
-- Expects a valid google API key in the config table.
--
-- Example:
-- config = {
--     ...
--     googleAPIKey = 'valid key here',
--     ...
-- }

local x0 = require'x0'
local httpclient = require'handler.http.client'
local json = require'json'
local html2unicode = require'html'

local client = httpclient.new(ivar2.Loop)
x0.init(ivar2.Loop)

local utify8 = function(str)
	str = str:gsub("\\u(....)", function(n)
		n = tonumber(n, 16)

		if(n < 128) then
			return string.char(n)
		elseif(n < 2048) then
			return string.char(192 + ((n - (n % 64)) / 64), 128 + (n % 64))
		else
			return string.char(224 + ((n - (n % 4096)) / 4096), 128 + (((n % 4096) - (n % 64)) / 64), 128 + (n % 64))
		end
	end)

	return str
end

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+')
end

local outFormat = '\002%s\002 <%s>'
local parseData = function(self, source, destination, data)
	data = utify8(data)
	data = json.decode(data)

	if(data and data.responseStatus == 200) then
		local arr = {}
		local n = 0
		for i=1,3 do
			local match = data.responseData.results[i]
			if(not match) then break end

			local title = html2unicode(match.titleNoFormatting)
			local url = match.unescapedUrl
			if(#url >= 75) then
				n = n + 1
				x0.lookup(url, function(short)
					n = n - 1
					arr[i] = outFormat:format(title, short or url)

					if(n == 0) then
						self:Msg('privmsg', destination, source, table.concat(arr, ' || '))
					end
				end)
			else
				arr[i] = outFormat:format(title, url)
			end
		end

		if(#arr == 0 and n == 0) then
			self:Msg('privmsg', destination, source, 'jack shit found :-(.')
		elseif(#arr == 3) then
			self:Msg('privmsg', destination, source, table.concat(arr, ' || '))
		end
	end
end

local url = 'http://www.google.com/uds/GwebSearch?context=0&hl=en&key=%s&v=1.0&q=%s&rsz=small'
local handler = function(self, source, destination, input)
	local search = urlEncode(input)

	local sink = {}
	client:request{
		url = url:format(self.config.googleAPIKey, search),

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
		['^!g (.+)$'] = handler,
		['^!google (.+)$'] = handler,
	},
}
