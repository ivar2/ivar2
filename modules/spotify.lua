-- http://developer.spotify.com/en/metadata-api/overview/

local simplehttp = require'simplehttp'
local json = require'json'
require'tokyocabinet'
require'logging.console'

local log = logging.console()
local spotify = tokyocabinet.hdbnew()

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

local validType = {
	track = true,
	album = true,
	artist = true,
}

local handlers = {
	track = function(json)
		if(json.description) then return nil, json.description end

		local title = utify8(json.track.name)
		local album = utify8(json.track.album.name)

		local artists = {}
		for _, artist in ipairs(json.track.artists) do
			table.insert(artists, utify8(artist.name))
		end

		return true, string.format('%s - [%s] %s', table.concat(artists, ', '), album, title)
	end,

	album = function(json)
		if(json.description) then return json.description end

		local artist = utify8(json.album.artist)
		local album = utify8(json.album.name)

		return true, string.format('%s - %s', artist, album)
	end,

	artist = function(json)
		if(json.description) then return json.description end

		return true, utify8(json.artist.name)
	end,
}

local handleData = function(metadata, json)
	local success, message = handlers[metadata.type](json)
	if(success) then
		return message
	else
		return string.format('%s is not a valid Spotify link', metadata.uri)
	end
end

local parseRFC1123
do
	local monthName = {
		Jan = '01',
		Feb = '02',
		Mar = '03',
		Apr = '04',
		May = '05',
		Jun = '06',
		Jul = '07',
		Aug = '08',
		Sep = '09',
		Oct = '10',
		Nov = '11',
		Dec = '12'
	}

	parseRFC1123 = function(date)
		-- RFC 1123: http://www.ietf.org/rfc/rfc1123.txt
		-- RFC 822: http://www.ietf.org/rfc/rfc822.txt
		local day = tonumber(date:sub(6, 7))
		local month = tonumber(monthName[date:sub(9, 11)])
		local year = tonumber(date:sub(13, 16))
		local hour = tonumber(date:sub(18, 19))
		local minute = tonumber(date:sub(21, 22))
		local seconds = tonumber(date:sub(24, 25))
		-- TODO: Handle EST and friends.
		local tz = date:sub(27)

		hour = hour + os.date('%H') - os.date('!%H')
		minute = minute + os.date('%M') - os.date('!%M')

		return os.time{day = day, month = month, year = year, hour = hour, min = minute, sec = seconds}
	end
end

local handleOutput = function(data)
	local uris = {}
	local uriOrder = {}
	for i, meta in ipairs(data.handled) do
		local uri = meta.uri
		if(not uris[uri]) then
			table.insert(uriOrder, uri)
			uris[uri] = {n = i, meta = meta}
		else
			uris[uri].n = string.format('%s+%d', uris[uri].n, i)
		end
	end

	local output = {}
	for i=1, #uriOrder do
		local lookup = uris[uriOrder[i]]
		local url = string.format('http://open.spotify.com/%s/%s', lookup.meta.type, lookup.meta.hash)
		table.insert(output, string.format('\002[%s]\002 %s - %s', lookup.n, lookup.meta.info, url))
	end

	if(#output > 0) then
		ivar2:Msg('privmsg', data.destination, data.source, table.concat(output, ' '))
	end
end

-- http://ws.spotify.com/lookup/1/.json?uri=spotify:artist:4YrKBkKSVeqDamzBPWVnSJ
-- http://ws.spotify.com/lookup/1/.json?uri=spotify:album:6G9fHYDCoyEErUkHrFYfs4
-- http://ws.spotify.com/lookup/1/.json?uri=spotify:track:6NmXV4o6bmp704aPGyTVVG
local fetchInformation = function(output, n, info)
	spotify:open('data/spotify', spotify.OWRITER + spotify.OCREAT)
	if(spotify[info.uri] and tonumber(spotify[info.uri .. ':timestamp']) > os.time()) then
		log:debug(string.format('spotify: Fetching %s from cache.', info.uri))

		output.handled[n] = {uri = info.uri, type = info.type, hash = info.hash, info = spotify[info.uri]}
		output.num = output.num - 1

		spotify:close()

		if(output.num == 0) then
			handleOutput(output)
		end
		return
	else
		spotify:close()
		log:info(string.format('spotify: Requesting information on %s.', info.uri))

		simplehttp(
			('http://ws.spotify.com/lookup/1/.json?uri=%s'):format(info.uri),

			function(data, url, response)
				local message = handleData(info, json.decode(data))
				local expires = parseRFC1123(response.headers.Expires)

				spotify:open('data/spotify', spotify.OWRITER + spotify.OCREAT)
				spotify[info.uri] = message
				spotify[info.uri .. ':timestamp'] = expires
				spotify:close()

				output.handled[n] = {uri = info.uri, type = info.type, hash = info.hash, info = message}
				output.num = output.num - 1

				if(output.num == 0) then
					handleOutput(output)
				end
			end
		)
	end
end

return {
	PRIVMSG = {
		function(self, source, destination, argument)
			local tmp = {}
			local index = 0
			for uri, type, hash in argument:gmatch('(spotify:(%w+):(%S+))') do
				if(validType[type]) then
					index = index + 1

					tmp[index] = {
						uri = uri,
						type = type,
						hash = hash,
					}
				end
			end

			if(index > 0) then
				local output = {
					num = index,
					source = source,
					destination = destination,

					handled = {}
				}

				for i=1, #tmp do
					fetchInformation(output, i, tmp[i])
				end
			end
		end,
	}
}
