local socket = require("socket")

local peer = function(host, dport)
	local ip, port = host:match'(.-)[: ](%d+)'
	ip = socket.dns.toip(ip or host) or ip

	return ip or host, port or dport
end

return {
	["^:(%S+) PRIVMSG (%S+) :!q2 (.+)$"] = function(self, src, dest, msg)
		local packet = "\255\255\255\255status\n"

		local udp = socket.udp()
		udp:settimeout(1)
		udp:setpeername(peer(msg, 27910))

		local ping = socket.gettime()
		local nsent, err = udp:send(packet)
		local header, err = udp:receive()
		ping = (socket.gettime() - ping) * 1e3

		if(header) then
			local data = {players = {}}
			header = header:sub(11) -- strip away the firstline
			for key, var in header:gmatch'\\([^\\]+)\\([^\\\n]+)' do
				data[key] = var
			end

			for frag, ping, player in header:gmatch'(.?%d+) (%d+) "(.-)"\n' do
				table.insert(data.players, {frag = tonumber(frag), ping = ping, player = player})
			end

			data.hostname = data.hostname or msg
			if(#data.players > 0) then
				table.sort(data.players, function(a, b) return a.frag > b.frag end)

				local out = {}
				for k, v in ipairs(data.players) do
					table.insert(out, ("%s: %s"):format(v.player, v.frag))
				end
				self:privmsg(dest, "%s: ping: %i, players: %s/%s, map: %s [%s] - %s", data.hostname, ping, #data.players, data.maxclients, data.mapname, data.gamename, table.concat(out, ", "))
			else
				self:privmsg(dest, "%s: ping: %i, players: %s/%s, map: %s [%s]", data.hostname, ping, #data.players, data.maxclients, data.mapname, data.gamename)
			end
		else
			self:privmsg(dest, 'unable to connect.')
		end
	end,
	["^:(%S+) PRIVMSG (%S+) :!ws (.+)$"] = function(self, src, dest, msg)
		local packet = "\255\255\255\255getinfo\n"

		local udp = socket.udp()
		udp:settimeout(1)
		udp:setpeername(peer(msg, 44400))

		local ping = socket.gettime()
		local nsent, err = udp:send(packet)
		local header, err = udp:receive()
		ping = (socket.gettime() - ping) * 1e3

		if(header) then
			local data = {players = {}}
			header = header:sub(11) -- strip away the firstline
			for key, var in header:gmatch'\\([^\\]+)\\([^\\\n]+)' do
				data[key] = var
			end

			for frag, ping, player in header:gmatch'(.?%d+) (%d+) "(.-)" %d+\n' do
				table.insert(data.players, {frag = tonumber(frag), ping = ping, player = player:gsub('%^%d+', '')})
			end

			data['sv_hostname'] = data['sv_hostname'] or msg
			if(tonumber(data.clients) > 0) then
				table.sort(data.players, function(a, b) return a.frag > b.frag end)

				local out = {}
				for k, v in ipairs(data.players) do
					table.insert(out, ("%s: %s"):format(v.player, v.frag))
				end
				self:privmsg(dest, "%s: ping: %i, players: %s/%s, map: %s [%s] - %s", data['sv_hostname']:gsub('%^%d+', ''), ping, data.clients, data['sv_maxclients'], data.mapname, data['g_gametype'], table.concat(out, ", "))
			else
				self:privmsg(dest, "%s: ping: %i, players: %s/%s, map: %s [%s]", data['sv_hostname']:gsub('%^%d+', ''), ping, data.clients, data['sv_maxclients'], data.mapname, data['g_gametype'])
			end
		else
			self:privmsg(dest, 'unable to connect.')
		end
	end,
}
