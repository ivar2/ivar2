local util = require'util'
local simplehttp = util.simplehttp
local urlEncode = util.urlEncode
local json = util.json


local Sequence = {}

function Sequence:new(done, fail)
	return setmetatable(
		{
			done = done,
			fail = fail,

			sequence = nil,
			sequences = {},
			results = {},
		},
		{
			__index = self,
			__call = self.success
		}
	)
end

function Sequence:add(func)
	table.insert(self.sequences, func)
end

function Sequence:success(...)
	if(not self.sequence) then
		self.sequence = 1
		return self.sequences[1](self, ...)
	end

	if(select('#', ...) > 1) then
		self.results[self.sequence] = {...}
	else
		self.results[self.sequence] = ...
	end
	self.sequence = self.sequence + 1

	if(self.sequences[self.sequence]) then
		return self.sequences[self.sequence](self, ...)
	end

	if(self.done) then
		return self:done(self.results)
	end
end

function Sequence:error(...)
	if(self.fail) then
		self:fail(self.results, ...)
	end
end

local episode = function(url, pre)
	return function(seq)
		simplehttp(
			url,

			function(data)
				data = json.decode(data)
				seq:success(
					string.format(
						'%s: %02dx%02d %s %s',
						pre,
						data.season, data.number,
						data.airdate, data.airtime
					)
				)
			end
		)
	end
end

local search = function(input)
	return function(seq)
		simplehttp(
			('http://api.tvmaze.com/singlesearch/shows?q=%s'):format(urlEncode(input)),
			function(data, _, response)
				if(response.status_code == 404) then
					return seq:error()
				end

				data = json.decode(data)

				local out = {}
				local ins = function(fmt, ...)
					for i=1, select('#', ...) do
						local val = select(i, ...)
						if(type(val) == 'nil' or val == -1 or val == '') then
							return
						end
					end

					table.insert(
						out,
						string.format(fmt, ...)
					)
				end

				ins(
					'%s (%s) %s',
					data.name, data.premiered, data.status
				)

				if(data.genres) then
					ins('// %s', table.concat(data.genres, ', '))
				end

				local links = data._links
				if(links.previousepisode) then
					seq:add(episode(links.previousepisode.href, 'Latest'))
				end

				if(links.nextepisode) then
					-- This should probbly do some ETA thingy...
					seq:add(episode(links.nextepisode.href, 'Next'))
				end

				seq:add(function(seq)
					seq:success(data.url)
				end)

				seq:success(table.concat(out, ' '))
			end
		)
	end
end

local handle = function(self, source, destination, input)
	local seq = Sequence:new(
		-- Success
		function(seq, results)
			local output = table.concat(results, ' | ')
			say(output)
		end,

		-- Fail
		function(sef, results, ...)
			say('%s', source.nick, 'Invalid show? :(')
		end
	)

	seq:add(search(input))
	seq()
end

return {
	PRIVMSG = {
		['^%ptv (.+)$'] = handle,
		['^%ptvm (.+)$'] = handle,
		['^%ptvmaze (.+)'] = handle,
	},
}
