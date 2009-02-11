return {
	['^:%S+ (%d+)'] = function(self, num)
		if(num == '376') then
			for _, chan in next, self.config.autojoin do
				self:log('INFO', 'Automatically joining %s', chan)
				self:send('JOIN %s', chan)
			end
		end
	end
}
