local ivar2 = ...
local util = require'util'

return function(url, callback)
	local x0 = ivar2.persist
	if(x0["x0:" .. url]) then
		local nurl = x0["x0:" .. url]

		return callback(nurl)
	end

	-- Since httplib is strange right now, just hack around it
	url = util.json.encode{url=url}
	util.simplehttp(
		{url = 'https://xt.gg/url',
		method = 'POST',
		data = url,
		},
		function(data, realurl)
			data = util.json.decode(data).url
			x0["x0:" .. realurl] = data
			return callback(data)
		end
	)
end
