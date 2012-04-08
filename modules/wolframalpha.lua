local simplehttp = require'simplehttp'
local html2unicode = require'html'

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+')
end

-- Soon, expat.
local parseXML = function(xml)
	local results = {}
	for args, pod in xml:gmatch('<pod([^>]+)>(.-)</pod>') do
		local title = args:match("title='([^']+)'")
		local id = args:match("id='Input'")
		if(not id) then
			local sub = {}
			for args, subpod in pod:gmatch('<subpod([^>]+)>(.-)</subpod>') do
				local plain = subpod:match('<plaintext>(.-)</plaintext>')
				if(plain and #plain > 0) then
					-- Output tends to have double spaces.
					plain = plain:gsub('%s+', ' ')
					-- Convert the WA unicode escaping into HTML.
					plain = plain:gsub('\\:([0-9a-z][0-9a-z][0-9a-z][0-9a-z])', '&#x%1;')
					table.insert(sub, (html2unicode(plain)))
				end
			end

			if(#sub > 0) then
				table.insert(results, string.format('\002%s\002: %s', title, table.concat(sub, '; ')))
			end
		end
	end

	return results
end

local APIBase = 'http://api.wolframalpha.com/v2/query?input=%s&format=plaintext&appid=' .. ivar2.config.wolframalphaAPIKey
return {
	PRIVMSG = {
		['^!wa (.+)$'] = function(self, source, destination, input)
			simplehttp(
				APIBase:format(urlEncode(input)),

				function(data)
					local results = parseXML(data)
					local out = {}

					local n = 0
					local msgLimit = (512 - 16 - 65 - 10) - #self.config.nick - #destination
					for i=1, #results do
						n = n + #results[i]
						if(n < msgLimit) then
							table.insert(out, results[i])
						else
							break
						end
					end

					if(#out > 0) then
						self:Msg('privmsg', destination, source, table.concat(out, ' '))
					else
						self:Msg('privmsg', destination, source, '%s: That made no sense at all.', source.nick)
					end
				end
			)
		end,
	},
}
