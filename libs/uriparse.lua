local lconsole = require'logging.console'
local log = lconsole()
local lpeg = require'lpeg'
local uri_patts = require "lpeg_patterns.uri"
local EOF = lpeg.P(-1)
local uri_patt = uri_patts.uri * EOF
return function(uri)
	local ok, match = pcall(function()
		return uri_patt:match(uri)
	end)
	if not ok then
		log:error('uriparse> error uri:<%s> <%s>', uri, match)

		return nil
	end
	return match
end


