local httpclient = require'handler.http.client'
local ev = require'ev'
local client = httpclient.new(ev.Loop.default)

return function(url, callback, stream, limit)
	local sinkSize = 0
	local sink = {}

	client:request{
		url = url,
		stream_response = stream,

		on_data = function(request, response, data)
			if(data) then
				sinkSize = sinkSize + #data
				sink[#sink + 1] = data
				if(limit and sinkSize > limit) then
					request.connection.skip_complete = true
					request.on_finished(response)
				end
			end
		end,

		on_finished = function(response)
			callback(table.concat(sink), url, response)
		end,
	}
end
