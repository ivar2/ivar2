local iconv = require"iconv"
local parse = require"socket.url".parse
local patterns = {
	-- X://Y url
	"^(%a[%w%.+-]+://%S+)",
	"%f[%S](%a[%w%.+-]+://%S+)",
	-- www.X.Y url
	"^(www%.[%w_-%%]+%.%S+)",
	"%f[%S](www%.[%w_-%%]+%.%S+)",
	-- XXX.YYY.ZZZ.WWW:VVVV/UUUUU IPv4 address with port and path
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)",
	-- XXX.YYY.ZZZ.WWW/VVVVV IPv4 address with path
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)",
	-- XXX.YYY.ZZZ.WWW IPv4 address
	"^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",
	"%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",
	-- X.Y.Z:WWWW/VVVVV url with port and path
	"^([%w_-%%%.]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",
	"%f[%S]([%w_-%%%.]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",
	-- X.Y.Z:WWWW url with port (ts server for example)
	"^([%w_-%%%.]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]",
	"%f[%S]([%w_-%%%.]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]",
	-- X.Y.Z/WWWWW url with path
	--	"^([%w_-%%%.]+[%w_-%%]%.(%a%a+)/%S+)",
	"%f[%S]([%w_-%%%.]+[%w_-%%]%.(%a%a+)/%S+)",
	-- X.Y.Z url
	--	"^([%w_-%%%.]+[%w_-%%]%.(%a%a+))",
	--	"%f[%S]([%w_-%%%.]+[%w_-%%]%.(%a%a+))",
}

local danbooru = function(path)
	local path = path['path']

	if(path and path:match'/data/([^%.]+)') then
		local md5 = path:match'/data/([^%.]+)'
		local xml, s = utils.http('http://danbooru.donmai.us/post/index.xml?tags=md5:'..md5)
		if(s == 200) then
			local id = xml:match' id="(%d+)"'
			local tags = xml:match'tags="([^"]+)'

			return string.format('http://danbooru.donmai.us/post/show/%s/ - %s', id, tags)
		end
	end
end

local iiHost = {
	['danbooru.donmai.us'] = danbooru,
	['miezaru.donmai.us'] = danbooru,
	['open.spotify.com'] = function(path)
		local path = path['path']

		if(path and path:match'/(%w+)/(.+)') then
			local type, id = path:match'/(%w+)/(.+)'

			return string.format('spotify:%s:%s', type, id)
		end
	end,
	['s3.amazonaws.com'] = function(path)
		local path = path['path']

		if(path and path:match'/danbooru/([^%.]+)') then
			local md5 = path:match'/danbooru/([^%.]+)'
			local xml, s = utils.http('http://danbooru.donmai.us/post/index.xml?tags=md5:'..md5)
			if(s == 200) then
				local id = xml:match' id="(%d+)"'
				local tags = xml:match'tags="([^"]+)'

				return string.format('http://danbooru.donmai.us/post/show/%s/ - %s', id, tags)
			end
		end
	end,
}

local kiraiTitle = {
	['sexy-lena.com'] = true, -- fap fap fap fap
	['unsere-nackte-pyjamaparty.net'] = true,
	['johnsrevenge.com'] = true,
	['tapuz.me2you.co.il'] = true,
}

local renameCharset = {
	['x-sjis'] = 'sjis',
}

local validProtocols = {
	['http'] = true,
	['https'] = true,
}

local getTitle = function(url, offset)
	local path = parse(url)
	local host = path['host']:gsub('^www%.', '')

	-- evil title of doom!
	if(kiraiTitle[host]) then return "Blacklisted domain (acies sucks!)" end
	if(iiHost[host]) then
		return iiHost[host](path)
	end

	local body, status, headers = utils.http(url)
	if(body) then
		local charset = body:lower():match'<meta.-content=["\'].-(charset=.-)["\'].->'
		if(charset) then
			charset = charset:match"charset=(.+)$?;?"
		end

		if(not charset) then
			charset = body:match'<%?xml.-encoding=[\'"](.-)[\'"].-%?>'
		end

		if(not charset) then
			local tmp = utils.split(headers['content-type'], ' ')
			for _, v in pairs(tmp) do
				if(v:lower():match"charset") then
					charset = v:lower():match"charset=(.+)$?;?"
					break
				end
			end
		end

		local title = body:match"<[tT][iI][tT][lL][eE]>(.-)</[tT][iI][tT][lL][eE]>"

		if(title) then
			for _, pattern in ipairs(patterns) do
				title = title:gsub(pattern, '<snip />')
			end
		end

		if(charset and title and charset:lower() ~= "utf-8") then
			charset = charset:gsub("\n", ""):gsub("\r", "")
			charset = renameCharset[charset] or charset
			local cd, err = iconv.new("utf-8", charset)
			if(cd) then
				title = cd:iconv(title)
			end
		end

		if(title and title ~= "" and title ~= '<snip />') then
			title = utils.decodeHTML(title)
			title = title:gsub("[%s%s]+", " ")

			if(#url > 75) then
				local short = utils.x0(url)
				if(short ~= url) then
					title = "Downgraded URL: " ..short.." - "..title
				end
			end

			return title
		end
	end
end

local found = 0
local urls
local gsubit = function(url)
	found = found + 1

	local total = 1
	for k in pairs(urls) do
		total = total + 1
	end

	if(not url:match"://") then
		url = "http://"..url
	elseif(not validProtocols[url:match'^[^:]+']) then
		return
	end

	if(not urls[url]) then
		urls[url] = {
			n = found,
			m = total,
			title = getTitle(url),
		}
	else
		urls[url].n = string.format("%s+%d", urls[url].n, found)
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :(.+)$"] = function(self, src, dest, msg)
		if(self:srctonick(src) == self.config.nick or msg:sub(1,1) == '!') then return end
		urls, found = {}, 0
		for key, msg in pairs(utils.split(msg, " ")) do
			for _, pattern in ipairs(patterns) do
				msg:gsub(pattern, gsubit)
			end
		end

		if(next(urls)) then
			local out = {}
			for url, data in pairs(urls) do
				if(data.title) then
					table.insert(out, data.m, string.format("\002[%s]\002 %s", data.n, data.title))
				end
			end

			if(#out > 0) then self:msg(dest, src, table.concat(out, " ")) end
		end
	end,
}
