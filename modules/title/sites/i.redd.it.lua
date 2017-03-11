local util = require'util'
local simplehttp = util.simplehttp
local json = util.json

local generateTitle = function(gallery)
	if(gallery.error) then return end

	local out = {}

	if(type(gallery.subreddit) == "string" and gallery.subreddit ~= '') then
		table.insert(out, '['..tostring(gallery.subreddit)..']')
	end

	if(gallery.title) then
		table.insert(out, gallery.title)
	end

	local tags = {}

	if(gallery.ups and gallery.downs) then
		table.insert(tags, string.format("+%d/-%d", gallery.ups, gallery.downs))
	end

	if(gallery.over_18) then
		table.insert(tags, 'NSFW')
	end

	table.insert(out, string.format("[%s]", table.concat(tags, ", ")))

	return table.concat(out, " ")
end

customHosts['^i%.redd%.it'] = function(queue, info)
	if(not info.path) then return end

	local object = info.path:match('/(.*)$')
	if(not object) then return end

	local url = 'https://www.reddit.com/api/info.json?url=https%3A%2F%2Fi.redd.it%2F' .. object
	local data = simplehttp(url)
	if not data then return end

	local gallery
	local decoded = json.decode(data)
	if decoded.data and decoded.data.children and decoded.data.children[1] then
		gallery = decoded.data.children[1].data
	else
		return
	end

	queue:done(generateTitle(gallery))
	return true
end

