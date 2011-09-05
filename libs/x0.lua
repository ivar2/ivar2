local simplehttp = require'simplehttp'
require'tokyocabinet'

return {
	lookup = function(url, callback)
		x0:open('data/x0', x0.OWRITER + x0.OCREAT)
		if(x0[url]) then
			local url = x0[url]
			x0:close()

			return callback(url)
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
