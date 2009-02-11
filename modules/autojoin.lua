-- Expects a autojoin table in the config file.
--
-- Example:
-- config = {
--      ...
--      autojoin = {
--           '#chan1', '#chan2',
--      }
--      ...
-- }

return {
	['^:%S+ 376'] = function(self)
		if(self.config.autojoin) then
			for _, chan in next, self.config.autojoin do
				self:log('INFO', 'Automatically joining %s', chan)
				self:send('JOIN %s', chan)
			end
		end
	end
}
