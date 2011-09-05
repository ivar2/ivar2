local simplehttp = require'simplehttp'
require'tokyocabinet'

local x0 = tokyocabinet.hdbnew()

return {
	lookup = function(url, callback)
		x0:open('data/x0', x0.OWRITER + x0.OCREAT)
		if(x0[url]) then
			local url = x0[url]
			x0:close()

			return callback(url)
		else
			x0:close()
		end

		simplehttp(url, function(data, url, callback)
			if(data:sub(8,9) =='x0') then
				x0:open('data/x0', x0.OWRITER + x0.OCREAT)
				x0[url] = data
				x0:close()

				return callback(data)
			end
		end)
	end,
}
