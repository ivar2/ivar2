local simplehttp = require'simplehttp'
local util = require'util'
local html2unicode = require'html'

customHosts['snl.no'] = function(queue, info)
	local path = info.path
	if(path and path:match('/.*/.*')) then
			return false
	end

	if(path and path:match('/(.*)$')) then
		local artikkel = path:match('/(.*)$')
		local domain = info.host
		simplehttp(
			string.format('http://%s/%s.json', domain, artikkel),

			function(js, url, response)
				local data = util.json.decode(js)
				-- extract first paragraph
				local match = data.xhtml_body:match[[<p>(.-)</p>]]
				-- extract text from links
				local text = match:gsub('<a href=.->(.-)</a>', function(m)
						return m
				end)
				-- strip all html tags and convert html entities
				text = html2unicode(text:gsub('<.->', '')):gsub('%s+', ' ')

				queue:done(string.format('[%s] %s', util.bold(data.title), text))
			end
		)

		return true
	end
end
