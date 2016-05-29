local ivar2 = ...
local util = require'util'

return function(url, callback)
	local x0 = ivar2.persist
	if(x0["x0:" .. url]) then
		local nurl = x0["x0:" .. url]

		return callback(nurl)
	end

	util.simplehttp(
		'https://xt.gg/url?url=' .. util.urlEncode(url),
		function(data, realurl)
			data = util.json.decode(data).url
			x0["x0:" .. realurl] = data
			return callback(data)
		end
	)
end
