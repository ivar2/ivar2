--fileno = (require "posix").fileno -- could be org.conman.fsys instead
--cqueues = require "cqueues"
--queue = cqueues.new()

PRIVMSG:
  '^%pfortune$': (s, d) =>
    f = assert(io.popen("/usr/games/fortune","r"))
    data = f\read("*a") -- this isn't necessarily correct; if a whole line isn't ready to read it will block
    if data
      say data
    f\close!
    -- nonblocking
    --
--    cnt = 0
--    notdone = true
--    fortune = ''
--    queue\wrap ->
--        f = assert(io.popen("/usr/games/fortune","r"))
--        pollable = {
--            pollfd: fileno(f)
--            events: "r"
--        }
--        while cqueues.poll(pollable) -- yield the current thread until we have data
--          data = f\read("*l") -- this isn't necessarily correct; if a whole line isn't ready to read it will block
--          if data == nil then
--              -- f:read returns nil on EOF
--              f\close()
--              break
--          else
--            fortune = fortune .. data
--        notdone = false
--        say fortune
--    queue\wrap ->
--        while notdone
--            cnt = cnt + 1
--            cqueues.poll() -- yield the current thread
--    queue\loop!
