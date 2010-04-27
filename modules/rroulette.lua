require'tokyocabinet'
local tc = tokyocabinet
math.randomseed(os.time() % 1e5)

local getBullet = function(n)
	return n % 10
end

local getChamber = function(n)
	return (n - getBullet(n)) / 10 % 10
end

local getDeaths = function(n)
	return (n - (n % 100)) / 100
end

local rr = tc.hdbnew()
local chamberReset = function(self, data)
	rr:open('data/rr', rr.OWRITER + rr.OCREAT)

	local n = rr[data.nick]
	rr[data.nick] = n - (n - getBullet(n)) / 10 % 10 * 10 + 60

	rr:close()
end

return {
	["^:(%S+) PRIVMSG (%S+) :!rr$"] = function(self, src, dest, msg)
		rr:open('data/rr', rr.OWRITER + rr.OCREAT)
		local nick = self:srctonick(src)

		if(not rr[nick]) then
			rr[nick] = 60 + math.random(1,6)
		end

		local bullet = getBullet(rr[nick])
		local chamber = getChamber(rr[nick])
		local deaths = getDeaths(rr[nick])
		local seed = math.random(1, chamber)

		if(seed == bullet) then
			bullet = math.random(1, 6)
			chamber = 6
			deaths = deaths + 1
			self:send('KICK %s %s :%s', dest, nick, 'BANG!')
		else
			chamber = chamber - 1
			if(bullet > chamber) then
				bullet = chamber
			end

			local timers = self.timers or {}
			self.timers = timers

			local src = 'Russian Roulette:' .. nick
			for index, timerData in pairs(timers) do
				if(timerData.name == src) then
					table.remove(timers, index)
					break
				end
			end

			table.insert(timers, {
				nick = nick,

				name = 'Russian Roulette:' .. nick,
				oneCall = true,
				callTime = os.time() + (5 * 60),
				func = chamberReset,
			})

			self:privmsg(dest, 'Click, %s tries left.', chamber)
		end

		rr[nick] = (deaths * 100) + (chamber * 10) + bullet

		rr:close()
	end,

	["^:(%S+) PRIVMSG (%S+) :!rrstats ?(.*)$"] = function(self, src, dest, nick)
		rr:open('data/rr')
		if(#nick > 0) then
			nick = nick:match'^%s*(.*%S)' or ''
			local data = rr[nick] and getDeaths(rr[nick])
			if(not data) then
				self:privmsg(dest, '%s has no deaths.', nick)
			else
				self:privmsg(dest, '%s has %s deaths.', nick, data)
			end
		else
			local all = {}
			for k, v in rr:pairs() do
				table.insert(all, {nick = k, deaths = getDeaths(v)})
			end

			table.sort(all, function(a,b) return a.deaths > b.deaths end)
			local tmp = {}
			for i=1, math.min(#all, 5) do
				table.insert(tmp, string.format('%s (%s)', all[i].nick, all[i].deaths))
			end

			local out = 'Top deaths: ' .. table.concat(tmp, ', ')
			self:privmsg(dest, out)
		end

		rr:close()
	end,
}
