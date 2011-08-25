local split = function(str, pattern)
	local out = {}
	str:gsub(pattern, function(match)
		table.insert(out, match)
	end)

	return out
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
	PRIVMSG = {
		['!choose (.*)$'] = function(self, source, destination, choices)
			local hax = {}
			local arr = split(choices, '%s*([^,]+)%s*')

			for k, v in pairs(arr) do
				hax[v] = true
			end

			local i = 0
			for k, v in pairs(hax) do
				i = i + 1
			end

			if(#arr == 1 or i == 1) then
				self:Msg('privmsg', destination, source, reply[math.random(1, #reply)])
			else
				local seed = math.random(1, #arr)
				self:Msg('privmsg', destination, source, '%s: %s', source.nick, arr[seed])
			end
		end
	}
}
