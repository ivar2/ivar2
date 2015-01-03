local simplehttp = require'simplehttp'

return {
	lookup = function(url, callback)
		local x0 = ivar2.persist
		if(x0["x0:" .. url]) then
			local url = x0["x0:" .. url]

			return callback(url)
		end

		simplehttp(
			'http://api.x0.no/?' .. url,
			function(data, url)
				if(data:sub(8,9) =='x0') then
					x0["x0:" .. url] = data

					return callback(data)
				end
			end
		)
	end,
}
