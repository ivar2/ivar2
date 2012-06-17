local simplehttp = require'simplehttp'
local json = require'json'
local html2unicode = require'html'

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

customHosts['twitter%.com'] = function(queue, info)
	local query = info.query
	local path = info.path
	local fragment = info.fragment
	local tid

	local pattern = '/status[es]*/(%d+)'
	if(fragment and fragment:match(pattern)) then
		tid = fragment:match(pattern)
	elseif(path and path:match(pattern)) then
		tid = path:match(pattern)
	end

	if(tid) then
		simplehttp(
			('https://api.twitter.com/1/statuses/show/%s.json'):format(tid),

			function(data)
				local info = json.decode(utify8(data))
				local name = info.user.name
				local screen_name = html2unicode(info.user.screen_name)
				local tweet = html2unicode(info.text)

				local out = {}
				if(name == screen_name) then
					table.insert(out, string.format('\002%s\002:', name))
				else
					table.insert(out, string.format('\002%s\002 @%s:', name, screen_name))
				end

				table.insert(out, tweet)
				queue:done(table.concat(out, ' '))
			end
		)

		return true
	end
end
