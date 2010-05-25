return {
	["^:(%S+) PRIVMSG (%S+) :!awesomejapan%s*$"] = function(self, src, dest, msg)
		local _END = os.date('*t', os.time{year = 2010; month = 6; day = 30; hour = 11;})
		local _NOW = os.date('*t', os.time())
		local _MAX = {60,60,24,os.date('*t',os.time{year=_NOW.year,month=_NOW.month+1,day=0}).day,12}

		local diff = {}
		local order = {'sec','min','hour','day','month','year'}
		for i, v in ipairs(order) do
			diff[v] = _END[v] - _NOW[v] + (carry and -1 or 0)
			carry = diff[v] < 0
			if(carry) then diff[v] = diff[v] + _MAX[i] end
		end

		local relative = {}
		local nor = {'sekund', 'sekunder', 'minutt', 'minutter', 'time', 'timer', 'dag', 'dager', 'måned', 'måneder', 'år', 'år'}
		for i=#order, 1, -1 do
			local field = order[i]
			local d = diff[field]
			if(d > 0) then
				local L = (d ~= 1 and i * 2) or (i * 2) - 1
				table.insert(relative, string.format('%d %s', d, nor[L]))
			end
		end

		self:msg(dest, src, 'Om %s sitter Awesomegjengen på flyet mot Japan!', table.concat(relative, ', '):gsub(', ([^,]+)$', ' and %1'))
	end,
}
