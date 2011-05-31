local iconv = require"iconv"
local iso2utf = iconv.new("utf-8", "iso-8859-15")
local utf2iso = iconv.new('iso-8859-15', 'utf-8')

return {
	["^:(%S+) PRIVMSG (%S+) :!dokpro (.+)$"] = function(self, src, dest, msg)
		local query = utils.escape(utf2iso:iconv(msg)):gsub('%s', '+')
		print(query)
		local content, status = utils.http("http://www.nob-ordbok.uio.no/perl/ordbok.cgi?ordbok=bokmaal&bokmaal=+&OPP=" .. query)

		if(content) then
			-- It might explode, but shouldn't!
			local ans = content:match('</table></td><td>(.-)</table>')
			local nick = src:match'^([^!]+)'
			if(ans) then
				ans = iso2utf:iconv(ans)
				-- strip out all the html and convert entities:
				ans = utils.decodeHTML(ans:gsub('<%/?[%w:]+.-%/?>', ''))
				self:msg(
					dest, src,
					"%s: %s | http://x0.no/dokpro/%s",
					nick,
					ans,
					msg:gsub('%s', '+')
				)
			else
				self:msg(dest, src, '%s: %s', nick, 'Du suger, prøv igjen')
			end
		end
	end
}
