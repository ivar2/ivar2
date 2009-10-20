local prints
-- make environment
local _X = setmetatable({
	round = function(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end,
	print = function(val)
		if(val) then
			table.insert(prints, val)
		end
	end
}, {__index = math})

local MaxRunTime = 2
local StartTime = os.time()
local wrap = function()
	-- This is a debug hook, to ensure functions run in the sandbox end within n seconds
	--      print("Hook time: "..os.difftime(StartTime, os.time()))
	if os.difftime(os.time(),StartTime) > MaxRunTime then
		return nil, "Sorry, the function ran too long, unable to complete"
	end
end

local arg = ...
return {
	["^:(%S+) PRIVMSG (%S+) :c>(.+)$"] = function(self, src, dest, script)
		-- If the first non-whitespace token in an =, convert it to print
		if script:match("^%s*(%S)") == "=" then
			script = script:gsub("^%s*(%S)", "return ")
		end

		local func,err = loadstring(script, "=c")
		local retfunc,reterr = loadstring("return " .. script, "=c")
		if not (func or retfunc) then return nil, err or reterr end

		if(func) then
			setfenv(func, _X)
		end
		if(retfunc) then
			setfenv(retfunc, _X)
		end

		prints = {}
		local out = err
		if type(retfunc) ~= "function" then
			if type(func) == "function" then
				-- Run this script, and hope it prints something
				debug.sethook(wrap, "", 100)
				out = select(2, pcall(func))
				debug.sethook()
			end
		else
			debug.sethook(wrap, "", 100)
			out = select(2, pcall(retfunc))
			debug.sethook()
		end
		if(#prints ~= 0) then
			self:msg(dest, src, "%s: %s", src:match"^([^!]+)", table.concat(prints, ", "))
		else
			self:msg(dest, src, "%s: %s", src:match"^([^!]+)", out)
		end
	end
}
