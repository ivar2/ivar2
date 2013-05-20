local simplehttp = require'simplehttp'
local sql = require'lsqlite3'

local trim = function(s)
	return s:match('^%s*(.-)%s*$')
end

local parseDate = function(datestr)
	local year, month, day, hour, min, sec = datestr:match("([^-]+)%-([^-]+)%-([^T]+)T([^:]+):([^:]+):(%d%d)")
	return os.time{
		year = year,
		month = month,
		day = day,
		hour = hour,
		min = min,
		sec = sec,
	}
end

local formatPeriod = function(period)
	return string.format("%s, %s°C", period.symbol.name, period.temperature.value)
end

local handleData = function(type, line)
	local out = {}
	local data = line:match(string.format("<%s (.-) />", type))

	string.gsub(data, '(%w+)="([^"]+)"', function(a, b)
		out[a] = b
	end)

	return out
end

local handleOutput = function(source, destination, data)
	local location = data:match("<location>(.-)</location>")
	local name = location:match("<name>([^<]+)</name>")
	local country = location:match("<country>([^<]+)</country>")

	local periods = {}
	local tabular = data:match("<tabular>(.*)</tabular>")
	for from, to, period, data in tabular:gmatch([[<time from="([^"]+)" to="([^"]+)" period="([^"]+)">(.-)</time>]]) do
		local time = {
			from = parseDate(from),
			to = parseDate(to),
			period = period
		}

		time.symbol = handleData('symbol', data)
		time.precipitation = handleData('precipitation', data)
		time.windDirection = handleData('windDirection', data)
		time.windSpeed = handleData("windSpeed", data)
		time.temperature = handleData('temperature', data)
		time.pressure = handleData('pressure', data)

		table.insert(periods, time)
	end

	local nextDay = os.time() - (os.time() % 86400) + 86400
	local now = periods[1]
	local later, laterKey
	if(now.period ~= "3") then
		for i=2, #periods do
			local period = periods[i]
			if(period.period == "2") then
				laterKey = i
				later = period
				break
			end
		end
	end

	local tomorrow
	for i=laterKey, #periods do
		local period = periods[i]
		if(period.from > nextDay and period.period == "2") then
			tomorrow = period

			break
		end
	end

	local out = {}
	table.insert(out, string.format("Current weather in %s (%s): %s", name, country, formatPeriod(now)))
	table.insert(out, string.format("Tonight: %s", formatPeriod(later)))
	if(tomorrow) then
		table.insert(out, string.format("Tomorrow: %s", formatPeriod(tomorrow)))
	end

	ivar2:Msg('privmsg', destination, source, table.concat(out, " - "))
end

return {
	PRIVMSG = {
		['^!yr (.+)$'] = function(self, source, destination, input)
			input = (input:gsub("^%l", string.upper))

			local db = sql.open("cache/places")
			local selectStmt = db:prepare("SELECT place, url FROM places WHERE place LIKE ?")
			selectStmt:bind_values(trim(input))

			local iter, vm = selectStmt:nrows()
			local place = iter(vm)

			if(place) then
				simplehttp(
					place.url,
					function(data)
						handleOutput(source, destination, data)
					end
				)
			else
				ivar2:Msg('privmsg', destination, source, "Does that place even exist?")
			end
		end,
	}
}
