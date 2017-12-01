local util = require'util'
local simplehttp = util.simplehttp
local json = util.json

customHosts['twitch%.tv'] = function(queue, info)
	if not ivar2.config.twitchApiKey then
		return
	end

	local path = info.path
	if(not path) then
		return
	end

  local url
	if(path:match('^/videos/(%d+)')) then
    local video = path:match('^/videos/(%d+)')
		url = string.format('https://api.twitch.tv/kraken/videos/%s', video)
	elseif(path:match('/[^/]+')) then
		local username = path:match('[^/]+')
		url = string.format('https://api.twitch.tv/kraken/channels/%s', username)
	end

	if(not url) then
		return
	end

	simplehttp({
		url=url,
		-- HTTP doesn't allow lowercase haeders
		version=1.1,
		headers={
			['Client-ID'] = ivar2.config.twitchApiKey,
		}},

		function(data, url, response)
			local resp = json.decode(data)

			local out = {}
			if(resp['error']) then
				table.insert(out, resp['error'])
				table.insert(out, ': ')
				table.insert(out, resp['message'])
				queue:done(table.concat(out))
				return
			end
			if(resp.title) then
				table.insert(out, resp.title)
			else
				table.insert(out, string.format('\002%s\002: ', resp.display_name))
				if(resp.status) then
					table.insert(out, (tostring(resp.status):gsub('\n', ' ')))
				end
			end

			if(resp.game ~= json.null) then
				table.insert(out, string.format(" (Playing: %s)", resp.game))
			end

			queue:done(table.concat(out))
		end
	)

	return true
end
