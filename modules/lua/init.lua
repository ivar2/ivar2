return {
	PRIVMSG = {
		['^lua>(.+)$'] = function(self, source, destination, lua)
			local inputFile = os.tmpname()
			local outputFile = os.tmpname()
			local file = io.open(inputFile, 'w')
			file:write(lua)
			file:close()

			local cmd = string.format([[modules/lua/sandbox.sh %s %s &> /dev/null]], inputFile, outputFile)
			local status = os.execute(cmd) / 256
			local file = io.open(outputFile, 'r')
			local output = file:read(251)
			file:close()

			-- Clean up our mess
			os.remove(inputFile)
			os.remove(outputFile)

			local postfix = output:sub(-4)

			if(status == 0) then
				-- Cut of the initial RUN: and the newline+postfix
				output = output:sub(5, -6)

				if(output == 'not enough memory') then
					output = 'Your code exceeded set memory limits'
				end
			elseif(status == 137) then
				output = 'Your code exceeded set CPU limits'
			elseif(status == 1) then
				-- cut RUN:ERR:web and newline
				output = output:sub(12, -1)
			end

			if(not output:match('%S')) then
				output = 'No output'
			elseif(#output > 250) then
				output = output:sub(1, 250) .. '(truncated)'
			end

			ivar2:Msg('privmsg', destination, source, '%s: %s', source.nick, output)
		end,
	},
}
