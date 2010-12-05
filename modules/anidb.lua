local udp

-- Cache
local cache = {}

-- Socket var
local host = 'api.anidb.info'
local port = 9000
local ip = socket.dns.toip(host)

-- AniDB related vars
local destination
local source
local message
local session

local db = 'data/anidb_db.lua'

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

-- Reply handlers.
local handlers = {}

local _fmt = function(self, fmt, ...)
	if(select('#', ...) > 0) then
		local succ, err = pcall(string.format, fmt, ...)
		if(not succ) then
			self:log('ERROR', 'Failed string.format: ' .. tostring(err) .. ' Traceback' .. debug.traceback())

			return
		end

		fmt = err
	end

	return fmt
end

local send = function(self, fmt, ...)
	fmt = _fmt(self, fmt, ...)

	if(fmt) then
		local sent, err = udp:send(fmt)
		if(err) then
			return nil, err
		else
			return true
		end
	end
end

local recv = function(self)
	local reply, err = udp:receive()
	if(err) then
		return nil, err
	end

	return true, reply
end

local sendrecv = function(self, fmt, ...)
	local succ, err  = send(self, fmt, ...)

	if(succ) then
		local succ, err = recv()

		if(succ) then
			local id, data = err:match'(%d+) (.*)'
			if(handlers[id]) then
				local succ, err = handlers[id](self, data)
				if(not succ) then
					print('Handler failed!', id, err)
				elseif(err) then
					self:msg(destination, source, err)
				end
			else
				print('Unknown handler id', id, data)
			end
		else
			return nil, err, 'receive'
		end
	else
		return nil, err, 'send'
	end

	return true
end

local doLogin = function(self)
	local succ, err, handler = sendrecv(self, 'AUTH user=%s&pass=%s&protover=3&client=ivartre&clientver=0&enc=utf-8', self.config.anidbUser, self.config.anidbPassword)
	if(not succ) then
		if(handler == 'send') then
			self:msg(destination, source, 'AniDB login failed.. :(')
		elseif(handler == 'receive') then
			self:msg(destination, source, 'AniDB reply failed. :(')
		end

		return nil, err
	else
		return true
	end
end

-- 501 LOGIN FIRST
handlers['501'] = function(self)
	local succ, err = doLogin(self)
	if(not succ) then
		print('Login failed!', tostring(err))
		return nil, err
	end

	return true
end

-- 200 LOGIN ACCEPTED
-- Send data.
handlers['200'] = function(self, data)
	if(data) then
		session = data:match'(%S+)'
	end

	local succ, err, handler = sendrecv(self, 'ANIME aid=%s&amask=%s&s=%s', message, amask, session)
	if(not succ) then
		if(handler == 'send') then
			self:msg(destination, source, 'Fetching information from AniDB failed. :(')
		elseif(handler == 'receive') then
			self:msg(destination, source, 'AniDB reply failed. :(')
		end

		return nil, err
	else
		return true
	end
end

-- 230 ANIME
handlers['230'] = function(self, data)
	data = data:match'\n(.*)\n'
	-- LINE OF DOOM!
	local aid, year, type, catlist, catweight, romaji, kanji, max, min, airStart, airEnd, rating, temp, review = unpack(utils.split(data, '|'))
	local cats = mergeCatInfo(utils.split(catlist, ','), utils.split(catweight, ','))

	-- Convert airEnd:
	if(airEnd == '0') then
		airEnd = '?'
	else
		airEnd = os.date('%d.%m.%y', airEnd)
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
	local total = 300
	if(rating == '0') then total = total - 100 end
	if(temp == '0') then total = total - 100 end
	if(review == '0') then total = total - 100 end

	local out = string.format(
		'%s (%s till %s) %s, %s/%s episodes, %.2f rating / %s | http://anidb.net/a%s',
		title,
		os.date('%d.%m.%y', airStart), airEnd,
		type, min, max,
		(rating + temp + review) / total,
		table.concat(cats, ', '), aid
	)

	cache[message] = out
	return true, out
end

-- 330 NO SUCH ANIME
handlers['330'] = function(self)
	return true, 'No such anime. :('
end

-- 504 CLIENT BANNED
handlers['504'] = function(self, msg)
	return nil, msg
end

-- 506 INVALID SESSION
handlers['506'] = function(self)
	local succ, err = doLogin(self)
	if(not succ) then
		print('Login failed!', tostring(err))
		return nil, err
	end

	return true
end

return {
	["^:(%S+) PRIVMSG (%S+) :!anidb (.+)$"] = function(self, src, dest, msg)
		local num = tonumber(msg)
		if(num) then
			msg = num
		else
			local search = loadfile(db) (msg)
			local matches = loadstring('return ' .. search) ()

			if(#matches == 0) then
				return self:msg(dest, src, 'No matches found. :(')
			elseif(matches[1].weight == 1000 or matches[1] and not matches[2]) then
				msg = matches[1].aid
			else
				local n = 15
				local out = {}
				for i=1, #matches do
					local match = matches[i]
					local aid = match.aid
					local title = match.title

					n = n + #title + #tostring(aid) + 4
					if(n < utils.limit) then
						table.insert(out, string.format('\002[%s]\002 %s', aid, title))
					end
				end

				return self:msg(dest, src, 'Multiple hits: %s', table.concat(out, ' '))
			end
		end

		-- we should have a timer here, but...
		if(cache[msg]) then
			self:log('INFO', 'Fetching [%s] AniDB information from cache.', msg)
			return self:msg(dest, src, cache[msg])
		end

		destination = dest
		source = src
		message = msg

		if(not udp) then
			udp = self.AniDBudp or socket.udp()
			udp:settimeout(3)
			udp:setpeername(ip, port)
			self.AniDBudp = udp
		end

		if(not session) then
			local succ, err = handlers['501'](self)
			if(not succ) then return self:msg(dest, src, 'AniDB login failed. :(') end
		else
			handlers['200'](self)
		end
	end,
}
