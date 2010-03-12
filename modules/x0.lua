local handler = function(self, src, dest, msg)
	local short = utils.x0(msg)
	if(short) then self:msg(dest, src, "%s: %s", self:srctonick(src), short) end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!shorten (.+)$"] = handler,
	["^:(%S+) PRIVMSG (%S+) :!x0 (.+)$"] = handler,
}
