PRIVMSG:
  '^%pupper (.+)$': (source, destination, arg) =>
    say arg\upper!
  '^%plower (.+)$': (source, destination, arg) =>
    say ivar2.util.utf8.lower(arg)
  '^%preverse (.+)$': (source, destination, arg) =>
    say arg\reverse!
  '^%plen (.+)$': (source, destination, arg) =>
    say tostring(arg\len!)
  '^%pnicks$': (source, destination) =>
    chan = ivar2.channels[destination] or ivar2.channels[destination\lower!]
    say table.concat([ivar2.util.nonickalert(chan.nicks, n) for n,k in pairs(chan.nicks)], ' ')
  '^%prandom (.+)$': (source, destination, arg) =>
    words = [word for word in arg\gmatch('%S+')]
    say words[math.random(1, #words)]
  '^%pbold (.+)$': (source, destination, arg) =>
    say ivar2.util.bold(arg)
  '^%punderline (.+)$': (source, destination, arg) =>
    say ivar2.util.underline(arg)
  '^%pitalic (.+)$': (source, destination, arg) =>
    say ivar2.util.italic(arg)
  '^%pinvert (.+)$': (source, destination, arg) =>
    say ivar2.util.reverse(arg)
  '^%ptrim (.+)$': (source, destination, arg) =>
    say ivar2.util.trim(arg)
  '^%pcolor ([0-9]+) (.+)$': (source, destination, color, arg) =>
    say ivar2.util.color(arg, color)
  '^%pfirst (.+)$': (source, destination, arg) =>
    say ivar2.util.split(arg, '%s')[1]
  '^%psplit (.-) (.*)$': (source, destination, arg, args) =>
    say table.concat(ivar2.util.split(args, arg), ' ')
  '^%preplace (.-) (.-) (.*)$': (source, destination, pat, repl, arg) =>
    new, n = string.gsub(arg, pat, repl)
    say(new)
  '^%pnocolor (.*)$': (source, destination, arg) =>
    say ivar2.util.stripformatting(arg)
  '^%pstutter (.*)$': (source, destination, arg) =>
    -- Stutter by anders from luabot
    s_senpai = 0.65
    say arg\gsub("(%a[%w%p]+)", (w) ->
      if math.random! >= s_senpai
        return (w\sub(1, 1).."-")\rep(math.random(1, 3))..w
      else
        return w)
  '^%prot13 (.+)$': (source, destination, arg) =>
    say ivar2.util.rot13(arg)
  '^%phex (.+)$': (source, destination, arg) =>
    say arg\gsub '.', (b) ->
      ('%02x ')\format(b\byte!)
  '^%prtl (.+)$': (source, destination, arg) =>
    say '‮'..arg
  '^%pltr (.+)$': (source, destination, arg) =>
    say '‎'..arg
  '^%pemote (.+)$': (source, destination, arg) =>
    @Action destination, arg
  'botsnack': =>
    replies = {
      'Nom nom nom.'
      'Ooooh'
      'Yummi!'
      'Delightful.'
      'That makes me happy'
      'How kind!'
      'Sweet.'
      "Sorry, but I can't handle more right now."
      "*burp*"
      "Ah.. Hiccup!"
    }
    reply replies[math.random #replies]
  "#{ivar2.config.nick}.?%?": =>
    replies = {
      "Sorry, but I tried my best"
      "I am not fully sentient yet, but I'm learning every day"
      "Please, I tried my best."
      "That was what my very best, just for you"
      "Maybe another time"
      "Sorry, not feeling so good"
      "Oof."
      "Whoopsie."
      "Just give me some time, I will get it eventually"
      "ಠ_ಠ"
      "( ͡° ͜ʖ ͡°) "
    }
    reply replies[math.random #replies]
  --'^%prepeat (%d+) (.*)$': (source, destination, nr, command) =>
  --  for i=1, nr
  --    @DispatchCommand 'PRIVMSG', command, source, destination
