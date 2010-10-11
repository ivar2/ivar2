require'socket.url'
local date = require'date'

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
		if(month and day and year) then
			return string.format('%s.%s.%s', day, monthName[month], year:sub(-2))
		end

		local month, year = str:match('([^/]+)/([^/]+)')
		if(month and year) then
			return string.format('%s.%s.%s', '??', monthName[month], year:sub(-2))
		end

		return str
	else
		return '?'
	end
end

local handleGenres = function(str)
	return str:gsub(' |', ',')
end

local handleEpisode = function(str, raw)
	local num, name, date = str:match('([^%^]+)%^([^%^]+)%^([^%^]+)')

	if(raw) then
		return num, name, date
	else
		return string.format('%s %s', num, handleDate(date))
	end
end

local handleAirtime = function(rfc)
	local year, month, day, hour, minute, seconds, offset = rfc:match('([^%-]+)%-([^%-]+)%-([^T]+)T([^:]+):([^:]+):([^%-%+]+)(.*)$')

	year = tonumber(year)
	month = tonumber(month)
	day = tonumber(day)
	hour = tonumber(hour)
	minute = tonumber(minute)

	-- lua doesn't have any issues with HORRIBLE WRAPPING OF DOOMS!
	-- so feeding it 26 or something retarded as hour works fine.
	if(offset ~= 'Z') then
		local flag, oh, om = offset:match('([%+%-])([^:]+):(.*)$')
		if(flag == '-') then
			hour = hour + oh
			minute = minute + oh
		else
			hour = hour - oh
			minute = minute - oh
		end
	end

	if(year and month and day) then
		local airTime = {
			year = year,
			month = month,
			day = day,
			-- We should really compare date to date -u and fetch the offset, by why do
			-- that when we can use a HACK!
			hour = hour + 2,
			minute = minute,
		}

		local relTime = date.relativeTimeShort(os.time(airTime))
		if(relTime) then
			return relTime
		end
	end

	return 'In the future!'
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
	local output = string.format('%s', utils.decodeHTML(data['Show Name']))

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

		if(data['RFC3339']) then
			output = output .. ' (ETA: ' .. handleAirtime(data['RFC3339']) .. ')'
		end
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
				self:msg(dest, src, "%s", output)
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
