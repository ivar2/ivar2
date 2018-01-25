local util = require'util'
local simplehttp = util.simplehttp
local json = util.json
local html2unicode = require'html'
local base64 = require 'base64'

local access_token

-- luacheck: ignore
customHosts['twitter%.com'] = function(queue, info)
	-- local query = info.query
	local path = info.path
	local fragment = info.fragment
	local tid

	local pattern = '/status[es]*/(%d+)'
	if(fragment and fragment:match(pattern)) then
		tid = fragment:match(pattern)
	elseif(path and path:match(pattern)) then
		tid = path:match(pattern)
	end

	local function getStatus(t_id)
		simplehttp({
			url = string.format('https://api.twitter.com/1.1/statuses/show/%s.json?tweet_mode=extended', t_id),
			headers = {
				['Authorization'] = string.format("Bearer %s", access_token)
			},
		},
		function(data)
			local tweet_d = json.decode(data)
			if tweet_d.errors then
				queue:done(tweet_d.errors[1].message)
				return
			end
			local name = tweet_d.user.name
			local screen_name = html2unicode(tweet_d.user.screen_name)

			local tweet
			if tweet_d.retweeted_status then
				local rter = tweet_d.retweeted_status.user.screen_name
				tweet = 'RT @'..rter..': '..html2unicode(tweet_d.retweeted_status.full_text)
			else
				tweet = html2unicode(tweet_d.full_text)
			end

			-- replace newlines with spaces
			tweet = tweet:gsub('\n', ' ')

			-- replace shortened URLs with their original
			for _, url in pairs(tweet_d.entities.urls) do
				tweet = tweet:gsub(url.url, url.expanded_url)
			end

			-- replace shortened media URLs with their original
			local counter = 0
			if(tweet_d.extended_entities ~= nil) then
				for _, media in pairs(tweet_d.extended_entities.media) do
					if counter == 0 then
						tweet = tweet:gsub(media.url, media.expanded_url .. ' ' .. media.media_url)
					else
						tweet = tweet .. " " .. media.media_url
					end
					counter = counter + 1
				end
			end

			local out = {}
			--if(name == screen_name) then
			--	table.insert(out, string.format('<\002%s\002>', name))
			--else
			--	table.insert(out, string.format('\002%s\002 <@%s>', name, screen_name))
			--end
			table.insert(out, string.format('<@%s>', screen_name))

			table.insert(out, tweet)
			queue:done(table.concat(out, ' '))
		end
		)
	end

	if(tid) then
		local tokenurl = "https://api.twitter.com/oauth2/token"
		if not access_token then
			simplehttp({
					url = tokenurl,
					method = 'POST',
					headers = {
						['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8',
						['Authorization'] = string.format(
							"Basic %s",
							base64.encode(
								string.format(
									"%s:%s",
									ivar2.config.twitterApiKey,
									ivar2.config.twitterApiSecret
								)
							)
						)
					},
					data = 'grant_type=client_credentials'
				},
				function(data)
					local tweet_d = json.decode(data)
					-- Save access token for further use
					access_token = tweet_d.access_token
					-- And after we got token, get the status
					getStatus(tid)
				end
			)
		else
			getStatus(tid)
		end

		return true
	end
end
