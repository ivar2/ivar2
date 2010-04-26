require'tokyocabinet'
local tc = tokyocabinet
math.randomseed(os.time() % 1e5)

local rr = tc.hdbnew()

return {
	["^:(%S+) PRIVMSG (%S+) :!rr$"] = function(self, src, dest, msg)
		local seed = math.random(1, 6)
		local bullet = math.random(1,6)

		if(seed == bullet) then
			rr:open('data/rr', rr.OWRITER + rr.OCREAT)
			local nick = self:srctonick(src)
			rr[nick] = (rr[nick] or 0) + 1
			rr:close()
			self:send('KICK %s %s :%s', dest, self:srctonick(src), 'BANG!')
		else
			self:privmsg(dest, 'Click!')
		end
	end,

	["^:(%S+) PRIVMSG (%S+) :!rrstats ?(.*)$"] = function(self, src, dest, nick)
		rr:open('data/rr', rr.OWRITER + rr.OCREAT)
		if(#nick > 0) then
			nick = nick:match'^%s*(.*%S)' or ''
			local data = rr[nick]
			if(not data) then
				self:privmsg(dest, '%s has no deaths.', nick)
			else
				self:privmsg(dest, '%s has %s deaths.', nick, data)
			end
		else
			local all = {}
			for k, v in rr:pairs() do
				table.insert(all, {nick = k, deaths = v})
			end

			table.sort(all, function(a,b) return a.deaths > b.deaths end)
			local tmp = {}
			for i=1, math.min(#all, 3) do
				table.insert(tmp, string.format('%s (%s)', all[i].nick, all[i].deaths))
			end

			local out = 'Top deaths: ' .. table.concat(tmp, ', ')
			self:privmsg(dest, out)
		end

		rr:close()
	end,
}
