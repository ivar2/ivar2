local x0 = require'x0'
x0.init(ivar2.Loop)

local handler = function(self, source, destination, input)
	x0.lookup(input, function(url)
		self:Msg('privmsg', destination, source, '%s: %s', source.nick, url)
	end)
end

return {
	PRIVMSG = {
		['^!shorten (.+)$'] = handler,
		['^!x0 (.+)$'] = handler,
	},
}
