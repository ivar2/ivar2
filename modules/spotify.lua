-- They'll probably add more crap later on...
-- http://developer.spotify.com/en/libspotify/docs/group__link.html
local patterns = {
	'(spotify:(track):([^%s]+))',
	'(spotify:(album):([^%s]+))',
	'(spotify:(artist):([^%s]+))',
	-- These two don't give us any nice information (yet).
--	'spotify:search:([^%s]+)',
--	'spotify:playlist:([^%s]+)',
}

local getinfo = function(str, type, hash)
	-- Hacks, we like them!
	local old = socket.http.USERAGENT
	socket.http.USERAGENT = 'Otravi/1.0'
	local url = string.format("http://open.spotify.com/%s/%s", type, hash)
	local content = utils.http(url)
	socket.http.USERAGENT = old

	local info = content:match"<title>(.-)</title>"
	if(info) then
		info = utils.decodeHTML(info)
		return string.format("%s - %s", info:gsub('%s%-%s[Ss]potify',''), url)
	end
end

local found = 0
local uris
local gsubit = function(str, type, hash)
	found = found + 1

	local total = 1
	for k in pairs(uris) do
		total = total + 1
	end

	if(not uris[str]) then
		uris[str] = {
			n = found,
			m = total,
			info = getinfo(str, type, hash),
		}
	else
		uris[str].n = string.format("%s+%d", uris[str].n, found)
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :(.+)$"] = function(self, src, dest, msg)
		uris, found = {}, 0
		for key, msg in pairs(utils.split(msg, " ")) do
			for _, pattern in ipairs(patterns) do
				msg:gsub(pattern, gsubit)
			end
		end

		if(next(uris)) then
			local out = {}
			for str, data in pairs(uris) do
				if(data.info) then
					table.insert(out, data.m, string.format("\002[%s]\002 %s", data.n, data.info))
				end
			end

			if(#out > 0) then self:msg(dest, src, table.concat(out, " ")) end
		end
	end
}
