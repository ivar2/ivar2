local db = {}

local toLuaPattern = function(str)
	return str:gsub('%%', '%%%%'):gsub('\\([%l%u%d^$()%%.%[%]*+%-?])', '%%%1'):gsub('\\/', '/')
end

local handleMessage = function(nick, destination, msg, update)
	if(db[nick] and db[nick][destination]) then
		local matchPoint = msg:match('()[^\\]/')
		local match = msg:sub(1, matchPoint)

		local replacePoint = msg:match('()[^\\]/', matchPoint + 1)
		local replace = msg:sub(matchPoint + 2, replacePoint)

		local flags = 1
		if(replacePoint) then
			local flagPoint = msg:match('()[^\\]/', replacePoint + 1)
			local flag = msg:sub(replacePoint + 2, flagPoint)
			if(flag:lower() == 'g') then
				flags = #db[nick][destination]
			end
		end

		local out = db[nick][destination]:gsub(toLuaPattern(match), toLuaPattern(replace), flags)
		if(out ~= db[nick][destination]) then
			if(update) then
				db[nick][destination] = out
			end

			return out
		end
	end
end

return {
	PRIVMSG = {
		['^s/(.+)$'] = function(self, source, destination, message)
			local out = handleMessage(source.nick, destination, message, true)
			if(out) then
				self:Msg('privmsg', destination, source, '%s meant: %s', source.nick, out)
			end
		end,

		['^<([^>]+)>s/(.+)$'] = function(self, source, destination, target, message)
			local out = handleMessage(target, destination, message)
			if(out) then
				self:Msg('privmsg', destination, source, '%s thought %s meant: %s', source.nick, target, out)
			end
		end,

		function(self, source, destination, argument)
			-- Don't validate input here, people fail to often and try again.
			if(argument:match('^<[^>]+>s/') or argument:sub(1, 2) == 's/') then return end

			local nick = source.nick
			if(not db[nick]) then db[nick] = {} end
			db[nick][destination] = argument
		end,
	}
}
