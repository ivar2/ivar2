local _M = {}

--- draw sparkline for 1 line using unicode chars, inspired by holman's spark lib.
_M.sparkline = function(numbers)
	local ticks = {[0]='▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'}
	local min = 3e38
	local max = 0
	for i=1,#numbers do
		local n = numbers[i]
		min = math.min(n, min)
		max = math.max(n, max)
	end
	if min == max then
		ticks = {'▅', '▆'}
	end
	local out = {}
	local scale = #ticks / (max-min)
	for i=1,#numbers do
		local tick = numbers[i]
		local index = math.floor(scale * (tick-min))
		out[#out+1] = ticks[index]
	end

	return table.concat(out)

end
return _M
