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

local headers = {
	['Authorization'] = string.format("Client-ID %s", ivar2.config.imgurClientID)
}

local function handleOutput(queue, hash, data)
	data = utify8(data)
	data = json.decode(data)
	local gallery = data.data

	if(data.status == 404) then
		local url = ('https://api.imgur.com/3/image/%s.json'):format(hash)
		return simplehttp(
			{
				url = url,
				headers = headers
			},

			function(data)
				return handleOutput(queue, hash, data)
			end,
			true,
			DL_LIMIT
		)
	end

	local out = {}

	table.insert(out, string.format("http://imgur.com/%s", gallery.id))

	if(type(gallery.title) == "string") then
		table.insert(out, "-")
		table.insert(out, gallery.title)

		local tags = {}
		table.insert(tags, string.format("%dx%d", gallery.width, gallery.height))

		if(gallery.ups and gallery.downs) then
			table.insert(tags, string.format("+%d/-%d", gallery.ups, gallery.downs))
		end

		if(gallery.nsfw and not gallery.title:match("[nN][sS][fF][wW]")) then
			table.insert(tags, "NSFW")
		end

		if(gallery.animated) then
			table.insert(tags, "gif")
		end

		table.insert(out, string.format("[%s]", table.concat(tags, ", ")))
	end

	queue:done(table.concat(out, " "))
end

customHosts['i%.imgur%.com'] = function(queue, info)
	if(not info.path) then return end

	local hash = info.path:match('/([^.]+)%.[a-zA-Z]+$')
	if(not hash) then return end

	local url = ('https://api.imgur.com/3/gallery/%s.json'):format(hash)
	simplehttp(
		{
			url = url,
			headers = headers,
		},

		function(data, _, response)
			return handleOutput(queue, hash, data)
		end,
		true,
		DL_LIMIT
	)

	return true
end
