local simplehttp = require'simplehttp'
local html2unicode = require'html'
local iconv = require"iconv"
local iso2utf = iconv.new("utf-8", "iso-8859-15")
local utf2iso = iconv.new('iso-8859-15', 'utf-8')

local urlEncode = function(str)
	return str:gsub(
		'([^%w ])',
		function (c)
			return string.format ("%%%02X", string.byte(c))
		end
	):gsub(' ', '+')
end

local trim = function(s)
	return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

local limitOutput = function(str)
	local limit = 100
	if(#str > limit) then
		str = str:sub(1, limit)
		if(#str == limit) then
			-- Clip it at the last space:
			str = str:match('^.* ') .. '…'
		end
	end

	return str
end

local parseLine = function(data)
	local entry = {
		lookup = {},
		examples = {},
	}

	local insertAt
	for td in data:gmatch('<td[^>]->(.-)</td>') do
		-- Strip away HTML.
		local line = trim(td:gsub('<span class="b">([^%d]-)</span>', '%1'):gsub('</?[%w:]+[^>]-/?>', ''))
		line = html2unicode(line:gsub('%s%s+', ' '))

		print(line)

		if(#line > 0) then
			if(tonumber(line)) then
				insertAt = tonumber(line)
			elseif(not line:match('%s+')) then
				table.insert(entry.lookup, line)
			elseif(insertAt) then
				entry.examples[insertAt] = line
				insertAt = nil
			else
				entry.meaning = line
			end
		end
	end

	return entry
end

local parseData = function(data)
	data = iso2utf:iconv(data)

	-- This page is a typical example of someone using XHTML+CSS+JS, while still
	-- coding like they used to back in 1998.
	data = data:gsub('\r', ''):match('<div id="kolonne_enkel"[^>]+>(.-)</div>'):gsub('&nbsp;', '')

	local words = {}
	if(data:match('liten_ordliste')) then
		for entryData in data:gmatch('<table class="liten_ordliste">([^\n]+)') do
			table.insert(words, parseLine(entryData))
		end
	else
		data = data:match('(<td><span class="b">[^\n]+)')
		local entry = parseLine(data)
		if(entry) then
			table.insert(words, entry)
		end
	end

	return words
end

local handleInput = function(self, source, destination, word)
	local query = urlEncode(utf2iso:iconv(word))
	simplehttp(
		"http://www.nob-ordbok.uio.no/perl/ordbok.cgi?ordbok=bokmaal&bokmaal=+&OPP=" .. query,

		function(data)
			local words = parseData(data)

			local msgLimit = (512 - 16 - 65 - 10) - #self.config.nick - #destination
			-- size of the word + x0 url.
			local n =  #word + 23
			local out = {}
			for i=1, #words do
				local word = words[i]
				local lookup = table.concat(word.lookup, ', ')
				local definition = word.meaning
				if(#definition < 30 and word.examples[1]) then
					definition = definition .. ' ' .. word.examples[1]
				end
				local message = string.format('\002[%s]\002: %s', lookup, limitOutput(definition))

				n = n + #message
				if(n < msgLimit) then
					table.insert(out, message)
				else
					break
				end
			end

			if(#out > 0) then
				self:Msg('privmsg', destination, source, '%s | http://x0.no/dokpro/%s', table.concat(out, ', '), word)
			else
				self:Msg('privmsg', destination, source, '%s: %s', source.nick, 'Du suger, prøv igjen.')
			end
		end
	)
end

return {
	PRIVMSG = {
		['^!dokpro (.+)$'] = handleInput,
		['^!ordbok (.+)$'] = handleInput,
	},
}
