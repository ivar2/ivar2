local ivar2 = ...

local httpclient = require'handler.http.client'
local form = require'handler.http.form'
local ev = require'ev'
local client = httpclient.new(ev.Loop.default)

return function(message)
	local apikey = ivar2.config.nmaAPIKey
	if(not apikey) then return end

	local req, err = client:request{
		method = 'POST',
		url = 'https://www.notifymyandroid.com/publicapi/notify',
		body = form.new{
			apikey = apikey,
			application = ivar2.config.nick,
			event = 'error :(',
			description = message,
		},
	}
end
