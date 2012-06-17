local simplehttp = require'simplehttp'
local json = require'json'
local html2unicode = require'html'

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
