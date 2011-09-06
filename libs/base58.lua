local math_floor = math.floor
local alphabet = '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'

return {
	encode = function(num)
		local enc = {}
		while(num ~= 0) do
			local char = (num % 58) + 1
			table.insert(enc, alphabet:sub(char, char))
			num = math_floor(num / 58)
		end

		return table.concat(enc):reverse()
	end,

	decode = function(str)
		local num, i = 0, 0

		for c in str:reverse():gmatch('.') do
			num = num + (alphabet:find(c) - 1) * 58^i
			i = i + 1
		end

		return num
	end,
}
