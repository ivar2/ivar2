-- vim: set noexpandtab:
local server = require'http.server'
local new_headers = require "http.headers".new
local lconsole = require'logging.console'
local log = lconsole()

-- Keep this amount in mem before handler has to read from tmpfile
local BODY_BUFFER_SIZE = 2^17

local timeout = 30

local runningserver

local webserver = {}

local handlerNotFound = function(stream, res)
	res:upsert(":status", "404")
	stream:write_headers(res, false, timeout)
	stream:write_body_from_string('Nyet. I am four oh four', timeout)
end

local handlers = {
	['/favicon.ico'] = handlerNotFound
}

local on_response_sent = function(res)
	if res.filename then
		log:info('webserver> on_response_sent: deleting tmp file: %s', res.filename)
		os.remove(res.filename)
	end
end

local on_error = function(req, res, err)
	log:info('webserver> error: req %s, res %s, err %s', req, res, err)
end

-- Will be called for every chunk
local on_data = function(req, res, data)
	if data then
		-- Save the chunks into a temp file
		if not req.fd then
			local filename = os.tmpname()
			req.filename = filename
			-- Save filename in request so it can be cleaned up in on_response_sent
			res.filename = filename
			-- Append mode, owner only
			req.fd = nixio.open(filename, 'a', 0400)
		end
		req.fd:write(data)
		if not req.body then
			req.body = data
		else
			if #req.body < BODY_BUFFER_SIZE then
				req.body = req.body .. data
			end
		end
	end
end

local on_finish = function(req, handler)
	-- If file upload has been in progress, close the tmpfile
	if req.fd then
		req.fd:sync()
		req.fd:close()
	end
	-- Check size of tmpfile, if it's small, read into memory
	return handler
end

local on_request = function(cur_server, req, res)
	local found
	for pattern, handler in pairs(handlers) do
		if req.url:match(pattern) then
			log:info('webserver> request for pattern :%s', pattern)
			req.on_finished = on_finish(req, handler)
			req.on_data = on_data
			req.on_error = on_error
			-- Stream incoming data
			req.stream_response = true
			res.on_response_sent = on_response_sent
			break
		end
	end
	if not found then
		log:info('webserver> returning 404 for request: %s', req.url)
		req.on_finished = function(cur_req, cur_res)
			cur_res:set_status(404)
			cur_res:send()
		end
	end
end

webserver.on_stream = function(stream)
	print(tostring(stream))
	local headers = stream:get_headers(30)
	local path
	--print('tls', stream:checktls())
	--print('peer', stream:peername())
	--print('local', stream:localname())
	local res = new_headers()
	if headers then
		for k, v in headers:each() do
			if k == ':path' then
				path = v
				stream.url = v -- for compability
			end
			if k ~= 'connection' then -- yeah...
				print('setting', k,v)
				stream[k] = v
			end
		end
	end
	local found
	for pattern, handler in pairs(handlers) do
		if path:match(pattern) then
			log:info('webserver> request for pattern :%s', pattern)
			found = true
			local ok, err = pcall(handler, stream, res)
			if not ok then
				log:error('webserver> error for URL pattern: %s: %s', pattern, err)
			end
			break
		end
	end
	if not found then
		log:info('webserver> returning 404 for request: %s', path)
		handlerNotFound(stream, res)
	end
	print('Shutdown', stream:shutdown())
end

webserver.start = function(host, port)
	if not (host and port) then
		return
	end
	log:info('webserver> starting webserver: %s:%s', host, port)
	runningserver = server.listen{
		host = host,
		port = port,
	}
	return runningserver
end

webserver.stop = function()
	if(not server) then return end

	log:info('webserver> stopping webserver.')
	server.acceptors[1]:close()
end

webserver.regUrl = function(pattern, handler)
	log:info('webserver> registering new handler for URL pattern: %s', pattern)
	handlers[pattern] = handler
end

webserver.unRegUrl = function(pattern)
	log:info('webserver> unregistering handler for URL pattern: %s', pattern)
	handlers[pattern] = nil
end

return webserver
