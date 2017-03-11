local lconsole = require'logging.console'
local log = lconsole()
local lpeg = require'lpeg'
local uri_patts = require "lpeg_patterns.uri"
local EOF = lpeg.P(-1)
local uri_patt = uri_patts.uri * EOF

-- RFC 2396, section 1.6, 2.2, 2.3 and 2.4.1.
local smartEscape = function(str)
	local pathOffset = str:match("//[^/]+/()")

	-- No path means nothing to escape.
	if(not pathOffset) then return str end
	local prePath = str:sub(1, pathOffset - 1)

	-- lowalpha: a-z | upalpha: A-Z | digit: 0-9 | mark: -_.!~*'() |
	-- reserved: ;/?:@&=+$, | delims: <>#%" | unwise: {}|\^[]` | space: <20>
	local pattern = '[^a-zA-Z0-9%-_%.!~%*\'%(%);/%?:@&=%+%$,<>#%%"{}|\\%^%[%] ]'
	local path = str:sub(pathOffset):gsub(pattern, function(c)
		return ('%%%02X'):format(c:byte())
	end)

	return prePath .. path
end

return function(uri)
	local ok, match = pcall(function()
		-- URI parser has problems with some URLs, so we help it out a bit
		return uri_patt:match(smartEscape(uri))
	end)
	if not ok then
		log:error('uriparse> error uri:<%s> <%s>', uri, match)

		return nil
	end
	return match
end


