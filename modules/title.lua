local iconv = require"iconv"
local html2unicode = require'html'
local x0 = require'x0'
local uri = require"handler.uri"

local uri_parse = uri.parse
local DL_LIMIT = 2^16

local patterns = {
	-- X://Y url
	"^(https?://%S+)",
	"%f[%S](https?://%S+)",
	-- www.X.Y url
	"^(www%.[%w_-%%]+%.%S+)",
	"%f[%S](www%.[%w_-%%]+%.%S+)",
}

local translateCharset = {
	utf8 = 'utf-8',
	['x-sjis'] = 'sjis',
}

local verify = function(charset)
	if(charset) then
		charset = charset:lower()
		charset = translateCharset[charset] or charset

		return charset
	end
end

local guessCharset = function(headers, data)
	local charset
	-- XML:
	charset = verify(data:match('<%?xml .-encoding=[\'"]([^\'"]+)[\'"].->'))
	if(charset) then return charset end

	-- HTML5:
	charset = verify(data:match('<meta charset=[\'"]([\'"]+)[\'"]>'))
	if(charset) then return charset end

	-- HTML:
	charset = data:lower():match('<meta.-content=[\'"].-(charset=.-)[\'"].->')
	if(charset) then
		charset = verify(charset:match'=([^;]+)')
		if(charset) then return charset end
	end

	-- Header:
	local contentType = headers['Content-Type']
	if(contentType and contentType:match'charset') then
		charset = verify(contentType:match('charset=([^;]+)'))
		if(charset) then return charset end
	end
end

local handleData = function(headers, data)
	local charset = guessCharset(headers, data)
	if(charset and charset ~= 'utf-8') then
		local cd, err = iconv.new("utf-8", charset)
		if(cd) then
			data = cd:iconv(data)
		end
	end

	local title = data:match('<[tT][iI][tT][lL][eE]>(.-)</[tT][iI][tT][lL][eE]>')
	if(title) then
		for _, pattern in ipairs(patterns) do
			title = title:gsub(pattern, '<snip />')
		end

		title = html2unicode(title)
		title = title:gsub('%s%s+', ' ')

		if(title ~= '<snip />') then
			return title
		end
	end
end

local handleOutput = function(metadata)
	local output = {}
	for i=1, #metadata.processed do
		local lookup = metadata.processed[i]
		table.insert(output, string.format('\002[%s]\002 %s', lookup.index, lookup.output))
	end

	if(#output > 0) then
		ivar2:Msg('privmsg', metadata.destination, metadata.source, table.concat(output, ' '))
	end
end

local fetchInformation = function(metadata, index, url, indexString)
	local info = uri_parse(url)
	if(info.path == '') then
		url = url .. '/'
	end

	simplehttp(
		url,

		function(data, url, response)
			local message = handleData(response.headers, data)
			metadata.processed[index] = {index = indexString, output = message}
			metadata.num = metadata.num - 1

			if(metadata.num == 0) then
				handleOutput( metadata)
			end
		end,
		true,
		DL_LIMIT)
end

return {
	PRIVMSG = {
		function(self, source, destination, argument)
			-- We don't want to pick up URLs from commands.
			if(argument:sub(1,1) == '!') then return end

			local tmp = {}
			local tmpOrder = {}
			local index = 0
			for split in argument:gmatch('%S+') do
				index = index + 1
				for i=1, #patterns do
					local _, count = split:gsub(patterns[i], function(url)
						if(url:sub(1,4) ~= 'http') then
							url = 'http://' .. url
						end

						if(not tmp[url]) then
							table.insert(tmpOrder, url)
							tmp[url] = index
						else
							tmp[url] = string.format('%s+%d', tmp[url], index)
						end
					end)
					if(count > 0) then break end
				end
			end

			if(#tmpOrder > 0) then
				local output = {
					num = #tmpOrder,
					source = source,
					destination = destination,
					processed = {},
				}

				for i=1, #tmpOrder do
					local url = tmpOrder[i]
					fetchInformation(output, i, url, tmp[url])
				end
			end
		end,
	},
}
