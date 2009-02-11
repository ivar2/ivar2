return {
	['^:%S+ 376'] = function(self)
		for _, chan in next, self.config.autojoin do
			self:log('INFO', 'Automatically joining %s', chan)
			self:send('JOIN %s', chan)
		end
	end
}
