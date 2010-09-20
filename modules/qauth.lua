-- Q Challenge Auth
--
-- Expects QAuthUser and QAuthMD5Hash in the config table.
-- Example:
-- config = {
--     ...
--     QAuthUser = 'Qnetuser',
--     QAuthMD5Hash = 'md5 hash of password'
--     ...
-- }

require"md5"
require"bit"

-- http://en.wikipedia.org/wiki/HMAC
local function hmac(key, data)
	if key:len() > 64 then
		key = md5.sumhexa(key)
	end

	if key:len() < 64 then
		key = key..string.char(0):rep(64 - key:len())
	end

	local ipad = key:gsub(".", function(char) return string.char(bit.bxor(char:byte(), 0x36)) end)
	local opad = key:gsub(".", function(char) return string.char(bit.bxor(char:byte(), 0x5C)) end)

	return md5.sumhexa(opad..md5.sum(ipad..data))
end

--[[
    * challenge = "3afabede5c2859fd821e315f889d9a6c"
    * lowercase_username = "{fishking}"
    * truncated_password = "iLOVEfish1"
    * password_hash = SHA-1("<truncated password>")
    * password_hash = SHA-1("iLOVEfish1")
    * password_hash = "15ccbbd456d321ef98fa1b58e724828619b6066e"
    * key = SHA-1("<lowercase username>:<password hash>")
    * key = SHA-1("{fishking}:15ccbbd456d321ef98fa1b58e724828619b6066e")
    * key = "c05587aeb231e8f90a2df8bc66142c2a8b1be908"
    * response = HMAC-SHA-1("<challenge>"){"<key>"}
    * response = HMAC-SHA-1("3afabede5c2859fd821e315f889d9a6c"){"c05587aeb231e8f90a2df8bc66142c2a8b1be908"}
    * response = "e683c83fd16a03b6d690ea231b4f346c32ae0aaa"
    * /msg Q@CServe.quakenet.org CHALLENGEAUTH [fishking] e683c83fd16a03b6d690ea231b4f346c32ae0aaa HMAC-SHA-1
--]]

return {
	["^:(%S+) 001"] = function(self, src, dest, msg)
		if(not src:match"quakenet%.org") then return end
		self:privmsg("Q@CServe.quakenet.org", "CHALLENGE")
	end,
	[":Q!TheQBot@CServe%.quakenet%.org NOTICE (%S+) :CHALLENGE (%S+)"] = function(self, dest, challenge)
		local user, pass_hash = self.config.QAuthUser, self.config.QAuthMD5Hash
		local key = md5.sumhexa(("%s:%s"):format(user:lower(), pass_hash))

		self:privmsg("Q@CServe.quakenet.org", "CHALLENGEAUTH %s %s %s", user, hmac(key, challenge), "HMAC-MD5")
	end,
	[":Q!TheQBot@CServe%.quakenet%.org NOTICE (%S+) :You are now logged in as (%S+)."] = function(self, dest, qauth)
		if(self.config.QAuthHideHost) then
			self:send("MODE %s :%s", self.config.nick, 'x')
		end
	end,
}
