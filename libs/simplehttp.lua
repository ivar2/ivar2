local httpclient = require'handler.http.client'
local ev = require'ev'
local client = httpclient.new(ev.Loop.default)

local function simplehttp(url, callback, stream, limit, visited)
	local sinkSize = 0
	local sink = {}
	local visited = visited or {}

	-- Prevent infinite loops!
	if(visited[url]) then return end
	visited[url] = true

	client:request{
		url = url,
		stream_response = stream,

		on_data = function(request, response, data)
			if(data) then
				sinkSize = sinkSize + #data
				sink[#sink + 1] = data
				if(limit and sinkSize > limit) then
					request.on_finished(request, response)
					-- Cancel it
					request:close()
				end
			end
		end,

		on_finished = function(request, response)
			if(response.status_code == 301 or response.status_code == 302) then
				return simplehttp(response.headers.Location, callback, stream, limit, visited)
			end

			callback(table.concat(sink), url, response)
		end,
	}
end

return simplehttp
