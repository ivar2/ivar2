-- vim: set noexpandtab:
local verifyOwner = function(self, src, destination)
	for _, mask in next, ivar2.config.owners do
		if(src.mask:match(mask)) then
			return true
		end
	end
	self:reply('You don\'t look like an admin to my eyes.')
end

return {
	PRIVMSG = {
		['^%pmadd%s*(%S+)$'] = function(self, source, destination, module)
			if(not verifyOwner(self, source, destination)) then return end

			self:LoadModule(module)

			self:Msg('privmsg', destination, source, "Loaded module: %s", module)
		end,

		['^%pmdel%s*(%S+)$'] = function(self, source, destination, module)
			if(not verifyOwner(self, source, destination)) then return end

			self:DisableModule(module)

			self:Msg('privmsg', destination, source, "Disable module: %s", module)
		end,

		['^%pirc (%S+) (.+)$'] = function(self, source, destination, command, argument)
			if(not verifyOwner(self, source, destination)) then return end

			command = command:lower()
			if(command == "join") then
				local chan, pass = argument:match('^(%S+) ?(%S*)')
				if(pass == '') then pass = nil end
				self:Join(chan, pass)
			elseif(command == "part") then
				self:Part(argument)
			elseif(command == "nick") then
				self:Nick(argument)
			elseif(command == "mode") then
				local dest, mode = argument:match('^(%S+) (.+)$')
				self:Mode(dest, mode)
			elseif(command == "topic") then
				local chan, topic = argument:match('^(%S+) (.+)$')
				self:Topic(chan, topic)
			elseif(command == "kick") then
				local chan, user, comment = argument:match('^(%S+) (%S+) ?(.*)$')
				self:Kick(chan, user, comment)
			end
		end,

		['^%preload$'] = function(self, source, destination)
			if(not verifyOwner(self, source, destination)) then return end

			self:Msg('privmsg', destination, source, "Triggered reload.")
			self:Reload()
		end,

		['^%preload%s*(%S+)$'] = function(self, source, destination, module)
			if(not verifyOwner(self, source, destination)) then return end

			self:Msg('privmsg', destination, source, "Reloading module: %s", module)
			self:DisableModule(module)
			self:LoadModule(module)
		end,


		['^%ptimers%s*(%S+) ?(.*)$'] = function(self, source, destination, command, argument )
			if(not verifyOwner(self, source, destination)) then return end

			command = command:lower()
			if(command == "list") then
				local out = {}
				for id,_ in pairs(self.timers) do
					out[#out+1] = id
				end
				self:Msg('privmsg', destination, source, "Timer ids: %s", table.concat(out, ', '))
			elseif command == "stop" then
				self.timers[argument]:stop(self.Loop)
				self.timers[argument] = nil
				self:Msg('privmsg', destination, source, 'OK')
			end
		end,
	},
}
