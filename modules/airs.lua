return {
	["^:(%S+) PRIVMSG (%S+) :!airs (.+)$"] = function(self, src, dest, msg)
		local content, status = utils.http"http://www.mahou.org/Showtime/"
		content = content:match("<h1>Currently Airing</h1></center>.-<table.-<table.->(.-)</table>")

		msg = msg:lower()
		for title, station, airtime, eta in content:gmatch('<tr.->\n<td>.-</td>\n<td>(.-)<a name="%d+"></a></td>\n<td.->.-</td>\n<td.->(.-)</td>\n<td.->.-</td>\n<td.->(.-)</td>\n<td.->(.-)</td>\n') do
			local lower = title:lower()
			if(lower:match(msg)) then
				return self:msg(dest, src, "%s airs on %s on %s (ETA: %s)", title, station, airtime, eta:sub(1,-2))
			end
		end

		self:msg(dest, src, "The requested anime does not currently air, or you just simply failed.")
	end,
}
