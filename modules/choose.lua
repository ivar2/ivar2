local ltrim = function(r, s)
	if s == nil then
		s, r = r, "%s+"
	end
	return (string.gsub(s, "^" .. r, ""))
end

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


local reply = {
	'┗(＾0＾)┓))(( ┏(＾0＾)┛',
	'（　´_ゝ`）ﾌｰﾝ',
	'（　°‿‿°）',
	'（　°∀°）',
	' (　´〰`)',
	'○|￣|＿',
	'ಠ_ಠ',
}

math.randomseed(os.time() % 1e5)

return {
	["^:(%S+) PRIVMSG (%S+) :!choose (.+)$"] = function(self, src, dest, msg)
		local hax = {}
		local http = msg:match("^%s*(http://%S*)")
		local arr
		if(http) then
			local content, status = utils.http(http)
			if(content) then
				-- Strip out any HTML.
				content = content:gsub('<%/?[%w:]+.-%/?>', '')
				-- K-Line prevention!
				for _, pattern in ipairs(patterns) do
					content = content:gsub(pattern, '<snip />')
				end

				arr = utils.split(content, '[\n\r]+')
			else
				arr = {}
			end
		else
			arr = utils.split(msg, ",[%s]?")
		end

		for k, v in pairs(arr) do
			hax[v] = true
		end

		local i = 0
		for k, v in pairs(hax) do
			i = i + 1
		end

		local seed = math.random(1, #arr)

		if(#arr == 1 or i == 1) then
			self:msg(dest, src, reply[math.random(1, #reply)])
		else
			self:msg(dest, src, "%s: %s", src:match"^([^!]+)", ltrim(arr[seed]))
		end
	end
}
