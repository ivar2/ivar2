alot = (source, destination, arg, arg2) =>
  -- Ignore URLs
  if arg\match'https?://'
    return
  elseif arg\match'%f[%a][aA][lL][oO][tT]%f[%A]'
    say 'http://hyperboleandahalf.blogspot.no/2010/04/alot-is-better-than-you-at-everything.html'
PRIVMSG:
  '.*[aA][lL][oO][tT].*': alot
