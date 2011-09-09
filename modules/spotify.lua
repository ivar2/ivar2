-- http://developer.spotify.com/en/metadata-api/overview/

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
	simplehttp(
		('http://ws.spotify.com/lookup/1/.json?uri=%s'):format(info.uri),

		function(data)
			local message = handleData(info, json.decode(data))
			output.handled[n] = {uri = info.uri, type = info.type, hash = info.hash, info = message}
			output.num = output.num - 1

			if(output.num == 0) then
				handleOutput(output)
			end
		end
	)
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
