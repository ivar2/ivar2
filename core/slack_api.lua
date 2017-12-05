-- vim: set noexpandtab:
--
-- Simple Slack API meant to be run under cqueues
--
package.path = table.concat({
	'libs/?.lua',
	'libs/?/init.lua',

	'',
}, ';') .. package.path

package.cpath = table.concat({
	'libs/?.so',

	'',
}, ';') .. package.cpath

local lconsole = require'logging.console'
local log = lconsole()
local util = require 'util'

local websocket = require "http.websocket" -- 'lua-http'

local http = util.simplehttp
local json = util.json

local slack = {
	selfdata = nil,
	name = nil,
	channels = {},
	users = {},
	url = nil,
	handlers = {},
	ws = nil,
}

function slack:Connect(token)
	self:Log('info', 'Authing')

	local data = http('https://slack.com/api/rtm.start?token='..token)
	if not data then
		return nil, 'No data returned'
	end
	data = json.decode(data)
	if not data then
		return nil, 'Invalid json'
	end
	if not data.ok then
		return nil, 'Ok: '..tostring(data.ok)
	end

	self.selfdata = data.self
	self.name = data.self.name

	for _, c in ipairs(data.channels) do
		self.channels[c.id] = c
	end

	for _, u in ipairs(data.users) do
		self.users[u.id] = u
	end

	self.url = data.url

	self:Log('info', 'Connecting to websocket RTM API')
	self.ws = websocket.new_from_uri(self.url)
	self.ws:connect()

	while true do
		local wdata = self.ws:receive()
		self:Log('debug', '%s', wdata)
		wdata = json.decode(wdata)
		if wdata.type then
			-- do some simple processing to help the consumers of this api
			if wdata.type == 'message' and wdata.text then
				wdata.text = wdata.text:gsub('&gt;', '>')
				wdata.text = wdata.text:gsub('&lt;', '<')
				wdata.text = wdata.text:gsub('&amp;', '&')
				-- try to rewrite URLs back to hostnames.. FIXME, no idea to handle this correctly
				-- URL Format #1 for URLs with title
				wdata.text = wdata.text:gsub('<(.-)://(.-)|(.-)>', '%3')
				-- URL Format #2 for URLs without title
				wdata.text = wdata.text:gsub('<(.-)://(.-)>', '%1://%2')
			end

			for id, fn in pairs(self.handlers[wdata.type] or {}) do
				if fn then
					fn(wdata)
				end
			end
		end
	end
end

function slack:_next_message_id()
	if not self.message_id then
		self.message_id = 0
	end
	self.message_id = self.message_id + 1
	return self.message_id
end

function slack:get_channel(id)
	local channel = self.channels[id]
	if not channel then
		return nil, 'Channel not found'
	end
	return channel.name
end

function slack:get_user(id)
	local user = self.users[id]
	if not user then
		return nil, 'User not found'
	end
	return user.name
end

function slack:Send(payload)
	local js = json.encode(payload)
	self:Log('debug', 'send: %s', js)
	return self.ws:send(js)
end

function slack:Privmsg(destination, message)
	-- resolve channel
	if destination:match('^#') then
		local dname = destination:match('^#(.*)$')
		for id, c in pairs(self.channels) do
			if c.name == dname then
				destination = id
				break
			end
		end
	end
	local payload = {
		id = self:_next_message_id(),
		type = 'message',
		channel = destination,
		text = util.stripformatting(message)
	}
	return self:Send(payload)
end

local safeFormat = function(format, ...)
	if(select('#', ...) > 0) then
		local success, message = pcall(string.format, format, ...)
		if(success) then
			return message
		end
	else
		return format
	end
end

function slack:Log(level, ...)
	local message = safeFormat(...)
	if(message) then
		message = 'slack> ' .. message
		log[level](log, message)
	end
end

function slack:RegisterHandler(event_type, fn, id)
	if not self.handlers[event_type] then
		self.handlers[event_type] = {}
	end
	id = id or 'random' -- XXX
	self.handlers[event_type][id] = fn
end

function slack:UnRegisterHandler(event_type, fn)
	--TODO
end

--[[
Usage

local handleMessage = function(m)
	local channel = slack:get_channel(m.channel)
	if not channel then
		channel = 'DM'
	else
		channel = '#'..channel
	end
	local user = slack:get_user(m.user)
	local message = m.text
	print(channel..' <'..user..'>'.. ' '..message)
	if message == 'k' then
		slack:Privmsg(m.channel, 'okay')
	end
end

--slack:RegisterHandler('message', handleMessage, 'testid')
--]]

return slack
