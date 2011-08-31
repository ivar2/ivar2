local httpclient = require'handler.http.client'
local ev = require'ev'
require'tokyocabinet'

local x0 = tokyocabinetc.hdbnew()
local loop = ev.Loop.default
local client = httpclient.new(loop)

local handleRequest = function(data, callback)
	if(data:sub(8,9) =='x0') then
		x0:open('data/x0', x0.OWRITER + x0.OCREAT)
		x0[url] = data
		x0:close()
		
		return callback(url)
	end
end

return {
	lookup = function(url, callback)
		x0:open('data/x0', x0.OWRITER + x0.OCREAT)
		if(x0[url]) then
			local url = x0[url]
			x0:close()

			return callback(url)
		end

		local sink = {}
		client:request{
			url = 'http://api.x0.no/?'..url,
			stream_response = true,

			on_data = function(request, response, data)
				if(data) then sink[#sink + 1] = data end
			end,

			on_finished = function()
				handleRequest(table.concat(sink), callback)
			end,
		}
	end
}
