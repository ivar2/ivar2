local handle = function(self, src, dest, msg)
	msg = utils.escape(msg):gsub('%s', '+')
	local content, status = utils.http("http://www.google.com/search?q=" .. msg)
	if(content) then
		-- It might explode, but shouldn't!
		local ans = content:match('<h2 .-><b>(.-)</b></h2><div')
		if(ans) then
			self:msg(dest, src, "%s: %s", src:match"^([^!]+)", utils.decodeHTML(ans:gsub("<sup>(.-)</sup>", "^%1"):gsub("<[^>]+> ?", "")))
		else
			self:msg(dest, src, '%s: %s', src:match"^([^!]+)", 'Do you want some air with that fail?')
		end
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!gcalc (.+)$"] = handle,
	["^:(%S+) PRIVMSG (%S+) :!calc (.+)$"] = handle,
	["^:(%S+) PRIVMSG (%S+) :!galc (.+)$"] = handle,
}
