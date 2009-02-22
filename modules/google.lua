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

require'json'

local url = 'http://www.google.com/uds/GwebSearch?context=0&hl=en&key=%s&v=1.0&q=%s&rsz=small'

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

local handler = function(self, src, dest, msg)
	if(self.config.googleAPIKey) then
		msg = utils.escape(msg):gsub('%s', '+')

		local content, status = utils.http(url:format(self.config.googleAPIKey, msg))
		if(status == 200) then
			local data = utify8(content)
			data = json.decode(data)

			if(data and data.responseStatus == 200) then
				local arr = {}
				for i=1,3 do
					local match = data.responseData.results[i]
					if(not match) then break end

					local title = utils.decodeHTML(match.titleNoFormatting)
					local url = match.unescapedUrl
					if(#url >= 75) then
						url = utils.x0(url) or url
					end
					table.insert(arr, ('\002%s\002 <%s>'):format(title, url))
				end

				if(#arr ~= 0) then
					return self:msg(dest, src, table.concat(arr, " || "))
				end

				if(#arr == 0) then
					self:msg(dest, src, "jack shit found...")
				end
			end
		end
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!g (.+)$"] = handler,
}
