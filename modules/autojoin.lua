return {
	['^:%S+ 376'] = function(self)
		if(self.config.channels) then
			for chan, chanData in next, self.config.channels do
				self:log('INFO', 'Automatically joining %s', chan)
				if(type(chanData) == 'table' and chanData.password) then
					self:send('JOIN %s %s', chan, chanData.password)
				else
					self:send('JOIN %s', chan)
				end
			end
		end
	end
}
