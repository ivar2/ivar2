============================
ivar2 - DO-OH!
============================

Introduction
------------
ivar2 is an IRC bot on speed, with a mentally unstable mind.
Partially because its written in lua, which could make the most sane mind go unstable.

Installation
------------------

The installation instructions are made for Debian Jessie, you might have to adapt yourself for other distributions. Some additional dependencies are required for some of the modules, like PostgreSQL for pgolds.lua. Persisting data can be done using either sqlite og Redis, naturally lua-redis and redis-server is required as a dependency if you want to use redis.

Install deps:

::

    sudo apt-get install luarocks liblua5.1-iconv0 lua-cjson cmake libsqlite3-dev git libssl-dev m4
    sudo luarocks install lsqlite3
    sudo luarocks install luabitop
    sudo luarocks install luarocks #newer version of luarocks to support git+https
    sudo luarocks install --server=http://luarocks.org/dev http
    sudo luarocks install luafilesystem



Decompress the required data files in cache directory.

Configuration File
------------------

Create a bot config sort of like this

**myconfig.lua**

::

    return {
        nick = 'ivar2',
        autoReconnect = true,
        ident = 'ivar2',
        uri = 'tcp://irc.efnet.no:6667/',
        password = false,
        realname = 'ivar',
        owners = {
            'nick!ident@my.host.name'
        },
        webserverhost = '::',
        webserverport = 9000,
        webserverprefix = 'https://my.web.proxy/', -- optional URL if bot is behind proxy
        commandPattern = "!",
        notice = false, -- Reply with PRIVMSG instead of NOTICE
        modules = {
            'admin',
            'autojoin',
            'lastfm',
            'spotify',
            'karma',
            'roll',
            'title',
            'tvrage',
            'urbandict',
            'substitute',
            'lua',
        },
        channels = {
            ['#ivar'] = {
                disabledModules = {
                    'olds'
               },
               commandPattern = '>',
               ignoredNicks = {'otherbot'},
               modulePatterns = {
                    lastfm = '#',
               },
            },
        }
    }



Launch bot
----------

::

    # Using Lua
    lua ivar2.lua myconfig.lua
    # Using LuaJIT (apt-get install luajit)
    luajit ivar2.lua myconfig.lua
    # If you want to try the Matrix adapter
    lua(jit) matrix.lua yourmatrixconfigfile.lua

    # Or install the provided systemd service
    sudo cp scripts/ivar2.service /etc/systemd/system/ivar2.service
    sudo systemctl daemon-reload
    sudo systemctl start ivar2



Modules
-------

So. Many. Useless. Modules!
And they are written in either Lua or MoonScript.
