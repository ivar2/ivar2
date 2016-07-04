
package.path = table.concat({
    'libs/?.lua',
    'libs/?/init.lua',

    '',
}, ';') .. package.path

package.cpath = table.concat({
    'libs/?.so',

    '',
}, ';') .. package.cpath

local util = require 'util'
local irc = require 'irc'
local utf8 = util.utf8
local busted = require'busted'
local cqueues = require'cqueues'
local new_headers = require "http.headers".new
local queue = cqueues.new()
local describe = busted.describe
local it = busted.it

describe("test IRC lib", function()
    describe("parse 352 message", function()
        it("should parse 352 message with IPv6 host", function()
              local line = ':server.server.com 352 botnick #channel user 2a00:dd52:211g::2 server.server.com nick H :0 Realname'
              local command, argument, source, destination = irc.parse(line)
              assert.are_equal('352', command)
              assert.are_equal('server.server.com', source)
              assert.are_equal('#channel', destination)
              assert.are_same({
                  mode = 'H',
                  hopcount = ':0',
                  server = 'server.server.com',
                  nick = 'nick',
                  realname = 'Realname',
                  user = 'user',
                  sourcenick = 'botnick',
                  host = '2a00:dd52:211g::2',
              }, argument)
        end)
    end)
    describe("split irc message", function()
        local hostmask = 'irc@irc.example.com'
        local destination = '#channel'
        it("should keep short messages intact", function()
            local out = 'foobar'
            local message, extra = irc.split(hostmask, destination, out)
            assert.are_equal(out, message)
            assert.are_equal(extra, nil)
        end)
        it("should split long messages into two", function()
            local out = string.rep('A', 4096)
            local message, extra = irc.split(hostmask, destination, out)
            local less = #message < 512
            assert.is_true(less)
        end)
        it("should handle mb3 mb4 utf8", function()
            local out = "𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔛𝔜ℨ 𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔛𝔜ℨ 𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔛𝔜ℨ "
            local message, extra = irc.split(hostmask, destination, out)
            local less = #message < 512
            assert.is_true(less)
        end)
        it("should not lose any bytes", function()
            local out = string.rep('A', 4096)
            local message, extra = irc.split(hostmask, destination, out, '')
            local therest = #out - #message
            assert.are_equal(#extra, therest)
        end)
        it("should not die on empty", function()
            local message, extra = irc.split(hostmask, destination, nil, '')
            assert.are_equal(nil, message)
            assert.are_equal(nil, extra)
            local message, extra = irc.split(hostmask, destination, '', '')
            assert.are_equal('', message)
            assert.are_equal(nil, extra)
        end)
        it("should parse ACTION with stripping the 01 at the end", function()
              local line = ':server.server.com 352 botnick #channel user 2a00:dd52:211g::2 server.server.com nick H :0 Realname'
              local line = ":tx!tx@127.0.0.1 PRIVMSG #testchan :\001ACTION testing\001"
              local command, argument, source, destination = irc.parse(line)
              assert.are_equal('PRIVMSG', command)
              assert.are_equal('#testchan', destination)
              assert.are_equal('\001ACTION testing\001', argument)
        end)
    end)
    describe("format irc messages", function()
        it("should format ACTION ", function()
            assert.are_equal('\001ACTION testing\001', irc.formatCtcp('testing', 'ACTION'))
        end)
    end)
end)

describe("test util lib", function()
    describe("utf8 string tests", function()
        it("should work with multibye utf8 chars", function()
            local line = {'F','o','o',' ','æ','ø','Å','😀'}
            local uline = {}
            for c in util.utf8.chars(table.concat(line)) do
                table.insert(uline, c)
            end
            assert.are_same(line, uline)
            assert.are_equal(#line, utf8.len(table.concat(line)))
            local reversed = {}
            for i=#line,1,-1 do
                table.insert(reversed, line[i])
            end
            assert.are_same(table.concat(reversed), utf8.reverse(table.concat(line)))

            assert.are_equal('foo æøå😀', utf8.lower(table.concat(line)))

            assert.are_equal(utf8.char(97), 'a')
            assert.are_equal(utf8.char(0x1f600), '😀')
        end)
    end)
end)

describe("test webserver", function()
    describe("webserver tests", function()
        it("should listen", function()
            local webserver = assert(loadfile('core/webserver.lua'))(ivar2)
            local server = webserver.start('::', '9999')
            queue:wrap(function()
                server:listen()
                local cqueue = cqueues.running()
                server:run(webserver.on_stream, cqueue)
            end)
            webserver.regUrl('/test', function(self, req, res)
              assert.are_equal(req.url, '/test')
              res:append(":status", "200")
              req:write_headers(res, false)
              req:write_body_from_string('Hello world!')
            end)
            webserver.regUrl('/simplereturn', function(self, req, res)
              return 'OK'
            end)
            queue:wrap(function()
                util.simplehttp('http://127.0.0.1:9999/asdf', function(data)
                    assert.are_equal(data, 'Nyet. I am four oh four')
                end)
            end)
            queue:wrap(function()
                util.simplehttp('http://[::1]:9999/test', function(data)
                    assert.are_equal(data, 'Hello world!')
                end)
                local data = util.simplehttp('http://[::1]:9999/simplereturn')
                assert.are_equal(data, 'OK')
            end)
            queue:wrap(function()
                util.simplehttp({
                    url='http://127.0.0.1:9999/test',
                    --headers={Connection='close'}
                }, function(data)
                    assert.are_equal(data, 'Hello world!')
                end)
            end)
            queue:wrap(function()
                util.simplehttp({
                    url='http://xt.gg/test.txt',
                }, function(data)
                    assert.are_equal(data, 'Hello world!\n')
                end)
            end)
            for i=1,10 do
                queue:wrap(function()
                    local data = util.simplehttp('http://[2a02:cc41:100f::10]/test.txt')
                    assert.are_equal(data, 'Hello world!\n')
                end)
            end
            assert_loop(queue, TEST_TIMEOUT)

        end)
    end)
end)
