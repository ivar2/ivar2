local httpclient = require'handler.http.client'
local uri = require"handler.uri"
local ev = require'ev'

local client = httpclient.new(ev.Loop.default)
local uri_parse = uri.parse

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
				local location = response.headers.Location
				if(location:sub(1, 4) ~= 'http') then
					local info = uri_parse(url)
					location = string.format('%s://%s/', info.scheme, info.host, location)
				end

				return simplehttp(location, callback, stream, limit, visited)
			end

			callback(table.concat(sink), url, response)
		end,
	}
end

return simplehttp
