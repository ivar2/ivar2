local simplehttp = require'simplehttp'

customHosts['i%.imgur%.com'] = function(queue, info)
	if(not info.path) then return end

	local hash = info.path:match('/([^.]+)%.[a-zA-Z]+$')
	if(not hash) then return end

	local url = ('http://imgur.com/gallery/%s'):format(hash)
	simplehttp(
		url,

		function(data, _, response)
			local title = handleData(response.headers, data)

			local output
			if(title == 'imgur: the simple image sharer') then
				output = url
			else
				output = string.format('%s - %s', url, title:sub(1, -9))
			end

			queue:done(output)
		end,
		true,
		DL_LIMIT
	)

	return true
end
