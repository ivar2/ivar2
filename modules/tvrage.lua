require'socket.url'

local monthName = {
	Jan = '01',
	Feb = '02',
	Mar = '03',
	Apr = '04',
	May = '05',
	Jun = '06',
	Jul = '07',
	Aug = '08',
	Sep = '09',
	Oct = '10',
	Nov = '11',
	Dec = '12'
}

local handleDate = function(str)
	if(str ~= '') then
		local month, day, year = str:match('([^/]+)/([^/]+)/([^/]+)')
		return string.format('%s.%s.%s', day, monthName[month], year:sub(-2))
	else
		return '?'
	end
end

local handleGenres = function(str)
	return str:gsub(' |', ',')
end

local handleEpisode = function(str)
	local num, name, date = str:match('([^%^]+)%^([^%^]+)%^([^%^]+)')

	return string.format('%s %s', num, handleDate(date))
end

local handleData = function(str)
	local data = {}

	local tmp = utils.split(str:gsub('\n', '@'), '@')
	for i=1, #tmp, 2 do
		local k, v = tmp[i], tmp[i+1]
		data[k] = v
	end

	return data
end

local out = function(data)
	local output = string.format('%s', data['Show Name'])

	if(data['Started'] and data['Ended']) then
		output = output .. string.format(' (%s till %s)', handleDate(data['Started']), handleDate(data['Ended']))
	end

	if(data['Status']) then
		output = output .. ' ' .. data['Status']
	end

	if(data['Genres']) then
		output = output .. ' // ' .. handleGenres(data['Genres'])
	end

	if(data['Latest Episode']) then
		output = output .. ' | Latest: ' .. handleEpisode(data['Latest Episode'])
	end

	if(data['Next Episode']) then
		output = output .. ' | Next: ' .. handleEpisode(data['Next Episode'])
	end

	if(data['Show URL']) then
		output = output .. ' | ' .. data['Show URL']
	end

	return output
end

local handle = function(self, src, dest, msg)
	local url = ('http://services.tvrage.com/tools/quickinfo.php?show=%s'):format(socket.url.escape(msg))
	local content, status = utils.http(url)
	if(status == 200) then
		if(content:sub(1,15) == 'No Show Results') then
			self:msg(dest, src, "%s: %s", src:match"^([^!]+)", 'Invalid show? :(')
		else
			local data = handleData(content)
			local output = out(data)

			if(out) then
				self:msg(dest, src, "%s: %s", src:match"^([^!]+)", output)
			else
				self:msg(dest, src, "%s: %s", 'haste', 'I blew up :(')
			end
		end
	else
		self:msg(dest, src, "Sorry %s, I'm emo at haste and need to cut myself %s times.", src:match"^([^!]+)", status)
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!tv (.+)$"] = handle,
	["^:(%S+) PRIVMSG (%S+) :!tvr (.+)$"] = handle,
	["^:(%S+) PRIVMSG (%S+) :!tvrage (.+)$"] = handle,
}
