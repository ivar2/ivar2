local ivar2 = ...

local nixio = require'nixio'
local ev = require'ev'

-- For now we just use the bots nick as our pipe name.
local fileName = ivar2.config.nick

local commands = {
	['>'] = function(lua)
		local func = loadstring(lua)
		if(func) then
			local env = {
				ivar2 = ivar2,
			}

			local proxy = setmetatable(env, {__index = _G })
			setfenv(func, proxy)

			pcall(func, self)
		end
	end,

	quit = function(message)
		ivar2:Quit(message)
	end,

	join = function(argument)
		local chan, pass = argument:match('^(%S+) ?(%S*)')
		if(pass == '') then pass = nil end
		ivar2:Join(chan, pass)
	end,

	part = function(argument)
		ivar2:Part(argument)
	end,

	topic = function(argument)
		local chan, topic = argument:match('^(%S+) (.+)$')
		ivar2:Topic(chan, topic)
	end,

	mode = function(argument)
		local destination, mode = argument:match('^(%S+) (.+)$')
		ivar2:Mode(destination, mode)
	end,

	kick = function(argument)
		local chan, user, comment = argument:match('^(%S+) (%S+) ?(.*)$')
		ivar2:Kick(chan, user, comment)
	end,

	nick = function(nick)
		ivar2:Nick(nick)
	end,

	ignore = function(mask)
		ivar2:Ignore(mask)
	end,

	unignore = function(mask)
		ivar2:Unignore(mask)
	end,

	loadmodule = function(module)
		ivar2:LoadModule(module)
	end,

	disablemodule = function(module)
		ivar2:DisableModule(module)
	end,

	reload = function()
		ivar2:Reload()
	end
}

-- Might fail, but mkfifo doesn't care if the pipe already exists.
nixio.fs.unlink(fileName)

local watcher = ev.Stat.new(function(loop, stat, revents)
	for line in io.lines() do
		local command, argument  = line:match('^(%S+) ?(.*)$')
		if(commands[command]) then
			pcall(commands[command], argument)
		end
	end
end, ivar2.config.nick)

nixio.fs.mkfifo(fileName, 600)

-- Calling io.input() on a fifo will lock us until the first event happens.
os.execute(string.format('sleep .1 && touch %q &', fileName))
io.input(fileName)

return watcher
