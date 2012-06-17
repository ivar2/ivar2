local simplehttp = require'simplehttp'

customHosts['%.donmai%.us'] = function(queue, info)
	local path = info.path

	if(path and path:match('/data/([^%.]+)')) then
		local md5 = path:match('/data/([^%.]+)')
		local domain = info.host
		simplehttp(
			string.format('http://%s/post/index.xml?tags=md5:%s', domain, md5),

			function(data, url, response)
				local id = data:match(' id="(%d+)"')
				local tags = data:match('tags="([^"]+)')

				queue:done(string.format('http://%s/post/show/%s/ - %s', domain, id, limitOutput(tags)))
			end
		)

		return true
	end
end
