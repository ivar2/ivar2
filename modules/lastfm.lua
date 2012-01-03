local simplehttp = require'simplehttp'
local json = require'json'

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
	local response = json.decode(data)
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
