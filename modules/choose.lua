local ltrim = function(r, s)
	if s == nil then
		s, r = r, "%s+"
	end
	return (string.gsub(s, "^" .. r, ""))
end

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
