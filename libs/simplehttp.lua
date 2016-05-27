local httpclient = require'http.request'
local urip = require"handler.uri"
local idn = require'idn'
--local ev = require'ev'
local zlib = require'zlib'
local lconsole = require'logging.console'
local log = lconsole()
--local cq = cqueues.new()
--local ev_loop = ev.Loop.default
-- Change to DEBUG if you want to see full URL fetch log
--
--log:setLevel('INFO')


--do -- initialize
--	if timer then
--		timer:stop(ev.Loop.default)
--		eio:stop(ev.Loop.default)
--		cq:cancel()
--		wrapper:cancel()
--	end
--	cq = cqueues.new()
--
--	-- TODO: figure out reloading
--	local function step()
--		-- luacheck: ignore errno
--		local ok, err, errno, thd = cq:step(0)
--		if not ok then
--			print("ERROR", debug.traceback(thd, err))
--		end
--		local timeout = cq:timeout()
--		if timeout then
--			timer:again(ev.Loop.default, timeout)
--		else
--			timer:stop(ev.Loop.default)
--			if cq:empty() then
--				eio:stop(ev.Loop.default)
--			end
--		end
--	end
--	timer = ev.Timer.new(step, math.huge)
--	eio = ev.IO.new(step, cq:pollfd(), ev.READ)
--	timer:start(ev.Loop.default)
--	eio:start(ev.Loop.default)
--end
--local rnd = math.random(100)
--local wrapper = cq:wrap(function() while true do print("simplehttp " ..tostring(rnd)) cqueues.sleep(10) end end)

local uri_parse = urip.parse

local toIDN = function(url)
	local info = uri_parse(url, nil, true)
	-- Support IPv6 [host]
	if (info.host:sub(1, 1) ~= '[') then
		info.host = idn.encode(info.host)
	end

	if(info.port) then
		info.host = info.host .. ':' .. info.port
	end

	return string.format(
		'%s://%s%s%s',

		info.scheme,
		info.userinfo or '',
		info.host,
		info.path or ''
	)
end

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

	log:debug('simplehttp> request <%s>', uri)

	-- Add support for IDNs.
	uri = toIDN(uri)

	local client = httpclient.new_from_uri(uri)

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

	local req_timeout = 30

	--cq:wrap(function()
		local data
		local status_code
		--for k,v in client.headers:each() do
		--	print(k,v)
		--end

		local headers, stream = client:go(req_timeout)

		if not headers then
			log:error('simplehttp> request %s, error :%s.', uri, stream)
			return
		end
		status_code = headers:get(':status')
		-- H2 might not be number
		status_code = tonumber(status_code, 10) or status_code

		local simple_headers = {}
		for k,v in headers:each() do
			--print(k,v)
			simple_headers[k] = v
		end

		if stream then
			if(limit) then
				data = stream:get_body_chars(limit, req_timeout)
			else
				data = stream:get_body_as_string(req_timeout)
			end
			-- Stream shutdown lets luahttp reuse I'm told
			stream:shutdown()
			-- Some servers send gzip even if not requested
			if simple_headers['content-encoding'] == 'gzip' then
				data = zlib.inflate()(data)
			end
		end

		local response = {
			headers = simple_headers,
			status_code = status_code -- for compability with old simplehttp API
		}
		callback(data, uri, response)
	--end)
end

return simplehttp
