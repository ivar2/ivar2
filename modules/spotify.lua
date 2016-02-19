-- OLD: http://developer.spotify.com/en/metadata-api/overview/
-- NEW: https://developer.spotify.com/web-api/migration-guide/
-- NEW: https://api.spotify.com/v1/tracks/3tLAA1LA06ecIaRSRbMFbi
local util = ivar2.util
local simplehttp = util.simplehttp
local decode = util.json.decode

local spotify = ivar2.persist

local validType = {
	track = true,
	album = true,
	artist = true,
}

local handlers = {
	track = function(json)
		if(json.description) then return nil, json.description end
		if(json.error) then return nil, json.error.message end

		local title = json.name
		local album = json.album.name

		local artists = {}
		for _, artist in ipairs(json.artists) do
			table.insert(artists, artist.name)
		end

		return true, string.format('%s - [%s] %s', table.concat(artists, ', '), album, title)
	end,

	album = function(json)
		if(json.description) then return json.description end
		if(json.error) then return nil, json.error.message end

		local artists = {}
		for _, artist in ipairs(json.artists) do
			table.insert(artists, artist.name)
		end
		local album = json.name

		return true, string.format('%s - %s', table.concat(artists, ', '), album)
	end,

	artist = function(json)
		if(json.description) then return json.description end
		if(json.error) then return nil, json.error.message end

		return true, json.name
	end,
}

local handleData = function(metadata, json)
	local success, message = handlers[metadata.type](json)
	if(success) then
		return message
	else
		return string.format('%s error %s', metadata.uri, message)
	end
end

local handleOutput = function(data)
	if(data.num ~= 0) then return end

	local uris = {}
	local uriOrder = {}
	for i, meta in ipairs(data.handled) do
		local uri = meta.uri
		if(not uris[uri]) then
			table.insert(uriOrder, uri)
			meta.n = i
			uris[uri] = meta
		else
			uris[uri].n = string.format('%s+%d', uris[uri].n, i)
		end
	end

	local output = {}
	for i=1, #uriOrder do
		local lookup = uris[uriOrder[i]]
		table.insert(output, string.format('\002[%s]\002 %s - %s', lookup.n, lookup.info, lookup.open))
	end

	if(#output > 0) then
		ivar2:Msg('privmsg', data.destination, data.source, table.concat(output, ' '))
	end
end

-- https://api.spotify.com/v1/tracks/3tLAA1LA06ecIaRSRbMFbi
-- https://api.spotify.com/v1/albums/6G9fHYDCoyEErUkHrFYfs4
-- https://api.spotify.com/v1/artists/4YrKBkKSVeqDamzBPWVnSJ
local fetchInformation = function(output, n, info)
	if(spotify['spotify:'..info.uri] and tonumber(spotify['spotify:'.. info.uri .. ':timestamp']) > os.time()) then
		ivar2:Log('debug', string.format('spotify: Fetching %s from cache.', info.uri))

		info.info = spotify['spotify:'..info.uri]
		output.handled[n] = info
		output.num = output.num - 1

		handleOutput(output)
	else
		ivar2:Log('info', string.format('spotify: Requesting information on %s.', info.uri))

		simplehttp(
			('https://api.spotify.com/v1/%ss/%s'):format(info.type, info.hash),

			function(data, url, response)
				local message = handleData(info, decode(data))
				-- New API doesn't provide a Expires header, but they do set
				-- cache-control public max-age 7200. If we were good citizens we
				-- could parse this. Alas, I'm lazy.
				local expires = os.time() + 7200

				spotify['spotify:'..info.uri] = message
				spotify['spotify:'..info.uri .. ':timestamp'] = expires

				output.handled[n] = info
				info.info = message
				output.num = output.num - 1

				handleOutput(output)
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
						open = ('http://open.spotify.com/%s/%s'):format(type, hash)
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
