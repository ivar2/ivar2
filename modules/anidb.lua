local udp

-- Cache
local cache = {}

-- Socket var
local host = 'api.anidb.info'
local port = 9000
local ip = socket.dns.toip(host)

-- AniDB related vars
local session
local amask = string.format(
	'%02X%02X%02X%02X%02X',

	--aid, year, type, catlist, catweight
	128 + 32 + 16 + 2 + 1,
	-- romaji, kanji
	128 + 64,
	-- episodes, normal ep count, air date, end date
	128 + 64 + 16 + 8,
	-- rating, temp rating, review rating
	128 + 32 + 8,
	-- nil...
	0
)

local mergeCatInfo = function(cats, weight)
	local out = {}

	for index, cat in next, cats do
		if(weight[index] == "6") then
			table.insert(out, cat)
		end
	end

	table.sort(out)

	return out
end

local doLogin = function(self)
	local sent, err = udp:send(string.format('AUTH user=%s&pass=%s&protover=3&client=ivartre&clientver=0&enc=utf-8', self.config.anidbUser, self.config.anidbPassword))
	if(err) then
		return nil, err
	end

	local reply, err = udp:receive()
	if(err) then
		return nil, err
	end

	local id, msg = reply:match'(%d+) (.*)'
	if(id == '200') then
		session = msg:match'(%S+)'
		return true
	else
		print('WHAT?!', id, msg)
		return nil, msg, id
	end
end

local handlers = {
	-- 501 LOGIN FIRST
	['501'] = function(self)
		local succ, err = doLogin(self)
		if(not succ) then
			print('Login failed!', tostring(err))
			return nil, err
		end

		return true
	end,
	-- 230 ANIME
	['230'] = function(self, msg, data)
		data = data:match'\n(.*)\n'
		local aid, year, type, catlist, catweight, romaji, kanji, max, min, startDate, endDate, rating, temp, review = unpack(utils.split(data, '|'))
		local cats = mergeCatInfo(utils.split(catlist, ','), utils.split(catweight, ','))

		-- Convert endDate:
		if(endDate == '0') then
			endDate = '?'
		else
			endDate = os.date('%d.%m.%y', endDate)
		end

		local title
		-- Convert titles:
		if(romaji == '') then
			title = kanji
		elseif(kanji == '') then
			title = romaji
		else
			title = string.format('%s // %s', romaji, kanji)
		end

		-- Convert episode.
		if(max == '0') then
			max = '?'
		end

		-- Cheat ratings...
		if(rating == '0') then rating = 1000 end
		if(temp == '0') then temp = 1000 end
		if(review== '0') then review = 1000 end

		local out = string.format(
			'%s (%s till %s) %s, %s/%s episodes, %.2f rating / %s | http://anidb.net/a%s',
			title,
			os.date('%d.%m.%y', startDate), endDate,
			type, min, max,
			(rating + temp + review) / 300,
			table.concat(cats, ', '), aid
		)

		cache[msg] = out
		return true, out
	end,
	-- 330 NO SUCH ANIME
	['330'] = function(self)
		return true, 'No such anime. :('
	end,

	-- 504 CLIENT BANNED
	['504'] = function(self, msg)
		return nil, msg
	end,
	-- 506 INVALID SESSION
	['506'] = function(self)
		local succ, err = doLogin(self)
		if(not succ) then
			print('Login failed!', tostring(err))
			return nil, err
		end

		return true
	end,
}

return {
	["^:(%S+) PRIVMSG (%S+) :!anidb (.+)$"] = function(self, src, dest, msg)
		-- we should have a timer here, but...
		local type = 'aname'
		local num = tonumber(msg)
		if(num) then
			msg = num
			type = 'aid'
		end

		if(cache[msg]) then
			return self:privmsg(dest, cache[msg])
		end

		if(not udp) then
			udp = self.AniDBudp or socket.udp()
			udp:settimeout(3)
			udp:setpeername(ip, port)
			self.AniDBudp = udp
		end

		if(not session) then
			local succ, err = handlers['501'](self)
			if(not succ) then return self:privmsg(dest, 'AniDB login failed. :(') end
		end

		local sent, err = udp:send(string.format('ANIME %s=%s&amask=%s&s=%s', type, msg, amask, session))
		if(err) then
			self:privmsg(dest, 'Fetching information from AniDB failed. :(')
			print('Fetch failed', tostring(err))

			return
		end

		local reply, err = udp:receive()
		if(err) then
			self:privmsg(dest, 'AniDB reply failed. :(')
			print('Receive failed.', err)

			return
		end

		local id, data = reply:match'(%d+) (.*)'
		if(handlers[id]) then
			local succ, err = handlers[id](self, msg, data)
			if(not succ) then
				print('Handler failed!', err)
			else
				self:privmsg(dest, err, id, data)
			end
		else
			print('Unknown handler id', id, data)
		end
	end,
}
