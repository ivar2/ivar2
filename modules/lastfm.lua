local simplehttp = require'simplehttp'
local json = require'json'

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

local APIBase = 'http://ws.audioscrobbler.com/2.0/?format=json&api_key=' .. ivar2.config.lastfmAPIKey

local buildQuery = function(param)
	local url = {APIBase}

	for k, v in next, param do
		table.insert(url, string.format('%s=%s', k, v))
	end

	return table.concat(url, '&')
end

local pattern = ('<td>[^<]+</td><td>([^<]+)</td>'):rep(3) .. '<td>([^<]+)</td>'
local parseData = function(source, destination, data)
	local response = json.decode(utify8(data))
	if(response.error) then
		return ivar2:Msg('privmsg', destination, source, response.message)
	end

	local out = {}
	local info = response.topartists
	for i=1, #info.artist do
		local entry = info.artist[i]
		table.insert(out, string.format('%s (%s)', entry.name, entry.playcount))
	end

	ivar2:Msg(
		'privmsg', destination, source,
		"%s's top artists the last 7 days: %s",
		info['@attr'].user,
		table.concat(out, ', ')
	)
end

return {
	PRIVMSG = {
		['^!lastfm (.+)$'] = function(self, source, destination, user)
			simplehttp(
				buildQuery{
					method = 'user.getTopArtists',
					period = '7day',
					limit = '3',
					user = user,
				},
				function(data)
					parseData(source, destination, data)
				end
			)
		end,
	},
}
