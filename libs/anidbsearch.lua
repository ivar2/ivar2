local animeTitles = loadfile('libs/anidbtitles.lua')()
local lastReload = tonumber(os.date('%V'))

local scores = {
	main = 1,
	syn = .8,
	short = .5,
	official = 1,
}

local THRESHOLD = 100
local insert = function(tbl, aid, weight)
	weight = math.floor(weight)
	if(weight < THRESHOLD) then return end

	local title = animeTitles[aid].main
	local data = tbl[aid]
	if(data and data[2] < weight) then
		data[2] = weight
	elseif(not data) then
		tbl[aid] = {title, weight}
	end
end

local compare = function(tbl, aid, type, pattern, title)
	title = title:lower()

	if(pattern == title) then
		return insert(tbl, aid, 1e3 * scores[type])
	else
		local x, y = title:find(pattern)
		if(y) then
			return insert(tbl, aid, 1e3 * (1 + y - x) / #title *  scores[type])
		end
	end
end

local doSearch = function(pattern)
	local matches = {}
	local search = pattern:lower():gsub('([-?]+)', '%%%1'):gsub("'", '`')
	-- Search, lol!
	for aid, anime in next, animeTitles do
		compare(matches, aid, 'main', search, anime.main)

		for _, type in next, {'syn', 'short', 'official'} do
			for _, title in next, anime[type] do
				compare(matches, aid, type, search, title)
			end
		end
	end

	local output = {}
	for k,v in next, matches do
		table.insert(output, {aid = k, title = v[1], weight = v[2]})
	end

	table.sort(output, function(a,b) return a.weight > b.weight end)

	return output
end

return {
	lookup = doSearch,
	reload = function()
		local week = tonumber(os.date('%V'))
		if(lastReload ~= week) then
			lastReload = week
			animeTitles = loadfile('libs/anidbtitles.lua')()
		end
	end,
}
