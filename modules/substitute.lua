local db = {}

return {
	["^:(%S+) PRIVMSG (%S+) :(.+)$"] = function(self, src, dest, msg)
		if(msg:match"s/(.*)/(.-)/(%w?)$" or msg:match"<(.-)>s/(.*)/(.-)/(%w?)$") then return end

		src = self:srctonick(src)
		if(not db[src]) then db[src] = {} end
		db[src][dest] = msg
	end,
	["^:(%S+) PRIVMSG (%S+) :s/(.*)/(.-)/(%w?)$"] = function(self, src, dest, match, replace, flag)
		src = self:srctonick(src)

		if(db[src] and db[src][dest]) then
			if(flag == "g") then
				flag = #db[src][dest]
			else
				flag = 1
			end

			local new = db[src][dest]:gsub(match, replace, flag)
			if(new ~= db[src][dest]) then
				db[src][dest] = new
				self:privmsg(dest, "%s meant: %s", src, new)
			end
		end
	end,
	["^:(%S+) PRIVMSG (%S+) :<(.-)>s/(.*)/(.-)/(%w?)$"] = function(self, src, dest, target, match, replace, flag)
		src = self:srctonick(src)

		if(src ~= target and db[target] and db[target][dest]) then
			if(flag == "g") then
				flag = #db[target][dest]
			else
				flag = 1
			end

			local new = db[target][dest]:gsub(match, replace, flag)
			if(new ~= db[target][dest]) then
				self:privmsg(dest, "%s thought %s meant: %s", src, target, new)
			end
		end
	end,
}
