local matchFirst = function(pattern, ...)
	for i=1, select('#', ...) do
		local arg = select(i, ...)
		if(arg) then
			local match = arg:match(pattern)
			if(match) then return match end
		end
	end
end

local events = {
	['PING'] = {
		core = {
			function(self, source, destination, server)
				self:Send('PONG %s', server)
			end,
		},
	},

	['JOIN'] = {
		core = {
			function(self, source, chan)
				chan = chan:lower()

				if(not self.channels[chan]) then
					self.channels[chan] = {
						nicks = {},
						modes = {},
					}
				end

				if(source.nick == self.config.nick) then
					self:Mode(chan, '')
					-- Servers sends us our hostmask on joins, use that to set it
					self.hostmask = source.mask
				end

				self.channels[chan].nicks[source.nick] = {
					modes = {},
				}
			end,
		},
	},

	['PART'] = {
		core = {
			function(self, source, chan)
				chan = chan:lower()

				if(source.nick == self.config.nick) then
					self.channels[chan] = nil
				else
					self.channels[chan].nicks[source.nick] = nil
				end
			end,
		},
	},

	['KICK'] = {
		core = {
			function(self, source, destination, message)
				local chan, nick = destination:match("^(%S+) (%S+)$")
				chan = chan:lower()

				if(nick == self.config.nick) then
					self.channels[chan] = nil
				else
					self.channels[chan].nicks[nick] = nil
				end
			end,
		},
	},

	['NICK'] = {
		core = {
			function(self, source, nick)
				for channel, data in pairs(self.channels) do
					data.nicks[nick] = data.nicks[source.nick]
					data.nicks[source.nick] = nil
				end
			end,
		},
	},

	['MODE'] = {
		core = {
			function(self, source, channel, modeLine)
				if(channel == self.config.nick) then return end

				local dir, mode, nick = modeLine:match('([+%-])([^ ]+) ?(.*)$')
				local modes

				channel = channel:lower()
				if(self.channels[channel].nicks[nick]) then
					modes = self.channels[channel].nicks[nick].modes
				elseif(nick == '') then
					modes = self.channels[channel].modes
				end

				if(not modes) then
					return
				end

				if(dir == '+') then
					for m in mode:gmatch('[a-zA-Z]') do
						table.insert(modes, m)
					end
				elseif(dir == '-') then
					for m in mode:gmatch('[a-zA-Z]') do
						for i=1, #modes do
							if(modes[i] == m) then
								table.remove(modes, i)
								break
							end
						end
					end
				end
			end,
		},
	},

	['005'] = {
		core = {
			-- XXX: We should probably parse out everything and move it to
			-- self.server or something.
			function(self, source, param, param2)
				local network = matchFirst("NETWORK=(%S+)", param, param2)
				if(network) then
					self.network = network
				end

				local maxNickLength = matchFirst("MAXNICKLEN=(%d+)", param, param2)
				if(maxNickLength) then
					self.maxNickLength = maxNickLength
				end
			end,
		},
	},

	['324'] = {
		core = {
			function(self, source, _, argument)
				local chan, dir, modes = argument:match('([^ ]+) ([+%-])(.*)$')

				chan = chan:lower()
				local chanModes = self.channels[chan].modes
				for mode in modes:gmatch('[a-zA-Z]') do
					table.insert(chanModes, mode)
				end
			end,
		},
	},

	['353'] = {
		core = {
			function(self, source, chan, nicks)
				chan = chan:match('[=*@] (.*)$')
				chan = chan:lower()

				local convert = {
					['+'] = 'v',
					['@'] = 'o',
				}

				if(not self.channels[chan]) then
					self.channels[chan] = {
						nicks = {},
						modes = {},
					}
				end
				for nick in nicks:gmatch("%S+") do
					local prefix = nick:sub(1, 1)
					if(convert[prefix]) then
						nick = nick:sub(2)
					else
						prefix = nil
					end

					self.channels[chan].nicks[nick] = {
						modes = {
							convert[prefix]
						},
					}
				end
			end,
		},
	},

	['433'] = {
		core = {
			function(self)
				local nick = self.config.nick:sub(1,8) .. '_'
				self:Nick(nick)
			end,
		},
	},

	['437'] = {
		core = {
			function(self, source, chan, argument)
				chan = chan:lower()

				local password
				for channel, data in next, self.config.channels do
					if(channel == chan) then
						if(type(data) == 'table' and data.password) then
							password = data.password
						end

						break
					end
				end

				self:Timer('_join', 30, function(loop, timer, revents)
					self:Join(chan, password)
				end)
			end,
		},
	},
}
return events
