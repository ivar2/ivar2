local cqueues = require'cqueues'
local socket = require'cqueues.socket'
local util = require'util'

return {
    PRIVMSG = {
        ['^%pstreamtitle (.+)$'] = function(ivar, source, destination, url)
            local queue = cqueues.new()
            local resdata = ""
            local datalen = 0
            local urip = util.uri_parse(url)
            queue:wrap(function()
                local sock = assert(socket.connect(urip.host, urip.port or 80))
                sock:write('GET ' .. urip.path .. ' HTTP/1.1\nHost: ' .. urip.host .. '\nAccept-Encoding: identity\nUser-Agent: WinampMPEG/5.52\nIcy-Metadata: 1\n\n')
                while true do
                    local data = sock:read(8192)
                    datalen = datalen + #data
                    resdata = resdata .. data
                    local res = resdata:match("StreamTitle='(.-)'")
                    if res then
                        ivar:Msg('privmsg', destination, source, 'Now playing ♫ \002%s\002', res)
                        break
                    end
                    if datalen > 65535 then
                        break
                    end
                end
                sock:close()
            end)
            queue:loop()
        end,
    },
}
