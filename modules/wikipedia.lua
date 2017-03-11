local util = require'util'

local function handler(self, source, destination, args, domain)
	local query = util.urlEncode(args:gsub(' ', '_'))
	domain = domain or 'en'
	util.simplehttp(
		string.format('https://%s.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&redirects=1&titles=%s', domain, query),
		function(js, url, response)
			local data = util.json.decode(js)
			local _, entry = next(data.query.pages)
			if not entry or not entry.extract then
				say('Missing entry')
			else
				-- Sometimes text is very long, let's try to snip some
				local text = entry.extract
				text = text:match('(.-)\n') or text
				say(text)
			end
		end
	)
end

return {
	PRIVMSG = {
		['^%pwikipedia (.*)$'] = handler,
		['^%pwp (.*)$'] = handler,
		['^%p([a-z][a-z])wp (.*)$'] = function(self, source, destination, code, arg)
			handler(self, source, destination, arg, code)
		end
	},
}
