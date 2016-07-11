local rr = ivar2.persist

local getBullet = function(n)
	return n % 10
end

local getChamber = function(n)
	return (n - getBullet(n)) / 10 % 10
end

local loadChamber = function(destination)
		rr['rr:'..destination] = 60 + math.random(1,6)
end

return {
	PRIVMSG = {
		['^%prr$'] = function(self, source, destination)
			local nick = source.nick

			if(not rr['rr:'..destination]) then
				loadChamber(destination)
			end

			local bullet = getBullet(rr['rr:'..destination])
			local chamber = getChamber(rr['rr:'..destination])

			local deathKey = destination .. ':' .. nick .. ':deaths'
			local attemptKey = destination .. ':' .. nick .. ':attempts'

			local deaths = rr['rr:'..deathKey] or 0
			local attempts = (rr['rr:'..attemptKey] or 0) + 1
			local seed = math.random(1, chamber)

			local forgetful = math.random(100)

			if(seed == bullet and not (forgetful<5)) then
				bullet = math.random(1, 6)
				chamber = 6
				local misfire = math.random(100)
				if(misfire < 10) then
					say('FIZZLE! The revolver misfired. Do you feel lucky? Well, do ya, punk?')
				else
					deaths = deaths + 1
					self:Kick(destination, nick, 'BANG!')
					say('BANG! %s died a gruesome death. R.I.P.', source.nick)
				end
			else
				chamber = chamber - 1
				if(bullet > chamber) then
					bullet = chamber
				end

				local src = 'Russian Roulette:' .. destination
				self:Timer(src, 15*60, function(loop, timer, revents)
					loadChamber(destination)
				end)

				if(chamber == 0) then
					say('Click. %d/6. Click?! Oops. Forgot to load the revolver.', chamber)
					bullet = math.random(1, 6)
					chamber = 6
				else
					say('Click. %d/6', chamber)
				end
			end

			rr['rr:'..destination] = (chamber * 10) + bullet
			rr['rr:'..deathKey] = deaths
			rr['rr:'..attemptKey] = attempts

		end,

		['^%prrstat$'] = function(self, source, destination)
			local nicks = {}
			for n,t in pairs(self.channels[destination].nicks) do
				nicks[n] = destination..':'..n
			end

			local tmp = {}
			for nick, key in next, nicks do
				if(not tmp[nick]) then tmp[nick] = {} end
				local rtype = 'attempts'
				local res = tonumber(rr['rr:'..key..':'..rtype])
				if not res then res = 0 end
				tmp[nick][rtype] = res
				rtype = 'deaths'
				res = tonumber(rr['rr:'..key..':'..rtype])
				if not res then res = 0 end
				tmp[nick][rtype] = res
			end

			local stats = {}
			for nick, data in next, tmp do
				-- cut off at 5
				if data.deaths > 0 or data.attempts > 5 then
					local deathRatio = data.deaths / data.attempts
					table.insert(stats, {nick = nick, deaths = data.deaths, attempts = data.attempts, ratio = deathRatio})
				end
			end
			--table.sort(stats, function(a,b) return a.ratio < b.ratio end)
			-- Sort by attempts
			table.sort(stats, function(a,b) return a.attempts > b.attempts end)

			local out = {}
			for i=1, #stats do
				table.insert(out, string.format('%s (%.1f%%/%s)', stats[i].nick, (1 - stats[i].ratio) * 100, stats[i].attempts))
			end

			say('Survival rate: %s', ivar2.util.nonickalert(self.channels[destination].nicks, table.concat(out, ', ')))
		end,
	}
}
