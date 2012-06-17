local simplehttp = require'simplehttp'
local html2unicode = require'html'

local fetchInformation = function(queue, vid)
	simplehttp(
		'https://gdata.youtube.com/feeds/api/videos/' .. vid,

		function(data)
			local title = html2unicode(data:match("<title type='text'>([^<]+)</title>"))
			local uploader = html2unicode(data:match('<author><name>([^<]+)</name>'))
			local duration = tonumber(data:match("<yt:duration seconds='(%d+)'/>"))

			local output
			if(duration) then
				if(duration > 3600) then
					duration = string.format(
						'%d:%02d:%02d',
						math.floor(duration / 3600),
						math.floor((duration % 3600) / 60),
						duration % 60
					)
				else
					duration = string.format(
						'%d:%02d',
						math.floor(duration / 60),
						duration % 60
					)
				end

				output = string.format('%s (%s) by %s', title, duration, uploader)
			else
				output = string.format('%s by %s', title, uploader)
			end

			queue:done(output)
		end
	)
end

customHosts['youtube%.com'] = function(queue, info)
	local query = info.query
	local path = info.path
	local fragment = info.fragment
	local vid

	if(query and query:match('v=[a-zA-Z0-9_-]+')) then
		vid = query:match('v=([a-zA-Z0-9_-]+)')
	elseif(fragment and fragment:match('.*/%d+/([a-zA-Z0-9_-]+)')) then
		vid = fragment:match('.*/%d+/([a-zA-Z0-9_-]+)')
		-- FIXME: lua-handler's URI parser doesn't split path and fragment
		-- correctly when there's no query present.
	elseif(path) then
		if(path:match('#.*/%d+/([a-zA-Z0-9_-]+)')) then
			vid = path:match('#.*/%d+/([a-zA-Z0-9_-]+)')
		elseif(path:match('/v/([a-zA-Z0-9_-]+)')) then
			vid = path:match('/v/([a-zA-Z0-9_-]+)')
		end
	end

	if(vid) then
		fetchInformation(queue, vid)

		return true
	end
end

customHosts['youtu%.be'] = function(queue, info)
	local path = info.path
	local vid

	if(path and path:match('/([a-zA-Z0-9_-]+)')) then
		vid = path:match('/([a-zA-Z0-9_-]+)')
	end

	if(vid) then
		fetchInformation(queue, vid)

		return true
	end
end
