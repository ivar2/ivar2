local simplehttp = require'simplehttp'
local json = require'json'

local utify8 = function(str)
	str = str:gsub("\\u(....)", function(n)
		n = tonumber(n, 16)

		if(n < 128) then
			return string.char(n)
		elseif(n < 2048) then
			return string.char(192 + ((n - (n % 64)) / 64), 128 + (n % 64))
		else
			return string.char(224 + ((n - (n % 4096)) / 4096), 128 + (((n % 4096) - (n % 64)) / 64), 128 + (n % 64))
		end
	end)

	return str
end

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+')
end

local parseData = function(source, destination, data)
	data = utify8(data)
	data = json.decode(data)

	local movie = data.movies[1]
	if(not movie) then
		return ivar2:Msg('privmsg', destination, source, "Not even Rotten Tomatoes would rate that movie.")
	end

	local out = string.format(
		"\002%s\002 (%d) %d min, %s - Critics: %d%% (%s) Audience: %d%% (%s) - %s",
		movie['title'], movie['year'], movie['runtime'], movie['mpaa_rating'],
		movie['ratings']['critics_score'], movie['ratings']['critics_rating'],
		movie['ratings']['audience_score'], movie['ratings']['audience_rating'],
		movie['critics_consensus']
	)

	ivar2:Msg('privmsg', destination, source, out)
end

local urlFormat = 'http://api.rottentomatoes.com/api/public/v1.0/movies.json?page_limit=1&apikey=%s&q=%s'
local handler = function(self, source, destination, input)
	local search = urlEncode(input)

	simplehttp(
		urlFormat:format(self.config.rottenTomatoesAPIKey, search),
		function(data)
			parseData(source, destination, data)
		end
	)
end

return {
	PRIVMSG = {
		['^!rt (.+)$'] = handler,
		['^!rotten (.+)$'] = handler,
	},
}
