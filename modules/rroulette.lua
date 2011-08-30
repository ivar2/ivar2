local ev = require'ev'

require'tokyocabinet'

local ivar2 = ...
local rr = tokyocabinet.hdbnew()

if(not ivar2.timers) then ivar2.timers = {} end

local getBullet = function(n)
	return n % 10
end

local getChamber = function(n)
	return (n - getBullet(n)) / 10 % 10
end

local getDeaths = function(n)
	return (n - (n % 100)) / 100
end

return {
	PRIVMSG = {
		['!rr$'] = function(self, source, destination)
			rr:open('cache/rr', rr.OWRITER + rr.OCREAT)
			local nick = source.nick

			-- kinda depricated.
			if(not rr[nick]) then
				rr[nick] = 0
			end

			if(not rr[destination]) then
				rr[destination] = 60 + math.random(1,6)
			end

			local bullet = getBullet(rr[destination])
			local chamber = getChamber(rr[destination])
			local deaths = getDeaths(rr[nick])
			local seed = math.random(1, chamber)

			if(seed == bullet) then
				bullet = math.random(1, 6)
				chamber = 6
				deaths = deaths + 1
				self:Kick(destination, nick, 'BANG!')
			else
				chamber = chamber - 1
				if(bullet > chamber) then
					bullet = chamber
				end

				local src = 'Russian Roulette:' .. destination
				if(self.timers[src]) then
					self.timers[src]:again(ivar2.Loop, 15 * 60)
				else
					local timer = ev.Timer.new(
						function(loop, timer, revents)
							rr:open('cache/rr', rr.OWRITER + rr.OCREAT)

							local n = rr[destination]
							rr[destination] = 60 + math.random(1,6)
							rr:close()
						end,
						15 * 60
					)
					self.timers[src] = timer
					timer:start(ivar2.Loop)
				end

				print('Click', chamber)
				self:Msg('privmsg', destination, source, 'Click. %d/6', chamber)
			end

			rr[destination] = (chamber * 10) + bullet
			rr[nick] = (deaths * 100)

			rr:close()
		end,

		['!rrstats ?(.*)$'] = function(self, source, destination, nick)
			rr:open('cache/rr')
			if(#nick > 0) then
				nick = nick:match'^%s*(.*%S)' or ''
				local data = rr[nick] and getDeaths(rr[nick])
				if(not data) then
					self:Msg('privmsg', destination, source, '%s has no deaths.', nick)
				else
					self:Msg('privmsg', destination, source, '%s has %s deaths.', nick, data)
				end
			else
				local all = {}
				for k, v in rr:pairs() do
					if(k:sub(1,1) ~= '#') then
						table.insert(all, {nick = k, deaths = getDeaths(v)})
					end
				end

				table.sort(all, function(a,b) return a.deaths > b.deaths end)
				local tmp = {}
				for i=1, math.min(#all, 5) do
					table.insert(tmp, string.format('%s (%s)', all[i].nick, all[i].deaths))
				end

				local out = 'Top deaths: ' .. table.concat(tmp, ', ')
				self:Msg('privmsg', destination, source, out)
			end

			rr:close()
		end,
	}
}
