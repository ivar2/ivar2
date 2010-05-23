local readGitLog = function()
	local cl = utils.shell'git log --date=relative --pretty=format:"%x1e%ar%x1f%s%x1f" --name-only'
	local split = utils.split(cl, '\030')
--	for relTime, logEntry, files in cl:gmatch('(.-)\031(.-)') do
--	end
	for i=2, #split do
		local entry = split[i]
		local relTime, logEntry, files = entry:match('(.-)\031(.-)\031(.*)')
		files = utils.split(files:sub(3, -4), ',')
		split[i] = {time = relTime, log = logEntry, files = files}
	end
	table.remove(split, 1)

	return split
end

local getModuleString = function(files)
	local touched = {}
	for k,v in ipairs(files) do
		local name = v:gsub('modules/', ''):gsub('%.lua', ''):gsub('ircbot', 'core')
		table.insert(touched, name)
	end

	return '[' .. table.concat(touched, ',') .. ']'
end

return {
	["^:(%S+) PRIVMSG (%S+) :!changelog ?(.*)"] = function(self, src, dest, msg)
		local cl = readGitLog()
		if(#msg > 0) then
			local total = #cl
			local entry = cl[tonumber(msg)]
			if(entry) then
				self:msg(dest, src, '%s: (%d/%d) %s %s | %s', src:match'^([^!]+)', tonumber(msg), total, getModuleString(entry.files), entry.time, entry.log)
			end
		else
			local total = #cl
			local entry = cl[1]
			self:msg(dest, src, '%s: (%d/%d) %s %s | %s', src:match'^([^!]+)', 1, total, getModuleString(entry.files), entry.time, entry.log)
		end
	end
}
