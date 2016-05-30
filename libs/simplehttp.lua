local httpclient = require'http.request'
local uri_parse = require'uriparse'
local idn = require'idn'
local zlib = require'zlib'
local lconsole = require'logging.console'
local log = lconsole()

-- Change to DEBUG if you want to see full URL fetch log
log:setLevel('INFO')

local REQ_TIMEOUT = 60

local function simplehttp(url, callback, unused, limit)
	local uri
	if(type(url) == "table") then
		uri = url.url or url[1]
	else
		uri = url
	end

	-- Don't include fragments in the request.
	uri = uri:gsub('#.*$', '')
	-- Trim trailing whitespace
	uri = uri:gsub('%s+$', '')

	-- IDN hack for now, until http/uriparse supports it
	uri = uri:gsub('://(.-)%.', function(match)
		if match:sub(1,1) ~= '[' then
			match = idn.encode(match)
		end
		return '://'..match..'.'
	end, 1)

	log:debug('simplehttp> request <%s>', uri)

	local uri_t = uri_parse(uri)
	local client = httpclient.new_from_uri(uri_t)

	if(type(url) == "table") then
		if(url.headers) then
			for k, v in next, url.headers do
				-- Overwrite any existing
				client.headers:upsert(k, v)
			end
		end

		if(url.method) then
			client.headers:upsert(":method", url.method)
		end

		if(url.data) then
			client:set_body(url.data)
		end
	end

	local data
	local status_code

	local headers, stream = client:go(REQ_TIMEOUT)

	if not headers then
		log:error('simplehttp> request %s, error :%s.', uri, stream)
		return
	end
	status_code = headers:get(':status')
	-- H2 might not be number
	status_code = tonumber(status_code, 10) or status_code

	local simple_headers = {}
	for k,v in headers:each() do
		-- Will overwrite duplicate headers.
		simple_headers[k] = v
	end

	if stream then
		if(limit) then
			data = stream:get_body_chars(limit, REQ_TIMEOUT)
		else
			data = stream:get_body_as_string(REQ_TIMEOUT)
		end
		-- Stream shutdown lets luahttp reuse I'm told
		stream:shutdown()
		-- without these two, seems to be leaking fds
		stream.connection:shutdown()
		stream.connection:close()
		-- Some servers send gzip even if not requested
		if simple_headers['content-encoding'] == 'gzip' then
			data = zlib.inflate()(data)
		end
	end

	local response = {
		headers = simple_headers,
		status_code = status_code -- for compability with old simplehttp API
	}
	-- Old style callback
	if callback then
		callback(data, uri, response)
	end
	-- New style.
	return data, uri, response
end

return simplehttp
