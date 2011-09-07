local httpclient = require'handler.http.client'
local ev = require'ev'
local client = httpclient.new(ev.Loop.default)

local function simplehttp(url, callback, stream, limit, visited)
	local sinkSize = 0
	local sink = {}
	local visited = visited or {}

	local resp
	-- Prevent infinite loops!
	if(visited[url]) then return end
	visited[url] = true

	client:request{
		url = url,
		stream_response = stream,

		on_data = function(request, response, data)
			if(data) then
				resp = response
				sinkSize = sinkSize + #data
				sink[#sink + 1] = data
				if(limit and sinkSize > limit) then
					request.connection.skip_complete = true
					request.on_finished(response)
				end
			end
		end,

		on_finished = function()
			if(resp.status_code == 301 or resp.status_code == 302) then
				return simplehttp(resp.headers.Location, callback, stream, limit, visited)
			end

			callback(table.concat(sink), url, resp)
		end,
	}
end

return simplehttp
