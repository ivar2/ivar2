local simplehttp = require'simplehttp'
require'tokyocabinet'

local x0 = tokyocabinet.hdbnew()

return {
	lookup = function(url, callback)
		x0:open('cache/x0', x0.OWRITER + x0.OCREAT)
		if(x0[url]) then
			local url = x0[url]
			x0:close()

			return callback(url)
		else
			x0:close()
		end


		simplehttp(
			'http://api.x0.no/?' .. url,
			function(data, url)
				if(data:sub(8,9) =='x0') then
					x0:open('cache/x0', x0.OWRITER + x0.OCREAT)
					x0[url] = data
					x0:close()

					return callback(data)
				end
			end
		)
	end,
}
