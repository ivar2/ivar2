require'logging.console'
local log = logging.console()

return {
	['376'] = {
		function(self)
			if(self.config.channels) then
				for channel, data in next, self.config.channels do
					log:info(string.format('Automatically joining %s.', channel))
					if(type(data) == 'table' and data.password) then
						self:Join(channel, data.password)
					else
						self:Join(channel)
					end
				end
			end
		end,
	}
}
