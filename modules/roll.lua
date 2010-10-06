local ltrim = function(r, s)
	if s == nil then
		s, r = r, "%s+"
	end
	return (string.gsub(s, "^" .. r, ""))
end

math.randomseed(os.time() % 1e5)

return {
	["^:(%S+) PRIVMSG (%S+) :!roll (.+)$"] = function(self, src, dest, msg)
		local a,b = unpack(utils.split(msg, "%s+"))
		a, b = tonumber(a), tonumber(b)

		local nick = self:srctonick(src)
		local seed
		if(a and b and a < b) then
			seed = math.random(a, b)
		elseif(a and a > 1) then
			seed = math.random(1, a)
		else
			return self:msg(dest, src, '%s: %s', nick, 'I will suffocate you with a pillow in your sleep')
		end

		self:msg(dest, src, "%s: %s", nick, seed)
	end
}
